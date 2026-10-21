package com.ruoyi.clinic.service;

import java.util.List;
import com.ruoyi.clinic.domain.ClinicAppointment;

/**
 * 挂号预约 Service
 */
public interface IClinicAppointmentService {
    ClinicAppointment selectById(Long appointmentId);
    List<ClinicAppointment> selectList(ClinicAppointment q);
    int deleteByIds(Long[] appointmentIds);

    /**
     * 挂号（号源事务 + 限约 + 日志）
     * @param patientId   患者ID（必须来自可信登录态）
     * @param scheduleId  排班ID
     * @param source      来源 WEB/AI/FRONTDESK
     * @param operatorId  操作人ID
     * @return 预约单（含取号凭证号）
     */
    ClinicAppointment book(Long patientId, Long scheduleId, String source, Long operatorId);

    /**
     * 取消（2 小时规则 + 返号 + 日志）
     */
    void cancel(Long appointmentId, String reason, Long operatorId);
}