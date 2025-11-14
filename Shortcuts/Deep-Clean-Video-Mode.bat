@echo off
title Deep Clean Pro - VIDEO MODE 📹
color 0D
cls

echo ========================================================
echo        DEEP CLEAN PRO - VIDEO EDITING MODE
echo ========================================================
echo.
echo Optimizing for video editing and rendering:
echo   - Increase GPU timeout for heavy renders
echo   - Tune file system caching for large media
echo   - Improve responsiveness during editing
echo.
echo Press any key to optimize for video editing...
pause > nul

echo.
echo [*] Launching Video Editing Optimization...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Video''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Video optimization started!
echo Your editing and rendering workflows should feel smoother.
echo ========================================================
echo.
timeout /t 5 > nul

