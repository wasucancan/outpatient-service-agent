# -*- coding: utf-8 -*-
"""BM25 检索测试：验证科室过滤 + 引用"""
import pickle
import sys
from pathlib import Path

import jieba

ROOT = Path(__file__).resolve().parents[1]
BM25_PATH = ROOT / "data" / "bm25_index.pkl"


def search(query: str, top_k: int = 3, department: str | None = None):
    with BM25_PATH.open("rb") as f:
        data = pickle.load(f)
    bm25 = data["bm25"]
    chunks = data["chunks"]

    tokens = [t.strip() for t in jieba.cut(query) if t.strip()]
    scores = bm25.get_scores(tokens)

    # 科室过滤：把非目标科室的分数压到 -inf
    if department:
        for i, c in enumerate(chunks):
            if c["department"] != department and c["department"] != "公共":
                scores[i] = float("-inf")

    top_idx = scores.argsort()[::-1][:top_k]
    return [(float(scores[i]), chunks[i]) for i in top_idx if scores[i] > 0]


def main():
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass

    tests = [
        ("初诊就诊流程", None),
        ("取消预约 2 小时", None),
        ("内科 医生", "内科"),
        ("小孩 儿科", "儿科"),
    ]

    for q, dept in tests:
        print(f"\n===== 查询: {q}  (department={dept}) =====")
        results = search(q, top_k=3, department=dept)
        if not results:
            print("  （无结果）")
            continue
        for score, c in results:
            preview = c["content"][:80].replace("\n", " ")
            print(f"  [{score:6.2f}] {c['chunk_id']} | {c['department']} | {c['title']} / {c['heading']}")
            print(f"            {preview}...")


if __name__ == "__main__":
    main()