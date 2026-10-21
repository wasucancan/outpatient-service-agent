# -*- coding: utf-8 -*-
"""
若依门诊业务 HTTP 客户端。
所有请求走"用户级 token"——由前端把登录 token 透传过来。
"""
from typing import Any

import httpx

from .config import get_settings


class ClinicClientError(Exception):
    def __init__(self, code: int, msg: str, raw: Any = None):
        super().__init__(f"[{code}] {msg}")
        self.code = code
        self.msg = msg
        self.raw = raw


class ClinicClient:
    """
    注意：本类不保存 token。每次请求由调用方传 user_token（登录态透传），
    或由服务自己用 admin 账号拿一个服务级 token（仅用于读公共号源）。
    """

    def __init__(self, user_token: str | None = None):
        s = get_settings()
        self.base = s.ruoyi_base_url.rstrip("/")
        self.user_token = user_token
        self._svc_token: str | None = None

    # ---------- 内部 ----------
    def _headers(self) -> dict[str, str]:
        token = self.user_token or self._svc_token
        return {"Authorization": f"Bearer {token}"} if token else {}

    def _post(self, path: str, json: dict | None = None) -> dict:
        url = f"{self.base}{path}"
        r = httpx.post(url, json=json, headers=self._headers(), timeout=15)
        return self._handle(r)

    def _get(self, path: str, params: dict | None = None) -> dict:
        url = f"{self.base}{path}"
        r = httpx.get(url, params=params, headers=self._headers(), timeout=15)
        return self._handle(r)

    @staticmethod
    def _handle(r: httpx.Response) -> dict:
        try:
            data = r.json()
        except Exception:
            raise ClinicClientError(r.status_code, f"非 JSON 响应: {r.text[:200]}")
        code = data.get("code", r.status_code)
        if code != 200:
            raise ClinicClientError(code, data.get("msg", "未知错误"), data)
        return data

    # ---------- 服务级 token ----------
    def ensure_service_token(self) -> None:
        """用 admin 登录拿一个服务 token（只读公共号源时用）"""
        if self._svc_token:
            return
        s = get_settings()
        data = self._post("/login", {"username": s.ruoyi_username, "password": s.ruoyi_password})
        self._svc_token = data.get("token")
        if not self._svc_token:
            raise ClinicClientError(401, "服务级登录失败")

    # ---------- 业务 ----------
    def bind_me(self) -> dict:
        """当前登录用户绑定的患者档案"""
        return self._get("/clinic/bind/me")["data"]

    def schedule_list(self, status: str = "OPEN", page_size: int = 20) -> list[dict]:
        data = self._get(
            "/clinic/schedule/list",
            {"status": status, "pageNum": 1, "pageSize": page_size},
        )
        return data.get("rows", [])

    def schedule_get(self, schedule_id: int) -> dict:
        return self._get(f"/clinic/schedule/{schedule_id}")["data"]

    def appointment_book(self, schedule_id: int, source: str = "AI") -> dict:
        """挂号。patientId 由后端从登录态取，客户端不传。"""
        return self._post("/clinic/appointment/book", {"scheduleId": schedule_id, "source": source})["data"]

    def appointment_cancel(self, appointment_id: int, reason: str = "AI 助手代取消") -> None:
        self._post(f"/clinic/appointment/cancel/{appointment_id}", {"reason": reason})

    def appointment_list(self, patient_id: int, status: str | None = None) -> list[dict]:
        params = {"patientId": patient_id, "pageNum": 1, "pageSize": 20}
        if status:
            params["status"] = status
        return self._get("/clinic/appointment/list", params).get("rows", [])

    def appointment_get(self, appointment_id: int) -> dict:
        return self._get(f"/clinic/appointment/{appointment_id}")["data"]