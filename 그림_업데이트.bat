@echo off
chcp 65001 >nul
echo 선율이 그림을 확인하고 있어요...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0update.ps1"
echo.
pause
