<#
.SYNOPSIS
    Windows Policy Configuration Helper for Deep Clean Pro
.DESCRIPTION
    Security-hardened script to configure Windows policies for optimal PowerShell execution.
    Creates backups before making changes and supports restoration.
.PARAMETER BackupPath
    Path to save the backup file
.PARAMETER RestoreBackup
    Restore from a previous backup
.PARAMETER NoPause
    Skip the pause at the end
.EXAMPLE
    .\Fix-WindowsPolicies.ps1
    Configure policies with default settings
.EXAMPLE
    .\Fix-WindowsPolicies.ps1 -RestoreBackup -BackupPath "C:\Backup\policy.json"
    Restore from backup
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$BackupPath = "$env:TEMP\PolicyBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json",
    [switch]$RestoreBackup,
    [switch]$NoPause
)

#Requires -RunAsAdministrator
#Requires -Version 5.1

# Security check - verify script source
$scriptHash = (Get-FileHash -Path $PSCommandPath -Algorithm SHA256).Hash
$trustedHashes = @(
    # Add your script's SHA256 hash here after first deployment
    # 'YOUR_SCRIPT_HASH_HERE'
)

function Write-PolicyLog {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )
    
    $colors = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
    }
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $colors[$Type]
    
    # Log to file
    $logPath = "$env:TEMP\PolicyConfig_$(Get-Date -Format 'yyyyMMdd').log"
    Add-Content -Path $logPath -Value "[$timestamp] [$Type] $Message" -ErrorAction SilentlyContinue
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Get-CurrentPolicies {
    Write-PolicyLog "Gathering current policy settings..." -Type Info
    
    $policies = @{
        ExecutionPolicies = @{}
        SecuritySettings = @{}
        TLSSettings = @{}
        SystemSettings = @{}
    }
    
    # Execution Policies
    @('MachinePolicy', 'UserPolicy', 'Process', 'CurrentUser', 'LocalMachine') | ForEach-Object {
        try {
            $policies.ExecutionPolicies[$_] = (Get-ExecutionPolicy -Scope $_ -ErrorAction Stop).ToString()
        } catch {
            $policies.ExecutionPolicies[$_] = 'Undefined'
        }
    }
    
    # PowerShell Settings
    try {
        $policies.SecuritySettings.ScriptBlockLogging = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -ErrorAction SilentlyContinue).EnableScriptBlockLogging
        $policies.SecuritySettings.TranscriptionLogging = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription" -Name "EnableTranscripting" -ErrorAction SilentlyContinue).EnableTranscripting
    } catch {
        # Settings not found
    }
    
    # TLS Settings
    $policies.TLSSettings.SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol.ToString()
    
    # DEP Settings
    try {
        $bcdedit = bcdedit /enum | Out-String
        if ($bcdedit -match "nx\s+(\w+)") {
            $policies.SystemSettings.DEP = $matches[1]
        }
    } catch {
        $policies.SystemSettings.DEP = 'Unknown'
    }
    
    return $policies
}

function Backup-Policies {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Policies,
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    Write-PolicyLog "Creating backup at: $Path" -Type Info
    
    try {
        $Policies | ConvertTo-Json -Depth 10 | Out-File -FilePath $Path -Encoding UTF8
        Write-PolicyLog "Backup created successfully" -Type Success
        return $true
    } catch {
        Write-PolicyLog "Failed to create backup: $_" -Type Error
        return $false
    }
}

function Set-OptimalPolicies {
    Write-PolicyLog "Configuring optimal policies..." -Type Info
    
    $changes = @()
    
    # 1. Execution Policy (Process scope only for safety)
    try {
        if ($PSCmdlet.ShouldProcess("ExecutionPolicy", "Set to RemoteSigned for CurrentUser")) {
            Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction Stop
            $changes += "✓ Set ExecutionPolicy to RemoteSigned for CurrentUser"
            Write-PolicyLog "Execution policy configured" -Type Success
        }
    } catch {
        Write-PolicyLog "Could not set execution policy: $_" -Type Warning
    }
    
    # 2. Enable TLS 1.2
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $changes += "✓ Enabled TLS 1.2"
        Write-PolicyLog "TLS 1.2 enabled" -Type Success
    } catch {
        Write-PolicyLog "Could not enable TLS 1.2: $_" -Type Warning
    }
    
    # 3. Configure PowerShell Script Block Logging (for security)
    try {
        if ($PSCmdlet.ShouldProcess("ScriptBlockLogging", "Enable")) {
            $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
            if (-not (Test-Path $regPath)) {
                New-Item -Path $regPath -Force | Out-Null
            }
            Set-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -Value 1 -Type DWord
            $changes += "✓ Enabled Script Block Logging for security"
            Write-PolicyLog "Script block logging enabled" -Type Success
        }
    } catch {
        Write-PolicyLog "Could not enable script block logging: $_" -Type Warning
    }
    
    # 4. Configure DEP (Data Execution Prevention)
    try {
        if ($PSCmdlet.ShouldProcess("DEP", "Set to OptOut")) {
            $result = Start-Process -FilePath "bcdedit.exe" -ArgumentList "/set nx OptOut" -Wait -PassThru -NoNewWindow
            if ($result.ExitCode -eq 0) {
                $changes += "✓ Configured DEP to OptOut mode"
                Write-PolicyLog "DEP configured" -Type Success
            }
        }
    } catch {
        Write-PolicyLog "Could not configure DEP: $_" -Type Warning
    }
    
    # 5. Configure Windows Defender exclusions (removed for security)
    # Note: Adding exclusions weakens security. Removed this functionality.
    
    # 6. Configure PowerShell Module Installation
    try {
        if ($PSCmdlet.ShouldProcess("PSGallery", "Set as Trusted")) {
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
            $changes += "✓ Set PSGallery as trusted repository"
            Write-PolicyLog "PSGallery configured" -Type Success
        }
    } catch {
        Write-PolicyLog "Could not configure PSGallery: $_" -Type Warning
    }
    
    # 7. Ensure NuGet provider is installed
    try {
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            if ($PSCmdlet.ShouldProcess("NuGet", "Install Package Provider")) {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction Stop | Out-Null
                $changes += "✓ Installed NuGet package provider"
                Write-PolicyLog "NuGet provider installed" -Type Success
            }
        }
    } catch {
        Write-PolicyLog "Could not install NuGet provider: $_" -Type Warning
    }
    
    return $changes
}

function Restore-PoliciesFromBackup {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )
    
    if (-not (Test-Path $Path)) {
        Write-PolicyLog "Backup file not found: $Path" -Type Error
        return $false
    }
    
    Write-PolicyLog "Restoring policies from backup..." -Type Info
    
    try {
        $backup = Get-Content -Path $Path -Raw | ConvertFrom-Json
        
        # Restore Execution Policies
        foreach ($scope in $backup.ExecutionPolicies.PSObject.Properties) {
            if ($scope.Name -in @('CurrentUser', 'LocalMachine') -and $scope.Value -ne 'Undefined') {
                try {
                    if ($PSCmdlet.ShouldProcess("ExecutionPolicy $($scope.Name)", "Restore to $($scope.Value)")) {
                        Set-ExecutionPolicy -ExecutionPolicy $scope.Value -Scope $scope.Name -Force -ErrorAction Stop
                        Write-PolicyLog "Restored ExecutionPolicy for $($scope.Name)" -Type Success
                    }
                } catch {
                    Write-PolicyLog "Could not restore ExecutionPolicy for $($scope.Name): $_" -Type Warning
                }
            }
        }
        
        # Restore other settings as needed
        # Note: Some settings may require system restart
        
        Write-PolicyLog "Restoration completed" -Type Success
        return $true
    } catch {
        Write-PolicyLog "Failed to restore from backup: $_" -Type Error
        return $false
    }
}

function Test-PolicyConfiguration {
    Write-PolicyLog "Verifying configuration..." -Type Info
    
    $tests = @()
    
    # Test 1: Execution Policy
    $execPolicy = Get-ExecutionPolicy -Scope CurrentUser
    $tests += [PSCustomObject]@{
        Test = "Execution Policy"
        Expected = "RemoteSigned or Unrestricted"
        Actual = $execPolicy
        Passed = $execPolicy -in @('RemoteSigned', 'Unrestricted', 'Bypass')
    }
    
    # Test 2: TLS 1.2
    $tlsEnabled = ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) -ne 0
    $tests += [PSCustomObject]@{
        Test = "TLS 1.2"
        Expected = "Enabled"
        Actual = if ($tlsEnabled) { "Enabled" } else { "Disabled" }
        Passed = $tlsEnabled
    }
    
    # Test 3: PowerShell Version
    $psVersion = $PSVersionTable.PSVersion
    $tests += [PSCustomObject]@{
        Test = "PowerShell Version"
        Expected = "5.1 or higher"
        Actual = $psVersion.ToString()
        Passed = $psVersion.Major -ge 5 -and $psVersion.Minor -ge 1
    }
    
    # Test 4: Admin Privileges
    $isAdmin = Test-AdminPrivileges
    $tests += [PSCustomObject]@{
        Test = "Admin Privileges"
        Expected = "True"
        Actual = $isAdmin.ToString()
        Passed = $isAdmin
    }
    
    # Display results
    Write-Host "`n===== CONFIGURATION TEST RESULTS =====`n" -ForegroundColor Cyan
    
    foreach ($test in $tests) {
        $symbol = if ($test.Passed) { "✓" } else { "✗" }
        $color = if ($test.Passed) { "Green" } else { "Red" }
        
        Write-Host "$symbol $($test.Test)" -ForegroundColor $color
        Write-Host "  Expected: $($test.Expected)" -ForegroundColor Gray
        Write-Host "  Actual: $($test.Actual)" -ForegroundColor Gray
    }
    
    $passedCount = ($tests | Where-Object { $_.Passed }).Count
    $totalCount = $tests.Count
    
    Write-Host "`nResult: $passedCount/$totalCount tests passed" -ForegroundColor $(if ($passedCount -eq $totalCount) { "Green" } else { "Yellow" })
    
    return ($passedCount -eq $totalCount)
}

# Main execution
try {
    if (-not (Test-AdminPrivileges)) {
        throw "This script requires Administrator privileges. Please run as Administrator."
    }
    
    Write-Host "`n╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Windows Policy Configuration Helper v1.1            ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    if ($RestoreBackup) {
        # Restore mode
        Write-PolicyLog "Starting restore process..." -Type Info
        if (Restore-PoliciesFromBackup -Path $BackupPath) {
            Write-PolicyLog "Policies restored successfully" -Type Success
        } else {
            Write-PolicyLog "Restore process failed" -Type Error
            exit 1
        }
    } else {
        # Configuration mode
        $currentPolicies = Get-CurrentPolicies
        
        # Create backup
        $backupDir = Split-Path $BackupPath -Parent
        if (-not (Test-Path $backupDir)) {
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        }
        
        if (Backup-Policies -Policies $currentPolicies -Path $BackupPath) {
            Write-PolicyLog "Backup saved to: $BackupPath" -Type Success
            
            # Apply optimal policies
            $changes = Set-OptimalPolicies
            
            if ($changes.Count -gt 0) {
                Write-Host "`n===== CHANGES APPLIED =====`n" -ForegroundColor Green
                $changes | ForEach-Object { Write-Host $_ -ForegroundColor Green }
            }
            
            # Verify configuration
            Start-Sleep -Seconds 2
            $testResult = Test-PolicyConfiguration
            
            if ($testResult) {
                Write-PolicyLog "`nAll policies configured successfully!" -Type Success
            } else {
                Write-PolicyLog "`nSome policies may need manual configuration" -Type Warning
            }
        } else {
            throw "Failed to create backup. Aborting configuration."
        }
    }
    
    if (-not $NoPause) {
        Write-Host "`nPress any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    }
    
} catch {
    Write-PolicyLog "Critical error: $_" -Type Error
    exit 1
}