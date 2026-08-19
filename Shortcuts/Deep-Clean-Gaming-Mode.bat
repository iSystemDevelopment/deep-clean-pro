@echo off
setlocal EnableExtensions
title Deep Clean Pro - GAMING MODE
color 0C
cls

echo ========================================================
echo        DEEP CLEAN PRO - GAMING MODE
echo ========================================================
echo.
echo Optimizes your PC for gaming performance (Game DVR off, High Performance, etc.).
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -Profile Gaming -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul