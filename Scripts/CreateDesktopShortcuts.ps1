<#
.SYNOPSIS
    Creates desktop shortcuts for Deep Clean Pro with various configurations
.DESCRIPTION
    Generates desktop shortcuts for different Deep Clean Pro modes including
    local execution and GitHub-based launcher shortcuts.
.PARAMETER TargetPath
    Path to Deep Clean Pro installation directory
.PARAMETER GistLauncherURL
    Raw URL of the launcher script (GitHub Gist or raw GitHub .ps1)
.PARAMETER Silent
    Run without console output
.EXAMPLE
    .\CreateDesktopShortcuts.ps1
    Create standard local shortcuts
.EXAMPLE
    .\CreateDesktopShortcuts.ps1 -GistLauncherURL "https://gist.githubusercontent.com/..."
    Create shortcuts using GitHub launcher
#>

[CmdletBinding()]
param(
    [string]$TargetPath = (Split-Path $PSScriptRoot -Parent),
    [string]$GistLauncherURL = "",
    [switch]$Silent
)

#Requires -Version 5.1

function Write-ShortcutLog {
    param(
        [string]$Message,
        [string]$Type = 'Info'
    )
    
    if ($Silent) { return }
    
    $colors = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    Write-Host $Message -ForegroundColor $colors[$Type]
}

function New-DCPShortcut {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$TargetPath,
        [string]$Arguments = "",
        [string]$Description = "",
        [string]$IconPath = "",
        [int]$IconIndex = 0,
        [hashtable]$EnvironmentVariables = @{},
        [switch]$RunAsAdmin
    )
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $desktopPath = [Environment]::GetFolderPath('Desktop')
        $shortcutPath = Join-Path $desktopPath "$Name.lnk"
        
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = $TargetPath
        $shortcut.Arguments = $Arguments
        $shortcut.Description = $Description
        $shortcut.WorkingDirectory = Split-Path $TargetPath -Parent
        
        # Set icon if specified
        if ($IconPath) {
            $shortcut.IconLocation = "$IconPath,$IconIndex"
        } else {
            # Use PowerShell icon
            $shortcut.IconLocation = "powershell.exe,0"
        }
        
        # Save shortcut
        $shortcut.Save()
        
        # Set Run as Administrator if needed
        if ($RunAsAdmin) {
            $bytes = [System.IO.File]::ReadAllBytes($shortcutPath)
            $bytes[0x15] = $bytes[0x15] -bor 0x20
            [System.IO.File]::WriteAllBytes($shortcutPath, $bytes)
        }
        
        # Clean up COM object
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shortcut) | Out-Null
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        
        Write-ShortcutLog "Created: $Name" -Type Success
        return $true
    } catch {
        Write-ShortcutLog "Failed to create $Name`: $_" -Type Error
        return $false
    }
}

function New-LocalShortcuts {
    param(
        [string]$BasePath
    )
    
    Write-ShortcutLog "`nCreating local Deep Clean Pro shortcuts..." -Type Info
    
    $scripts = @(
        @{ Name = "Deep Clean Pro (Full)";     Script = "DeepCleanPro.ps1";       Args = "";                          Desc = "Run Deep Clean Pro (full optimization mode)" },
        @{ Name = "Deep Clean Pro - Quick";    Script = "DeepCleanPro.ps1";       Args = "-QuickMode -NoReboot";      Desc = "Quick mode (5-10 minutes, no reboot prompt)" },
        @{ Name = "Deep Clean Pro - Gaming";   Script = "DeepCleanPro.ps1";       Args = "-Profile Gaming";           Desc = "Gaming optimizations" },
        @{ Name = "Deep Clean Pro - Dev";      Script = "DeepCleanPro.ps1";       Args = "-Profile Development";      Desc = "Development optimizations" },
        @{ Name = "Deep Clean Pro - Music";    Script = "DeepCleanPro.ps1";       Args = "-Profile Music";            Desc = "Music production optimizations" },
        @{ Name = "Deep Clean Pro - Video";    Script = "DeepCleanPro.ps1";       Args = "-Profile Video";            Desc = "Video editing optimizations" },
        @{ Name = "Deep Clean Pro - Office";   Script = "DeepCleanPro.ps1";       Args = "-Profile Office";           Desc = "Office/workstation optimizations" },
        @{ Name = "Deep Clean Pro - Test";     Script = "DeepCleanPro.ps1";       Args = "-WhatIf";                   Desc = "Test mode (no changes made)" }
    )
    
    $created = 0
    foreach ($shortcut in $scripts) {
        $scriptPath = Join-Path $BasePath $shortcut.Script
        
        if (Test-Path $scriptPath) {
            if (New-DCPShortcut -Name $shortcut.Name `
                                -TargetPath "powershell.exe" `
                                -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $($shortcut.Args)" `
                                -Description $shortcut.Desc `
                                -RunAsAdmin) {
                $created++
            }
        } else {
            Write-ShortcutLog "Script not found: $scriptPath" -Type Warning
        }
    }
    
    return $created
}

function New-GitHubShortcuts {
    param(
        [string]$LauncherURL
    )
    
    Write-ShortcutLog "`nCreating GitHub launcher shortcuts..." -Type Info
    
    # Validate URL: allow either Gist raw or raw GitHub script URLs ending in .ps1
    if ($LauncherURL -notmatch '^https://(gist\.githubusercontent\.com|raw\.githubusercontent\.com)/.*\.ps1$') {
        Write-ShortcutLog "Invalid launcher URL. Must be a raw GitHub URL ending in .ps1 (Gist or repository)." -Type Error
        return 0
    }
    
    $shortcuts = @(
        @{
            Name = "Deep Clean Pro (Online)"
            BaseArgs = "-NoProfile -ExecutionPolicy Bypass -Command `"& {irm '$LauncherURL' | iex}`""
            EnvVars = @{}
            Description = "Run Deep Clean Pro from GitHub (Latest Version)"
        },
        @{
            Name = "Deep Clean Pro Quick (Online)"
            BaseArgs = "-NoProfile -ExecutionPolicy Bypass -Command `"`$env:DCP_QUICK_MODE='true'; irm '$LauncherURL' | iex`""
            EnvVars = @{ DCP_QUICK_MODE = 'true' }
            Description = "Quick mode from GitHub (5-10 minutes)"
        },
        @{
            Name = "Deep Clean Pro Test (Online)"
            BaseArgs = "-NoProfile -ExecutionPolicy Bypass -Command `"`$WhatIfPreference=`$true; irm '$LauncherURL' | iex`""
            EnvVars = @{}
            Description = "Test mode from GitHub (no changes)"
        }
    )
    
    $created = 0
    foreach ($shortcut in $shortcuts) {
        if (New-DCPShortcut -Name $shortcut.Name `
                            -TargetPath "powershell.exe" `
                            -Arguments $shortcut.BaseArgs `
                            -Description $shortcut.Description `
                            -RunAsAdmin) {
            $created++
        }
    }
    
    return $created
}

function New-UtilityShortcuts {
    param(
        [string]$BasePath
    )
    
    Write-ShortcutLog "`nCreating utility shortcuts..." -Type Info
    
    $scripts = @(
        @{ Name = "Deep Clean Pro - OneDrive Liberator"; Script = "OneDriveNuke.ps1"; Args = "";              Desc = "Safely remove OneDrive and move files locally" },
        @{ Name = "Deep Clean Pro - Fix Policies";       Script = "Fix-WindowsPolicies.ps1"; Args = "";       Desc = "Repair broken local Windows policies" },
        @{ Name = "Deep Clean Pro - Validate";           Script = "Scripts\\VALIDATE.ps1"; Args = "";         Desc = "Run Deep Clean Pro validation checks" }
    )
    
    $created = 0
    foreach ($shortcut in $scripts) {
        $scriptPath = Join-Path $BasePath $shortcut.Script
        
        if (Test-Path $scriptPath) {
            if (New-DCPShortcut -Name $shortcut.Name `
                                -TargetPath "powershell.exe" `
                                -Arguments "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $($shortcut.Args)" `
                                -Description $shortcut.Desc `
                                -RunAsAdmin) {
                $created++
            }
        } else {
            Write-ShortcutLog "Script not found: $($shortcut.Script)" -Type Warning
        }
    }
    
    return $created
}

# Main execution
try {
    if (-not $Silent) {
        Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
        Write-Host "║          DEEP CLEAN PRO - SHORTCUT CREATOR v1.0             ║" -ForegroundColor Cyan
        Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
        Write-Host "Target installation path: $TargetPath" -ForegroundColor Gray
        
        if ($GistLauncherURL) {
            Write-Host "GitHub launcher URL:     $GistLauncherURL" -ForegroundColor Gray
        }
    }
    
    if (-not (Test-Path $TargetPath)) {
        Write-ShortcutLog "TargetPath does not exist: $TargetPath" -Type Error
        exit 1
    }
    
    $totalCreated = 0
    
    # Create local shortcuts
    $localCount = New-LocalShortcuts -BasePath $TargetPath
    $totalCreated += $localCount
    
    # Create GitHub shortcuts if URL provided
    if ($GistLauncherURL) {
        $githubCount = New-GitHubShortcuts -LauncherURL $GistLauncherURL
        $totalCreated += $githubCount
    }
    
    # Create utility shortcuts
    $utilityCount = New-UtilityShortcuts -BasePath $TargetPath
    $totalCreated += $utilityCount
    
    # Summary
    if (-not $Silent) {
        Write-Host "`n═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "✅ Created $totalCreated desktop shortcuts successfully!" -ForegroundColor Green
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
        if (-not $GistLauncherURL) {
            Write-Host "`n💡 Tip: To create online shortcuts, run this script with:" -ForegroundColor Yellow
            Write-Host "   -GistLauncherURL `"<your-launcher-raw-url>`"" -ForegroundColor Gray
        }
        
        Write-Host "`n📝 All shortcuts have been configured to run as Administrator" -ForegroundColor Gray
    }
    
    exit 0
    
} catch {
    Write-ShortcutLog "Critical error: $_" -Type Error
    exit 1
}
