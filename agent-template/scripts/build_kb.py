# -*- coding: utf-8 -*-
"""
知识库构建：18 篇 stage3-knowledge → 分块 → BM25 索引
不依赖任何 LLM/embedding API。
"""
import json
import pickle
import re
import sys
from pathlib import Path

import jieba
from rank_bm25 import BM25Okapi

ROOT = Path(__file__).resolve().parents[2]
KB_DIR = ROOT / "materials" / "stage3-knowledge"
OUT_DIR = Path(__file__).resolve().parents[1] / "data"
OUT_DIR.mkdir(parents=True, exist_ok=True)

CHUNKS_PATH = OUT_DIR / "knowledge_chunks.jsonl"
BM25_PATH = OUT_DIR / "bm25_index.pkl"
META_PATH = OUT_DIR / "knowledge_meta.json"


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """解析 YAML frontmatter（简单实现，避免 pyyaml 对中文的坑）"""
    if not text.startswith("---"):
        return {}, text
    m = re.match(r"^---\s*\n(.*?)\n---\s*\n(.*)$", text, re.DOTALL)
    if not m:
        return {}, text
    fm_text, body = m.group(1), m.group(2)
    fm = {}
    for line in fm_text.splitlines():
        if ":" in line:
            k, v = line.split(":", 1)
            fm[k.strip()] = v.strip().strip("'").strip('"')
    return fm, body


def split_by_h2(body: str) -> list[tuple[str, str]]:
    """按 ## 二级标题分块，返回 [(heading, content), ...]"""
    parts = re.split(r"^##\s+", body, flags=re.MULTILINE)
    out = []
    if parts[0].strip():
        # 前言部分（## 之前的内容），归到 heading="概述"
        out.append(("概述", parts[0].strip()))
    for p in parts[1:]:
        lines = p.split("\n", 1)
        heading = lines[0].strip()
        content = lines[1].strip() if len(lines) > 1 else ""
        if content:
            out.append((heading, content))
    return out


def main():
    md_files = sorted(KB_DIR.glob("*.md"))
    print(f"发现 {len(md_files)} 篇文档")

    chunks = []
    for md in md_files:
        text = md.read_text(encoding="utf-8")
        fm, body = parse_frontmatter(text)
        doc_id = fm.get("doc_id", md.stem)
        title = fm.get("title", md.stem)
        department = fm.get("department", "公共")

        for idx, (heading, content) in enumerate(split_by_h2(body)):
            chunk = {
                "chunk_id": f"{doc_id}#{idx:02d}",
                "doc_id": doc_id,
                "title": title,
                "department": department,
                "heading": heading,
                "content": content,
                "source_file": md.name,
            }
            chunks.append(chunk)

    print(f"共切分 {len(chunks)} 个 chunk")

    # 写 jsonl
    with CHUNKS_PATH.open("w", encoding="utf-8") as f:
        for c in chunks:
            f.write(json.dumps(c, ensure_ascii=False) + "\n")

    # 建 BM25 索引
    corpus_tokens = []
    for c in chunks:
        # BM25 对中文需要先分词
        tokens = list(jieba.cut(c["title"] + " " + c["heading"] + " " + c["content"]))
        tokens = [t.strip() for t in tokens if t.strip()]
        corpus_tokens.append(tokens)

    bm25 = BM25Okapi(corpus_tokens)
    with BM25_PATH.open("wb") as f:
        pickle.dump({
            "bm25": bm25,
            "corpus_tokens": corpus_tokens,
            "chunks": chunks,
        }, f)

    # 元数据摘要
    dept_counts = {}
    for c in chunks:
        dept_counts[c["department"]] = dept_counts.get(c["department"], 0) + 1

    meta = {
        "num_docs": len(md_files),
        "num_chunks": len(chunks),
        "departments": dept_counts,
        "chunks_path": str(CHUNKS_PATH),
        "bm25_path": str(BM25_PATH),
    }
    META_PATH.write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")

    print("\n=== 构建完成 ===")
    print(json.dumps(meta, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    # Windows 控制台 UTF-8
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except Exception:
        pass
    main()