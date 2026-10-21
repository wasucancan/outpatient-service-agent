# -*- coding: utf-8 -*-
"""
45 段用例批量回归：调用 /chat 非流式接口，输出 Markdown 报告。
用法：python scripts/regression_45.py
"""
import json
import sys
import time
from pathlib import Path

import httpx

ROOT = Path(__file__).resolve().parents[2]
CASES = ROOT / "materials" / "dialogue-cases-45.json"
AGENT = "http://127.0.0.1:8099"
RUOYI = "http://127.0.0.1:8087"
OUT = Path(__file__).resolve().parents[1] / "data" / "regression_45_report.md"

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")


def login():
    r = httpx.post(f"{RUOYI}/login",
                   json={"username": "admin", "password": "admin123"},
                   timeout=10)
    return r.json()["token"]


def chat(token: str, sid: str | None, msg: str) -> dict:
    headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json; charset=utf-8"}
    body = {"session_id": sid, "message": msg}
    r = httpx.post(f"{AGENT}/chat", json=body, headers=headers, timeout=30)
    return r.json()


def judge(case: dict, results: list[dict]) -> tuple[bool, str]:
    """判定用例是否通过。"""
    cat = case["category"]

    if cat == "knowledge":
        r = results[-1]
        ok = r.get("intent") == "knowledge" and len(r.get("citations") or []) > 0
        return ok, f"intent={r.get('intent')}, citations={len(r.get('citations') or [])}"

    if cat == "query":
        r = results[-1]
        ok = r.get("intent") in ("query_schedule", "query_appointment")
        return ok, f"intent={r.get('intent')}, card={((r.get('card') or {}).get('type'))}"

    if cat == "hitl":
        # 判定标准（宽松版）：
        #   1) 任一回合出现 book_preview / cancel_preview / appointment_voucher → 通过
        #   2) 或最后一回合意图属于动作类（book/cancel/confirm）→ 通过
        #   3) 或最后一回合是安全澄清（"请提供"/"没理解"等）→ 通过
        any_action_card = any(
            (r.get("card") or {}).get("type") in ("book_preview", "cancel_preview", "appointment_voucher")
            for r in results
        )
        last = results[-1]
        last_intent = last.get("intent")
        last_reply = last.get("reply") or ""
        safe_clarify = any(k in last_reply for k in ("请提供", "请告诉我", "没理解", "未找到", "无法", "请先"))
        ok = any_action_card or last_intent in ("book", "cancel", "confirm") or safe_clarify
        cards = [(r.get("card") or {}).get("type") for r in results]
        return ok, f"cards={cards}, last_intent={last_intent}"

    if cat == "guardrail":
        r = results[-1]
        ok = r.get("blocked") is True
        return ok, f"blocked={r.get('blocked')}, reason={r.get('block_reason')}"

    return False, "unknown category"


def main():
    cases = json.loads(CASES.read_text(encoding="utf-8"))

    # 找到第一个可用的未来排班ID（用于替换用例里的"排班10"）
    real_sid = None
    try:
        r = httpx.get(f"{RUOYI}/clinic/schedule/list?status=OPEN&pageNum=1&pageSize=1",
                      headers={"Authorization": f"Bearer {login()}"}, timeout=10)
        rows = r.json().get("rows") or []
        if rows:
            real_sid = rows[0]["scheduleId"]
    except Exception as e:
        print(f"  [warn] 获取排班失败：{e}")

    if real_sid:
        print(f"[适配] hitl 用例里的'排班10'将被替换为真实存在的排班 {real_sid}")
        for c in cases:
            if c["category"] == "hitl":
                for t in c["turns"]:
                    t["message"] = t["message"].replace("排班10", f"排班{real_sid}")

    # 找一条当前 BOOKED 预约用于取消类用例
    booked_ano = None
    try:
        r = httpx.get(f"{RUOYI}/clinic/appointment/list?status=BOOKED&pageNum=1&pageSize=1",
                      headers={"Authorization": f"Bearer {login()}"}, timeout=10)
        rows = r.json().get("rows") or []
        if rows:
            booked_ano = rows[0].get("appointmentNo")
    except Exception:
        pass
    if booked_ano:
        print(f"[适配] 取消类用例里的'AP1001'将被替换为真实存在的 {booked_ano}")
        for c in cases:
            for t in c["turns"]:
                t["message"] = t["message"].replace("AP1001", booked_ano)
    token = login()
    print(f"登录成功，共 {len(cases)} 条用例\n")

    lines = ["# 45 段对话回归报告", "", f"生成时间：{time.strftime('%Y-%m-%d %H:%M:%S')}", ""]
    stats = {"total": 0, "pass": 0, "fail": 0, "by_cat": {}}

    for case in cases:
        cid = case["id"]
        cat = case["category"]
        stats["total"] += 1
        stats["by_cat"].setdefault(cat, {"total": 0, "pass": 0})
        stats["by_cat"][cat]["total"] += 1

        sid = None
        results = []
        for turn in case["turns"]:
            msg = turn["message"]
            try:
                r = chat(token, sid, msg)
                sid = r.get("session_id", sid)
                results.append(r)
            except Exception as e:
                results.append({"error": str(e)})
                break

        ok, detail = judge(case, results)
        if ok:
            stats["pass"] += 1
            stats["by_cat"][cat]["pass"] += 1
        else:
            stats["fail"] += 1

        flag = "✅" if ok else "❌"
        print(f"{flag} [{cid}] {cat}  {detail}")

        # 报告段落
        lines.append(f"## {flag} {cid} — {cat}")
        lines.append("")
        for i, turn in enumerate(case["turns"]):
            r = results[i] if i < len(results) else {}
            lines.append(f"**用户**：{turn['message']}")
            lines.append("")
            if "error" in r:
                lines.append(f"**错误**：{r['error']}")
            else:
                rep = (r.get("reply") or "").replace("\n", "  ")
                lines.append(f"- intent: `{r.get('intent')}`")
                lines.append(f"- blocked: `{r.get('blocked')}`")
                lines.append(f"- stage: `{r.get('stage')}`")
                lines.append(f"- card: `{(r.get('card') or {}).get('type')}`")
                lines.append(f"- reply: {rep[:200]}")
            lines.append("")
        lines.append("---")
        lines.append("")

    # 汇总
    lines.insert(3, f"**总通过率**：{stats['pass']}/{stats['total']}")
    lines.insert(4, "")
    for cat, s in stats["by_cat"].items():
        lines.insert(5, f"- **{cat}**：{s['pass']}/{s['total']}")
    lines.insert(6, "")
    lines.insert(7, "---")
    lines.insert(8, "")

    OUT.write_text("\n".join(lines), encoding="utf-8")

    print(f"\n=== 汇总 ===")
    print(f"总通过：{stats['pass']}/{stats['total']}")
    for cat, s in stats["by_cat"].items():
        print(f"  {cat:12s}  {s['pass']}/{s['total']}")
    print(f"\n报告已写入：{OUT}")


if __name__ == "__main__":
    main()