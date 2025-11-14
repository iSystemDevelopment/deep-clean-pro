<#
.SYNOPSIS
    Creates desktop shortcuts for Deep Clean Pro with various configurations
.DESCRIPTION
    Generates desktop shortcuts for different Deep Clean Pro modes including
    local execution and GitHub-based launcher shortcuts.
.PARAMETER TargetPath
    Path to Deep Clean Pro installation directory
.PARAMETER GistLauncherURL
    Raw URL of the GitHub Gist containing the launcher script
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
        $desktop = [Environment]::GetFolderPath("Desktop")
        $shortcutPath = Join-Path $desktop "$Name.lnk"
        
        # Remove existing shortcut if present
        if (Test-Path $shortcutPath) {
            Remove-Item -Path $shortcutPath -Force
        }
        
        # Create shortcut
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
        [string]$ScriptPath
    )
    
    Write-ShortcutLog "`nCreating local execution shortcuts..." -Type Info
    
    $shortcuts = @(
        @{
            Name = "Deep Clean Pro"
            Arguments = "-NoProfile -ExecutionPolicy RemoteSigned -File `"$ScriptPath`""
            Description = "Run Deep Clean Pro - Full optimization mode"
        },
        @{
            Name = "Deep Clean Pro (Quick)"
            Arguments = "-NoProfile -ExecutionPolicy RemoteSigned -File `"$ScriptPath`" -QuickMode"
            Description = "Run Deep Clean Pro - Quick optimization mode (5-10 minutes)"
        },
        @{
            Name = "Deep Clean Pro (Test)"
            Arguments = "-NoProfile -ExecutionPolicy RemoteSigned -File `"$ScriptPath`" -WhatIf"
            Description = "Test Deep Clean Pro without making changes"
        },
        @{
            Name = "Deep Clean Pro (No Reboot)"
            Arguments = "-NoProfile -ExecutionPolicy RemoteSigned -File `"$ScriptPath`" -NoReboot"
            Description = "Run Deep Clean Pro without automatic reboot"
        }
    )
    
    $created = 0
    foreach ($shortcut in $shortcuts) {
        if (New-DCPShortcut -Name $shortcut.Name `
                            -TargetPath "powershell.exe" `
                            -Arguments $shortcut.Arguments `
                            -Description $shortcut.Description `
                            -RunAsAdmin) {
            $created++
        }
    }
    
    return $created
}

function New-GitHubShortcuts {
    param(
        [string]$LauncherURL
    )
    
    Write-ShortcutLog "`nCreating GitHub launcher shortcuts..." -Type Info
    
    # Validate URL
    if ($LauncherURL -notmatch '^https://gist\.githubusercontent\.com/.*\.ps1$') {
        Write-ShortcutLog "Invalid Gist URL format. Must be a raw GitHub Gist URL ending in .ps1" -Type Error
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
                            -EnvironmentVariables $shortcut.EnvVars `
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
    
    $shortcuts = @(
        @{
            Name = "Deep Clean Pro - Validate"
            Script = "Scripts\VALIDATE.ps1"
            Description = "Run system validation checks"
        },
        @{
            Name = "Deep Clean Pro - Fix Policies"
            Script = "Fix-WindowsPolicies.ps1"
            Description = "Configure Windows policies for optimal execution"
        }
    )
    
    $created = 0
    foreach ($shortcut in $shortcuts) {
        $scriptPath = Join-Path $BasePath $shortcut.Script
        if (Test-Path $scriptPath) {
            if (New-DCPShortcut -Name $shortcut.Name `
                                -TargetPath "powershell.exe" `
                                -Arguments "-NoProfile -ExecutionPolicy RemoteSigned -File `"$scriptPath`"" `
                                -Description $shortcut.Description `
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
    }
    
    # Verify installation
    $mainScript = Join-Path $TargetPath "DeepCleanPro.ps1"
    if (-not (Test-Path $mainScript)) {
        throw "DeepCleanPro.ps1 not found at $TargetPath"
    }
    
    $totalCreated = 0
    
    # Create local shortcuts
    $localCount = New-LocalShortcuts -ScriptPath $mainScript
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
        
        if (-not $GistLauncherURL) {
            Write-Host "`n💡 Tip: To create online shortcuts, run this script with:" -ForegroundColor Yellow
            Write-Host "   -GistLauncherURL `"<your-gist-raw-url>`"" -ForegroundColor Gray
        }
        
        Write-Host "`n📝 All shortcuts have been configured to run as Administrator" -ForegroundColor Gray
    }
    
    exit 0
    
} catch {
    Write-ShortcutLog "Critical error: $_" -Type Error
    exit 1
}