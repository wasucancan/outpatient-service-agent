# -*- coding: utf-8 -*-
"""LangGraph 编排：意图路由 + 条件边 + 确认循环

注意：节点名不能与 State 键同名（LangGraph 0.4.8 硬约束）。
State 里有 'intent' 键，所以节点名用 'classify_intent' 避免冲突。
"""
from langgraph.graph import END, START, StateGraph

from . import nodes
from .state import GraphState


def route_after_intent(state: GraphState) -> str:
    """意图 → 节点名"""
    intent = state.get("intent", "unknown")
    if intent == "knowledge":
        return "knowledge"
    if intent == "query_schedule":
        return "schedule"
    if intent == "query_appointment":
        return "appt_query"
    if intent == "book":
        return "book_preview"
    if intent == "cancel":
        return "cancel_preview"
    if intent == "confirm":
        stage = state.get("stage", "idle")
        if stage == "awaiting_confirm_book":
            return "book_execute"
        if stage == "awaiting_confirm_cancel":
            return "cancel_execute"
        return "clarify"
    return "clarify"


def route_after_guardrail(state: GraphState) -> str:
    return "blocked" if state.get("blocked") else "continue"


def build_graph():
    g = StateGraph(GraphState)

    # 节点名避开 State 键：intent / stage / pending 等都别用作节点名
    g.add_node("guardrail", nodes.guardrail_node)
    g.add_node("classify_intent", nodes.intent_node)   # ← 关键：不叫 "intent"
    g.add_node("knowledge", nodes.knowledge_node)
    g.add_node("schedule", nodes.schedule_node)
    g.add_node("appt_query", nodes.appt_query_node)
    g.add_node("book_preview", nodes.book_preview_node)
    g.add_node("book_execute", nodes.book_execute_node)
    g.add_node("cancel_preview", nodes.cancel_preview_node)
    g.add_node("cancel_execute", nodes.cancel_execute_node)
    g.add_node("clarify", nodes.clarify_node)

    g.add_edge(START, "guardrail")
    g.add_conditional_edges("guardrail", route_after_guardrail, {
        "blocked": END,
        "continue": "classify_intent",
    })
    g.add_conditional_edges("classify_intent", route_after_intent, {
        "knowledge": "knowledge",
        "schedule": "schedule",
        "appt_query": "appt_query",
        "book_preview": "book_preview",
        "book_execute": "book_execute",
        "cancel_preview": "cancel_preview",
        "cancel_execute": "cancel_execute",
        "clarify": "clarify",
    })
    for n in [
        "knowledge", "schedule", "appt_query",
        "book_preview", "book_execute",
        "cancel_preview", "cancel_execute",
        "clarify",
    ]:
        g.add_edge(n, END)

    return g.compile()


graph = build_graph()