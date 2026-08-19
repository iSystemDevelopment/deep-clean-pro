@echo off
setlocal EnableExtensions
title Deep Clean Pro - Control Center
color 0A

set "SCRIPT_ROOT=%~dp0"
set "LAUNCHER=%SCRIPT_ROOT%Scripts\Invoke-DcpElevated.ps1"

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
echo  9) Security Harden (safe set)
echo 10) Security Harden STRICT (prompts for each choice)
echo 11) Harden Only preview (-WhatIf)
echo 12) Exit
echo.
echo  Note: Hardening reduces common exposure. It is NOT
echo        a guarantee against attackers.
echo.
set /p choice="Enter your choice (1-12): "

if "%choice%"=="1" goto quickfix
if "%choice%"=="2" goto quickfix_update
if "%choice%"=="3" goto gaming
if "%choice%"=="4" goto gaming_update
if "%choice%"=="5" goto dev
if "%choice%"=="6" goto dev_update
if "%choice%"=="7" goto onedrive
if "%choice%"=="8" goto testmode
if "%choice%"=="9" goto harden
if "%choice%"=="10" goto harden_strict
if "%choice%"=="11" goto harden_whatif
if "%choice%"=="12" goto end
goto menu

:quickfix
echo.
echo [*] Running Quick Fix (no Windows Update)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -QuickMode -NoReboot
goto done

:quickfix_update
echo.
echo [*] Running Quick Fix + Windows Update...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -QuickMode -RunWindowsUpdates -NoReboot
goto done

:gaming
echo.
echo [*] Running Gaming Mode...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -Profile Gaming -NoReboot
goto done

:gaming_update
echo.
echo [*] Running Gaming Mode + Windows Update...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -Profile Gaming -RunWindowsUpdates -NoReboot
goto done

:dev
echo.
echo [*] Running Dev Mode...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -Profile Development -NoReboot
goto done

:dev_update
echo.
echo [*] Running Dev Mode + Windows Update...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -Profile Development -RunWindowsUpdates -NoReboot
goto done

:onedrive
echo.
echo [*] Running OneDrive Liberator...
set "ONEDRIVE=%SCRIPT_ROOT%OneDriveNuke.ps1"
if not exist "%ONEDRIVE%" set "ONEDRIVE=C:\DeepCleanPro\OneDriveNuke.ps1"
if exist "%ONEDRIVE%" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process powershell.exe -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File \"%ONEDRIVE%\"'"
) else (
  echo [ERROR] OneDriveNuke.ps1 not found. Run DEPLOY.ps1 first or keep the repo copy next to this menu.
  pause
)
goto done

:testmode
echo.
echo [*] Running Test Mode (no changes will be made)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -WhatIf -NoReboot
goto done

:harden
echo.
echo [*] Security Harden — safe defaults (firewall, SMBv1, AutoPlay, Guest, UAC, Defender)...
echo     Does NOT silently disable RDP/WinRM.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -HardenOnly -NoReboot
goto done

:harden_strict
echo.
echo [*] Security Harden STRICT — you will be asked YES for each risky choice.
echo     Keep an alternate way to reach this PC if you use RDP.
pause
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -HardenOnly -HardenStrict -NoReboot
goto done

:harden_whatif
echo.
echo [*] Preview hardening (WhatIf — no changes)...
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%LAUNCHER%" -HardenOnly -HardenStrict -WhatIf -NoReboot
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
