# -*- coding: utf-8 -*-
"""LangGraph 节点集合"""
import re
import datetime as dt
from typing import Any

from . import session
from .clinic_client import ClinicClient, ClinicClientError
from .guardrail import REFUSAL_ANSWER, check_input, check_output
from .intent import classify, extract_slots
from .llm import get_llm
from .retriever import Retriever
from .state import GraphState


# =====================================================
# Node 1：护栏（第一层，进路由前）
# =====================================================
def guardrail_node(state: GraphState) -> dict:
    blocked, reason = check_input(state["message"])
    if blocked:
        return {
            "intent": "guardrail",
            "blocked": True,
            "block_reason": reason,
            "reply": REFUSAL_ANSWER,
            "citations": [],
            "card": None,
        }
    return {"blocked": False, "block_reason": ""}


# =====================================================
# Node 2：意图识别 + 槽位抽取
# =====================================================
def intent_node(state: GraphState) -> dict:
    sess = session.load(state["session_id"])
    stage = sess.get("stage", "idle")

    intent = classify(state["message"], stage=stage)
    new_slots = extract_slots(state["message"])

    # 合并已有槽位（新值覆盖旧值）
    slots = dict(sess.get("slots") or {})
    slots.update(new_slots)

    # 保存槽位
    session.update_slots(state["session_id"], **new_slots)

    return {"intent": intent, "slots": slots, "stage": stage}


# =====================================================
# Node 3：知识问答（RAG）
# =====================================================


def _clean_md(s: str) -> str:
    """去掉 Markdown 标题/引用/加粗符号，让纯文本显示更干净"""
    if not s:
        return s
    # 去掉行首的 # / > / - / * 等
    s = re.sub(r"(?m)^\s*#{1,6}\s*", "", s)
    s = re.sub(r"(?m)^\s*>\s*", "", s)
    s = re.sub(r"(?m)^\s*[-*]\s+", "· ", s)
    # 去掉 **加粗** / *斜体*
    s = s.replace("**", "").replace("__", "")
    # 压缩多余空行
    s = re.sub(r"\n{3,}", "\n\n", s)
    return s.strip()


def knowledge_node(state: GraphState) -> dict:
    q = state["message"]
    slots = state.get("slots") or {}
    dept = slots.get("department")

    r = Retriever.instance()
    hits = r.search(q, top_k=3, department=dept)

    if not hits:
        return {
            "reply": "抱歉，我没有在门诊知识库中找到相关说明。建议您联系门诊前台（021-66081001）或到现场咨询。",
            "citations": [],
            "card": None,
        }

    # 拼上下文
    context = "\n\n".join(
        f"[{h['chunk_id']}] {h['title']} / {h['heading']}\n{h['content']}" for h in hits
    )

    llm = get_llm()
    if llm.enabled:
        system = (
            "你是青枫门诊的服务助手，只回答门诊流程、挂号规则、科室介绍等服务性问题。"
            "严禁做疾病诊断、推荐药物或剂量、解读检查报告。"
            "如果资料不足，明确说'未找到'，不要编造。回答须引用 [chunk_id]。"
        )
        user = f"用户问题：{q}\n\n可用资料：\n{context}\n\n请基于资料作答，并引用来源 chunk_id。"
        answer = llm.chat(system, user)
        if answer and check_output(answer)[0]:
            answer = REFUSAL_ANSWER
    else:
        # 降级：把最相关的 chunk 前 200 字直接回给用户
        top = hits[0]
        answer = f"{_clean_md(top['content'])[:240]}…\n\n（来源：{top['chunk_id']} 《{top['title']}》/ {top['heading']}）"

    return {
        "reply": answer,
        "citations": r.format_citations(hits),
        "card": None,
    }


# =====================================================
# Node 4：号源查询
# =====================================================
def schedule_node(state: GraphState) -> dict:
    slots = state.get("slots") or {}
    dept = slots.get("department")
    date_offset = slots.get("date_offset")
    period = slots.get("period")

    # 公共号源，用服务 token
    c = ClinicClient(user_token=state.get("user_token"))
    if not state.get("user_token"):
        c.ensure_service_token()

    try:
        rows = c.schedule_list(status="OPEN", page_size=500)
    except ClinicClientError as e:
        return {"reply": f"查询号源失败：{e.msg}", "card": None, "citations": []}

    # 过滤
    today = dt.date.today()
    filtered = []
    for row in rows:
        if dept and row.get("departmentId") is None:
            pass
        vd = row.get("visitDate")
        if not vd:
            continue
        try:
            vd_date = dt.date.fromisoformat(vd[:10])
        except Exception:
            continue
        if date_offset is not None:
            if (vd_date - today).days != int(date_offset):
                continue
        if period and row.get("period") != period:
            continue
        filtered.append(row)

    filtered = filtered[:8]

    if not filtered:
        return {
            "reply": "抱歉，没找到符合条件的排班，请调整科室、日期或时段后再试。",
            "card": None,
            "citations": [],
        }

    # 卡片
    card = {
        "type": "schedule_list",
        "data": [
            {
                "scheduleId": x["scheduleId"],
                "departmentId": x["departmentId"],
                "doctorId": x["doctorId"],
                "visitDate": x["visitDate"],
                "period": x["period"],
                "startTime": x["startTime"],
                "endTime": x["endTime"],
                "remainingQuota": x["remainingQuota"],
                "totalQuota": x["totalQuota"],
            }
            for x in filtered
        ],
    }
    return {
        "reply": f"为您找到 {len(filtered)} 条排班（实时余号见卡片）。",
        "card": card,
        "citations": [],
        "stage": "idle",
    }


# =====================================================
# Node 5：预约单查询（本人）
# =====================================================
def appt_query_node(state: GraphState) -> dict:
    token = state.get("user_token")
    if not token:
        return {
            "reply": "查询本人预约需要先登录若依系统并绑定患者档案。请在若依页面登录后重试。",
            "card": None, "citations": [],
        }

    c = ClinicClient(user_token=token)
    try:
        bind = c.bind_me()
    except ClinicClientError as e:
        return {"reply": f"获取绑定信息失败：{e.msg}", "card": None, "citations": []}

    if not bind or not bind.get("bound"):
        return {
            "reply": "当前账号未绑定患者档案，无法查询本人预约。请在'门诊管理 / 患者绑定'中完成绑定。",
            "card": None, "citations": [],
        }

    try:
        rows = c.appointment_list(bind["patientId"], status="BOOKED")
    except ClinicClientError as e:
        return {"reply": f"查询预约失败：{e.msg}", "card": None, "citations": []}

    if not rows:
        return {"reply": "您当前没有生效中的预约。", "card": None, "citations": []}

    card = {"type": "appointment_list", "data": rows[:8]}
    return {
        "reply": f"您有 {len(rows)} 条生效中的预约：",
        "card": card, "citations": [],
    }


# =====================================================
# Node 6：挂号预览（写操作第一步）
# =====================================================
def book_preview_node(state: GraphState) -> dict:
    token = state.get("user_token")
    if not token:
        return {
            "reply": "智能挂号需要先登录若依并绑定患者档案。",
            "card": None, "citations": [],
        }

    slots = state.get("slots") or {}
    sid = slots.get("schedule_id")
    if not sid:
        # 参数不全，请澄清
        return {
            "reply": "请告诉我您想挂的排班 ID，例如'我要挂号排班10'。",
            "card": None, "citations": [],
        }

    c = ClinicClient(user_token=token)

    # 1) 校验绑定
    try:
        bind = c.bind_me()
    except ClinicClientError as e:
        return {"reply": f"获取绑定信息失败：{e.msg}", "card": None, "citations": []}
    if not bind or not bind.get("bound"):
        return {
            "reply": "当前账号未绑定患者档案，无法挂号。请先在'门诊管理 / 患者绑定'中完成绑定。",
            "card": None, "citations": [],
        }

    # 2) 查号源
    try:
        sc = c.schedule_get(int(sid))
    except ClinicClientError as e:
        return {"reply": f"查询排班失败：{e.msg}", "card": None, "citations": []}

    if sc.get("status") != "OPEN":
        return {"reply": "该排班已关闭，无法挂号。", "card": None, "citations": []}
    if (sc.get("remainingQuota") or 0) <= 0:
        return {"reply": "该时段号源已满，请选择其他时段。", "card": None, "citations": []}

    # 3) 生成预览，进 awaiting 状态
    preview = {
        "scheduleId": sc["scheduleId"],
        "departmentId": sc["departmentId"],
        "doctorId": sc["doctorId"],
        "visitDate": sc["visitDate"],
        "period": sc["period"],
        "startTime": sc["startTime"],
        "endTime": sc["endTime"],
        "remainingQuota": sc["remainingQuota"],
        "patientId": bind["patientId"],
    }
    session.set_stage(
        state["session_id"],
        "awaiting_confirm_book",
        {"kind": "book", "schedule_id": int(sid), "preview": preview},
    )

    return {
        "reply": (
            f"请确认以下挂号信息（预览不代表已挂号）：\n"
            f"• 患者ID：{bind['patientId']}\n"
            f"• 排班：{sc['scheduleId']}  {sc['visitDate']}  {sc['period']}  "
            f"{sc['startTime']}-{sc['endTime']}\n"
            f"• 实时余号：{sc['remainingQuota']}\n"
            f"\n回复“确认”提交挂号；回复“取消”放弃。"
        ),
        "card": {"type": "book_preview", "data": preview},
        "citations": [],
        "stage": "awaiting_confirm_book",
    }


# =====================================================
# Node 7：挂号执行（写操作第二步，条件边进入）
# =====================================================
def book_execute_node(state: GraphState) -> dict:
    token = state.get("user_token")
    sess = session.load(state["session_id"])
    pending = sess.get("pending") or {}

    if pending.get("kind") != "book":
        session.reset_stage(state["session_id"])
        return {"reply": "当前没有待确认的挂号，请重新发起。", "card": None, "citations": []}

    sid = pending["schedule_id"]
    c = ClinicClient(user_token=token)

    try:
        appt = c.appointment_book(int(sid), source="AI")
    except ClinicClientError as e:
        session.reset_stage(state["session_id"])
        return {
            "reply": f"挂号失败：{e.msg}。请重新选择时段或稍后再试。",
            "card": None, "citations": [],
        }

    session.reset_stage(state["session_id"])

    card = {
        "type": "appointment_voucher",
        "data": {
            "appointmentId": appt["appointmentId"],
            "appointmentNo": appt["appointmentNo"], "scheduleId": int(sid),
            "visitDate": appt["visitDate"],
            "period": appt["period"],
            "departmentId": appt["departmentId"],
            "doctorId": appt["doctorId"],
        },
    }
    return {
        "reply": (
            f"✅ 挂号成功！\n"
            f"• 取号凭证：{appt['appointmentNo']}\n"
            f"• 就诊时间：{appt['visitDate']} {appt['period']}\n"
            f"• 请保存凭证号，到院时向前台出示。\n"
            f"• 就诊开始前 2 小时内不可取消。"
        ),
        "card": card,
        "citations": [],
        "stage": "idle",
    }


# =====================================================
# Node 8：取消预览
# =====================================================
def cancel_preview_node(state: GraphState) -> dict:
    token = state.get("user_token")
    if not token:
        return {"reply": "取消预约需要先登录若依。", "card": None, "citations": []}

    slots = state.get("slots") or {}
    aid = slots.get("appointment_id")
    ano = slots.get("appointment_no")

    c = ClinicClient(user_token=token)
    try:
        bind = c.bind_me()
    except ClinicClientError as e:
        return {"reply": f"获取绑定信息失败：{e.msg}", "card": None, "citations": []}
    if not bind or not bind.get("bound"):
        return {"reply": "当前账号未绑定患者档案。", "card": None, "citations": []}

    # 通过 appointment_no 反查
    if not aid and ano:
        try:
            rows = c.appointment_list(bind["patientId"], status="BOOKED")
            for r in rows:
                if r.get("appointmentNo") == ano:
                    aid = r["appointmentId"]
                    break
        except ClinicClientError as e:
            return {"reply": f"查询失败：{e.msg}", "card": None, "citations": []}

    if not aid:
        return {"reply": "请提供要取消的预约单号，例如'取消预约单 AP1001'。", "card": None, "citations": []}

    try:
        appt = c.appointment_get(int(aid))
    except ClinicClientError as e:
        return {"reply": f"查询预约失败：{e.msg}", "card": None, "citations": []}

    if appt.get("status") != "BOOKED":
        return {"reply": f"该预约当前状态为 {appt.get('status')}，不可取消。", "card": None, "citations": []}

    session.set_stage(
        state["session_id"],
        "awaiting_confirm_cancel",
        {"kind": "cancel", "appointment_id": int(aid), "appointment_no": appt.get("appointmentNo")},
    )
    card = {"type": "cancel_preview", "data": appt}
    return {
        "reply": (
            f"请确认取消以下预约：\n"
            f"• 凭证：{appt.get('appointmentNo')}\n"
            f"• 就诊：{appt.get('visitDate')} {appt.get('period')}\n"
            f"• 取消规则：时段开始前至少 2 小时\n"
            f"\n回复“确认”执行取消；回复“取消”放弃。"
        ),
        "card": card,
        "citations": [],
        "stage": "awaiting_confirm_cancel",
    }


# =====================================================
# Node 9：取消执行
# =====================================================
def cancel_execute_node(state: GraphState) -> dict:
    token = state.get("user_token")
    sess = session.load(state["session_id"])
    pending = sess.get("pending") or {}

    if pending.get("kind") != "cancel":
        session.reset_stage(state["session_id"])
        return {"reply": "当前没有待确认的取消。", "card": None, "citations": []}

    aid = pending["appointment_id"]
    c = ClinicClient(user_token=token)
    try:
        c.appointment_cancel(int(aid), reason="AI 助手代取消")
    except ClinicClientError as e:
        session.reset_stage(state["session_id"])
        return {"reply": f"取消失败：{e.msg}", "card": None, "citations": []}

    session.reset_stage(state["session_id"])
    return {
        "reply": f"✅ 已取消预约 {pending.get('appointment_no')}，号源已返还。",
        "card": None, "citations": [], "stage": "idle",
    }


# =====================================================
# Node 10：兜底澄清
# =====================================================
def clarify_node(state: GraphState) -> dict:
    return {
        "reply": (
            "抱歉，我没理解您的需求。您可以试试：\n"
            "• 问流程：「初诊就诊流程是什么」\n"
            "• 查号源：「明天内科号源」\n"
            "• 查预约：「查我的预约」\n"
            "• 挂号：「我要挂号排班10」（会先给预览，再需确认）\n"
            "• 取消：「取消预约单 AP1001」（同样需确认）"
        ),
        "card": None, "citations": [],
    }