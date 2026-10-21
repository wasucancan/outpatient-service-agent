package com.ruoyi.clinic.service;

import java.util.List;
import com.ruoyi.clinic.domain.ClinicDrugBatch;

/**
 * 药品批次 Service
 */
public interface IClinicDrugBatchService {
    ClinicDrugBatch selectById(Long batchId);
    List<ClinicDrugBatch> selectList(ClinicDrugBatch q);
    int insert(ClinicDrugBatch b);
    int update(ClinicDrugBatch b);
    int deleteByIds(Long[] batchIds);
    /** 临期（30 天）+ 已过期，且 available_qty > 0 */
    List<ClinicDrugBatch> selectExpiring();
}