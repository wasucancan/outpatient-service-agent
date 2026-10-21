package com.ruoyi.clinic.mapper;

import java.util.List;
import com.ruoyi.clinic.domain.ClinicDrugBatch;

public interface ClinicDrugBatchMapper {
    ClinicDrugBatch selectById(Long batchId);
    List<ClinicDrugBatch> selectList(ClinicDrugBatch q);
    int insert(ClinicDrugBatch b);
    int update(ClinicDrugBatch b);
    int deleteById(Long batchId);
    int deleteByIds(Long[] batchIds);
    List<ClinicDrugBatch> selectExpiring();
}