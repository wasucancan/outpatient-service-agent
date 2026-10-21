package com.ruoyi.clinic.controller;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import com.ruoyi.clinic.domain.ClinicDrugBatch;
import com.ruoyi.clinic.service.IClinicDrugBatchService;
import com.ruoyi.common.annotation.Log;
import com.ruoyi.common.core.controller.BaseController;
import com.ruoyi.common.core.domain.AjaxResult;
import com.ruoyi.common.core.page.TableDataInfo;
import com.ruoyi.common.enums.BusinessType;

@RestController
@RequestMapping("/clinic/drugbatch")
public class ClinicDrugBatchController extends BaseController {

    @Autowired
    private IClinicDrugBatchService drugBatchService;

    @PreAuthorize("@ss.hasPermi('clinic:drugbatch:list')")
    @GetMapping("/list")
    public TableDataInfo list(ClinicDrugBatch q) {
        startPage();
        List<ClinicDrugBatch> list = drugBatchService.selectList(q);
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('clinic:drugbatch:query')")
    @GetMapping("/{batchId}")
    public AjaxResult getInfo(@PathVariable Long batchId) {
        return success(drugBatchService.selectById(batchId));
    }

    /** 临期预警清单（30 天内 + 已过期，且库存 > 0） */
    @PreAuthorize("@ss.hasPermi('clinic:drugbatch:expiring')")
    @GetMapping("/expiring")
    public TableDataInfo expiring() {
        startPage();
        List<ClinicDrugBatch> list = drugBatchService.selectExpiring();
        return getDataTable(list);
    }

    @PreAuthorize("@ss.hasPermi('clinic:drugbatch:add')")
    @Log(title = "药品批次", businessType = BusinessType.INSERT)
    @PostMapping
    public AjaxResult add(@RequestBody ClinicDrugBatch b) {
        return toAjax(drugBatchService.insert(b));
    }

    @PreAuthorize("@ss.hasPermi('clinic:drugbatch:edit')")
    @Log(title = "药品批次", businessType = BusinessType.UPDATE)
    @PutMapping
    public AjaxResult edit(@RequestBody ClinicDrugBatch b) {
        return toAjax(drugBatchService.update(b));
    }

    @PreAuthorize("@ss.hasPermi('clinic:drugbatch:remove')")
    @Log(title = "药品批次", businessType = BusinessType.DELETE)
    @DeleteMapping("/{batchIds}")
    public AjaxResult remove(@PathVariable Long[] batchIds) {
        return toAjax(drugBatchService.deleteByIds(batchIds));
    }
}