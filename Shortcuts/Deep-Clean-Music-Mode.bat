@echo off
title Deep Clean Pro - MUSIC MODE 🎵
color 0B
cls

echo ========================================================
echo        DEEP CLEAN PRO - MUSIC PRODUCTION MODE
echo ========================================================
echo.
echo Optimizing for DAW and audio production:
echo   - Reduce DPC latency
echo   - Disable audio "enhancements"
echo   - Optimize USB and power for audio interfaces
echo.
echo Press any key to optimize for music production...
pause > nul

echo.
echo [*] Launching Music Production Optimization...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Music''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Music optimization started!
echo Your DAW and plugins should run more smoothly.
echo ========================================================
echo.
timeout /t 5 > nul
