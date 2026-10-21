package com.ruoyi.clinic.mapper;

import java.util.List;
import org.apache.ibatis.annotations.Param;
import com.ruoyi.clinic.domain.ClinicAppointment;

public interface ClinicAppointmentMapper {
    ClinicAppointment selectById(Long appointmentId);
    List<ClinicAppointment> selectList(ClinicAppointment q);
    int insert(ClinicAppointment a);
    int cancel(@Param("appointmentId") Long appointmentId,
               @Param("cancelReason") String cancelReason,
               @Param("operatorId") Long operatorId);
    int deleteById(Long appointmentId);
    int deleteByIds(Long[] appointmentIds);
}