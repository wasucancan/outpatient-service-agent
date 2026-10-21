-- 门诊管理系统业务表与演示数据。仅创建 clinic_* 新表，不删除或覆盖已有业务数据。
SET NAMES utf8mb4;

CREATE TABLE IF NOT EXISTS clinic_department (
  department_id BIGINT PRIMARY KEY AUTO_INCREMENT, department_code VARCHAR(32) NOT NULL, department_name VARCHAR(64) NOT NULL,
  floor_location VARCHAR(100), phone VARCHAR(32), introduction VARCHAR(1000), sort_order INT DEFAULT 0, status CHAR(1) DEFAULT '0',
  remark VARCHAR(500), create_by VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP, update_by VARCHAR(64), update_time DATETIME,
  UNIQUE KEY uk_clinic_department_code(department_code), KEY idx_clinic_department_status(status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='门诊科室';

CREATE TABLE IF NOT EXISTS clinic_doctor (
  doctor_id BIGINT PRIMARY KEY AUTO_INCREMENT, doctor_no VARCHAR(32) NOT NULL, doctor_name VARCHAR(64) NOT NULL, department_id BIGINT NOT NULL,
  title VARCHAR(50), specialties VARCHAR(500), profile VARCHAR(1000), status CHAR(1) DEFAULT '0', remark VARCHAR(500),
  create_by VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP, update_by VARCHAR(64), update_time DATETIME,
  UNIQUE KEY uk_clinic_doctor_no(doctor_no), KEY idx_clinic_doctor_dept_status(department_id,status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='门诊医生';

CREATE TABLE IF NOT EXISTS clinic_patient (
  patient_id BIGINT PRIMARY KEY AUTO_INCREMENT, patient_no VARCHAR(32) NOT NULL, patient_name VARCHAR(64) NOT NULL, gender CHAR(1),
  birth_date DATE, phone VARCHAR(20) NOT NULL, id_card_masked VARCHAR(30), insurance_type VARCHAR(30), status CHAR(1) DEFAULT '0',
  remark VARCHAR(500), create_by VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP, update_by VARCHAR(64), update_time DATETIME,
  UNIQUE KEY uk_clinic_patient_no(patient_no), KEY idx_clinic_patient_phone(phone), KEY idx_clinic_patient_name(patient_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='患者档案（演示数据均为虚构）';

CREATE TABLE IF NOT EXISTS clinic_schedule (
  schedule_id BIGINT PRIMARY KEY AUTO_INCREMENT, department_id BIGINT NOT NULL, doctor_id BIGINT NOT NULL, visit_date DATE NOT NULL,
  period VARCHAR(8) NOT NULL, start_time TIME NOT NULL, end_time TIME NOT NULL, total_quota INT NOT NULL, remaining_quota INT NOT NULL,
  version INT DEFAULT 0, status VARCHAR(16) DEFAULT 'OPEN', remark VARCHAR(500), create_by VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_by VARCHAR(64), update_time DATETIME, UNIQUE KEY uk_clinic_schedule_doctor_date_period(doctor_id,visit_date,period),
  KEY idx_clinic_schedule_query(department_id,visit_date,period,status), CHECK(total_quota>=0), CHECK(remaining_quota>=0 AND remaining_quota<=total_quota)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='医生排班与号源';

CREATE TABLE IF NOT EXISTS clinic_appointment (
  appointment_id BIGINT PRIMARY KEY AUTO_INCREMENT, appointment_no VARCHAR(40) NOT NULL, patient_id BIGINT NOT NULL, schedule_id BIGINT NOT NULL,
  department_id BIGINT NOT NULL, doctor_id BIGINT NOT NULL, visit_date DATE NOT NULL, period VARCHAR(8) NOT NULL, start_at DATETIME NOT NULL,
  status VARCHAR(20) NOT NULL, active_key TINYINT NULL, cancel_time DATETIME, cancel_reason VARCHAR(500), source VARCHAR(30), operator_id BIGINT,
  create_by VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP, update_by VARCHAR(64), update_time DATETIME,
  UNIQUE KEY uk_clinic_appointment_no(appointment_no), UNIQUE KEY uk_clinic_patient_dept_date_active(patient_id,department_id,visit_date,active_key),
  KEY idx_clinic_appointment_schedule(schedule_id), KEY idx_clinic_appointment_visit(visit_date,status), KEY idx_clinic_appointment_doctor(doctor_id,visit_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='挂号预约单';

CREATE TABLE IF NOT EXISTS clinic_drug (
  drug_id BIGINT PRIMARY KEY AUTO_INCREMENT, drug_code VARCHAR(32) NOT NULL, generic_name VARCHAR(100) NOT NULL, trade_name VARCHAR(100),
  specification VARCHAR(100), dosage_form VARCHAR(50), manufacturer VARCHAR(200), unit VARCHAR(20), warning_days INT DEFAULT 30,
  status CHAR(1) DEFAULT '0', remark VARCHAR(500), create_by VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_by VARCHAR(64), update_time DATETIME, UNIQUE KEY uk_clinic_drug_code(drug_code), KEY idx_clinic_drug_name(generic_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='药品档案';

CREATE TABLE IF NOT EXISTS clinic_drug_batch (
  batch_id BIGINT PRIMARY KEY AUTO_INCREMENT, drug_id BIGINT NOT NULL, batch_no VARCHAR(64) NOT NULL, supplier_name VARCHAR(200),
  production_date DATE, expiry_date DATE NOT NULL, inbound_qty INT NOT NULL, available_qty INT NOT NULL, purchase_price DECIMAL(12,2),
  warehouse_location VARCHAR(100), batch_status VARCHAR(20) DEFAULT 'NORMAL', create_by VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  update_by VARCHAR(64), update_time DATETIME, UNIQUE KEY uk_clinic_drug_batch(drug_id,batch_no),
  KEY idx_clinic_batch_expiry(expiry_date,available_qty), CHECK(inbound_qty>=0), CHECK(available_qty>=0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='药品批次库存';

CREATE TABLE IF NOT EXISTS clinic_drug_stock_record (
  record_id BIGINT PRIMARY KEY AUTO_INCREMENT, record_no VARCHAR(40) NOT NULL, drug_id BIGINT NOT NULL, batch_id BIGINT NOT NULL,
  record_type VARCHAR(16) NOT NULL, quantity INT NOT NULL, operator_name VARCHAR(64), remark VARCHAR(500), create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY uk_clinic_stock_record_no(record_no), KEY idx_clinic_stock_record_batch(batch_id,create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='药品库存流水';

CREATE TABLE IF NOT EXISTS clinic_operation_log (
  log_id BIGINT PRIMARY KEY AUTO_INCREMENT, business_type VARCHAR(32) NOT NULL, business_id BIGINT, business_no VARCHAR(64), action VARCHAR(32) NOT NULL,
  before_status VARCHAR(32), after_status VARCHAR(32), operator_id BIGINT, operator_name VARCHAR(64), result VARCHAR(16), detail VARCHAR(1000),
  source_ip VARCHAR(64), create_time DATETIME DEFAULT CURRENT_TIMESTAMP,
  KEY idx_clinic_operation_business(business_type,business_id), KEY idx_clinic_operation_no(business_no), KEY idx_clinic_operation_time(create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='门诊事务型业务日志';

INSERT IGNORE INTO clinic_department(department_id,department_code,department_name,floor_location,phone,introduction,sort_order,status,create_by) VALUES
(1,'DEP-IM','内科','门诊楼2层东区','021-66081001','提供常见内科疾病初诊、慢病随访和健康评估；急危重症由绿色通道转诊。',10,'0','admin'),
(2,'DEP-SG','外科','门诊楼2层西区','021-66081002','提供普通外科初诊、术后换药和伤口评估，不开展急诊手术。',20,'0','admin'),
(3,'DEP-PD','儿科','门诊楼3层东区','021-66081003','服务0至14岁儿童，设独立候诊区和家长咨询台。',30,'0','admin'),
(4,'DEP-GY','妇科','门诊楼3层西区','021-66081004','提供妇科常见问题咨询、常规检查和复诊服务。',40,'0','admin'),
(5,'DEP-TCM','中医科','门诊楼4层东区','021-66081005','提供中医辨证咨询、针灸推拿前评估及慢病调理服务。',50,'0','admin'),
(6,'DEP-GP','全科医学科','门诊楼1层综合服务区','021-66081006','承担常见健康问题首诊、健康管理和分诊转诊。',60,'0','admin');

INSERT IGNORE INTO clinic_doctor(doctor_id,doctor_no,doctor_name,department_id,title,specialties,profile,status,create_by) VALUES
(101,'D2026001','张明远',1,'主任医师','高血压、糖尿病、慢性咳嗽','从事基层内科临床二十余年，重视慢病连续管理。','0','admin'),
(102,'D2026002','李书宁',1,'主治医师','呼吸道感染、消化系统常见病','擅长常见内科疾病初诊与复诊评估。','0','admin'),
(103,'D2026003','王建华',2,'副主任医师','普通外科、伤口管理','负责普通外科门诊及术后换药评估。','0','admin'),
(104,'D2026004','周景川',2,'主治医师','体表肿物、轻症创伤','擅长基层外科常见问题处理与转诊判断。','0','admin'),
(105,'D2026005','陈雨桐',3,'副主任医师','儿童呼吸、儿童保健','关注儿童合理就医和家庭护理教育。','0','admin'),
(106,'D2026006','赵一诺',3,'主治医师','儿童消化、常见发热','提供儿童常见病初诊与复诊服务。','0','admin'),
(107,'D2026007','孙雅琴',4,'副主任医师','妇科炎症、月经健康','从事妇科门诊工作十五年。','0','admin'),
(108,'D2026008','吴静怡',4,'主治医师','妇科常见病、健康咨询','重视隐私保护和规范转诊。','0','admin'),
(109,'D2026009','钱文博',5,'副主任医师','失眠、脾胃调理','提供中医门诊辨证咨询。','0','admin'),
(110,'D2026010','郑思源',5,'主治医师','颈肩腰腿痛、亚健康调理','负责针灸推拿前评估与中医健康指导。','0','admin'),
(111,'D2026011','何安然',6,'副主任医师','全科首诊、老年健康','擅长多病共存患者的基层连续照护。','0','admin'),
(112,'D2026012','林清和',6,'主治医师','健康评估、分诊转诊','负责常见健康问题初筛和规范转诊。','0','admin');

INSERT IGNORE INTO clinic_patient(patient_id,patient_no,patient_name,gender,birth_date,phone,id_card_masked,insurance_type,status,create_by) VALUES
(1001,'P20260001','顾明哲','0','1982-04-16','13800001001','310***********1021','城镇职工医保','0','frontdesk'),
(1002,'P20260002','沈佳宜','1','1991-11-02','13800001002','310***********2046','城镇职工医保','0','frontdesk'),
(1003,'P20260003','陆承泽','0','2018-07-21','13800001003','310***********3012','城乡居民医保','0','frontdesk'),
(1004,'P20260004','唐婉清','1','1987-03-09','13800001004','310***********4028','自费','0','frontdesk'),
(1005,'P20260005','许知远','0','1958-09-28','13800001005','310***********5055','城镇职工医保','0','frontdesk'),
(1006,'P20260006','程若溪','1','2020-01-14','13800001006','310***********6063','城乡居民医保','0','frontdesk'),
(1007,'P20260007','韩景行','0','1974-06-30','13800001007','310***********7071','城镇职工医保','0','frontdesk'),
(1008,'P20260008','苏念安','1','1996-12-18','13800001008','310***********8084','自费','0','frontdesk'),
(1009,'P20260009','叶嘉树','0','1966-08-05','13800001009','310***********9099','城乡居民医保','0','frontdesk'),
(1010,'P20260010','宋语禾','1','1989-05-23','13800001010','310***********0117','城镇职工医保','0','frontdesk'),
(1011,'P20260011','蒋星河','0','2016-10-11','13800001011','310***********1120','城乡居民医保','0','frontdesk'),
(1012,'P20260012','邵安宁','1','1979-02-07','13800001012','310***********2138','城镇职工医保','0','frontdesk');

INSERT IGNORE INTO clinic_schedule(schedule_id,department_id,doctor_id,visit_date,period,start_time,end_time,total_quota,remaining_quota,status,create_by) VALUES
(5001,1,101,date_add(current_date,interval 1 day),'AM','08:00','12:00',8,8,'OPEN','admin'),
(5002,1,102,date_add(current_date,interval 1 day),'PM','13:30','17:30',10,10,'OPEN','admin'),
(5003,2,103,date_add(current_date,interval 1 day),'AM','08:00','12:00',6,6,'OPEN','admin'),
(5004,3,105,date_add(current_date,interval 1 day),'AM','08:00','12:00',8,8,'OPEN','admin'),
(5005,4,107,date_add(current_date,interval 1 day),'PM','13:30','17:30',8,8,'OPEN','admin'),
(5006,5,109,date_add(current_date,interval 1 day),'PM','13:30','17:30',6,6,'OPEN','admin'),
(5007,6,111,date_add(current_date,interval 1 day),'AM','08:00','12:00',12,12,'OPEN','admin'),
(5011,1,101,date_add(current_date,interval 2 day),'AM','08:00','12:00',8,3,'OPEN','admin'),
(5012,1,102,date_add(current_date,interval 2 day),'PM','13:30','17:30',10,0,'OPEN','admin'),
(5013,2,104,date_add(current_date,interval 2 day),'PM','13:30','17:30',6,2,'OPEN','admin'),
(5014,3,106,date_add(current_date,interval 2 day),'AM','08:00','12:00',8,1,'OPEN','admin'),
(5015,4,108,date_add(current_date,interval 2 day),'AM','08:00','12:00',8,6,'OPEN','admin'),
(5016,5,110,date_add(current_date,interval 2 day),'PM','13:30','17:30',6,4,'OPEN','admin'),
(5017,6,112,date_add(current_date,interval 2 day),'PM','13:30','17:30',12,9,'OPEN','admin'),
(5021,1,101,date_add(current_date,interval 3 day),'PM','13:30','17:30',8,8,'OPEN','admin'),
(5022,2,103,date_add(current_date,interval 3 day),'AM','08:00','12:00',6,6,'OPEN','admin'),
(5023,3,105,date_add(current_date,interval 3 day),'PM','13:30','17:30',8,8,'OPEN','admin'),
(5024,4,107,date_add(current_date,interval 3 day),'AM','08:00','12:00',8,8,'SUSPENDED','admin'),
(5025,5,109,date_add(current_date,interval 3 day),'AM','08:00','12:00',6,6,'OPEN','admin'),
(5026,6,111,date_add(current_date,interval 3 day),'PM','13:30','17:30',12,12,'OPEN','admin');

INSERT IGNORE INTO clinic_drug(drug_id,drug_code,generic_name,trade_name,specification,dosage_form,manufacturer,unit,warning_days,status,create_by) VALUES
(201,'DRG-0001','对乙酰氨基酚片','泰诺林','0.5g×20片','片剂','上海某合规制药有限公司','盒',30,'0','admin'),
(202,'DRG-0002','氯雷他定片','开瑞坦','10mg×6片','片剂','华东某制药有限公司','盒',30,'0','admin'),
(203,'DRG-0003','蒙脱石散','思密达','3g×10袋','散剂','博福某制药有限公司','盒',30,'0','admin'),
(204,'DRG-0004','生理氯化钠溶液','医用生理盐水','500ml','溶液剂','江苏某药业有限公司','瓶',30,'0','admin'),
(205,'DRG-0005','维生素C片','维C片','0.1g×100片','片剂','东北某制药有限公司','瓶',30,'0','admin'),
(206,'DRG-0006','创可贴','弹性创可贴','70mm×18mm×20片','外用耗材','浙江某医疗用品有限公司','盒',60,'0','admin'),
(207,'DRG-0007','碘伏消毒液','医用碘伏','100ml','外用溶液','山东某消毒科技有限公司','瓶',30,'0','admin'),
(208,'DRG-0008','口服补液盐散','ORS III','5.125g×6袋','散剂','安徽某制药有限公司','盒',30,'0','admin');

INSERT IGNORE INTO clinic_drug_batch(batch_id,drug_id,batch_no,supplier_name,production_date,expiry_date,inbound_qty,available_qty,purchase_price,warehouse_location,batch_status,create_by) VALUES
(3001,201,'PCM-260601','申城医药供应链有限公司',date_sub(current_date,interval 60 day),date_add(current_date,interval 300 day),120,86,12.50,'A01-01','NORMAL','admin'),
(3002,202,'LOR-260215','华康医药商业有限公司',date_sub(current_date,interval 150 day),date_add(current_date,interval 28 day),80,32,18.20,'A01-02','NEAR_EXPIRY','admin'),
(3003,203,'MON-251101','江南医药配送有限公司',date_sub(current_date,interval 280 day),date_add(current_date,interval 7 day),100,18,15.80,'A02-01','NEAR_EXPIRY','admin'),
(3004,204,'NS-260701','申城医药供应链有限公司',date_sub(current_date,interval 30 day),date_add(current_date,interval 500 day),60,51,6.30,'B01-01','NORMAL','admin'),
(3005,205,'VC-250101','华康医药商业有限公司',date_sub(current_date,interval 500 day),date_sub(current_date,interval 1 day),50,9,8.60,'Q-EXPIRED','EXPIRED','admin'),
(3006,206,'PLS-260401','安健医疗用品有限公司',date_sub(current_date,interval 90 day),date_add(current_date,interval 720 day),200,164,9.90,'C01-01','NORMAL','admin'),
(3007,207,'IOD-251220','安健医疗用品有限公司',date_sub(current_date,interval 220 day),current_date,72,12,5.60,'Q-WARNING','NEAR_EXPIRY','admin'),
(3008,208,'ORS-260510','江南医药配送有限公司',date_sub(current_date,interval 80 day),date_add(current_date,interval 190 day),90,74,22.00,'A02-02','NORMAL','admin');
