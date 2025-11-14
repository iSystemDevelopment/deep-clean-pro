@echo off
title Deep Clean Pro - Control Center
color 0A

:menu
cls
echo ========================================================
echo              DEEP CLEAN PRO - CONTROL CENTER
echo ========================================================
echo.
echo  Select an option:
echo.
echo  1) Quick Fix  (no updates)
echo  2) Quick Fix  + Windows Update
echo  3) Gaming Mode
echo  4) Gaming Mode + Windows Update
echo  5) Dev Mode
echo  6) Dev Mode   + Windows Update
echo  7) OneDrive Liberator
echo  8) Test Mode (safe preview)
echo  9) Exit
echo.
set /p choice="Enter your choice (1-9): "

if "%choice%"=="1" goto quickfix
if "%choice%"=="2" goto quickfix_update
if "%choice%"=="3" goto gaming
if "%choice%"=="4" goto gaming_update
if "%choice%"=="5" goto dev
if "%choice%"=="6" goto dev_update
if "%choice%"=="7" goto onedrive
if "%choice%"=="8" goto testmode
if "%choice%"=="9" goto end
goto menu

:quickfix
echo.
echo [*] Running Quick Fix (no Windows Update)...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex; DeepCleanPro.ps1 -QuickMode -NoReboot\"' -Verb RunAs}"
goto done

:quickfix_update
echo.
echo [*] Running Quick Fix + Windows Update...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex; DeepCleanPro.ps1 -QuickMode -RunWindowsUpdates -NoReboot\"' -Verb RunAs}"
goto done

:gaming
echo.
echo [*] Running Gaming Mode...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Gaming''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"
goto done

:gaming_update
echo.
echo [*] Running Gaming Mode + Windows Update...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Gaming''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex; DeepCleanPro.ps1 -Profile Gaming -RunWindowsUpdates -NoReboot\"' -Verb RunAs}"
goto done

:dev
echo.
echo [*] Running Dev Mode...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Development''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"
goto done

:dev_update
echo.
echo [*] Running Dev Mode + Windows Update...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$env:DCP_PROFILE=''Development''; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex; DeepCleanPro.ps1 -Profile Development -RunWindowsUpdates -NoReboot\"' -Verb RunAs}"
goto done

:onedrive
echo.
echo [*] Running OneDrive Liberator...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"C:\DeepCleanPro\OneDriveNuke.ps1\"' -Verb RunAs}"
goto done

:testmode
echo.
echo [*] Running Test Mode (no changes will be made)...
PowerShell -NoProfile -ExecutionPolicy Bypass -Command ^
  "& {Start-Process PowerShell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -Command \"$WhatIfPreference=$true; irm ''https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'' | iex\"' -Verb RunAs}"
goto done

:done
echo.
echo Operation started. You can close this window or run another option.
echo.
pause
goto menu

:end
echo.
echo Exiting Deep Clean Pro Control Center...
timeout /t 2 > nul
exit /b
