@echo off
setlocal EnableExtensions
title Deep Clean Pro - UPDATES + OPTIMIZE
color 0A
cls

echo ========================================================
echo        DEEP CLEAN PRO - UPDATES + OPTIMIZE
echo ========================================================
echo.
echo Runs Deep Clean Pro and installs pending Windows Updates.
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -RunWindowsUpdates -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul