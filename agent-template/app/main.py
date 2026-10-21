# -*- coding: utf-8 -*-
"""FastAPI + SSE 入口"""
import json

from fastapi import FastAPI, Header, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field

from . import session
from .config import get_settings
from .graph import graph

app = FastAPI(title="青枫门诊 AI 助手")


class ChatRequest(BaseModel):
    session_id: str | None = None
    message: str = Field(min_length=1, max_length=2000)


def _sse(event: str, data: dict) -> str:
    return f"event: {event}\ndata: {json.dumps(data, ensure_ascii=False)}\n\n"


@app.get("/health")
def health() -> dict:
    s = get_settings()
    return {
        "status": "ok",
        "llm_enabled": s.llm_enabled,
        "provider": s.llm_provider,
    }


@app.post("/chat/stream")
async def chat_stream(
    req: ChatRequest,
    authorization: str | None = Header(default=None),
):
    # 登录态透传：前端把若依 token 放 Authorization: Bearer xxx
    user_token = None
    if authorization and authorization.lower().startswith("bearer "):
        user_token = authorization[7:].strip()

    # session
    sid = req.session_id
    if not sid:
        sid = session.new_session()
    else:
        try:
            session.load(sid)
        except KeyError:
            sid = session.new_session()

    # 记录用户输入
    session.append_turn(sid, "user", req.message)

    # 构建初始 state
    init_state = {
        "session_id": sid,
        "user_token": user_token,
        "message": req.message,
        "reply": "",
        "card": None,
        "citations": [],
        "blocked": False,
        "block_reason": "",
        "intent": "",
        "slots": {},
        "stage": "idle",
        "pending": None,
        "error": None,
    }

    # 执行图
    try:
        result = graph.invoke(init_state)
    except Exception as e:
        result = {
            "reply": f"抱歉，处理出错：{e}",
            "card": None,
            "citations": [],
            "intent": "error",
            "blocked": False,
        }

    reply = result.get("reply") or ""
    card = result.get("card")
    citations = result.get("citations") or []

    # 记录助手输出
    session.append_turn(sid, "assistant", reply)

    async def events():
        yield _sse("session", {"session_id": sid})
        yield _sse("intent", {
            "intent": result.get("intent", ""),
            "blocked": result.get("blocked", False),
            "block_reason": result.get("block_reason", ""),
        })
        # 按 20 字一段 token 化（伪流式；真实 LLM 时逐 token 更自然）
        step = 20
        for i in range(0, len(reply), step):
            yield _sse("token", {"content": reply[i:i+step]})
        if card:
            yield _sse("card", card)
        if citations:
            yield _sse("citation", {"items": citations})
        yield _sse("done", {
            "session_id": sid,
            "stage": result.get("stage", "idle"),
        })

    return StreamingResponse(events(), media_type="text/event-stream")


@app.post("/chat")
async def chat(req: ChatRequest, authorization: str | None = Header(default=None)) -> dict:
    """非流式接口，方便脚本回归测试"""
    user_token = None
    if authorization and authorization.lower().startswith("bearer "):
        user_token = authorization[7:].strip()

    sid = req.session_id
    if not sid:
        sid = session.new_session()
    else:
        try:
            session.load(sid)
        except KeyError:
            sid = session.new_session()

    session.append_turn(sid, "user", req.message)

    init_state = {
        "session_id": sid,
        "user_token": user_token,
        "message": req.message,
        "reply": "", "card": None, "citations": [],
        "blocked": False, "block_reason": "",
        "intent": "", "slots": {}, "stage": "idle", "pending": None, "error": None,
    }
    try:
        result = graph.invoke(init_state)
    except Exception as e:
        return {"session_id": sid, "reply": f"出错：{e}", "intent": "error"}

    session.append_turn(sid, "assistant", result.get("reply", ""))

    return {
        "session_id": sid,
        "intent": result.get("intent"),
        "blocked": result.get("blocked"),
        "block_reason": result.get("block_reason"),
        "reply": result.get("reply"),
        "card": result.get("card"),
        "citations": result.get("citations"),
        "stage": result.get("stage", "idle"),
    }