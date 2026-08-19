@echo off
setlocal EnableExtensions
title Deep Clean Pro - VIDEO MODE
color 0E
cls

echo ========================================================
echo        DEEP CLEAN PRO - VIDEO MODE
echo ========================================================
echo.
echo Optimizes your PC for video editing workloads.
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -Profile Video -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul