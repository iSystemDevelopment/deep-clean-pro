@echo off
setlocal EnableExtensions
title Deep Clean Pro - SECURITY HARDEN
color 0E
cls

echo ========================================================
echo        DEEP CLEAN PRO - SECURITY HARDENING
echo ========================================================
echo.
echo Safe defaults: firewall ON, SMBv1 off, AutoPlay off,
echo Guest off, UAC secure, Defender check, Remote Assistance off.
echo.
echo This reduces common attack surface.
echo It does NOT make Windows immune to attackers.
echo.
echo Press any key to continue...
pause > nul

echo.
echo [*] Launching Harden Only...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -HardenOnly -NoReboot

echo.
timeout /t 5 > nul
