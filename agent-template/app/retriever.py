# -*- coding: utf-8 -*-
"""BM25 检索封装，含科室过滤"""
import pickle
from pathlib import Path
from typing import Any

import jieba

from .config import get_settings


class Retriever:
    _instance = None

    def __init__(self):
        s = get_settings()
        path = s.data_dir / "bm25_index.pkl"
        if not path.exists():
            raise RuntimeError(f"索引不存在: {path}，先跑 scripts/build_kb.py")
        with path.open("rb") as f:
            data = pickle.load(f)
        self.bm25 = data["bm25"]
        self.chunks: list[dict] = data["chunks"]

    @classmethod
    def instance(cls) -> "Retriever":
        if cls._instance is None:
            cls._instance = cls()
        return cls._instance

    def search(
        self,
        query: str,
        top_k: int = 3,
        department: str | None = None,
        min_score: float = 0.5,
    ) -> list[dict[str, Any]]:
        """
        返回 [{score, chunk_id, title, heading, content, department, source_file}, ...]
        """
        tokens = [t.strip() for t in jieba.cut(query) if t.strip()]
        if not tokens:
            return []
        scores = self.bm25.get_scores(tokens)

        if department:
            for i, c in enumerate(self.chunks):
                if c["department"] != department and c["department"] != "公共":
                    scores[i] = float("-inf")

        order = scores.argsort()[::-1][:top_k]
        out = []
        for i in order:
            s = float(scores[i])
            if s < min_score:
                continue
            c = self.chunks[i]
            out.append({
                "score": round(s, 3),
                "chunk_id": c["chunk_id"],
                "title": c["title"],
                "heading": c["heading"],
                "content": c["content"],
                "department": c["department"],
                "source_file": c["source_file"],
            })
        return out

    def format_citations(self, results: list[dict]) -> list[dict]:
        """把检索结果转成引用卡片"""
        return [
            {
                "chunk_id": r["chunk_id"],
                "title": r["title"],
                "heading": r["heading"],
                "department": r["department"],
                "source_file": r["source_file"],
                "score": r["score"],
            }
            for r in results
        ]