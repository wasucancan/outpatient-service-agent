package com.ruoyi.clinic.service.impl;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.ruoyi.clinic.domain.ClinicSchedule;
import com.ruoyi.clinic.mapper.ClinicScheduleMapper;
import com.ruoyi.clinic.service.IClinicScheduleService;

@Service
public class ClinicScheduleServiceImpl implements IClinicScheduleService {

    @Autowired
    private ClinicScheduleMapper scheduleMapper;

    @Override
    public ClinicSchedule selectById(Long scheduleId) {
        return scheduleMapper.selectById(scheduleId);
    }

    @Override
    public List<ClinicSchedule> selectList(ClinicSchedule q) {
        return scheduleMapper.selectList(q);
    }

    @Override
    public int insert(ClinicSchedule s) {
        return scheduleMapper.insert(s);
    }

    @Override
    public int update(ClinicSchedule s) {
        return scheduleMapper.update(s);
    }

    @Override
    public int deleteByIds(Long[] scheduleIds) {
        return scheduleMapper.deleteByIds(scheduleIds);
    }
}