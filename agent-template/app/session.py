# -*- coding: utf-8 -*-
"""会话持久化：每个 session 一个 JSON 文件，可续聊"""
import json
import time
import uuid
from pathlib import Path

from .config import get_settings

_SESS_DIR: Path | None = None


def _dir() -> Path:
    global _SESS_DIR
    if _SESS_DIR is None:
        _SESS_DIR = get_settings().data_dir / "sessions"
        _SESS_DIR.mkdir(parents=True, exist_ok=True)
    return _SESS_DIR


def new_session() -> str:
    sid = uuid.uuid4().hex[:16]
    _save(sid, {
        "session_id": sid,
        "created_at": time.time(),
        "updated_at": time.time(),
        "history": [],       # [{role, content, ts}, ...]
        "slots": {},         # 槽位：schedule_id / appointment_id / department / date / period
        "stage": "idle",     # idle | awaiting_confirm_book | awaiting_confirm_cancel
        "pending": None,     # 待确认的动作 {"kind": "book", "schedule_id": 10, "preview": {...}}
    })
    return sid


def _path(sid: str) -> Path:
    return _dir() / f"{sid}.json"


def _save(sid: str, data: dict) -> None:
    data["updated_at"] = time.time()
    _path(sid).write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")


def load(sid: str) -> dict:
    p = _path(sid)
    if not p.exists():
        raise KeyError(f"session 不存在: {sid}")
    return json.loads(p.read_text(encoding="utf-8"))


def append_turn(sid: str, role: str, content: str) -> dict:
    data = load(sid)
    data["history"].append({"role": role, "content": content, "ts": time.time()})
    # 只保留最近 20 轮
    data["history"] = data["history"][-40:]
    _save(sid, data)
    return data


def update_slots(sid: str, **kwargs) -> dict:
    data = load(sid)
    for k, v in kwargs.items():
        if v is not None:
            data["slots"][k] = v
    _save(sid, data)
    return data


def set_stage(sid: str, stage: str, pending: dict | None = None) -> dict:
    data = load(sid)
    data["stage"] = stage
    data["pending"] = pending
    _save(sid, data)
    return data


def reset_stage(sid: str) -> dict:
    return set_stage(sid, "idle", None)