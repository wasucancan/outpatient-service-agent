# -*- coding: utf-8 -*-
"""规则版意图分类与槽位抽取。零 LLM 依赖，确定性。"""
import re

BOOK_KW = ["我要挂号", "帮我挂", "挂号排班", "预约排班", "预约挂号", "帮我预约", "我要预约"]
CANCEL_KW = ["取消预约", "取消单", "取消号", "取消挂号", "退号", "取消预约单"]
QUERY_APPT_KW = ["我的预约", "预约状态", "查询预约", "查我的"]
QUERY_SCHED_KW = ["号源", "还有号", "排班查询", "排班列表", "有什么号", "排班", "有号吗", "放号"]

STRONG_QUERY_SIG = [
    r"号\s*源", r"有\s*号", r"还\s*有\s*号", r"排\s*班", r"余\s*号", r"号\s*放",
]

QUESTION_KW = [
    "须知", "流程", "规则", "介绍", "怎么", "如何", "什么",
    "材料", "医保", "停诊", "老年人", "隐私", "报到", "签到",
    "复诊", "初诊", "急症", "候诊", "制度", "要求", "规定",
    "指南", "注意事项",
]

CONFIRM_KW = ["确认", "好的", "是的", "嗯", "对", "可以", "没问题", "确认挂号", "确认取消", "好"]

DEPARTMENTS = ["内科", "外科", "儿科", "妇科", "中医科", "全科医学科", "全科"]


def extract_slots(text: str) -> dict:
    slots: dict = {}
    m = re.search(r"排班\s*[_\-]?\s*(?:id|ID)?\s*[:=]?\s*(\d+)", text)
    if m:
        slots["schedule_id"] = int(m.group(1))
    m = re.search(r"(?:预约单|预约号|单号)?\s*([A-Z]{2,4}\d{3,})", text)
    if m:
        slots["appointment_no"] = m.group(1)
    if "明天" in text:
        slots["date_offset"] = 1
    elif "后天" in text:
        slots["date_offset"] = 2
    elif "今天" in text:
        slots["date_offset"] = 0
    m = re.search(r"(\d{4}-\d{2}-\d{2})", text)
    if m:
        slots["visit_date"] = m.group(1)
    if "上午" in text:
        slots["period"] = "AM"
    elif "下午" in text:
        slots["period"] = "PM"
    for d in DEPARTMENTS:
        if d in text:
            slots["department"] = "全科医学科" if d == "全科" else d
            break
    return slots


def _is_question(text: str) -> bool:
    if any(k in text for k in QUESTION_KW):
        return True
    if any(x in text for x in ["？", "?", "吗", "呢"]):
        return True
    return False


def _has_strong_query_signal(text: str) -> bool:
    return any(re.search(p, text) for p in STRONG_QUERY_SIG)


def classify(text: str, stage: str = "idle") -> str:
    """
    优先级（从高到低）：
      1. awaiting 阶段：确认 → confirm；换时段 → book
      2. 排班数字 + 挂号/预约动作 → book
      3. 取消预约单 XX → cancel
      4. 强 query 信号（号源/排班）
      5. 疑问式 → knowledge
      6. CANCEL / BOOK / QUERY 关键词
      7. idle 下纯"确认" → unknown
    """
    if not text:
        return "unknown"
    t = text.strip()

    # 1. awaiting 阶段
    if stage in ("awaiting_confirm_book", "awaiting_confirm_cancel"):
        if any(k in t for k in CONFIRM_KW):
            return "confirm"
        if any(k in t for k in ["换到", "改成", "改到", "改为"]):
            return "book"

    # 2. 排班数字 + 挂号/预约动作
    if re.search(r"排班\s*[_\-]?\s*\d+", t) and any(k in t for k in ["挂号", "预约"]):
        return "book"

    # 3. 取消预约单 XX
    if re.search(r"取消预约单\s*[A-Z]{2,4}\d{3,}", t):
        return "cancel"

    # 4. 强 query 信号
    if _has_strong_query_signal(t):
        if re.search(r"预约单\s*[A-Z]{2,4}\d{3,}", t):
            return "query_appointment"
        return "query_schedule"

    # 5. 疑问式 → knowledge
    if _is_question(t):
        return "knowledge"

    # 6. 关键词按序
    if any(k in t for k in CANCEL_KW):
        return "cancel"
    if any(k in t for k in BOOK_KW):
        return "book"
    if any(k in t for k in QUERY_APPT_KW):
        return "query_appointment"
    if any(k in t for k in QUERY_SCHED_KW):
        return "query_schedule"

    # 7. idle 下纯"确认"
    if stage == "idle" and t in CONFIRM_KW:
        return "unknown"

    return "unknown"