@echo off
title Deep Clean Pro - GAMING MODE 🎮
color 0C
cls

echo ========================================================
echo        DEEP CLEAN PRO - GAMING OPTIMIZATION
echo ========================================================
echo.
echo This will optimize your PC for MAXIMUM GAMING PERFORMANCE!
echo.
echo What it will do:
echo   - Disable Xbox Game Bar and DVR
echo   - Set High Performance mode
echo   - Optimize GPU settings
echo   - Reduce input lag
echo   - Increase FPS
echo.
echo Press any key to boost your gaming performance...
pause > nul

echo.
echo [*] Launching Gaming Optimization...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Gaming''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Gaming optimization started!
echo Your games will run MUCH better after this!
echo ========================================================
echo.
timeout /t 5 > nul
