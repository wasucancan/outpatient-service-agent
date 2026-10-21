# =====================================================
# 首次初始化：建库 + 导入 SQL + 编译后端 + 构建知识库
# 用法：powershell -ExecutionPolicy Bypass -File .\scripts\init-all.ps1
# =====================================================
$ErrorActionPreference = "Stop"
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ROOT = Split-Path $PSScriptRoot -Parent
$BE   = "$ROOT\RuoYi-Vue-springboot3"
$FE   = "$ROOT\RuoYi-Vue3-master"
$AGT  = "$ROOT\agent-template"
$PY   = "$AGT\.venv\Scripts\python.exe"

$MYSQL   = "D:\mysql8\bin\mysql.exe"
$CHARSET = "--default-character-set=utf8mb4"
$DB      = "ocms_ruoyi_starter"

# ============ 1. 前置检查 ============
Write-Host "===== [1/6] 前置检查 =====" -ForegroundColor Cyan
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.12.7-hotspot"
foreach ($c in @("java","mvn","node","npm","python")) {
    if (-not (Get-Command $c -ErrorAction SilentlyContinue)) {
        Write-Host "  ✗ 缺少命令：$c" -ForegroundColor Red; return
    }
    Write-Host "  ✓ $c"
}
if (-not (Test-Path $MYSQL)) {
    Write-Host "  ✗ 找不到 mysql.exe：$MYSQL" -ForegroundColor Red; return
}
Write-Host "  ✓ mysql.exe"

# ============ 2. MySQL 密码 ============
Write-Host "`n===== [2/6] MySQL 密码 =====" -ForegroundColor Cyan
$passFile = "$ROOT\.mysqlpass"
if (Test-Path $passFile) {
    $env:MYSQL_PWD = (Get-Content $passFile -Raw).Trim()
    Write-Host "  ✓ 从 .mysqlpass 读取"
} else {
    $secure = Read-Host "MySQL root 密码（保存到 .mysqlpass）" -AsSecureString
    $env:MYSQL_PWD = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure))
    $env:MYSQL_PWD | Out-File -Encoding utf8 $passFile
    Write-Host "  ✓ 密码已保存到 .mysqlpass"
}

# ============ 3. 建库 ============
Write-Host "`n===== [3/6] 建库 $DB =====" -ForegroundColor Cyan
& $MYSQL $CHARSET -h 127.0.0.1 -P 3306 -u root -e `
  "CREATE DATABASE IF NOT EXISTS $DB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;"
if ($LASTEXITCODE -ne 0) { Write-Host "  ✗ 建库失败" -ForegroundColor Red; return }
Write-Host "  ✓ 库就绪"

# ============ 4. 导入 SQL ============
Write-Host "`n===== [4/6] 导入 SQL =====" -ForegroundColor Cyan
$sqls = @(
  "RuoYi-Vue-springboot3\sql\ry_20260417.sql",
  "RuoYi-Vue-springboot3\sql\quartz.sql",
  "materials\sql\clinic.sql",
  "materials\sql\clinic_enterprise_seed.sql",
  "materials\sql\clinic_stage3_seed.sql"
)
foreach ($f in $sqls) {
    Write-Host "  - $f"
    cmd /c "`"$MYSQL`" $CHARSET -h 127.0.0.1 -P 3306 -u root $DB < `"$ROOT\$f`""
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ✗ 导入失败：$f" -ForegroundColor Red; return
    }
}
Write-Host "  ✓ 5 份 SQL 全部导入"

# ============ 5. 编译后端 ============
Write-Host "`n===== [5/6] 编译若依后端 =====" -ForegroundColor Cyan
Push-Location $BE
mvn -pl ruoyi-admin -am package -DskipTests -q
$ok = ($LASTEXITCODE -eq 0)
Pop-Location
if (-not $ok) { Write-Host "  ✗ 编译失败，请重跑 mvn 看详细" -ForegroundColor Red; return }
Write-Host "  ✓ ruoyi-admin.jar 已生成"

# ============ 6. 前端依赖 + Python venv + 知识库 ============
Write-Host "`n===== [6/6] 前端 + Python + 知识库 =====" -ForegroundColor Cyan

# 前端
if (-not (Test-Path "$FE\node_modules")) {
    Write-Host "  - npm install（约 1-2 分钟）"
    Push-Location $FE
    npm install --no-audit --no-fund 2>&1 | Select-Object -Last 3
    Pop-Location
}
Write-Host "  ✓ 前端依赖"

# Python venv
if (-not (Test-Path $PY)) {
    Write-Host "  - 创建 venv + pip install"
    Push-Location $AGT
    python -m venv .venv
    & $PY -m pip install --upgrade pip -i https://pypi.tuna.tsinghua.edu.cn/simple --quiet
    & $PY -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    Pop-Location
}
Write-Host "  ✓ Python venv"

# 知识库
& $PY "$AGT\scripts\build_kb.py"
Write-Host "  ✓ 知识库索引"

Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
Write-Host "`n===== 初始化完成 =====" -ForegroundColor Green
Write-Host "下一步：powershell -ExecutionPolicy Bypass -File .\scripts\start-all.ps1" -ForegroundColor Yellow