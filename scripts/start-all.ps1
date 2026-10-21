# =====================================================
# 一键启动：若依后端 (8087) + Python Agent (8099) + 前端 (3007)
# 用法：powershell -ExecutionPolicy Bypass -File .\scripts\start-all.ps1
# =====================================================
$ErrorActionPreference = "Continue"
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ROOT = Split-Path $PSScriptRoot -Parent
$BE   = "$ROOT\RuoYi-Vue-springboot3"
$FE   = "$ROOT\RuoYi-Vue3-master"
$AGT  = "$ROOT\agent-template"
$PY   = "$AGT\.venv\Scripts\python.exe"

$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.12.7-hotspot"

function Test-Port($p) {
    return [bool](Get-NetTCPConnection -State Listen -LocalPort $p -ErrorAction SilentlyContinue)
}

function Wait-Port($p, $name, $maxSec = 90) {
    $steps = [math]::Ceiling($maxSec / 3)
    for ($i=1; $i -le $steps; $i++) {
        Start-Sleep -Seconds 3
        if (Test-Port $p) {
            Write-Host ("  ✓ {0} (:{1}) 就绪" -f $name, $p) -ForegroundColor Green
            return $true
        }
    }
    Write-Host ("  ✗ {0} (:{1}) 启动超时" -f $name, $p) -ForegroundColor Red
    return $false
}

# ============ 0. MySQL / Redis 检查 ============
Write-Host "===== [0/4] 基础服务 =====" -ForegroundColor Cyan
if (Test-Port 3306) { Write-Host "  ✓ MySQL (3306)" -ForegroundColor Green }
else { Write-Host "  ✗ MySQL (3306) 未启动，后续步骤会失败" -ForegroundColor Red }

if (Test-Port 6379) {
    Write-Host "  ✓ Redis (6379)" -ForegroundColor Green
} else {
    Write-Host "  Redis (6379) 未启动，自动拉起..." -ForegroundColor Yellow
    $redisExe = $null
    foreach ($p in @(
        "D:\Redis\redis-server.exe",
        "D:\Redis\redis-server",
        "C:\Redis\redis-server.exe",
        "C:\Program Files\Redis\redis-server.exe"
    )) {
        if (Test-Path $p) { $redisExe = $p; break }
    }
    if ($redisExe) {
        Start-Process -FilePath $redisExe `
            -WorkingDirectory (Split-Path $redisExe -Parent) `
            -WindowStyle Hidden | Out-Null
        $okR = $false
        for ($i = 1; $i -le 10; $i++) {
            Start-Sleep -Seconds 1
            if (Test-Port 6379) { $okR = $true; break }
        }
        if ($okR) {
            Write-Host "  ✓ Redis 已自动启动" -ForegroundColor Green
        } else {
            Write-Host "  ✗ Redis 启动失败，请手动运行 $redisExe" -ForegroundColor Red
        }
    } else {
        Write-Host "  ✗ 找不到 redis-server.exe（已查 D:\Redis / C:\Redis / Program Files）" -ForegroundColor Red
        Write-Host "    请手动启动 Redis 后重跑本脚本" -ForegroundColor Yellow
    }
}

# ============ 1. 若依后端 ============
Write-Host "`n===== [1/4] 若依后端 (8087) =====" -ForegroundColor Cyan
if (Test-Port 8087) {
    Write-Host "  - 已在运行" -ForegroundColor Yellow
} else {
    # 读密码：优先 .mysqlpass，其次交互输入
    $passFile = "$ROOT\.mysqlpass"
    if (Test-Path $passFile) {
        $env:MYSQL_PASSWORD = (Get-Content $passFile -Raw).Trim()
        Write-Host "  ✓ 从 .mysqlpass 读密码"
    } else {
        $secure = Read-Host "MySQL root 密码（将保存到 .mysqlpass）" -AsSecureString
        $env:MYSQL_PASSWORD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
        $env:MYSQL_PASSWORD | Out-File -Encoding utf8 $passFile
        Write-Host "  ✓ 密码已保存到 .mysqlpass"
    }

    $env:SERVER_PORT    = "8087"
    $env:MYSQL_HOST     = "127.0.0.1"
    $env:MYSQL_PORT     = "3306"
    $env:MYSQL_DATABASE = "ocms_ruoyi_starter"
    $env:MYSQL_USER     = "root"
    $env:REDIS_HOST     = "127.0.0.1"
    $env:REDIS_PORT     = "6379"
    $env:REDIS_DATABASE = "7"
    $env:REDIS_PASSWORD = ""

    $jar = "$BE\ruoyi-admin\target\ruoyi-admin.jar"
    if (-not (Test-Path $jar)) {
        Write-Host "  ✗ jar 不存在，请先跑 .\scripts\init-all.ps1" -ForegroundColor Red
    } else {
        Start-Process -FilePath "java" `
            -ArgumentList "-Dfile.encoding=UTF-8","-jar",$jar `
            -WorkingDirectory "$BE\ruoyi-admin\target" `
            -RedirectStandardOutput "$BE\ruoyi-admin\target\run.log" `
            -RedirectStandardError  "$BE\ruoyi-admin\target\run.err.log" `
            -WindowStyle Hidden | Out-Null
        Wait-Port 8087 "若依后端" 90 | Out-Null
    }
}

# ============ 2. Python Agent ============
Write-Host "`n===== [2/4] Python Agent (8099) =====" -ForegroundColor Cyan
if (Test-Port 8099) {
    Write-Host "  - 已在运行" -ForegroundColor Yellow
} else {
    if (-not (Test-Path $PY)) {
        Write-Host "  ✗ venv 不存在，请先跑 .\scripts\init-all.ps1" -ForegroundColor Red
    } else {
        Start-Process -FilePath $PY `
            -ArgumentList "-m","uvicorn","app.main:app","--host","127.0.0.1","--port","8099" `
            -WorkingDirectory $AGT `
            -RedirectStandardOutput "$AGT\agent.log" `
            -RedirectStandardError  "$AGT\agent.err.log" `
            -WindowStyle Hidden | Out-Null
        Wait-Port 8099 "Python Agent" 30 | Out-Null
    }
}

# ============ 3. 前端 ============
Write-Host "`n===== [3/4] 前端 (3007) =====" -ForegroundColor Cyan
if (Test-Port 3007) {
    Write-Host "  - 已在运行" -ForegroundColor Yellow
} else {
    Start-Process -FilePath "cmd.exe" `
        -ArgumentList "/c","npm run dev > frontend.log 2>&1" `
        -WorkingDirectory $FE `
        -WindowStyle Hidden | Out-Null
    Wait-Port 3007 "前端" 90 | Out-Null
}

# ============ 4. 汇总 ============
Write-Host "`n===== [4/4] 服务状态 =====" -ForegroundColor Cyan
foreach ($s in @(
    @{n="MySQL";        p=3306},
    @{n="Redis";        p=6379},
    @{n="若依后端";     p=8087},
    @{n="Python Agent"; p=8099},
    @{n="前端";         p=3007}
)) {
    $ok = Test-Port $s.p
    $c = if ($ok) { "Green" } else { "Red" }
    $flag = if ($ok) { "✓" } else { "✗" }
    Write-Host ("  {0} {1,-15} :{2}" -f $flag, $s.n, $s.p) -ForegroundColor $c
}

Write-Host "`n===== HTTP 探活 =====" -ForegroundColor Cyan
foreach ($u in @(
    "http://127.0.0.1:8087/captchaImage",
    "http://127.0.0.1:8099/health",
    "http://127.0.0.1:3007/"
)) {
    try {
        $r = Invoke-WebRequest $u -UseBasicParsing -TimeoutSec 3
        Write-Host ("  ✓ {0} → {1}" -f $u, $r.StatusCode) -ForegroundColor Green
    } catch {
        Write-Host ("  ✗ {0}" -f $u) -ForegroundColor Red
    }
}

Write-Host "`n===== 全部就绪 =====" -ForegroundColor Green
Write-Host "前端：http://localhost:3007" -ForegroundColor Yellow
Write-Host "账号：admin / admin123" -ForegroundColor Yellow
Write-Host "菜单：门诊管理 → AI 就诊助手" -ForegroundColor Yellow
Write-Host ""
Start-Process "http://localhost:3007"