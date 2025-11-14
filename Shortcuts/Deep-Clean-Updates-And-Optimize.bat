@echo off
title Deep Clean Pro - UPDATES + OPTIMIZATION 🔄
color 0E
cls

echo ========================================================
echo     DEEP CLEAN PRO - UPDATES + OPTIMIZATION
echo ========================================================
echo.
echo This will:
echo   - Run Deep Clean Pro in FULL mode
echo   - Ask if you want Windows Update maintenance (Y/N)
echo   - Clean and optimize your system afterwards
echo.
echo Recommended:
echo   - Press ENTER or Y when asked about Windows Update
echo   - Restart when prompted for best results
echo.
echo Press any key to start Updates + Optimization...
pause > nul

echo.
echo [*] Launching Deep Clean Pro with Updates + Optimization...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Updates + Optimization started!
echo Follow the prompts in the PowerShell window.
echo ========================================================
echo.
timeout /t 5 > nul
