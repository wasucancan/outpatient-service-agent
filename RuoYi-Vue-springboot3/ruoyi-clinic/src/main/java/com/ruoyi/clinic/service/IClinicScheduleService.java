package com.ruoyi.clinic.service;

import java.util.List;
import com.ruoyi.clinic.domain.ClinicSchedule;

/**
 * 排班号源 Service
 */
public interface IClinicScheduleService {
    ClinicSchedule selectById(Long scheduleId);
    List<ClinicSchedule> selectList(ClinicSchedule q);
    int insert(ClinicSchedule s);
    int update(ClinicSchedule s);
    int deleteByIds(Long[] scheduleIds);
}