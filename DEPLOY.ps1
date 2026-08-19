<#
.SYNOPSIS
    Deep Clean Pro - Automated Deployment Script
.DESCRIPTION
    Deploys Deep Clean Pro to the system with proper validation, security checks,
    and optional features like scheduled tasks and desktop shortcuts.
.PARAMETER TargetPath
    Installation directory (default: C:\DeepCleanPro)
.PARAMETER CreateScheduledTask
    Create a weekly maintenance task
.PARAMETER CreateShortcuts
    Create desktop shortcuts
.PARAMETER NonInteractive
    Run without user prompts
.PARAMETER AutoDownloadMissing
    Automatically download missing files from repository
.EXAMPLE
    .\DEPLOY.ps1
    Interactive deployment with default settings
.EXAMPLE
    .\DEPLOY.ps1 -TargetPath "D:\Tools\DeepClean" -CreateScheduledTask -NonInteractive
    Non-interactive deployment with custom path and scheduled task
#>

[CmdletBinding()]
param(
    [string]$TargetPath = "C:\DeepCleanPro",
    [switch]$CreateScheduledTask,
    [switch]$CreateShortcuts = $true,
    [switch]$NonInteractive,
    [switch]$AutoDownloadMissing,
    [string]$RepositoryUrl = "https://github.com/iSystemDevelopment/deep-clean-pro"
)

#Requires -RunAsAdministrator
#Requires -Version 5.1

# Deployment configuration
$RequiredFiles = @(
    'DeepCleanPro.ps1',
    'Fix-WindowsPolicies.ps1',
    'OneDriveNuke.ps1',
    'Scripts\CreateDesktopShortcuts.ps1',
    'Scripts\VALIDATE.ps1',
    'Gist-Setup\gist-launcher.ps1',
    'README.md',
    'LICENSE',
    'SECURITY.md'
)

$DirectoryStructure = @(
    'Scripts',
    'Backups',
    'Logs',
    'Config',
    'Resources',
    'Extensions'
)

function Write-DeployLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug')]
        [string]$Type = 'Info'
    )
    
    $symbols = @{
        'Info'    = 'ℹ️'
        'Success' = '✅'
        'Warning' = '⚠️'
        'Error'   = '❌'
        'Debug'   = '🔍'
    }
    
    $colors = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Debug'   = 'Gray'
    }
    
    Write-Host "$($symbols[$Type]) $Message" -ForegroundColor $colors[$Type]
    
    # Log to file
    $logFile = "$env:TEMP\DeepCleanDeploy_$(Get-Date -Format 'yyyyMMdd').log"
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Add-Content -Path $logFile -Value "[$timestamp] [$Type] $Message" -ErrorAction SilentlyContinue
}

function Test-Prerequisites {
    Write-DeployLog "Checking prerequisites..." -Type Info
    
    $prereqs = @()
    
    # Admin privileges
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    $prereqs += [PSCustomObject]@{
        Check = "Administrator Privileges"
        Status = $isAdmin
        Required = $true
    }
    
    # PowerShell version
    $psVersion = $PSVersionTable.PSVersion
    $psValid = $psVersion.Major -ge 5 -and $psVersion.Minor -ge 1
    $prereqs += [PSCustomObject]@{
        Check = "PowerShell 5.1+"
        Status = $psValid
        Required = $true
    }
    
    # .NET Framework
    $dotNet = Get-ItemProperty "HKLM:SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release -ErrorAction SilentlyContinue
    $dotNetValid = $dotNet.Release -ge 461808  # .NET 4.7.2
    $prereqs += [PSCustomObject]@{
        Check = ".NET Framework 4.7.2+"
        Status = $dotNetValid
        Required = $false
    }
    
    # Git (optional)
    $gitInstalled = Get-Command git -ErrorAction SilentlyContinue
    $prereqs += [PSCustomObject]@{
        Check = "Git (optional)"
        Status = [bool]$gitInstalled
        Required = $false
    }
    
    # Display results
    foreach ($prereq in $prereqs) {
        $symbol = if ($prereq.Status) { "[OK]" } else { "[X]" }
        $color = if ($prereq.Status) { "Green" } elseif ($prereq.Required) { "Red" } else { "Yellow" }
        Write-Host "  $symbol $($prereq.Check)" -ForegroundColor $color
    }
    
    # Check for failures in required prerequisites
    $failedRequired = $prereqs | Where-Object { $_.Required -and -not $_.Status }
    if ($failedRequired) {
        throw "Required prerequisites not met. Please install missing components."
    }
    
    return $prereqs
}

function Test-FileIntegrity {
    param(
        [string]$FilePath,
        [string]$ExpectedHash
    )
    
    if (Test-Path $FilePath) {
        $actualHash = (Get-FileHash -Path $FilePath -Algorithm SHA256).Hash
        return $actualHash -eq $ExpectedHash
    }
    return $false
}

function Copy-DeploymentFiles {
    param(
        [string]$SourcePath,
        [string]$TargetPath
    )
    
    Write-DeployLog "Deploying files to $TargetPath..." -Type Info
    
    # Create directory structure
    foreach ($dir in $DirectoryStructure) {
        $dirPath = Join-Path $TargetPath $dir
        if (-not (Test-Path $dirPath)) {
            New-Item -Path $dirPath -ItemType Directory -Force | Out-Null
            Write-DeployLog "Created: $dir" -Type Debug
        }
    }
    
    # Copy files
    $copiedCount = 0
    $failedFiles = @()
    
    foreach ($file in $RequiredFiles) {
        $source = Join-Path $SourcePath $file
        $destination = Join-Path $TargetPath $file
        $destDir = Split-Path $destination -Parent
        
        if (-not (Test-Path $destDir)) {
            New-Item -Path $destDir -ItemType Directory -Force | Out-Null
        }
        
        if (Test-Path $source) {
            try {
                Copy-Item -Path $source -Destination $destination -Force -ErrorAction Stop
                $copiedCount++
                Write-DeployLog "Deployed: $file" -Type Debug
            } catch {
                $failedFiles += $file
                Write-DeployLog "Failed to copy: $file - $_" -Type Warning
            }
        } elseif ($AutoDownloadMissing) {
            # Try to download from repository
            Write-DeployLog "Downloading missing file: $file" -Type Warning
            $downloadUrl = "$RepositoryUrl/raw/main/$file"
            try {
                Invoke-WebRequest -Uri $downloadUrl -OutFile $destination -UseBasicParsing -ErrorAction Stop
                $copiedCount++
                Write-DeployLog "Downloaded: $file" -Type Success
            } catch {
                $failedFiles += $file
                Write-DeployLog "Could not download: $file" -Type Error
            }
        } else {
            $failedFiles += $file
            Write-DeployLog "Missing: $file" -Type Warning
        }
    }
    
    Write-DeployLog "Deployed $copiedCount files successfully" -Type Success
    
    if ($failedFiles.Count -gt 0) {
        Write-DeployLog "Failed to deploy $($failedFiles.Count) files" -Type Warning
        if (-not $NonInteractive) {
            $response = Read-Host "Continue with partial deployment? (Y/N)"
            if ($response -ne 'Y') {
                throw "Deployment cancelled due to missing files"
            }
        }
    }
    
    return $copiedCount
}

function Set-SecurityPermissions {
    param(
        [string]$Path
    )
    
    Write-DeployLog "Setting security permissions..." -Type Info
    
    try {
        # Get current ACL
        $acl = Get-Acl -Path $Path
        
        # Remove inheritance while preserving existing permissions
        $acl.SetAccessRuleProtection($true, $true)
        
        # Grant full control to Administrators
        $adminRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "BUILTIN\Administrators",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($adminRule)
        
        # Grant read & execute to Users
        $userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "BUILTIN\Users",
            "ReadAndExecute",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($userRule)
        
        # Apply ACL
        Set-Acl -Path $Path -AclObject $acl -ErrorAction Stop
        
        Write-DeployLog "Security permissions configured" -Type Success
        return $true
    } catch {
        Write-DeployLog "Failed to set permissions: $_" -Type Warning
        return $false
    }
}

function Create-ScheduledTask {
    param(
        [string]$ScriptPath
    )
    
    Write-DeployLog "Creating scheduled task..." -Type Info
    
    $taskName = "DeepCleanPro-Weekly"
    
    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        if (-not $NonInteractive) {
            $response = Read-Host "Scheduled task already exists. Replace? (Y/N)"
            if ($response -ne 'Y') {
                Write-DeployLog "Skipped scheduled task creation" -Type Warning
                return $false
            }
        }
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }
    
    try {
        # Create action
        $action = New-ScheduledTaskAction -Execute "powershell.exe" `
            -Argument "-NoProfile -ExecutionPolicy RemoteSigned -WindowStyle Hidden -File `"$ScriptPath`" -QuickMode -NoReboot"
        
        # Create trigger (Weekly on Sunday at 2 AM)
        $trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 1 -DaysOfWeek Sunday -At "2:00AM"
        
        # Create settings
        $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries `
            -StartWhenAvailable -RunOnlyIfNetworkAvailable -MultipleInstances IgnoreNew
        
        # Create principal (run as SYSTEM)
        $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
        
        # Register task
        $task = Register-ScheduledTask -TaskName $taskName `
            -Action $action `
            -Trigger $trigger `
            -Settings $settings `
            -Principal $principal `
            -Description "Weekly system optimization with Deep Clean Pro" `
            -ErrorAction Stop
        
        Write-DeployLog "Scheduled task created: $taskName" -Type Success
        return $true
    } catch {
        Write-DeployLog "Failed to create scheduled task: $_" -Type Error
        return $false
    }
}

function Create-DesktopShortcuts {
    param(
        [string]$TargetPath
    )
    
    Write-DeployLog "Creating desktop shortcuts..." -Type Info
    
    $shortcutScript = Join-Path $TargetPath "Scripts\CreateDesktopShortcuts.ps1"
    
    if (Test-Path $shortcutScript) {
        try {
            & $shortcutScript -TargetPath $TargetPath -Silent
            Write-DeployLog "Desktop shortcuts created" -Type Success
            return $true
        } catch {
            Write-DeployLog "Failed to create shortcuts: $_" -Type Warning
            return $false
        }
    } else {
        Write-DeployLog "Shortcut creation script not found" -Type Warning
        return $false
    }
}

function Test-Deployment {
    param(
        [string]$Path
    )
    
    Write-DeployLog "Validating deployment..." -Type Info
    
    $validationScript = Join-Path $Path "Scripts\VALIDATE.ps1"
    
    if (Test-Path $validationScript) {
        try {
            $result = & $validationScript -Silent -ReturnResults
            
            if ($result.AllPassed) {
                Write-DeployLog "All validation checks passed" -Type Success
                return $true
            } else {
                Write-DeployLog "Some validation checks failed" -Type Warning
                $result.FailedTests | ForEach-Object {
                    Write-DeployLog "  - $_" -Type Warning
                }
                return $false
            }
        } catch {
            Write-DeployLog "Validation script error: $_" -Type Error
            return $false
        }
    } else {
        # Basic validation if script not available
        $mainScript = Join-Path $Path "DeepCleanPro.ps1"
        if (Test-Path $mainScript) {
            Write-DeployLog "Main script found - basic validation passed" -Type Success
            return $true
        } else {
            Write-DeployLog "Main script not found - validation failed" -Type Error
            return $false
        }
    }
}

# Main Deployment Process
try {
    Clear-Host
    Write-Host @"
╔═══════════════════════════════════════════════════════════════╗
║          DEEP CLEAN PRO - DEPLOYMENT WIZARD v2.0             ║
╚═══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan
    
    # Step 1: Prerequisites
    Write-Host "`n[Step 1/6] Checking Prerequisites" -ForegroundColor Yellow
    $prereqs = Test-Prerequisites
    
    # Step 2: Confirm settings
    if (-not $NonInteractive) {
        Write-Host "`n[Step 2/6] Deployment Settings" -ForegroundColor Yellow
        Write-Host "  Target Path: $TargetPath" -ForegroundColor Gray
        Write-Host "  Create Scheduled Task: $CreateScheduledTask" -ForegroundColor Gray
        Write-Host "  Create Desktop Shortcuts: $CreateShortcuts" -ForegroundColor Gray
        Write-Host ""
        $confirm = Read-Host "Continue with these settings? (Y/N)"
        if ($confirm -ne 'Y') {
            Write-DeployLog "Deployment cancelled by user" -Type Warning
            exit 0
        }
    } else {
        Write-Host "`n[Step 2/6] Non-Interactive Mode" -ForegroundColor Yellow
        Write-DeployLog "Running in non-interactive mode" -Type Info
    }
    
    # Step 3: Create target directory
    Write-Host "`n[Step 3/6] Preparing Target Directory" -ForegroundColor Yellow
    if (-not (Test-Path $TargetPath)) {
        New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
        Write-DeployLog "Created target directory: $TargetPath" -Type Success
    } else {
        Write-DeployLog "Target directory exists: $TargetPath" -Type Info
    }
    
    # Step 4: Deploy files
    Write-Host "`n[Step 4/6] Deploying Files" -ForegroundColor Yellow
    $deployedFiles = Copy-DeploymentFiles -SourcePath $PSScriptRoot -TargetPath $TargetPath
    
    # Set permissions
    Set-SecurityPermissions -Path $TargetPath
    
    # Step 5: Optional features
    Write-Host "`n[Step 5/6] Configuring Optional Features" -ForegroundColor Yellow
    
    if ($CreateScheduledTask) {
        $mainScript = Join-Path $TargetPath "DeepCleanPro.ps1"
        Create-ScheduledTask -ScriptPath $mainScript
    }
    
    if ($CreateShortcuts) {
        Create-DesktopShortcuts -TargetPath $TargetPath
    }
    
    # Step 6: Validation
    Write-Host "`n[Step 6/6] Validating Deployment" -ForegroundColor Yellow
    $validationPassed = Test-Deployment -Path $TargetPath
    
    # Final summary
    Write-Host "`n" -NoNewline
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    DEPLOYMENT COMPLETE                        " -ForegroundColor Green
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    Write-Host "`n📁 Installed to: $TargetPath" -ForegroundColor White
    Write-Host "📊 Files deployed: $deployedFiles" -ForegroundColor White
    
    if ($CreateScheduledTask) {
        Write-Host "⏰ Scheduled task: Created" -ForegroundColor White
    }
    
    if ($CreateShortcuts) {
        Write-Host "🔗 Desktop shortcuts: Created" -ForegroundColor White
    }
    
    Write-Host "`n🚀 Next Steps:" -ForegroundColor Yellow
    Write-Host "  1. Run validation: $TargetPath\Scripts\VALIDATE.ps1" -ForegroundColor Gray
    Write-Host "  2. Test with: $TargetPath\DeepCleanPro.ps1 -WhatIf" -ForegroundColor Gray
    Write-Host "  3. First run: $TargetPath\DeepCleanPro.ps1 -QuickMode" -ForegroundColor Gray
    
    if (-not $validationPassed) {
        Write-Host "`n⚠️  Warning: Some validation checks failed. Please review." -ForegroundColor Yellow
    }
    
    Write-Host "`n🎉 Deployment successful!" -ForegroundColor Green
    
    if (-not $NonInteractive) {
        Write-Host "`nPress any key to exit..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
} catch {
    Write-DeployLog "CRITICAL ERROR: $_" -Type Error
    Write-DeployLog "Stack trace: $($_.ScriptStackTrace)" -Type Debug
    
    if (-not $NonInteractive) {
        Write-Host "`nPress any key to exit..." -ForegroundColor Red
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
    exit 1
}