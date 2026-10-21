package com.ruoyi.clinic.service.impl;

import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import com.ruoyi.clinic.domain.ClinicUserPatientBind;
import com.ruoyi.clinic.mapper.ClinicUserPatientBindMapper;
import com.ruoyi.clinic.service.IClinicUserPatientBindService;

@Service
public class ClinicUserPatientBindServiceImpl implements IClinicUserPatientBindService {

    @Autowired
    private ClinicUserPatientBindMapper bindMapper;

    @Override
    public ClinicUserPatientBind selectById(Long bindId) {
        return bindMapper.selectById(bindId);
    }

    @Override
    public List<ClinicUserPatientBind> selectList(ClinicUserPatientBind q) {
        return bindMapper.selectList(q);
    }

    @Override
    public ClinicUserPatientBind selectActiveByUserId(Long userId) {
        return bindMapper.selectActiveByUserId(userId);
    }

    @Override
    public int insert(ClinicUserPatientBind b) {
        return bindMapper.insert(b);
    }

    @Override
    public int update(ClinicUserPatientBind b) {
        return bindMapper.update(b);
    }

    @Override
    public int deleteById(Long bindId) {
        return bindMapper.deleteById(bindId);
    }
}