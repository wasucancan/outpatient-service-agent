# -*- coding: utf-8 -*-
"""
医疗护栏：意图分类 + 输出校验 双保险。
第一层：关键词黑名单规则（不依赖 LLM）。
第二层：LLM 输出后再次检测（如果有 LLM）。
"""
import re

REFUSAL_ANSWER = (
    "抱歉，作为门诊服务助手，我不能进行疾病诊断、推荐具体药物或剂量，也不能解读检查报告。"
    "如有身体不适，请尽快到门诊挂号就诊，由医生当面评估；"
    "如症状严重或突发，请立即拨打 120 或到就近急诊。"
)

# 药物词内部允许空格：布洛芬 / 布 洛 芬 / 阿司 匹林 ...
DRUG_NAMES = [
    r"阿\s*莫\s*西\s*林",
    r"布\s*洛\s*芬",
    r"对\s*乙\s*酰\s*氨\s*基\s*酚",
    r"头\s*孢",
    r"阿\s*司\s*匹\s*林",
    r"氯\s*雷\s*他\s*定",
    r"左\s*氧\s*氟\s*沙\s*星",
]

DIAGNOSIS_PATTERNS = [
    r"是不是.*病", r"是不是.*炎", r"是不是.*癌", r"是不是.*症",
    r"我.*(咳|疼|痛|烧|晕).*是.*(吗|么)",
    r"帮.*(诊断|看一?下|判断)",
    r"什么病", r"确诊", r"病症是",
    r"tell me.*(diagnosis|disease)",
]

DRUG_PATTERNS = [
    r"(推荐|开|买|吃|服|用)\s*.{0,4}(药|颗粒|胶囊|片|注射液)",
    *DRUG_NAMES,
    r"剂量", r"吃多少", r"毫克", r"mg\b",
    r"(dosage|dose|milligram|mg)",
]

REPORT_PATTERNS = [
    r"(检查|化验|血常规|CT|核磁|彩超|B超).*(报告|结果|单|正常吗)",
    r"解读", r"(正常|异常)吗",
    r"帮我看看.*(报告|化验单)",
]

JAILBREAK_PATTERNS = [
    r"忽略.*(规则|限制|约束)",
    r"扮演.*(医生|药师|专家)",
    r"角色扮演",
    r"假装",
    r"developer mode",
    r"越狱",
    r"ignore.*(rule|restriction|instruction)",
    r"act as",
]


def _match_any(text: str, patterns: list[str]) -> str | None:
    for p in patterns:
        if re.search(p, text, re.IGNORECASE):
            return p
    return None


def check_input(text: str) -> tuple[bool, str]:
    if not text:
        return False, ""

    p = _match_any(text, JAILBREAK_PATTERNS)
    if p:
        return True, f"jailbreak:{p}"

    p = _match_any(text, DIAGNOSIS_PATTERNS)
    if p:
        return True, f"diagnosis:{p}"

    p = _match_any(text, DRUG_PATTERNS)
    if p:
        return True, f"drug:{p}"

    p = _match_any(text, REPORT_PATTERNS)
    if p:
        return True, f"report:{p}"

    return False, ""


def check_output(text: str) -> tuple[bool, str]:
    if not text:
        return False, ""

    if re.search(r"(确诊|诊断为|患上|得了|确定是).{0,10}(病|炎|症|癌|瘤)", text):
        return True, "output_diagnosis"

    if re.search(r"\d+\s*(mg|毫克|克|g|ml|毫升)", text):
        return True, "output_dosage"

    return False, ""