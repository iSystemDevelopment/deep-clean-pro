@echo off
title Deep Clean Pro - OFFICE MODE 💼
color 0E
cls

echo ========================================================
echo          DEEP CLEAN PRO - OFFICE OPTIMIZATION
echo ========================================================
echo.
echo Optimizing for everyday office and productivity use:
echo   - Balanced performance and battery
echo   - Faster boot and application launch
echo   - Remove distractions and bloat
echo.
echo Press any key to optimize for Office work...
pause > nul

echo.
echo [*] Launching Office Optimization...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Office''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Office optimization started!
echo Your work PC will feel smoother and more responsive.
echo ========================================================
echo.
timeout /t 5 > nul
