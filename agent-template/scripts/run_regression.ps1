$ErrorActionPreference = "Continue"
try { chcp 65001 | Out-Null } catch {}
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$AGT = "C:\Users\25301\Desktop\qing-feng-clinic\agent-template"
$PY  = "$AGT\.venv\Scripts\python.exe"

& $PY "$AGT\scripts\regression_45.py"