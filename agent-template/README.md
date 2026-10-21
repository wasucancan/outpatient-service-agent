# Python 智能体技术模板

本模板只展示 FastAPI、LangGraph 与 SSE 的最小可运行连接，不处理真实患者身份，不访问门诊数据，也不执行挂号。`POST /template/stream` 返回的是“尚未实现”的演示事件，不能用于业务验收或部署。学员应自行设计可信身份透传、科室过滤 RAG、读工具、预览确认、会话持久化、医疗护栏和审计，并把正式端点与若依业务接口对接。

使用 Python 3.13 建立虚拟环境后安装依赖并启动：

```bash
python3.13 -m venv .venv
.venv/bin/pip install -r requirements.txt
.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 8007
```

访问 `http://127.0.0.1:8007/health` 检查模板进程。正式业务服务不得信任浏览器传入的 `user_id` / `patient_id`；应由若依后端从登录态确认身份，内部服务再校验共享认证信息。此模板没有实现这些安全条件。
