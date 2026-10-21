-- 仅用于首次建立演示库：先 clinic.sql，再本文件及 clinic_stage3_seed.sql。
-- 完整性与库存业务规则由开发者实现；本发包无须额外迁移脚本即可完成初始化。
-- 已有业务库升级不得重跑演示种子；固定ID用于避免同次初始化重复插入。
-- 执行后基线：6 科室、12 医生、80 患者、100 条未来排班、200 条历史预约、30 药品、60 批次。
SET NAMES utf8mb4;

-- 扩充虚构患者至 80 人。
INSERT IGNORE INTO clinic_patient
  (patient_id,patient_no,patient_name,gender,birth_date,phone,id_card_masked,insurance_type,status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<68)
SELECT 1100+n,
       CONCAT('P2026',LPAD(100+n,5,'0')),
       CONCAT(
         ELT(1+MOD(n-1,17),'陈','林','周','赵','徐','孙','马','朱','胡','郭','何','高','罗','梁','谢','宋','唐'),
         ELT(1+MOD(n-1,19),'安然','嘉宁','景行','若溪','知远','书瑶','明轩','清越','语桐','承宇','思齐','沐阳','婉宁','星河','一诺','嘉树','舒雅','景川','文博')
       ),
       IF(MOD(n,2)=0,'1','0'),
       DATE_ADD('1950-01-01',INTERVAL MOD(n*433,25500) DAY),
       CONCAT('1391000',LPAD(n,4,'0')),
       CONCAT('310***********',LPAD(MOD(n*37,10000),4,'0')),
       ELT(1+MOD(n-1,3),'城镇职工医保','城乡居民医保','自费'),
       '0','seed'
FROM seq;

-- 扩充未来排班至 100 条（原 20 + 新 80）。
INSERT IGNORE INTO clinic_schedule
  (schedule_id,department_id,doctor_id,visit_date,period,start_time,end_time,total_quota,remaining_quota,status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<80)
SELECT 6000+seq.n,d.department_id,d.doctor_id,
       DATE_ADD(CURRENT_DATE,INTERVAL (4+FLOOR((seq.n-1)/12)) DAY),
       IF(MOD(seq.n,2)=1,'AM','PM'),
       IF(MOD(seq.n,2)=1,'08:00:00','13:30:00'),
       IF(MOD(seq.n,2)=1,'12:00:00','17:30:00'),
       6+MOD(seq.n,7),6+MOD(seq.n,7),'OPEN','seed'
FROM seq
JOIN clinic_doctor d ON d.doctor_id=101+MOD(seq.n-1,12);

-- 若脚本跨自然日补跑，自动把已滚动为“今日”的排班缺口补到至少 100 条未来排班。
INSERT IGNORE INTO clinic_schedule
  (schedule_id,department_id,doctor_id,visit_date,period,start_time,end_time,total_quota,remaining_quota,status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<100)
SELECT 6800+seq.n,d.department_id,d.doctor_id,
       DATE_ADD(CURRENT_DATE,INTERVAL (11+FLOOR((seq.n-1)/12)) DAY),
       IF(MOD(seq.n,2)=1,'AM','PM'),
       IF(MOD(seq.n,2)=1,'08:00:00','13:30:00'),
       IF(MOD(seq.n,2)=1,'12:00:00','17:30:00'),
       8,8,'OPEN','seed-topup'
FROM seq
JOIN clinic_doctor d ON d.doctor_id=101+MOD(seq.n-1,12)
WHERE seq.n <= (
  SELECT missing_count FROM (
    SELECT GREATEST(0,100-COUNT(*)) AS missing_count
    FROM clinic_schedule WHERE visit_date>CURRENT_DATE
  ) gap
);

-- 历史统计专用排班，不计入“未来 100 条”口径。
INSERT IGNORE INTO clinic_schedule
  (schedule_id,department_id,doctor_id,visit_date,period,start_time,end_time,total_quota,remaining_quota,status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<20)
SELECT 7000+seq.n,d.department_id,d.doctor_id,
       DATE_SUB(CURRENT_DATE,INTERVAL (1+FLOOR((seq.n-1)/2)) DAY),
       IF(MOD(seq.n,2)=1,'AM','PM'),
       IF(MOD(seq.n,2)=1,'08:00:00','13:30:00'),
       IF(MOD(seq.n,2)=1,'12:00:00','17:30:00'),
       20,10,'CLOSED','seed'
FROM seq
JOIN clinic_doctor d ON d.doctor_id=101+MOD(seq.n-1,12);

-- 扩充药品档案至 30 条，名称、规格、生产企业均为教学模拟。
INSERT IGNORE INTO clinic_drug
  (drug_id,drug_code,generic_name,trade_name,specification,dosage_form,manufacturer,unit,warning_days,status,create_by)
VALUES
(209,'DRG-0009','布洛芬缓释胶囊','模拟品牌A','0.3g×20粒','胶囊剂','华东示例制药有限公司','盒',30,'0','seed'),
(210,'DRG-0010','奥美拉唑肠溶胶囊','模拟品牌B','20mg×14粒','胶囊剂','海州示例药业有限公司','盒',30,'0','seed'),
(211,'DRG-0011','盐酸氨溴索片','模拟品牌C','30mg×20片','片剂','江南示例制药有限公司','盒',30,'0','seed'),
(212,'DRG-0012','复方甘草片','模拟品牌D','100片','片剂','北方示例药业有限公司','瓶',30,'0','seed'),
(213,'DRG-0013','双歧杆菌三联活菌胶囊','模拟品牌E','0.21g×24粒','胶囊剂','沪上示例生物制药有限公司','盒',30,'0','seed'),
(214,'DRG-0014','盐酸西替利嗪片','模拟品牌F','10mg×12片','片剂','齐鲁示例制药有限公司','盒',30,'0','seed'),
(215,'DRG-0015','葡萄糖酸锌口服溶液','模拟品牌G','10ml×12支','口服溶液剂','江城示例药业有限公司','盒',30,'0','seed'),
(216,'DRG-0016','维生素B1片','模拟品牌H','10mg×100片','片剂','东北示例制药有限公司','瓶',30,'0','seed'),
(217,'DRG-0017','维生素B6片','模拟品牌I','10mg×100片','片剂','东北示例制药有限公司','瓶',30,'0','seed'),
(218,'DRG-0018','炉甘石洗剂','模拟品牌J','100ml','洗剂','苏南示例药业有限公司','瓶',30,'0','seed'),
(219,'DRG-0019','红霉素眼膏','模拟品牌K','2g','眼用制剂','宁州示例制药有限公司','支',30,'0','seed'),
(220,'DRG-0020','氯化钠滴眼液','模拟品牌L','10ml','滴眼剂','湖城示例药业有限公司','支',30,'0','seed'),
(221,'DRG-0021','复方薄荷脑鼻用吸入剂','模拟品牌M','0.675g','吸入制剂','南岭示例药业有限公司','支',30,'0','seed'),
(222,'DRG-0022','开塞露','模拟品牌N','20ml×2支','外用溶液','津门示例制药有限公司','盒',30,'0','seed'),
(223,'DRG-0023','碳酸钙D3片','模拟品牌O','30片','片剂','海滨示例制药有限公司','瓶',60,'0','seed'),
(224,'DRG-0024','叶酸片','模拟品牌P','0.4mg×31片','片剂','华中示例制药有限公司','盒',30,'0','seed'),
(225,'DRG-0025','医用棉签','无菌棉签','10cm×50支','医用耗材','安健示例医疗用品有限公司','包',90,'0','seed'),
(226,'DRG-0026','医用纱布块','无菌纱布','8cm×8cm×10片','医用耗材','安健示例医疗用品有限公司','包',90,'0','seed'),
(227,'DRG-0027','一次性使用口罩','医用外科口罩','10只','医用耗材','康护示例医疗器械有限公司','袋',180,'0','seed'),
(228,'DRG-0028','苯扎氯铵贴','创面敷贴','25mm×18mm×20片','外用耗材','浙东示例医疗用品有限公司','盒',60,'0','seed'),
(229,'DRG-0029','复方门冬维甘滴眼液','模拟品牌Q','10ml','滴眼剂','华北示例制药有限公司','支',30,'0','seed'),
(230,'DRG-0030','乳酸菌素片','模拟品牌R','0.4g×60片','片剂','中原示例制药有限公司','盒',30,'0','seed');

-- 扩充至 60 个批次，覆盖正常、30 天内临期、当天到期和过期场景。
INSERT IGNORE INTO clinic_drug_batch
  (batch_id,drug_id,batch_no,supplier_name,production_date,expiry_date,inbound_qty,available_qty,purchase_price,warehouse_location,batch_status,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<52)
SELECT 3100+seq.n,
       201+MOD(seq.n-1,30),
       CONCAT('ENT-',DATE_FORMAT(CURRENT_DATE,'%y%m'),'-',LPAD(seq.n,3,'0')),
       ELT(1+MOD(seq.n-1,4),'申城医药供应链有限公司','华康医药商业有限公司','江南医药配送有限公司','安健医疗用品有限公司'),
       DATE_SUB(CURRENT_DATE,INTERVAL (60+MOD(seq.n*7,240)) DAY),
       CASE
         WHEN MOD(seq.n,13)=0 THEN DATE_SUB(CURRENT_DATE,INTERVAL 2 DAY)
         WHEN MOD(seq.n,11)=0 THEN CURRENT_DATE
         WHEN MOD(seq.n,5)=0 THEN DATE_ADD(CURRENT_DATE,INTERVAL (5+MOD(seq.n,25)) DAY)
         ELSE DATE_ADD(CURRENT_DATE,INTERVAL (120+MOD(seq.n*17,500)) DAY)
       END,
       40+MOD(seq.n*9,120),
       10+MOD(seq.n*7,35),
       ROUND(4.50+MOD(seq.n*37,2600)/100,2),
       CONCAT(ELT(1+MOD(seq.n-1,3),'A','B','C'),LPAD(1+MOD(seq.n-1,12),2,'0'),'-',LPAD(1+MOD(seq.n-1,4),2,'0')),
       CASE
         WHEN MOD(seq.n,13)=0 THEN 'EXPIRED'
         WHEN MOD(seq.n,11)=0 OR MOD(seq.n,5)=0 THEN 'NEAR_EXPIRY'
         ELSE 'NORMAL'
       END,
       'seed'
FROM seq;

-- 200 条历史预约供统计页演示。非取消记录保留同日同科室唯一约束。
-- 患者重复轮次切换历史日期，避免生成同患者同日同科室的重复就诊。
INSERT IGNORE INTO clinic_appointment
  (appointment_id,appointment_no,patient_id,schedule_id,department_id,doctor_id,visit_date,period,start_at,status,active_key,cancel_time,cancel_reason,source,operator_id,create_by,create_time)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<200)
SELECT 10000+seq.n,
       CONCAT('YYH',DATE_FORMAT(s.visit_date,'%Y%m%d'),LPAD(seq.n,5,'0')),
       CASE WHEN MOD(seq.n-1,80)<12 THEN 1001+MOD(seq.n-1,80) ELSE 1101+(MOD(seq.n-1,80)-12) END,
       s.schedule_id,s.department_id,s.doctor_id,s.visit_date,s.period,
       TIMESTAMP(s.visit_date,s.start_time),
       CASE WHEN MOD(seq.n,10)=0 THEN 'CANCELLED' WHEN MOD(seq.n,10)=1 THEN 'NO_SHOW' ELSE 'COMPLETED' END,
       IF(MOD(seq.n,10)=0,NULL,1),
       CASE WHEN MOD(seq.n,10)=0 THEN TIMESTAMP(DATE_SUB(s.visit_date,INTERVAL 1 DAY),'10:00:00') ELSE NULL END,
       CASE WHEN MOD(seq.n,10)=0 THEN '历史样本：患者提前取消' ELSE NULL END,
       'MIGRATION',1,'seed',TIMESTAMP(DATE_SUB(s.visit_date,INTERVAL 2 DAY),'09:00:00')
FROM seq
JOIN clinic_schedule s ON s.schedule_id=7001+MOD(seq.n-1+4*FLOOR((seq.n-1)/80),20);

-- 演示历史排班的已用号源与非取消预约数量保持一致。
UPDATE clinic_schedule s SET s.remaining_quota=s.total_quota-(SELECT COUNT(*) FROM clinic_appointment a WHERE a.schedule_id=s.schedule_id AND a.status<>'CANCELLED')
WHERE s.schedule_id BETWEEN 7001 AND 7020 AND s.create_by='seed';


-- 为基础种子的低余号/满号场景补齐对应预约，避免有扣号却无预约的演示数据。
INSERT IGNORE INTO clinic_appointment
(appointment_id,appointment_no,patient_id,schedule_id,department_id,doctor_id,visit_date,period,start_at,status,active_key,source,operator_id,create_by)
WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<20),
occupied AS (
 SELECT s.*,ROW_NUMBER() OVER(ORDER BY s.schedule_id,seq.n) patient_index
 FROM clinic_schedule s JOIN seq ON seq.n<=s.total_quota-s.remaining_quota
 WHERE s.schedule_id IN (5011,5012,5013,5014,5015,5016,5017)
)
SELECT 90000+patient_index,CONCAT('YYH',DATE_FORMAT(visit_date,'%Y%m%d'),LPAD(90000+patient_index,5,'0')),
 IF(patient_index<=12,1000+patient_index,1100+patient_index-12),schedule_id,department_id,doctor_id,
 visit_date,period,TIMESTAMP(visit_date,start_time),'BOOKED',1,'MIGRATION',1,'seed'
FROM occupied;

-- 为全部演示批次生成可追溯入库流水与业务日志。
INSERT IGNORE INTO clinic_drug_stock_record
  (record_id,record_no,drug_id,batch_id,record_type,quantity,operator_name,remark,create_time)
SELECT 20000+b.batch_id,CONCAT('RK-SEED-',b.batch_id),b.drug_id,b.batch_id,'IN',b.inbound_qty,'seed','企业级演示数据初始化',b.create_time
FROM clinic_drug_batch b;

INSERT INTO clinic_operation_log
  (business_type,business_id,business_no,action,before_status,after_status,operator_id,operator_name,result,detail,source_ip,create_time)
SELECT 'DRUG_BATCH',b.batch_id,b.batch_no,'STOCK_IN',NULL,b.batch_status,1,'seed','SUCCESS',
       CONCAT('演示批次入库 ',b.inbound_qty,' ',d.unit),'127.0.0.1',b.create_time
FROM clinic_drug_batch b
JOIN clinic_drug d ON d.drug_id=b.drug_id
WHERE NOT EXISTS (
  SELECT 1 FROM clinic_operation_log l
  WHERE l.business_type='DRUG_BATCH' AND l.business_id=b.batch_id AND l.action='STOCK_IN'
);
