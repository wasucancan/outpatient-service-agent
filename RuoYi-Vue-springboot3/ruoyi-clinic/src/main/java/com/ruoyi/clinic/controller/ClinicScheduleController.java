package com.ruoyi.clinic.controller;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.clinic.domain.ClinicSchedule;
import com.ruoyi.clinic.service.IClinicScheduleService;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;

@RestController
@RequestMapping("/clinic/schedule")
public class ClinicScheduleController extends BaseController {

    @Autowired
    private IClinicScheduleService scheduleService;

    @PreAuthorize("@ss.hasPermi('clinic:schedule:list')")
    @GetMapping("/list")
    public TableDataInfo list(ClinicSchedule q) {
        startPage();
        List<ClinicSchedule> list = scheduleService.selectList(q);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('clinic:schedule:query')")
    @GetMapping("/{scheduleId}")
    public AjaxResult getInfo(@PathVariable Long scheduleId) {
        return success(scheduleService.selectById(scheduleId));
    }

    @PreAuthorize("@ss.hasPermi('clinic:schedule:add')")
    @Log(title = "门诊排班", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody ClinicSchedule s) {
        return toAjax(scheduleService.insert(s));
    }

    @PreAuthorize("@ss.hasPermi('clinic:schedule:edit')")
    @Log(title = "门诊排班", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody ClinicSchedule s) {
        return toAjax(scheduleService.update(s));
    }

    @PreAuthorize("@ss.hasPermi('clinic:schedule:remove')")
    @Log(title = "门诊排班", businessType = BusinessType.DELETE)
    @DeleteMapping("/{scheduleIds}")
    public AjaxResult remove(@PathVariable Long[] scheduleIds) {
        return toAjax(scheduleService.deleteByIds(scheduleIds));
    }
}