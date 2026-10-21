package com.ruoyi.clinic.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Param;
import com.ruoyi.clinic.domain.ClinicSchedule;

public interface ClinicScheduleMapper {
    ClinicSchedule selectById(Long scheduleId);
    List<ClinicSchedule> selectList(ClinicSchedule q);
    int insert(ClinicSchedule s);
    int update(ClinicSchedule s);
    int deleteById(Long scheduleId);
    int deleteByIds(Long[] scheduleIds);
    int deductQuota(@Param("scheduleId") Long scheduleId);
    int returnQuota(@Param("scheduleId") Long scheduleId);
}