# -*- coding: utf-8 -*-
"""LangGraph State 定义"""
from typing import Any, TypedDict


class GraphState(TypedDict, total=False):
    # 输入
    session_id: str
    user_token: str          # 若依登录 token（登录态透传）
    message: str

    # 处理中间态
    intent: str              # guardrail/knowledge/query_schedule/query_appointment/book/cancel/confirm
    slots: dict[str, Any]    # {schedule_id, appointment_id, department, date_offset, period}
    stage: str               # idle / awaiting_confirm_book / awaiting_confirm_cancel
    pending: dict[str, Any] | None

    # 输出
    reply: str               # 回复文本
    card: dict[str, Any] | None       # 预览卡片 / 凭证卡片
    citations: list[dict]    # 引用来源
    blocked: bool            # 是否被护栏拦截
    block_reason: str
    error: str | None