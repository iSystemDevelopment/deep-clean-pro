@echo off
title Deep Clean Pro - TEST MODE (Safe Preview) 🧪
color 0B
cls

echo ========================================================
echo        DEEP CLEAN PRO - TEST MODE (SAFE)
echo ========================================================
echo.
echo This will ONLY SHOW what would be changed.
echo NO ACTUAL CHANGES WILL BE MADE TO YOUR PC!
echo.
echo Perfect for:
echo   - First time users
echo   - Seeing what the tool does
echo   - Testing without risk
echo.
echo Press any key to see what would be optimized...
pause > nul

echo.
echo [*] Running in TEST MODE (no changes will be made)...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$WhatIfPreference=$true; irm ''https://gist.githubusercontent.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7/raw/DeepCleanPro-Launcher.ps1'' | iex\"' -Verb RunAs}"

echo.
echo ========================================================
echo Test mode started!
echo You can see what would be changed without any risk!
echo ========================================================
echo.
echo Press any key to close...
pause > nul