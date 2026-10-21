# -*- coding: utf-8 -*-
"""
LLM 工厂。
- LLM_ENABLED=false：chat() 返回 None，调用方走降级模板。
- LLM_ENABLED=true ：走 OpenAI 兼容 /chat/completions。
不引入额外依赖（httpx 已装）。
"""
from typing import Any

import httpx

from .config import get_settings


class LLM:
    def __init__(self):
        s = get_settings()
        self.enabled = s.llm_enabled and bool(s.llm_api_key)
        self.base = s.llm_base_url.rstrip("/")
        self.key = s.llm_api_key
        self.model = s.llm_model
        self.timeout = s.llm_timeout

    def chat(
        self,
        system: str,
        user: str,
        temperature: float = 0.2,
        max_tokens: int = 800,
    ) -> str | None:
        """返回字符串；未启用或失败返回 None（调用方走降级）"""
        if not self.enabled:
            return None
        url = f"{self.base}/chat/completions"
        payload: dict[str, Any] = {
            "model": self.model,
            "messages": [
                {"role": "system", "content": system},
                {"role": "user", "content": user},
            ],
            "temperature": temperature,
            "max_tokens": max_tokens,
            "stream": False,
        }
        headers = {
            "Authorization": f"Bearer {self.key}",
            "Content-Type": "application/json",
        }
        try:
            r = httpx.post(url, json=payload, headers=headers, timeout=self.timeout)
            r.raise_for_status()
            data = r.json()
            return data["choices"][0]["message"]["content"]
        except Exception as e:
            print(f"[llm] 调用失败，降级：{e}")
            return None


_llm: LLM | None = None


def get_llm() -> LLM:
    global _llm
    if _llm is None:
        _llm = LLM()
    return _llm