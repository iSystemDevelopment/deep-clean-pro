@echo off
setlocal EnableExtensions
title Deep Clean Pro - QUICK FIX
color 0B
cls

echo ========================================================
echo        DEEP CLEAN PRO - QUICK FIX
echo ========================================================
echo.
echo This runs a fast cleanup (temp files, services, performance tweaks).
echo No Windows Update. No reboot prompt.
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -QuickMode -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul