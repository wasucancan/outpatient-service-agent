# 服务状态检查
$ErrorActionPreference = "Continue"
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Test-Port($p) {
    return [bool](Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue)
}

Write-Host "===== 端口状态 =====" -ForegroundColor Cyan
foreach ($s in @(
    @{n="MySQL";        p=3306},
    @{n="Redis";        p=6379},
    @{n="若依后端";     p=8087},
    @{n="Python Agent"; p=8099},
    @{n="前端";         p=3007}
)) {
    $ok = Test-Port $s.p
    $c = if ($ok) { "Green" } else { "DarkGray" }
    $flag = if ($ok) { "✓" } else { "·" }
    Write-Host ("  {0} {1,-15} :{2}" -f $flag, $s.n, $s.p) -ForegroundColor $c
}

Write-Host "`n===== HTTP 探活 =====" -ForegroundColor Cyan
foreach ($u in @(
    "http://127.0.0.1:8087/captchaImage",
    "http://127.0.0.1:8099/health",
    "http://127.0.0.1:3007/"
)) {
    try {
        $r = Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 2
        Write-Host ("  ✓ {0} → {1}" -f $u, $r.StatusCode) -ForegroundColor Green
    } catch {
        Write-Host ("  ✗ {0}" -f $u) -ForegroundColor DarkGray
    }
}

Write-Host "`n  启动：.\scripts\start-all.ps1" -ForegroundColor Yellow
Write-Host "  停止：.\scripts\stop-all.ps1" -ForegroundColor Yellow