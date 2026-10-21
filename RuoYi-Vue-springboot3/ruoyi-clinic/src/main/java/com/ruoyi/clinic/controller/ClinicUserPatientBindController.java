package com.ruoyi.clinic.controller;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.clinic.domain.ClinicUserPatientBind;
import com.ruoyi.clinic.service.IClinicUserPatientBindService;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;
import com.ruoyi.common.utils.SecurityUtils;

@RestController
@RequestMapping("/clinic/bind")
public class ClinicUserPatientBindController extends BaseController {

    @Autowired
    private IClinicUserPatientBindService bindService;

    @PreAuthorize("@ss.hasPermi('clinic:bind:list')")
    @GetMapping("/list")
    public TableDataInfo list(ClinicUserPatientBind q) {
        startPage();
        List<ClinicUserPatientBind> list = bindService.selectList(q);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('clinic:bind:query')")
    @GetMapping("/{bindId}")
    public AjaxResult getInfo(@PathVariable Long bindId) {
        return success(bindService.selectById(bindId));
    }

    /**
     * 【AI 集成用】取当前登录用户绑定的患者档案
     * 不需要任何 clinic 菜单权限，登录即可访问
     * 返回: { "bindId":.., "patientId":.., "bindType":"SELF" } 或 data=null
     */
    @GetMapping("/me")
    public AjaxResult me() {
        Long userId = SecurityUtils.getUserId();
        ClinicUserPatientBind bind = bindService.selectActiveByUserId(userId);
        if (bind == null) {
            Map<String, Object> empty = new HashMap<>();
            empty.put("bound", false);
            return AjaxResult.success(empty);
        }
        Map<String, Object> data = new HashMap<>();
        data.put("bound", true);
        data.put("bindId", bind.getBindId());
        data.put("patientId", bind.getPatientId());
        data.put("bindType", bind.getBindType());
        data.put("userId", userId);
        return AjaxResult.success(data);
    }

    @PreAuthorize("@ss.hasPermi('clinic:bind:add')")
    @Log(title = "用户-患者绑定", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody ClinicUserPatientBind b) {
        b.setVerifiedBy(SecurityUtils.getUserId());
        return toAjax(bindService.insert(b));
    }

    @PreAuthorize("@ss.hasPermi('clinic:bind:edit')")
    @Log(title = "用户-患者绑定", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody ClinicUserPatientBind b) {
        return toAjax(bindService.update(b));
    }

    @PreAuthorize("@ss.hasPermi('clinic:bind:remove')")
    @Log(title = "用户-患者绑定", businessType = BusinessType.DELETE)
    @DeleteMapping("/{bindId}")
    public AjaxResult remove(@PathVariable Long bindId) {
        return toAjax(bindService.deleteById(bindId));
    }
}