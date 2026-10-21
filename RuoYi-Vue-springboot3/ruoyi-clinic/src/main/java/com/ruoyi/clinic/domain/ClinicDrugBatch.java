package com.ruoyi.clinic.domain;

import java.math.BigDecimal;
import java.util.Date;
import com.fasterxml.jackson.annotation.JsonFormat;
import com.ruoyi.common.core.domain.BaseEntity;

/**
 * 药品批次库存 clinic_drug_batch
 */
public class ClinicDrugBatch extends BaseEntity {
    private static final long serialVersionUID = 1L;

    private Long batchId;
    private Long drugId;
    private String batchNo;
    private String supplierName;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date productionDate;
    @JsonFormat(pattern = "yyyy-MM-dd")
    private Date expiryDate;
    private Integer inboundQty;
    private Integer availableQty;
    private BigDecimal purchasePrice;
    private String warehouseLocation;
    private String batchStatus;

    public Long getBatchId() { return batchId; }
    public void setBatchId(Long batchId) { this.batchId = batchId; }
    public Long getDrugId() { return drugId; }
    public void setDrugId(Long drugId) { this.drugId = drugId; }
    public String getBatchNo() { return batchNo; }
    public void setBatchNo(String batchNo) { this.batchNo = batchNo; }
    public String getSupplierName() { return supplierName; }
    public void setSupplierName(String supplierName) { this.supplierName = supplierName; }
    public Date getProductionDate() { return productionDate; }
    public void setProductionDate(Date productionDate) { this.productionDate = productionDate; }
    public Date getExpiryDate() { return expiryDate; }
    public void setExpiryDate(Date expiryDate) { this.expiryDate = expiryDate; }
    public Integer getInboundQty() { return inboundQty; }
    public void setInboundQty(Integer inboundQty) { this.inboundQty = inboundQty; }
    public Integer getAvailableQty() { return availableQty; }
    public void setAvailableQty(Integer availableQty) { this.availableQty = availableQty; }
    public BigDecimal getPurchasePrice() { return purchasePrice; }
    public void setPurchasePrice(BigDecimal purchasePrice) { this.purchasePrice = purchasePrice; }
    public String getWarehouseLocation() { return warehouseLocation; }
    public void setWarehouseLocation(String warehouseLocation) { this.warehouseLocation = warehouseLocation; }
    public String getBatchStatus() { return batchStatus; }
    public void setBatchStatus(String batchStatus) { this.batchStatus = batchStatus; }
}