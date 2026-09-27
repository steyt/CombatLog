@echo off
setlocal
cd /d "%~dp0"
echo CombatLog - local Windows trust setup
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\Install-CombatLogTrust.ps1"
echo.
pause
