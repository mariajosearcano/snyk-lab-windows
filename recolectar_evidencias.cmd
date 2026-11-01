@echo off
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0recolectar_evidencias.ps1" %*
echo.
pause
