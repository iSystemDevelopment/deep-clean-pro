@echo off
setlocal EnableExtensions
title Deep Clean Pro - SECURITY HARDEN STRICT
color 0C
cls

echo ========================================================
echo     DEEP CLEAN PRO - STRICT HARDENING (USER CHOICE)
echo ========================================================
echo.
echo Applies the safe set, then asks YES for each of:
echo   - Disable RDP
echo   - Disable WinRM
echo   - Disable LLMNR
echo   - Disable PowerShell v2
echo   - Enable Defender ASR base rules
echo.
echo WARNING: Wrong choices can lock you out of remote access.
echo Keep provider console / physical access available.
echo.
echo This is attack-surface reduction — not a security guarantee.
echo.
echo Press any key to continue...
pause > nul

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\Scripts\Invoke-DcpElevated.ps1" -HardenOnly -HardenStrict -NoReboot

echo.
timeout /t 5 > nul
