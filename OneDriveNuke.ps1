<#
.SYNOPSIS
    OneDrive Liberator - safely remove OneDrive and restore local shell folders.

.DESCRIPTION
    Backs up OneDrive files, restores Desktop/Documents/Pictures to local user folders,
    uninstalls OneDrive, cleans remnants, and optionally blocks reinstall via policy.

.PARAMETER Force
    Skip typing YES confirmation.

.PARAMETER WhatIf
    Show actions without changing the system (SupportsShouldProcess).

.NOTES
    Version: 1.0.0
    Part of Deep Clean Pro (iSystemDevelopment/deep-clean-pro)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$Force
)

#Requires -Version 5.1

$ErrorActionPreference = 'Stop'
$Script:BackupRoot = Join-Path $env:USERPROFILE ("Documents\OneDrive-Backup-{0}" -f (Get-Date -Format 'yyyy-MM-dd'))
$Script:Version = '1.0.0'

function Write-ColorOutput {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    $colors = @{ Info = 'Cyan'; Success = 'Green'; Warning = 'Yellow'; Error = 'Red' }
    $prefix = @{ Info = '[INFO]'; Success = '[OK]'; Warning = '[WARN]'; Error = '[ERROR]' }
    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

function Show-Header {
    Write-Host ''
    Write-Host '========================================================' -ForegroundColor Red
    Write-Host '       ONEDRIVE LIBERATOR  -  Deep Clean Pro' -ForegroundColor White
    Write-Host "       Version $Script:Version" -ForegroundColor Gray
    Write-Host '========================================================' -ForegroundColor Red
    Write-Host ''
    Write-Host 'This permanently removes OneDrive sync from this PC.' -ForegroundColor Yellow
    Write-Host 'Personal files are copied to a local backup first.' -ForegroundColor Yellow
    Write-Host ''
}

function Test-IsAdmin {
    $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Auto-elevate
if (-not (Test-IsAdmin)) {
    Write-ColorOutput 'Administrator privileges required - elevating...' -Type Warning
    $scriptPath = if ($PSCommandPath) { $PSCommandPath } else { $MyInvocation.MyCommand.Path }
    if (-not $scriptPath) {
        Write-ColorOutput 'Cannot auto-elevate: script path unknown.' -Type Error
        exit 1
    }
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    if ($Force) { $arguments += ' -Force' }
    if ($WhatIfPreference) { $arguments += ' -WhatIf' }
    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    exit
}

function Test-OneDriveInstalled {
    $paths = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive\OneDrive.exe'),
        (Join-Path ${env:ProgramFiles} 'Microsoft OneDrive\OneDrive.exe'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft OneDrive\OneDrive.exe')
    )
    foreach ($p in $paths) {
        if ($p -and (Test-Path -LiteralPath $p)) { return $true }
    }
    $setup = @(
        (Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'),
        (Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe')
    )
    foreach ($s in $setup) {
        if (Test-Path -LiteralPath $s) { return $true }
    }
    return $false
}

function Backup-OneDriveFiles {
    $candidates = @(
        (Join-Path $env:USERPROFILE 'OneDrive'),
        $env:OneDrive,
        $env:OneDriveConsumer,
        $env:OneDriveCommercial
    ) | Where-Object { $_ } | Select-Object -Unique

    $copied = 0
    foreach ($src in $candidates) {
        if (-not (Test-Path -LiteralPath $src)) { continue }
        if ($PSCmdlet.ShouldProcess($src, "Backup OneDrive folder to $Script:BackupRoot")) {
            New-Item -ItemType Directory -Path $Script:BackupRoot -Force | Out-Null
            $dest = Join-Path $Script:BackupRoot (Split-Path $src -Leaf)
            Write-ColorOutput "Copying $src -> $dest" -Type Info
            robocopy $src $dest /E /COPY:DAT /R:1 /W:1 /NFL /NDL /NJH /NJS | Out-Null
            $copied++
        }
    }
    if ($copied -eq 0) {
        Write-ColorOutput 'No OneDrive user folders found to backup (continuing).' -Type Warning
    } else {
        Write-ColorOutput "Backup complete under $Script:BackupRoot" -Type Success
    }
}

function Move-ShellFolders {
    $userProfile = $env:USERPROFILE
    $targets = @{
        'Desktop'   = Join-Path $userProfile 'Desktop'
        'Personal'  = Join-Path $userProfile 'Documents'
        'My Pictures' = Join-Path $userProfile 'Pictures'
    }
    $userShell = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders'
    $shell = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders'

    foreach ($name in $targets.Keys) {
        $path = $targets[$name]
        if (-not (Test-Path -LiteralPath $path)) {
            New-Item -ItemType Directory -Path $path -Force | Out-Null
        }
        if ($PSCmdlet.ShouldProcess($name, "Redirect shell folder to $path")) {
            if (Test-Path $userShell) {
                Set-ItemProperty -Path $userShell -Name $name -Value $path -ErrorAction SilentlyContinue
            }
            if (Test-Path $shell) {
                Set-ItemProperty -Path $shell -Name $name -Value $path -ErrorAction SilentlyContinue
            }
            Write-ColorOutput "Shell folder '$name' -> $path" -Type Success
        }
    }
}

function Stop-OneDriveProcess {
    if ($PSCmdlet.ShouldProcess('OneDrive.exe', 'Stop process')) {
        Get-Process -Name 'OneDrive' -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-ColorOutput 'OneDrive process stopped (if running).' -Type Info
    }
}

function Uninstall-OneDrive {
    $setupCandidates = @(
        (Join-Path $env:SystemRoot 'System32\OneDriveSetup.exe'),
        (Join-Path $env:SystemRoot 'SysWOW64\OneDriveSetup.exe')
    )
    $setup = $setupCandidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $setup) {
        Write-ColorOutput 'OneDriveSetup.exe not found - skipping uninstall executable.' -Type Warning
        return
    }
    if ($PSCmdlet.ShouldProcess($setup, 'Uninstall OneDrive (/uninstall)')) {
        Write-ColorOutput "Running $setup /uninstall" -Type Info
        Start-Process -FilePath $setup -ArgumentList '/uninstall' -Wait -NoNewWindow
        Write-ColorOutput 'OneDrive uninstall command finished.' -Type Success
    }
}

function Remove-OneDriveRemnants {
    $paths = @(
        (Join-Path $env:LOCALAPPDATA 'Microsoft\OneDrive'),
        (Join-Path ${env:ProgramFiles} 'Microsoft OneDrive'),
        (Join-Path ${env:ProgramFiles(x86)} 'Microsoft OneDrive'),
        (Join-Path $env:ProgramData 'Microsoft OneDrive')
    )
    foreach ($p in $paths) {
        if ($p -and (Test-Path -LiteralPath $p)) {
            if ($PSCmdlet.ShouldProcess($p, 'Remove remnant folder')) {
                Remove-Item -LiteralPath $p -Recurse -Force -ErrorAction SilentlyContinue
                Write-ColorOutput "Removed $p" -Type Success
            }
        }
    }

    # Explorer sidebar / NavigatePane residue (best-effort)
    $clsid = 'HKCU:\Software\Classes\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}'
    if (Test-Path $clsid) {
        if ($PSCmdlet.ShouldProcess($clsid, 'Remove OneDrive CLSID from Explorer')) {
            Remove-Item -Path $clsid -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Block-OneDriveReinstall {
    $policyPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive'
    if ($PSCmdlet.ShouldProcess($policyPath, 'Set DisableFileSyncNGSC / DisableFileSync')) {
        if (-not (Test-Path $policyPath)) {
            New-Item -Path $policyPath -Force | Out-Null
        }
        Set-ItemProperty -Path $policyPath -Name 'DisableFileSyncNGSC' -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $policyPath -Name 'DisableFileSync' -Value 1 -Type DWord -Force
        Write-ColorOutput 'OneDrive reinstall blocked via local policy keys.' -Type Success
    }
}

function Show-Summary {
    Write-Host ''
    Write-Host '========================================================' -ForegroundColor Cyan
    Write-Host ' OneDrive Liberator finished.' -ForegroundColor White
    Write-Host " Backup folder: $Script:BackupRoot" -ForegroundColor Gray
    Write-Host ' Restart Explorer or reboot if folders still look linked.' -ForegroundColor Yellow
    Write-Host '========================================================' -ForegroundColor Cyan
}

# --- Main ---
Show-Header

if (-not $Force) {
    $answer = Read-Host "Type YES to permanently remove OneDrive"
    if ($answer -ne 'YES') {
        Write-ColorOutput 'Aborted by user.' -Type Warning
        exit 0
    }
}

if (-not (Test-OneDriveInstalled)) {
    Write-ColorOutput 'OneDrive does not appear to be installed. Nothing to do.' -Type Warning
    exit 0
}

Backup-OneDriveFiles
Move-ShellFolders
Stop-OneDriveProcess
Uninstall-OneDrive
Remove-OneDriveRemnants
Block-OneDriveReinstall
Show-Summary

Write-ColorOutput 'Done.' -Type Success
