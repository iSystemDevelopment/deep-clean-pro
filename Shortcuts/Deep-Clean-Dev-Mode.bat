@echo off
setlocal EnableExtensions
title Deep Clean Pro - DEV MODE
color 0B
cls

echo ========================================================
echo        DEEP CLEAN PRO - DEV MODE
echo ========================================================
echo.
echo Optimizes your PC for development workloads.
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -Profile Development -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul