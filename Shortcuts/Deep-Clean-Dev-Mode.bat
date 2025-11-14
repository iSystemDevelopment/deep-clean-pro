@echo off
title Deep Clean Pro - DEVELOPER MODE 💻
color 0E
cls

echo ========================================================
echo      DEEP CLEAN PRO - DEVELOPER OPTIMIZATION
echo ========================================================
echo.
echo Optimizing for Programming and Development!
echo.
echo What it will do:
echo   - Enable long path support
echo   - Add Defender exclusions for dev folders
echo   - Enable Developer Mode
echo   - Optimize for IDEs (VS Code, Visual Studio, etc.)
echo   - Clean package caches (npm, nuget, etc.)
echo.
echo Press any key to optimize for development...
pause > nul

echo.
echo [*] Launching Developer Optimization...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Development''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Developer optimization started!
echo Your IDE and tools will run much smoother!
echo ========================================================
echo.
timeout /t 5 > nul
