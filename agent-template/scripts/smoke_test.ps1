# -*- coding: utf-8 -*-
# 青枫门诊 · Day2 冒烟测试脚本
# 用法: powershell -ExecutionPolicy Bypass -File .\scripts\smoke_test.ps1

$ErrorActionPreference = "Continue"
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$API_RUOYI = "http://127.0.0.1:8087"
$API_AGENT = "http://127.0.0.1:8099"

# ----- 工具 -----
function Invoke-Chat {
    param($sid, $msg, $token)
    $json = @{ session_id = $sid; message = $msg } | ConvertTo-Json -Compress
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
    $headers = @{ Authorization = "Bearer $token" }
    $resp = Invoke-WebRequest "$API_AGENT/chat" -Method Post -Body $bytes -Headers $headers `
        -ContentType "application/json; charset=utf-8" -UseBasicParsing
    $text = [System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray())
    return $text | ConvertFrom-Json
}

function Write-Section($title) {
    Write-Host ""
    Write-Host "===== $title =====" -ForegroundColor Cyan
}

# ----- 0. 健康检查 -----
Write-Section "0. 健康检查"
try {
    $h = (Invoke-WebRequest "$API_AGENT/health" -UseBasicParsing -TimeoutSec 3).Content
    Write-Host "  agent: $h" -ForegroundColor Green
} catch {
    Write-Host "  ✗ agent 未启动。请先启动：" -ForegroundColor Red
    Write-Host "     `$proc = Start-Process -FilePath `"$PWD\.venv\Scripts\python.exe`" ``"
    Write-Host "         -ArgumentList '-m','uvicorn','app.main:app','--host','127.0.0.1','--port','8099' ``"
    Write-Host "         -WorkingDirectory `"$PWD`" -WindowStyle Hidden -PassThru"
    return
}

# ----- 1. 登录若依 -----
Write-Section "1. 登录若依"
$loginBytes = [System.Text.Encoding]::UTF8.GetBytes('{"username":"admin","password":"admin123"}')
$login = Invoke-RestMethod "$API_RUOYI/login" -Method Post -Body $loginBytes `
    -ContentType "application/json; charset=utf-8"
$token = $login.token
Write-Host "  ✓ token = $($token.Substring(0,20))..."

# ----- 2. 找出当前待取消的 BOOKED 预约 -----
Write-Section "2. 找一条待取消预约"
$resp = Invoke-WebRequest "$API_RUOYI/clinic/appointment/list?pageNum=1&pageSize=20&status=BOOKED" `
    -Headers @{ Authorization = "Bearer $token" } -UseBasicParsing
$list = ([System.Text.Encoding]::UTF8.GetString($resp.RawContentStream.ToArray()) | ConvertFrom-Json)

$existing = $list.rows | Where-Object { $_.patientId -eq 1001 } | Select-Object -First 1

if (-not $existing) {
    Write-Host "  没有 BOOKED 预约，现挂一条："
    $r3 = Invoke-Chat $null "明天有哪些号源" $token
    if (-not $r3.card -or $r3.card.data.Count -eq 0) {
        Write-Host "  ✗ 没有可用排班" -ForegroundColor Red
        return
    }
    $sid = $r3.card.data[0].scheduleId
    $r4 = Invoke-Chat $null "我要挂号排班$sid" $token
    $r5 = Invoke-Chat $r4.session_id "确认" $token
    if (-not $r5.card -or $r5.card.type -ne 'appointment_voucher') {
        Write-Host "  ✗ 挂号失败：$($r5.reply)" -ForegroundColor Red
        return
    }
    $existing = [PSCustomObject]@{
        appointmentId = $r5.card.data.appointmentId
        appointmentNo = $r5.card.data.appointmentNo
    }
    Write-Host "  ✓ 新挂号：$($existing.appointmentNo)"
}

$ano = $existing.appointmentNo
Write-Host "  目标凭证号：$ano"

# ----- 3. 取消预览 -----
Write-Section "3. 取消预览"
$r6a = Invoke-Chat $null "取消预约单 $ano" $token
Write-Host "  intent = $($r6a.intent)"
Write-Host "  stage  = $($r6a.stage)"
Write-Host "  card   = $($r6a.card.type)"
Write-Host "  reply  = $($r6a.reply)"

# ----- 4. 确认取消 -----
Write-Section "4. 确认取消"
$r6b = Invoke-Chat $r6a.session_id "确认" $token
Write-Host "  intent = $($r6b.intent)"
Write-Host "  stage  = $($r6b.stage)"
Write-Host "  reply  = $($r6b.reply)"

# ----- 5. 判定 -----
Write-Section "5. 结果"
if ($r6b.intent -eq "confirm" -and $r6b.reply -match "已取消") {
    Write-Host "  ✓ [6] 取消预约完整闭环通过" -ForegroundColor Green
} else {
    Write-Host "  ✗ [6] 未通过" -ForegroundColor Red
    Write-Host "  完整响应：" ($r6b | ConvertTo-Json -Depth 5)
}

Write-Host ""
Write-Host "===== 冒烟测试完成 =====" -ForegroundColor Green