@echo off
setlocal EnableExtensions
title Deep Clean Pro - ONEDRIVE LIBERATOR
color 0C
cls

echo ========================================================
echo          DEEP CLEAN PRO - ONEDRIVE LIBERATOR
echo ========================================================
echo.
echo This tool will:
echo   - Backup OneDrive files locally
echo   - Restore Desktop / Documents / Pictures to local folders
echo   - Uninstall OneDrive
echo   - Remove Explorer remnants
echo   - Block OneDrive from reinstalling
echo.
echo WARNING: This is a ONE-WAY operation for cloud sync.
echo.
echo Press any key to run OneDrive Liberator...
pause > nul

echo.
echo [*] Launching OneDrive Liberator...
echo.

set "SCRIPT=%~dp0..\OneDriveNuke.ps1"
if not exist "%SCRIPT%" set "SCRIPT=C:\DeepCleanPro\OneDriveNuke.ps1"
if exist "%SCRIPT%" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%SCRIPT%\"'"
) else (
  echo [ERROR] OneDriveNuke.ps1 not found. Keep it next to the repo root or deploy to C:\DeepCleanPro.
  pause
)

echo.
timeout /t 5 > nul