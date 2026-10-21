package com.ruoyi.clinic.domain;

import java.util.Date;
import com.ruoyi.common.core.domain.BaseEntity;

/**
 * 用户-患者身份绑定 clinic_user_patient_bind
 */
public class ClinicUserPatientBind extends BaseEntity {
    private static final long serialVersionUID = 1L;

    private Long bindId;
    private Long userId;
    private Long patientId;
    private String bindType;
    private Long verifiedBy;
    private Date verifyTime;
    private String status;

    public Long getBindId() { return bindId; }
    public void setBindId(Long bindId) { this.bindId = bindId; }
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getPatientId() { return patientId; }
    public void setPatientId(Long patientId) { this.patientId = patientId; }
    public String getBindType() { return bindType; }
    public void setBindType(String bindType) { this.bindType = bindType; }
    public Long getVerifiedBy() { return verifiedBy; }
    public void setVerifiedBy(Long verifiedBy) { this.verifiedBy = verifiedBy; }
    public Date getVerifyTime() { return verifyTime; }
    public void setVerifyTime(Date verifyTime) { this.verifyTime = verifyTime; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
}