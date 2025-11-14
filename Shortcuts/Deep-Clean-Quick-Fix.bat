@echo off
title Deep Clean Pro - QUICK FIX 🚀
color 0A
cls

echo ========================================================
echo           DEEP CLEAN PRO - QUICK FIX MODE
echo ========================================================
echo.
echo This will perform a FAST, SAFE cleanup:
echo   - Clean temporary files
echo   - Basic service and system tuning
echo   - Light bloatware checks
echo   - No defrag, no heavy tasks
echo   - No automatic reboot
echo.
echo Press any key to run Quick Fix...
pause > nul

echo.
echo [*] Launching Quick Fix...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_QUICK_MODE=''true''; $env:DCP_NO_REBOOT=''true''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Quick Fix started!
echo Your PC will be cleaned and optimized in a few minutes.
echo ========================================================
echo.
timeout /t 5 > nul
