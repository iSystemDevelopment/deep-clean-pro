@echo off
title Deep Clean Pro - FULL OPTIMIZATION 🔥
color 0C
cls

echo ========================================================
echo         DEEP CLEAN PRO - FULL OPTIMIZATION
echo ========================================================
echo.
echo This will perform a COMPLETE optimization:
echo   - Full cleanup and service tuning
echo   - Bloatware removal
echo   - Network and startup optimization
echo   - Disk cleanup and defrag (if not skipped)
echo   - Optional Windows Update maintenance
echo.
echo You will be asked:
echo   - Whether to run Windows Update maintenance (Y/N)
echo   - Whether to restart when finished (Y/N)
echo.
echo Press any key to run Full Optimization...
pause > nul

echo.
echo [*] Launching Full Optimization...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Full Optimization started!
echo Follow the prompts in the PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul
