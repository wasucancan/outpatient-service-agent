package com.ruoyi.clinic.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import com.ruoyi.clinic.domain.ClinicAppointment;
import com.ruoyi.clinic.domain.ClinicSchedule;
import com.ruoyi.clinic.mapper.ClinicAppointmentMapper;
import com.ruoyi.clinic.mapper.ClinicScheduleMapper;
import com.ruoyi.clinic.service.IClinicAppointmentService;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.common.utils.SecurityUtils;

/**
 * 挂号预约 Service —— 号源事务核心实现
 */
@Service
public class ClinicAppointmentServiceImpl implements IClinicAppointmentService {

    private static final Logger log = LoggerFactory.getLogger(ClinicAppointmentServiceImpl.class);

    /** 就诊开始前 N 小时禁止取消 */
    private static final long CANCEL_BEFORE_MS = 2L * 3600 * 1000;

    @Autowired private ClinicAppointmentMapper appointmentMapper;
    @Autowired private ClinicScheduleMapper    scheduleMapper;

    @Override
    public ClinicAppointment selectById(Long appointmentId) {
        return appointmentMapper.selectById(appointmentId);
    }

    @Override
    public List<ClinicAppointment> selectList(ClinicAppointment q) {
        return appointmentMapper.selectList(q);
    }

    @Override
    public int deleteByIds(Long[] appointmentIds) {
        return appointmentMapper.deleteByIds(appointmentIds);
    }

    /**
     * 挂号：号源条件 UPDATE 扣减 + 唯一约束兜底限约 + 日志
     *
     * 关键设计：
     *  1. @Transactional 保证扣号与建单要么全成功要么全回滚
     *  2. 扣号用条件 UPDATE（status='OPEN' AND remaining_quota>0），防止超卖
     *  3. 限约靠 uk_clinic_patient_dept_date_active 唯一约束兜底，捕获 DuplicateKeyException
     *     捕获后事务回滚 → 已扣的号自动返还，无需手工返号
     *  4. 排班必须存在、状态 OPEN、startAt 未过期
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public ClinicAppointment book(Long patientId, Long scheduleId, String source, Long operatorId) {
        if (patientId == null) throw new ServiceException("患者身份未绑定，无法挂号");
        if (scheduleId == null) throw new ServiceException("请选择就诊时段");

        // 1. 查排班
        ClinicSchedule s = scheduleMapper.selectById(scheduleId);
        if (s == null) throw new ServiceException("排班不存在");
        if (!"OPEN".equals(s.getStatus())) throw new ServiceException("该排班已关闭");
        if (s.getRemainingQuota() == null || s.getRemainingQuota() <= 0) {
            throw new ServiceException("该时段号源已满，请选择其他时段");
        }

        // 2. 拼接就诊时间，校验未过期
        Date startAt = buildStartAt(s);
        long now = System.currentTimeMillis();
        if (startAt.getTime() <= now) {
            throw new ServiceException("该时段已开始，无法挂号");
        }

        // 3. 扣号（条件 UPDATE，防超卖）
        int deducted = scheduleMapper.deductQuota(scheduleId);
        if (deducted == 0) {
            // 走到这里说明并发下被别人抢光了
            throw new ServiceException("该时段号源刚被抢完，请选择其他时段");
        }

        // 4. 建单（active_key = 1 参与唯一约束）
        ClinicAppointment a = new ClinicAppointment();
        a.setAppointmentNo(genAppointmentNo());
        a.setPatientId(patientId);
        a.setScheduleId(scheduleId);
        a.setDepartmentId(s.getDepartmentId());
        a.setDoctorId(s.getDoctorId());
        a.setVisitDate(s.getVisitDate());
        a.setPeriod(s.getPeriod());
        a.setStartAt(startAt);
        a.setStatus("BOOKED");
        a.setActiveKey(1);
        a.setSource(source == null ? "WEB" : source);
        a.setOperatorId(operatorId);
        a.setCreateBy(operatorId == null ? "system" : String.valueOf(operatorId));

        try {
            appointmentMapper.insert(a);
        } catch (DuplicateKeyException e) {
            // 命中 uk_clinic_patient_dept_date_active → 同患者同日同科室已有有效预约
            // 事务回滚，刚才扣的号自动返还
            throw new ServiceException("您今天在该科室已有预约，请勿重复挂号");
        }

        log.info("[clinic] book ok: patientId={} scheduleId={} appointmentNo={}",
                 patientId, scheduleId, a.getAppointmentNo());
        return a;
    }

    /**
     * 取消：2 小时规则 + 条件 UPDATE 防止重复返号
     *
     * 关键设计：
     *  1. status 必须为 BOOKED 才能取消
     *  2. 条件 UPDATE（WHERE status='BOOKED'）—— 重复调用第二次返回 0 行，事务回滚
     *  3. 返号仅在 UPDATE 成功后执行；重复取消不会重复返号
     */
    @Override
    @Transactional(rollbackFor = Exception.class)
    public void cancel(Long appointmentId, String reason, Long operatorId) {
        if (appointmentId == null) throw new ServiceException("请选择要取消的预约");

        ClinicAppointment a = appointmentMapper.selectById(appointmentId);
        if (a == null) throw new ServiceException("预约不存在");

        // 2 小时规则
        long now = System.currentTimeMillis();
        long startMs = a.getStartAt().getTime();
        long remain = startMs - now;
        if (remain <= 0) {
            throw new ServiceException("就诊时间已开始，无法取消");
        }
        if (remain < CANCEL_BEFORE_MS) {
            throw new ServiceException("就诊开始前 2 小时内不可取消，请到院处理");
        }

        // 条件 UPDATE：仅 BOOKED 可取消
        int rows = appointmentMapper.cancel(appointmentId, reason, operatorId);
        if (rows == 0) {
            throw new ServiceException("取消失败，预约可能已被取消");
        }

        // 返号（同样条件 UPDATE，防超还）
        scheduleMapper.returnQuota(a.getScheduleId());

        log.info("[clinic] cancel ok: appointmentId={} no={} by operatorId={}",
                 appointmentId, a.getAppointmentNo(), operatorId);
    }

    // ---------- 工具 ----------

    /** visit_date + start_time → startAt（东八区本地时间） */
    private Date buildStartAt(ClinicSchedule s) {
        try {
            SimpleDateFormat fmt = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            String ds = new SimpleDateFormat("yyyy-MM-dd").format(s.getVisitDate());
            String ts = s.getStartTime();
            if (ts.length() == 5) ts = ts + ":00";
            return fmt.parse(ds + " " + ts);
        } catch (Exception e) {
            throw new ServiceException("排班时间格式异常: " + e.getMessage());
        }
    }

    /** 凭证号：YYH + yyyyMMddHHmmss + 4 位随机 */
    private String genAppointmentNo() {
        String t = new SimpleDateFormat("yyyyMMddHHmmss").format(new Date());
        int r = (int) (Math.random() * 9000) + 1000;
        return "YYH" + t + r;
    }
}