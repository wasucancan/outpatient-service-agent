# 阶段三门诊 AI 就诊助手：新手开发起点

本目录是与 `proj2-2-OCMS/base` **不同**的若依版起点。后端使用 RuoYi v3.9.2 的 Spring Boot 3 多模块结构，前端使用 RuoYi Vue3；系统用户、角色、菜单、字典、操作日志、登录鉴权和代码生成器已经提供。`ruoyi-clinic`、门诊页面、菜单及 AI 业务实现尚未提供，需由学员完成。完整参考成品位于上一级目录，不属于学员发包内容。

此底座从本项目的若依工程提取并剔除门诊业务，保留了当前工程的 Spring Boot 3、Vue3 依赖版本及部分通用安全修订。它是**项目适配的若依基础版**，并非经上游校验的官方原版源码快照。若考核必须逐字使用官方原版，授课方应另行提供经核验的 RuoYi v3.9.2 源码并明确版本差异。

## 下发顺序与目录

1. 先读 [正式题目](./[下发文件]考核-需求开发文档.md)，再读 [新手开发任务书](./新手开发任务书.md)。正式题目是功能和评分基准；任务书明确本底座的已有能力、资料位置、操作顺序与验收边界。
2. `RuoYi-Vue-springboot3/`：可编译的若依后端；`sql/ry_20260417.sql` 与 `sql/quartz.sql` 仅用于**全新空白库**的系统表初始化。
3. `RuoYi-Vue3-master/`：可构建的若依前端；首页是中性欢迎页，无门诊业务页面。
4. `agent-template/`：可启动的 FastAPI + LangGraph + SSE 技术模板，只演示技术链路，不含检索、工具、写操作或医疗护栏的业务答案。
5. `materials/sql/`：题目承诺的门诊业务表与模拟数据；`materials/dify-knowledge-import/` 是阶段二 `base` 中8篇权威原文的逐字发包副本；`materials/stage3-knowledge/` 有 18 篇带科室标签的适配稿，来源清单见 `materials/knowledge-provenance.json`。发包后可运行 `python3 materials/verify_knowledge.py` 核验摘要；在两个项目同处工作区且当前目录为本 `base/` 时，另传 `--canonical ../../proj2-2-OCMS/base/dify-knowledge-import` 做原文逐字核验。`materials/dialogue-cases-45.json` 仅包含 45 段题目输入，不含参考答案或通过判据。

## 首次启动

准备 JDK 17、Maven 3.9、Node.js 22、MySQL 8、Redis 和 Python 3.13。以下示例使用本地 MySQL 3308、Redis 6379；按实际环境调整。基础系统与完整成品分别使用 `ocms_ruoyi_starter` / `proj3_2_clinic`，Redis DB 7 / 2，后端 8087 / 8080，前端 3007 / 原工程端口。不要把此起点连接到成品库。

在**不存在的空白库**创建 `ocms_ruoyi_starter`，然后依次导入 `RuoYi-Vue-springboot3/sql/ry_20260417.sql`、`RuoYi-Vue-springboot3/sql/quartz.sql`。这两份若依脚本含 `DROP TABLE`，绝不能用于已有库。需要门诊演示数据时，再依次导入 `materials/sql/clinic.sql`、`materials/sql/clinic_enterprise_seed.sql`、`materials/sql/clinic_stage3_seed.sql`；它们只提供数据结构与模拟数据，业务服务和页面仍由新手村的你实现。SQL 中的相对日期以导入日生成，过期后须重建新的隔离演示库，不在已有业务库重跑。

例如在本目录、MySQL 使用本机 `3308` 端口时，可先执行 `mysql -h 127.0.0.1 -P 3308 -u root -p -e "CREATE DATABASE ocms_ruoyi_starter CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"`，再按上述顺序逐个执行 `mysql -h 127.0.0.1 -P 3308 -u root -p ocms_ruoyi_starter < 相应文件路径`。使用自己的数据库账号和端口；不要把密码写进命令或文档。

设置 `MYSQL_HOST`、`MYSQL_PORT`、`MYSQL_DATABASE=ocms_ruoyi_starter`、`MYSQL_USER`、`MYSQL_PASSWORD`、`REDIS_HOST`、`REDIS_PORT`、`REDIS_DATABASE=7`、`REDIS_PASSWORD` 等环境变量。真实密码不要提交。确认终端的 `JAVA_HOME` 指向 JDK 17（系统默认 Java 8 无法编译）。后端在 `RuoYi-Vue-springboot3/` 执行 `mvn -pl ruoyi-admin -am package -DskipTests`，运行打包后的 `ruoyi-admin/target/ruoyi-admin.jar`；也可在 IDEA 启动 `RuoYiApplication`。默认端口 `8087`，可用 `SERVER_PORT` 覆盖。

前端在 `RuoYi-Vue3-master/` 执行 `npm ci`、`npm run dev`，访问 `http://localhost:3007`，代理目标是 `http://localhost:8087`。初始若依管理员为 `admin / admin123`，首次登录应修改密码，不应该继续使用此 弱口令 密码(你知道什么是弱口令吗?)。Swagger UI 为 `http://localhost:8087/swagger-ui.html`。Python 模板单独按 `agent-template/README.md` 启动。

启动后先确认 `http://localhost:8087/captchaImage` 返回验证码，再访问前端并用验证码登录；若调整了后端端口，须同步设置前端 `.env.development` 的 `VITE_BACKEND_URL`。Python 模板的 `/health` 只证明模板进程启动，不能代表智能体功能通过。

默认口令和配置仅供本地隔离测试。部署到共享网络前，须修改管理员口令并设置独立的 `RUOYI_TOKEN_SECRET`、`DRUID_USERNAME`、`DRUID_PASSWORD`，限制 Druid 监控页面的可访问来源（当前 `application-druid.yml` 的 `allow` 为空）；不要直接公开默认配置的服务。

## 学员交付边界

先在若依中完成门诊业务模块和角色菜单，再实现 Python 智能体及若依对话页；AI 读写工具必须调用**本起点上开发出的业务接口**，不能调用阶段二原生版或完整成品。患者本人身份只能从可信登录态和核验绑定取得，不能由聊天文本指定。挂号/取消在两个时点校验并要求预览确认；医疗护栏属于一票否决要求。业务 SQL、角色菜单、接口契约、测试与部署证据由大家提交。