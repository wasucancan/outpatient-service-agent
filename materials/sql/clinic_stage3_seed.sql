-- 阶段三首次教学初始化增量。仅在空白演示库执行：
-- clinic.sql -> clinic_enterprise_seed.sql -> 本文件。
-- 完整性、库存和智能体相关迁移由开发者按实现设计；本发包无须额外迁移脚本即可完成初始化。
-- 不用于已有业务库补数据，不移动既有排班日期。固定ID确保同一天重复执行不增量。
-- 旧基线上增加50条未来排班、100条历史预约、20药品批次，对应需求10的150/300/80。
SET NAMES utf8mb4;
START TRANSACTION;

INSERT IGNORE INTO clinic_schedule
(schedule_id,department_id,doctor_id,visit_date,period,start_time,end_time,total_quota,remaining_quota,status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<50)
SELECT 8000+n,d.department_id,d.doctor_id,DATE_ADD(CURRENT_DATE,INTERVAL (22+FLOOR((n-1)/12)) DAY),
IF(MOD(n,2)=1,'AM','PM'),IF(MOD(n,2)=1,'08:00:00','13:30:00'),IF(MOD(n,2)=1,'12:00:00','17:30:00'),
10,10,'OPEN','stage3-seed'
FROM seq JOIN clinic_doctor d ON d.doctor_id=101+MOD(n-1,12);

INSERT IGNORE INTO clinic_schedule
(schedule_id,department_id,doctor_id,visit_date,period,start_time,end_time,total_quota,remaining_quota,status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<10)
SELECT 8100+n,d.department_id,d.doctor_id,DATE_SUB(CURRENT_DATE,INTERVAL (20+n) DAY),
'AM','08:00:00','12:00:00',20,20,'CLOSED','stage3-seed'
FROM seq JOIN clinic_doctor d ON d.doctor_id=101+MOD(n-1,12);

INSERT IGNORE INTO clinic_appointment
(appointment_id,appointment_no,patient_id,schedule_id,department_id,doctor_id,visit_date,period,start_at,status,active_key,cancel_time,cancel_reason,source,operator_id,create_by,create_time)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<100)
SELECT 120000+n,CONCAT('YY3H',LPAD(n,6,'0')),1101+MOD(n-1,68),s.schedule_id,s.department_id,s.doctor_id,
s.visit_date,s.period,TIMESTAMP(s.visit_date,s.start_time),IF(MOD(n,10)=0,'CANCELLED','COMPLETED'),
IF(MOD(n,10)=0,NULL,1),IF(MOD(n,10)=0,TIMESTAMP(DATE_SUB(s.visit_date,INTERVAL 1 DAY),'10:00:00'),NULL),
IF(MOD(n,10)=0,'教学历史预约：提前取消',NULL),'MIGRATION',1,'stage3-seed',TIMESTAMP(DATE_SUB(s.visit_date,INTERVAL 2 DAY),'09:00:00')
FROM seq JOIN clinic_schedule s ON s.schedule_id=8101+FLOOR((n-1)/10);

UPDATE clinic_schedule s SET remaining_quota=total_quota-(SELECT COUNT(*) FROM clinic_appointment a WHERE a.schedule_id=s.schedule_id AND a.status<>'CANCELLED')
WHERE s.schedule_id BETWEEN 8101 AND 8110 AND s.create_by='stage3-seed';

INSERT IGNORE INTO clinic_drug_batch
(batch_id,drug_id,batch_no,supplier_name,production_date,expiry_date,inbound_qty,available_qty,purchase_price,warehouse_location,batch_status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<20)
SELECT 4100+n,201+MOD(n-1,30),CONCAT('STAGE3-',LPAD(n,3,'0')),'教学模拟配送企业',DATE_SUB(CURRENT_DATE,INTERVAL 180 DAY),
DATE_ADD(CURRENT_DATE,INTERVAL (CASE WHEN n=1 THEN -1 WHEN n=2 THEN 0 WHEN n=3 THEN 30 WHEN n=4 THEN 31 ELSE 100+n END) DAY),
50,50,10,'S3-A01',CASE WHEN n=1 THEN 'EXPIRED' WHEN n IN(2,3) THEN 'NEAR_EXPIRY' ELSE 'NORMAL' END,'stage3-seed'
FROM seq;

INSERT IGNORE INTO clinic_drug_stock_record
(record_id,record_no,drug_id,batch_id,record_type,quantity,operator_name,remark,create_time)
SELECT 20000+b.batch_id,CONCAT('RK-STAGE3-',b.batch_id),b.drug_id,b.batch_id,'IN',b.inbound_qty,'stage3-seed','阶段三教学批次初始化',b.create_time
FROM clinic_drug_batch b WHERE b.create_by='stage3-seed';

INSERT INTO clinic_operation_log
(business_type,business_id,business_no,action,before_status,after_status,operator_id,operator_name,result,detail,source_ip,create_time)
SELECT 'DRUG_BATCH',b.batch_id,b.batch_no,'STOCK_IN',NULL,b.batch_status,1,'stage3-seed','SUCCESS',
CONCAT('教学批次入库 ',b.inbound_qty),'127.0.0.1',b.create_time
FROM clinic_drug_batch b WHERE b.create_by='stage3-seed' AND NOT EXISTS(
SELECT 1 FROM clinic_operation_log l WHERE l.business_type='DRUG_BATCH' AND l.business_id=b.batch_id AND l.action='STOCK_IN');
COMMIT;
