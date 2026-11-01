@echo off
cd /d "%~dp0"
echo.
echo === Aplicar remediacion (la ventana no se cierra) ===
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0aplicar_remediacion.ps1"
echo.
pause
