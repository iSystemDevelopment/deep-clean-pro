@echo off
setlocal EnableExtensions
title Deep Clean Pro - MUSIC MODE
color 0D
cls

echo ========================================================
echo        DEEP CLEAN PRO - MUSIC MODE
echo ========================================================
echo.
echo Optimizes your PC for music production (lower latency / audio focus).
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -Profile Music -NoReboot

echo.
echo ========================================================
echo Launch requested. Check the elevated PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul