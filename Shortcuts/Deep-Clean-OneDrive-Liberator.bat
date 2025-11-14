@echo off
title Deep Clean Pro - ONEDRIVE LIBERATOR ☁️
color 0C
cls

echo ========================================================
echo          DEEP CLEAN PRO - ONEDRIVE LIBERATOR
echo ========================================================
echo.
echo This tool will:
echo   - Move your OneDrive files to a local backup
echo   - Move Desktop / Documents / Pictures back to local folders
echo   - Uninstall OneDrive
echo   - Remove OneDrive from Explorer
echo   - Block OneDrive from reinstalling
echo.
echo WARNING: This is a ONE-WAY operation.
echo   - OneDrive sync will be disabled
echo   - Your files will stay safely on local disk
echo.
echo Press any key to run OneDrive Liberator...
pause > nul

echo.
echo [*] Launching OneDrive Liberator...
echo.

PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {
        if (Test-Path 'C:\DeepCleanPro\OneDriveNuke.ps1') {
            Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"C:\DeepCleanPro\OneDriveNuke.ps1\"' -Verb RunAs
        } else {
            Write-Host 'OneDriveNuke.ps1 not found in C:\DeepCleanPro. Please install Deep Clean Pro first.' -ForegroundColor Red
            Pause
        }
    }"

echo.
echo ========================================================
echo OneDrive Liberator started (if installed).
echo Check the PowerShell window for progress and prompts.
echo ========================================================
echo.
timeout /t 5 > nul
