package com.ruoyi.clinic.service;

import java.util.List;
import com.ruoyi.clinic.domain.ClinicUserPatientBind;

/**
 * 用户-患者绑定 Service
 */
public interface IClinicUserPatientBindService {
    ClinicUserPatientBind selectById(Long bindId);
    List<ClinicUserPatientBind> selectList(ClinicUserPatientBind q);
    ClinicUserPatientBind selectActiveByUserId(Long userId);
    int insert(ClinicUserPatientBind b);
    int update(ClinicUserPatientBind b);
    int deleteById(Long bindId);
}