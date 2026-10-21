package com.ruoyi.clinic.controller;

import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.clinic.domain.ClinicAppointment;
import com.ruoyi.clinic.domain.ClinicUserPatientBind;
import com.ruoyi.clinic.service.IClinicAppointmentService;
import com.ruoyi.clinic.service.IClinicUserPatientBindService;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.exception.ServiceException;
import com.ruoyi.common.utils.SecurityUtils;

@RestController
@RequestMapping("/clinic/appointment")
public class ClinicAppointmentController extends BaseController {

    @Autowired private IClinicAppointmentService appointmentService;
    @Autowired private IClinicUserPatientBindService bindService;

    @PreAuthorize("@ss.hasPermi('clinic:appointment:list')")
    @GetMapping("/list")
    public TableDataInfo list(ClinicAppointment q) {
        startPage();
        List<ClinicAppointment> list = appointmentService.selectList(q);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('clinic:appointment:query')")
    @GetMapping("/{appointmentId}")
    public AjaxResult getInfo(@PathVariable Long appointmentId) {
        return success(appointmentService.selectById(appointmentId));
    }

    /**
     * 挂号：patientId 从登录态绑定的患者档案取，不接受前端传入
     * body: { "scheduleId": 5001, "source": "WEB" }
     */
    @PreAuthorize("@ss.hasPermi('clinic:appointment:book')")
    @Log(title = "门诊挂号", businessType = BusinessType.INSERT)
    @PostMapping("/book")
    public AjaxResult book(@RequestBody Map<String, Object> body) {
        Long currentUserId = SecurityUtils.getUserId();
        ClinicUserPatientBind bind = bindService.selectActiveByUserId(currentUserId);
        if (bind == null) throw new ServiceException("当前账号未绑定患者档案，无法挂号");

        Object sObj = body.get("scheduleId");
        if (sObj == null) throw new ServiceException("请选择就诊时段");
        Long scheduleId = Long.valueOf(sObj.toString());
        String source = body.get("source") == null ? "WEB" : body.get("source").toString();

        ClinicAppointment a = appointmentService.book(bind.getPatientId(), scheduleId, source, currentUserId);
        return success(a);
    }

    /**
     * 取消：body: { "reason": "xxx" }
     */
    @PreAuthorize("@ss.hasPermi('clinic:appointment:cancel')")
    @Log(title = "门诊取消预约", businessType = BusinessType.UPDATE)
    @PostMapping("/cancel/{appointmentId}")
    public AjaxResult cancel(@PathVariable Long appointmentId,
                             @RequestBody(required = false) Map<String, String> body) {
        String reason = body == null ? null : body.get("reason");
        appointmentService.cancel(appointmentId, reason, SecurityUtils.getUserId());
        return success();
    }

    @PreAuthorize("@ss.hasPermi('clinic:appointment:remove')")
    @Log(title = "门诊预约", businessType = BusinessType.DELETE)
    @DeleteMapping("/{appointmentIds}")
    public AjaxResult remove(@PathVariable Long[] appointmentIds) {
        return toAjax(appointmentService.deleteByIds(appointmentIds));
    }
}