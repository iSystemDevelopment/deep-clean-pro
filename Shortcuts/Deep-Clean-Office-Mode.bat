@echo off
setlocal EnableExtensions
title Deep Clean Pro - OFFICE MODE
color 0A
cls

echo ========================================================
echo        DEEP CLEAN PRO - OFFICE MODE
echo ========================================================
echo.
echo Optimizes your PC for office / productivity workloads.
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -Profile Office -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul