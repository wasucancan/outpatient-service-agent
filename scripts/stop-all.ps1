# 一键停止三服务（不动 MySQL / Redis）
$ErrorActionPreference = "Continue"
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function KillPort($p, $name) {
    $c = Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue
    if ($c) {
        Write-Host "  停止 $name (:$p) PID=$($c.OwningProcess)"
        Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "  - $name (:$p) 未运行"
    }
}

Write-Host "===== 停止服务 =====" -ForegroundColor Cyan
KillPort 8087 "若依后端"
KillPort 8099 "Python Agent"
KillPort 3007 "前端"

# 兜底：venv python
Get-Process python -ErrorAction SilentlyContinue |
    Where-Object { $_.Path -and $_.Path -like "*agent-template\.venv*" } |
    ForEach-Object { Stop-Process -Id $_.Id -Force -ErrorAction SilentlyContinue }

Write-Host "`n===== 停止完成 =====" -ForegroundColor Green