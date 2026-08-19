@echo off
setlocal EnableExtensions
title Deep Clean Pro - FULL OPTIMIZATION
color 0A
cls

echo ========================================================
echo        DEEP CLEAN PRO - FULL OPTIMIZATION
echo ========================================================
echo.
echo This runs the FULL Deep Clean Pro optimization suite.
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul