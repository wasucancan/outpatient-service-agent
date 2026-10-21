package com.ruoyi.clinic.mapper;

import java.util.List;
import com.ruoyi.clinic.domain.ClinicUserPatientBind;

public interface ClinicUserPatientBindMapper {
    ClinicUserPatientBind selectById(Long bindId);
    List<ClinicUserPatientBind> selectList(ClinicUserPatientBind q);
    ClinicUserPatientBind selectActiveByUserId(Long userId);
    int insert(ClinicUserPatientBind b);
    int update(ClinicUserPatientBind b);
    int deleteById(Long bindId);
}