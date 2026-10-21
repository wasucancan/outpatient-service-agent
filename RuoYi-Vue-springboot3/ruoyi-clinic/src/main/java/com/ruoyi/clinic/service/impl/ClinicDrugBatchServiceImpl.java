package com.ruoyi.clinic.service.impl;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.ruoyi.clinic.domain.ClinicDrugBatch;
import com.ruoyi.clinic.mapper.ClinicDrugBatchMapper;
import com.ruoyi.clinic.service.IClinicDrugBatchService;

@Service
public class ClinicDrugBatchServiceImpl implements IClinicDrugBatchService {

    @Autowired
    private ClinicDrugBatchMapper drugBatchMapper;

    @Override
    public ClinicDrugBatch selectById(Long batchId) {
        return drugBatchMapper.selectById(batchId);
    }

    @Override
    public List<ClinicDrugBatch> selectList(ClinicDrugBatch q) {
        return drugBatchMapper.selectList(q);
    }

    @Override
    public int insert(ClinicDrugBatch b) {
        return drugBatchMapper.insert(b);
    }

    @Override
    public int update(ClinicDrugBatch b) {
        return drugBatchMapper.update(b);
    }

    @Override
    public int deleteByIds(Long[] batchIds) {
        return drugBatchMapper.deleteByIds(batchIds);
    }

    @Override
    public List<ClinicDrugBatch> selectExpiring() {
        return drugBatchMapper.selectExpiring();
    }
}