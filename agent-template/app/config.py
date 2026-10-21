# -*- coding: utf-8 -*-
"""环境配置：读取 .env，提供单例 Settings"""
import os
from functools import lru_cache
from pathlib import Path

from dotenv import load_dotenv

# 找 agent-template/.env
_ROOT = Path(__file__).resolve().parents[1]
load_dotenv(_ROOT / ".env")


class Settings:
    # 若依
    ruoyi_base_url: str = os.getenv("RUOYI_BASE_URL", "http://127.0.0.1:8087")
    ruoyi_username: str = os.getenv("RUOYI_USERNAME", "admin")
    ruoyi_password: str = os.getenv("RUOYI_PASSWORD", "admin123")

    # LLM
    llm_enabled: bool = os.getenv("LLM_ENABLED", "false").lower() == "true"
    llm_provider: str = os.getenv("LLM_PROVIDER", "deepseek")
    llm_base_url: str = os.getenv("LLM_BASE_URL", "")
    llm_api_key: str = os.getenv("LLM_API_KEY", "")
    llm_model: str = os.getenv("LLM_MODEL", "")
    llm_timeout: int = int(os.getenv("LLM_TIMEOUT", "30"))

    # 服务
    host: str = os.getenv("AGENT_HOST", "127.0.0.1")
    port: int = int(os.getenv("AGENT_PORT", "8099"))

    # 数据
    data_dir: Path = _ROOT / "data"


@lru_cache
def get_settings() -> Settings:
    return Settings()