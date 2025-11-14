<#
.SYNOPSIS
    Deep Clean Pro - GitHub Launcher Script
.DESCRIPTION
    Lightweight launcher that fetches and executes the latest Deep Clean Pro
    from the GitHub repository. Upload this to your Gist.
.NOTES
    Version: 1.0.1 - Fixed URLs and error handling
#>

[CmdletBinding()]
param()

# Configuration - YOUR ACTUAL REPO
$Script:Config = @{
    RepoUrl    = "https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1"
    ValidateUrl = "https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/Scripts/VALIDATE.ps1"
    Timeout    = 30
    RetryCount = 3
    RetryDelay = 2
}

function Write-LauncherMessage {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    $prefix = @{
        'Info'    = '[LAUNCHER]'
        'Success' = '[SUCCESS]'
        'Warning' = '[WARNING]'
        'Error'   = '[ERROR]'
    }
    
    $colors = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "https://api.github.com" -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Get-ScriptFromGitHub {
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [string]$Description = "script"
    )
    
    $attempt = 0
    $success = $false
    $content = $null
    
    while ($attempt -lt $Script:Config.RetryCount -and -not $success) {
        $attempt++
        
        try {
            Write-LauncherMessage "Downloading $Description (Attempt $attempt/$($Script:Config.RetryCount))..." -Type Info
            
            $response = Invoke-WebRequest -Uri $Url `
                                         -UseBasicParsing `
                                         -TimeoutSec $Script:Config.Timeout `
                                         -ErrorAction Stop
            
            if ($response.StatusCode -eq 200 -and $response.Content) {
                $content = $response.Content
                $success = $true
                Write-LauncherMessage "Successfully downloaded $Description" -Type Success
            } else {
                throw "Invalid response from server"
            }
            
        } catch {
            Write-LauncherMessage "Download failed: $_" -Type Warning
            
            if ($attempt -lt $Script:Config.RetryCount) {
                Write-LauncherMessage "Retrying in $($Script:Config.RetryDelay) seconds..." -Type Info
                Start-Sleep -Seconds $Script:Config.RetryDelay
            }
        }
    }
    
    if (-not $success) {
        throw "Failed to download $Description after $($Script:Config.RetryCount) attempts"
    }
    
    return $content
}

function Invoke-DeepCleanPro {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptContent
    )
    
    # Create temporary file
    $tempFile = [System.IO.Path]::GetTempFileName() -replace '\.tmp$', '.ps1'
    
    try {
        # Write script to temporary file
        $ScriptContent | Out-File -FilePath $tempFile -Encoding UTF8 -Force
        
        # Build arguments based on environment variables
        $arguments = @()
        
        # Profile support
        if ($env:DCP_PROFILE) {
            $arguments += "-Profile"
            $arguments += $env:DCP_PROFILE
            Write-LauncherMessage "Using profile: $($env:DCP_PROFILE)" -Type Info
        }
        
        if ($env:DCP_QUICK_MODE -eq 'true') {
            $arguments += '-QuickMode'
            Write-LauncherMessage "Quick Mode enabled" -Type Info
        }
        
        if ($env:DCP_NO_REBOOT -eq 'true') {
            $arguments += '-NoReboot'
            Write-LauncherMessage "Auto-reboot disabled" -Type Info
        }
        
        if ($WhatIfPreference) {
            $arguments += '-WhatIf'
            Write-LauncherMessage "WhatIf mode enabled - no changes will be made" -Type Warning
        }
        
        # Execute the script
        Write-LauncherMessage "Executing Deep Clean Pro..." -Type Info
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        
        if ($arguments.Count -gt 0) {
            & $tempFile @arguments
        } else {
            & $tempFile
        }
        
        Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-LauncherMessage "Deep Clean Pro execution completed" -Type Success
        
    } catch {
        Write-LauncherMessage "Execution failed: $_" -Type Error
        throw
    } finally {
        # Clean up temporary file
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Show-LauncherHeader {
    Write-Host @"

╔═══════════════════════════════════════════════════════════════╗
║           DEEP CLEAN PRO - GITHUB LAUNCHER v1.0               ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
}

function Show-ErrorHelp {
    Write-Host "`n💡 Troubleshooting Tips:" -ForegroundColor Yellow
    Write-Host "  1. Check your internet connection" -ForegroundColor Gray
    Write-Host "  2. Verify the repository URL is correct" -ForegroundColor Gray
    Write-Host "  3. Ensure GitHub is accessible from your network" -ForegroundColor Gray
    Write-Host "  4. Try downloading directly from: $($Script:Config.RepoUrl)" -ForegroundColor Gray
    Write-Host "  5. Check if your organization blocks GitHub access" -ForegroundColor Gray
}

# Main Execution
try {
    Clear-Host
    Show-LauncherHeader
    
    # Check prerequisites
    Write-LauncherMessage "Checking prerequisites..." -Type Info
    
    if (-not (Test-AdminPrivileges)) {
        Write-LauncherMessage "Administrator privileges required" -Type Warning
        Write-Host "`nPlease run this script as Administrator" -ForegroundColor Yellow
        Write-Host "Right-click the shortcut and select 'Run as administrator'" -ForegroundColor Gray
        
        Read-Host "`nPress Enter to exit"
        exit 1
    }
    
    Write-LauncherMessage "Administrator privileges confirmed" -Type Success
    
    # Check internet connection
    if (-not (Test-InternetConnection)) {
        throw "No internet connection detected. Please check your network connection."
    }
    
    Write-LauncherMessage "Internet connection verified" -Type Success
    
    # Download main script
    $scriptContent = Get-ScriptFromGitHub -Url $Script:Config.RepoUrl -Description "Deep Clean Pro main script"
    
    # Validate script content
    if ($scriptContent.Length -lt 1000) {
        throw "Downloaded script appears to be invalid (too small)"
    }
    
    if ($scriptContent -notmatch 'Deep Clean Pro') {
        throw "Downloaded content does not appear to be Deep Clean Pro"
    }
    
    # Execute the script
    Invoke-DeepCleanPro -ScriptContent $scriptContent
    
    # Pause if running interactively
    if (-not $env:DCP_NO_PAUSE) {
        Write-Host "`nPress Enter to exit..." -ForegroundColor Gray
        Read-Host
    }
    
    exit 0
    
} catch {
    Write-LauncherMessage "Critical error: $_" -Type Error
    Show-ErrorHelp
    
    # Pause on error
    Write-Host "`nPress Enter to exit..." -ForegroundColor Red
    Read-Host
    
    exit 1
}
