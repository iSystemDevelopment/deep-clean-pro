<#
.SYNOPSIS
    Deep Clean Pro - Enterprise-grade Windows optimization and maintenance tool
.DESCRIPTION
    Comprehensive Windows optimization tool with security-hardened operations, backup capabilities,
    and extensive system cleanup features. Supports both interactive and automated modes.
.PARAMETER QuickMode
    Runs essential optimizations only (5-10 minutes)
.PARAMETER WhatIf
    Shows what would be done without making changes
.PARAMETER NoReboot
    Prevents automatic reboot after completion
.PARAMETER AutoReboot
    Automatically reboots without prompting
.PARAMETER FixPolicies
    Runs Windows policy configuration helper
.EXAMPLE
    .\DeepCleanPro.ps1 -QuickMode
    Runs quick optimization mode
.EXAMPLE
    .\DeepCleanPro.ps1 -WhatIf
    Shows what would be done without making changes
.NOTES
    Version: 2.2.0
    Author: iSystem Development
    Repository: https://github.com/iSystemDevelopment/deep-clean-pro
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$QuickMode,
    [switch]$NoReboot,
    [switch]$AutoReboot,
    [switch]$FixPolicies,
    [switch]$SkipHealth,
    [switch]$SkipDefrag,
    
    # PC Profile Optimizations
    [ValidateSet('Balanced', 'Gaming', 'Development', 'Music', 'Video', 'Office')]
    [string]$Profile = 'Balanced'
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# Script Configuration
$Script:Version = "2.2.0"
$Script:StartTime = Get-Date
$Script:BasePath = if ($env:DEEPCLEANPRO_BASE_PATH) { $env:DEEPCLEANPRO_BASE_PATH } else { "C:\DeepCleanPro" }
$Script:BackupPath = if ($env:DEEPCLEANPRO_BACKUP_PATH) { $env:DEEPCLEANPRO_BACKUP_PATH } else { "$Script:BasePath\Backups" }
$Script:LogPath = "$Script:BasePath\Logs"
$Script:TempPath = "$env:TEMP\DeepCleanPro"

# Security Configuration
$Script:AllowedHosts = @(
    'github.com',
    'raw.githubusercontent.com',
    'gist.githubusercontent.com',
    'microsoft.com',
    'windows.com'
)

# Initialize environment from shortcut if set
if ($env:DCP_QUICK_MODE -eq 'true' -and -not $PSBoundParameters.ContainsKey('QuickMode')) {
    $QuickMode = $true
}
if ($env:DCP_NO_REBOOT -eq 'true' -and -not $PSBoundParameters.ContainsKey('NoReboot')) {
    $NoReboot = $true
}

#region Helper Functions

function Write-ColorOutput {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error', 'Debug')]
        [string]$Type = 'Info'
    )
    
    $colors = @{
        'Info'    = 'Cyan'
        'Success' = 'Green'
        'Warning' = 'Yellow'
        'Error'   = 'Red'
        'Debug'   = 'Gray'
    }
    
    $prefix = @{
        'Info'    = '[INFO]'
        'Success' = '[SUCCESS]'
        'Warning' = '[WARNING]'
        'Error'   = '[ERROR]'
        'Debug'   = '[DEBUG]'
    }
    
    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
    
    # Also log to file
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $($prefix[$Type]) $Message"
    Add-Content -Path "$Script:LogPath\DeepClean_$(Get-Date -Format 'yyyyMMdd').log" -Value $logMessage -ErrorAction SilentlyContinue
}

function Test-AdminPrivileges {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Initialize-Environment {
    Write-ColorOutput "Initializing Deep Clean Pro v$Script:Version" -Type Info
    
    # Verify admin privileges
    if (-not (Test-AdminPrivileges)) {
        throw "This script requires Administrator privileges. Please run as Administrator."
    }
    
    # Create necessary directories
    @($Script:BasePath, $Script:BackupPath, $Script:LogPath, $Script:TempPath) | ForEach-Object {
        if (-not (Test-Path $_)) {
            New-Item -Path $_ -ItemType Directory -Force | Out-Null
            Write-ColorOutput "Created directory: $_" -Type Debug
        }
    }
    
    # Set execution policy for session
    $Script:OriginalExecutionPolicy = Get-ExecutionPolicy -Scope Process
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force -ErrorAction SilentlyContinue
    
    # Enable TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
}

function Get-SystemInfo {
    Write-ColorOutput "Gathering system information..." -Type Info
    
    $info = @{
        'ComputerName' = $env:COMPUTERNAME
        'Username' = $env:USERNAME
        'OS' = (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
        'Build' = (Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion").CurrentBuild
        'Architecture' = $env:PROCESSOR_ARCHITECTURE
        'RAM' = "{0:N2} GB" -f ((Get-CimInstance -ClassName Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
        'FreeSpace' = "{0:N2} GB" -f ((Get-PSDrive -Name C).Free / 1GB)
        'LastBoot' = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    }
    
    return $info
}

function Backup-RegistryKey {
    param(
        [Parameter(Mandatory)]
        [string]$Path,
        [string]$BackupName = "Registry"
    )
    
    if ($PSCmdlet.ShouldProcess("Registry key: $Path", "Backup")) {
        $backupFile = "$Script:BackupPath\Registry\$BackupName`_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        $backupDir = Split-Path $backupFile -Parent
        
        if (-not (Test-Path $backupDir)) {
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        }
        
        try {
            $regPath = $Path -replace '^HKLM:', 'HKEY_LOCAL_MACHINE' -replace '^HKCU:', 'HKEY_CURRENT_USER'
            $process = Start-Process -FilePath "reg.exe" -ArgumentList "export", "`"$regPath`"", "`"$backupFile`"", "/y" -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                Write-ColorOutput "Backed up registry key to: $backupFile" -Type Success
                return $backupFile
            } else {
                Write-ColorOutput "Failed to backup registry key: $Path" -Type Warning
                return $null
            }
        } catch {
            Write-ColorOutput "Error backing up registry: $_" -Type Error
            return $null
        }
    }
}

function Optimize-Services {
    Write-ColorOutput "Optimizing Windows services..." -Type Info
    
    $services = @(
        @{Name = 'DiagTrack'; StartupType = 'Disabled'; Description = 'Connected User Experiences and Telemetry'},
        @{Name = 'dmwappushservice'; StartupType = 'Disabled'; Description = 'Device Management WAP Push'},
        @{Name = 'WSearch'; StartupType = 'Manual'; Description = 'Windows Search'},
        @{Name = 'SysMain'; StartupType = 'Manual'; Description = 'SysMain (Superfetch)'},
        @{Name = 'Print Spooler'; StartupType = 'Manual'; Description = 'Print Spooler'}
    )
    
    # Backup current service configurations
    $serviceBackup = @()
    foreach ($svc in $services) {
        $currentService = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($currentService) {
            $serviceBackup += [PSCustomObject]@{
                Name = $svc.Name
                StartupType = (Get-WmiObject -Class Win32_Service -Filter "Name='$($svc.Name)'").StartMode
                Status = $currentService.Status
            }
        }
    }
    
    # Save backup
    $backupFile = "$Script:BackupPath\Services\ServiceConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
    $backupDir = Split-Path $backupFile -Parent
    if (-not (Test-Path $backupDir)) {
        New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
    }
    $serviceBackup | Export-Csv -Path $backupFile -NoTypeInformation
    
    # Optimize services
    foreach ($service in $services) {
        try {
            if ($PSCmdlet.ShouldProcess("Service: $($service.Name)", "Set startup type to $($service.StartupType)")) {
                $svc = Get-Service -Name $service.Name -ErrorAction SilentlyContinue
                if ($svc) {
                    Set-Service -Name $service.Name -StartupType $service.StartupType -ErrorAction Stop
                    Write-ColorOutput "Set $($service.Description) to $($service.StartupType)" -Type Success
                }
            }
        } catch {
            Write-ColorOutput "Failed to configure $($service.Name): $_" -Type Warning
        }
    }
}

function Clear-TempFiles {
    Write-ColorOutput "Cleaning temporary files..." -Type Info
    
    $tempPaths = @(
        "$env:TEMP",
        "$env:LOCALAPPDATA\Temp",
        "$env:WINDIR\Temp",
        "$env:WINDIR\Prefetch",
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\*.db"
    )
    
    $totalSize = 0
    $deletedFiles = 0
    
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                if ($PSCmdlet.ShouldProcess("Path: $path", "Clean temporary files")) {
                    $items = Get-ChildItem -Path $path -Recurse -Force -ErrorAction SilentlyContinue
                    foreach ($item in $items) {
                        try {
                            $totalSize += $item.Length
                            Remove-Item -Path $item.FullName -Force -Recurse -ErrorAction Stop
                            $deletedFiles++
                        } catch {
                            # File in use, skip
                        }
                    }
                }
            } catch {
                Write-ColorOutput "Could not access: $path" -Type Debug
            }
        }
    }
    
    $freedSpace = [math]::Round($totalSize / 1MB, 2)
    Write-ColorOutput "Deleted $deletedFiles files, freed $freedSpace MB" -Type Success
}

function Optimize-SystemPerformance {
    Write-ColorOutput "Optimizing system performance settings..." -Type Info
    
    # Backup current settings
    Backup-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -BackupName "MemoryManagement"
    Backup-RegistryKey -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" -BackupName "Explorer"
    
    $optimizations = @(
        # Memory Management
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
            Name = "ClearPageFileAtShutdown"
            Value = 0
            Type = "DWord"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters"
            Name = "EnablePrefetcher"
            Value = 3
            Type = "DWord"
        },
        # Visual Effects
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
            Name = "VisualFXSetting"
            Value = 2
            Type = "DWord"
        }
    )
    
    foreach ($setting in $optimizations) {
        if ($PSCmdlet.ShouldProcess("$($setting.Path)\$($setting.Name)", "Set value to $($setting.Value)")) {
            try {
                if (-not (Test-Path $setting.Path)) {
                    New-Item -Path $setting.Path -Force | Out-Null
                }
                Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type $setting.Type -ErrorAction Stop
                Write-ColorOutput "Applied: $($setting.Name)" -Type Success
            } catch {
                Write-ColorOutput "Failed to apply $($setting.Name): $_" -Type Warning
            }
        }
    }
}

function Remove-BloatwareApps {
    Write-ColorOutput "Removing bloatware applications..." -Type Info
    
    $bloatwareApps = @(
        'Microsoft.BingNews',
        'Microsoft.BingWeather',
        'Microsoft.GamingApp',
        'Microsoft.GetHelp',
        'Microsoft.Getstarted',
        'Microsoft.Messaging',
        'Microsoft.Microsoft3DViewer',
        'Microsoft.MicrosoftOfficeHub',
        'Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.MixedReality.Portal',
        'Microsoft.OneConnect',
        'Microsoft.People',
        'Microsoft.Print3D',
        'Microsoft.SkypeApp',
        'Microsoft.Wallet',
        'Microsoft.WindowsMaps',
        'Microsoft.WindowsFeedbackHub',
        'Microsoft.Xbox.TCUI',
        'Microsoft.XboxApp',
        'Microsoft.XboxGameOverlay',
        'Microsoft.XboxGamingOverlay',
        'Microsoft.YourPhone',
        'Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo'
    )
    
    foreach ($app in $bloatwareApps) {
        if ($PSCmdlet.ShouldProcess("App: $app", "Remove")) {
            try {
                Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction Stop
                Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -ErrorAction Stop | Out-Null
                Write-ColorOutput "Removed: $app" -Type Success
            } catch {
                Write-ColorOutput "Could not remove $app (may not be installed)" -Type Debug
            }
        }
    }
}

function Optimize-NetworkSettings {
    Write-ColorOutput "Optimizing network settings..." -Type Info
    
    # Backup network settings
    Backup-RegistryKey -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -BackupName "NetworkTcpip"
    
    $networkSettings = @(
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Name = "TcpAckFrequency"
            Value = 1
            Type = "DWord"
            Description = "TCP Acknowledgment Frequency"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Name = "TCPNoDelay"
            Value = 1
            Type = "DWord"
            Description = "Disable Nagle Algorithm"
        },
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Name = "DefaultTTL"
            Value = 64
            Type = "DWord"
            Description = "Default Time To Live"
        }
    )
    
    foreach ($setting in $networkSettings) {
        if ($PSCmdlet.ShouldProcess("$($setting.Description)", "Optimize")) {
            try {
                Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type $setting.Type -ErrorAction Stop
                Write-ColorOutput "Optimized: $($setting.Description)" -Type Success
            } catch {
                Write-ColorOutput "Failed to optimize $($setting.Description): $_" -Type Warning
            }
        }
    }
}

function Update-SystemDrivers {
    Write-ColorOutput "Checking for driver updates..." -Type Info
    
    try {
        # Use pnputil to scan for driver updates
        $driverUpdate = pnputil /scan-devices
        if ($driverUpdate -match "No driver updates") {
            Write-ColorOutput "All drivers are up to date" -Type Success
        } else {
            Write-ColorOutput "Driver updates may be available. Check Device Manager for details." -Type Warning
        }
    } catch {
        Write-ColorOutput "Could not check for driver updates: $_" -Type Warning
    }
}

function Optimize-StartupPrograms {
    Write-ColorOutput "Analyzing startup programs..." -Type Info
    
    $startupPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"
    )
    
    $totalStartupItems = 0
    $recommendations = @()
    
    foreach ($path in $startupPaths) {
        if (Test-Path $path) {
            $items = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            $properties = $items.PSObject.Properties | Where-Object { $_.Name -notmatch '^PS' }
            
            foreach ($prop in $properties) {
                $totalStartupItems++
                # Check for common bloatware patterns
                if ($prop.Value -match 'Spotify|Skype|Steam|Discord|OneDrive|Teams') {
                    $recommendations += "$($prop.Name): Consider disabling for faster boot"
                }
            }
        }
    }
    
    Write-ColorOutput "Found $totalStartupItems startup items" -Type Info
    if ($recommendations.Count -gt 0) {
        Write-ColorOutput "Recommendations:" -Type Warning
        $recommendations | ForEach-Object { Write-ColorOutput "  - $_" -Type Warning }
    }
}

function Apply-ProfileOptimizations {
    param(
        [string]$ProfileName
    )
    
    Write-ColorOutput "Applying $ProfileName profile optimizations..." -Type Info
    
    switch ($ProfileName) {
        'Gaming' {
            Write-ColorOutput "Optimizing for Gaming Performance..." -Type Info
            
            # Disable Xbox Game Bar and DVR
            if ($PSCmdlet.ShouldProcess("Xbox Features", "Disable")) {
                Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
            }
            
            # Set high performance power plan
            if ($PSCmdlet.ShouldProcess("Power Plan", "Set to High Performance")) {
                powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            }
            
            # Disable Windows fullscreen optimizations
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Value 2 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -ErrorAction SilentlyContinue
            
            # GPU scheduling for gaming
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
            
            Write-ColorOutput "Gaming optimizations applied" -Type Success
        }
        
        'Development' {
            Write-ColorOutput "Optimizing for Development..." -Type Info
            
            # Enable long paths
            if ($PSCmdlet.ShouldProcess("Long Path Support", "Enable")) {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "LongPathsEnabled" -Value 1 -ErrorAction SilentlyContinue
            }
            
            # Optimize Windows Defender for development
            if ($PSCmdlet.ShouldProcess("Defender Exclusions", "Add common dev paths")) {
                $devPaths = @(
                    "$env:USERPROFILE\source",
                    "$env:USERPROFILE\projects",
                    "$env:USERPROFILE\.npm",
                    "$env:USERPROFILE\.nuget",
                    "C:\Program Files\nodejs",
                    "C:\Python*"
                )
                
                foreach ($path in $devPaths) {
                    if (Test-Path $path) {
                        Add-MpPreference -ExclusionPath $path -ErrorAction SilentlyContinue
                    }
                }
            }
            
            # Enable developer mode
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -Value 1 -ErrorAction SilentlyContinue
            
            Write-ColorOutput "Development optimizations applied" -Type Success
        }
        
        'Music' {
            Write-ColorOutput "Optimizing for Music Production..." -Type Info
            
            # Disable system sounds
            if ($PSCmdlet.ShouldProcess("System Sounds", "Disable")) {
                Set-ItemProperty -Path "HKCU:\AppEvents\Schemes" -Name "(Default)" -Value ".None" -ErrorAction SilentlyContinue
            }
            
            # Set audio to high performance
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            
            # Disable audio enhancements
            $audioKeys = Get-ChildItem -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render" -ErrorAction SilentlyContinue
            foreach ($key in $audioKeys) {
                Set-ItemProperty -Path "$($key.PSPath)\FxProperties" -Name "{5860E1C5-F95C-4a7a-8EC8-8AEF24F379A1},3" -Value 0 -ErrorAction SilentlyContinue
            }
            
            # Optimize USB for audio interfaces
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Value 1 -ErrorAction SilentlyContinue
            
            Write-ColorOutput "Music production optimizations applied" -Type Success
        }
        
        'Video' {
            Write-ColorOutput "Optimizing for Video Editing..." -Type Info
            
            # Increase GPU timeout for rendering
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "TdrDelay" -Value 60 -ErrorAction SilentlyContinue
            
            # Optimize disk caching for large files
            fsutil behavior set memoryusage 2 2>$null
            fsutil behavior set disablelastaccess 1 2>$null
            
            # Set high performance power plan
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            
            Write-ColorOutput "Video editing optimizations applied" -Type Success
        }
        
        'Office' {
            Write-ColorOutput "Optimizing for Office Work..." -Type Info
            
            # Balanced power plan
            powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
            
            # Optimize for battery life on laptops
            powercfg /change standby-timeout-ac 15
            powercfg /change monitor-timeout-ac 10
            
            # Enable fast startup
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 1 -ErrorAction SilentlyContinue
            
            Write-ColorOutput "Office optimizations applied" -Type Success
        }
        
        Default {
            Write-ColorOutput "Using balanced optimizations" -Type Info
        }
    }
}

function Test-SystemHealth {
    Write-ColorOutput "Running system health checks..." -Type Info
    
    $healthChecks = @()
    
    # Check Windows Defender status
    try {
        $defenderStatus = Get-MpComputerStatus -ErrorAction Stop
        $healthChecks += [PSCustomObject]@{
            Check = "Windows Defender"
            Status = if ($defenderStatus.RealTimeProtectionEnabled) { "✓ Enabled" } else { "✗ Disabled" }
            Type = if ($defenderStatus.RealTimeProtectionEnabled) { "Success" } else { "Warning" }
        }
    } catch {
        $healthChecks += [PSCustomObject]@{
            Check = "Windows Defender"
            Status = "Could not check"
            Type = "Warning"
        }
    }
    
    # Check Windows Update
    try {
        $updateSession = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        $searchResult = $updateSearcher.Search("IsInstalled=0")
        
        $healthChecks += [PSCustomObject]@{
            Check = "Windows Updates"
            Status = if ($searchResult.Updates.Count -eq 0) { "✓ Up to date" } else { "✗ $($searchResult.Updates.Count) updates available" }
            Type = if ($searchResult.Updates.Count -eq 0) { "Success" } else { "Warning" }
        }
    } catch {
        $healthChecks += [PSCustomObject]@{
            Check = "Windows Updates"
            Status = "Could not check"
            Type = "Warning"
        }
    }
    
    # Check disk health
    $diskHealth = Get-PhysicalDisk | Where-Object { $_.HealthStatus -ne 'Healthy' }
    $healthChecks += [PSCustomObject]@{
        Check = "Disk Health"
        Status = if ($diskHealth.Count -eq 0) { "✓ All disks healthy" } else { "✗ Issues detected" }
        Type = if ($diskHealth.Count -eq 0) { "Success" } else { "Error" }
    }
    
    # Display results
    foreach ($check in $healthChecks) {
        Write-ColorOutput "$($check.Check): $($check.Status)" -Type $check.Type
    }
    
    return $healthChecks
}

function Invoke-DiskCleanup {
    Write-ColorOutput "Running disk cleanup..." -Type Info
    
    if ($PSCmdlet.ShouldProcess("Windows Disk Cleanup", "Execute")) {
        try {
            # Configure cleanmgr
            $cleanmgrKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
            $categories = @(
                "Active Setup Temp Folders",
                "Downloaded Program Files",
                "Internet Cache Files",
                "Memory Dump Files",
                "Old ChkDsk Files",
                "Previous Installations",
                "Recycle Bin",
                "Setup Log Files",
                "System error memory dump files",
                "System error minidump files",
                "Temporary Files",
                "Temporary Setup Files",
                "Thumbnail Cache",
                "Update Cleanup",
                "Upgrade Discarded Files",
                "User file versions",
                "Windows Error Reporting Archive Files",
                "Windows Error Reporting Queue Files",
                "Windows Error Reporting System Archive Files",
                "Windows Error Reporting System Queue Files",
                "Windows Upgrade Log Files"
            )
            
            foreach ($category in $categories) {
                $regPath = "$cleanmgrKey\$category"
                if (Test-Path $regPath) {
                    Set-ItemProperty -Path $regPath -Name "StateFlags0100" -Value 2 -Type DWord -ErrorAction SilentlyContinue
                }
            }
            
            # Run cleanmgr
            Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/sagerun:100" -Wait -NoNewWindow
            Write-ColorOutput "Disk cleanup completed" -Type Success
        } catch {
            Write-ColorOutput "Disk cleanup failed: $_" -Type Warning
        }
    }
}

function Optimize-WindowsSearch {
    Write-ColorOutput "Optimizing Windows Search indexing..." -Type Info
    
    if ($PSCmdlet.ShouldProcess("Windows Search Index", "Optimize")) {
        try {
            # Rebuild search index
            Stop-Service -Name WSearch -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:ProgramData\Microsoft\Search\Data\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name WSearch -ErrorAction SilentlyContinue
            Write-ColorOutput "Windows Search index will rebuild in the background" -Type Success
        } catch {
            Write-ColorOutput "Could not optimize Windows Search: $_" -Type Warning
        }
    }
}

function Show-Summary {
    param(
        [DateTime]$StartTime,
        [object[]]$HealthChecks
    )
    
    $duration = (Get-Date) - $StartTime
    $minutes = [math]::Round($duration.TotalMinutes, 2)
    
    Write-Host "`n" -NoNewline
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    DEEP CLEAN PRO - SUMMARY                    " -ForegroundColor White
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    Write-Host "`n📊 System Information:" -ForegroundColor Yellow
    $sysInfo = Get-SystemInfo
    $sysInfo.GetEnumerator() | ForEach-Object {
        Write-Host "   $($_.Key): " -NoNewline -ForegroundColor Gray
        Write-Host $_.Value -ForegroundColor White
    }
    
    if ($HealthChecks) {
        Write-Host "`n🔍 Health Check Results:" -ForegroundColor Yellow
        foreach ($check in $HealthChecks) {
            $color = switch ($check.Type) {
                'Success' { 'Green' }
                'Warning' { 'Yellow' }
                'Error' { 'Red' }
                default { 'White' }
            }
            Write-Host "   $($check.Check): " -NoNewline -ForegroundColor Gray
            Write-Host $check.Status -ForegroundColor $color
        }
    }
    
    Write-Host "`n⏱️  Execution Time: " -NoNewline -ForegroundColor Yellow
    Write-Host "$minutes minutes" -ForegroundColor Green
    
    Write-Host "`n📁 Backup Location: " -NoNewline -ForegroundColor Yellow
    Write-Host $Script:BackupPath -ForegroundColor White
    
    Write-Host "`n📝 Log Location: " -NoNewline -ForegroundColor Yellow
    Write-Host "$Script:LogPath\DeepClean_$(Get-Date -Format 'yyyyMMdd').log" -ForegroundColor White
    
    Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
}

#endregion

#region Main Execution

try {
    # Initialize
    Initialize-Environment
    
    # Run policy fix if requested
    if ($FixPolicies) {
        Write-ColorOutput "Running Windows Policy Configuration..." -Type Info
        $policyScript = Join-Path $PSScriptRoot "Fix-WindowsPolicies.ps1"
        if (Test-Path $policyScript) {
            & $policyScript -BackupPath "$Script:BackupPath\PolicyBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
        } else {
            Write-ColorOutput "Policy configuration script not found" -Type Warning
        }
        exit 0
    }
    
    # Display header
    Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "               DEEP CLEAN PRO v$Script:Version                 " -ForegroundColor White
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Mode: $(if ($QuickMode) { 'Quick Optimization' } else { 'Full Optimization' })" -ForegroundColor Yellow
    Write-Host "Profile: $Profile" -ForegroundColor Yellow
    Write-Host "WhatIf: $(if ($WhatIfPreference) { 'Enabled (No changes will be made)' } else { 'Disabled' })" -ForegroundColor $(if ($WhatIfPreference) { 'Yellow' } else { 'Green' })
    Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # System health check
    $healthChecks = $null
    if (-not $SkipHealth) {
        $healthChecks = Test-SystemHealth
    }
    
    # Core optimizations
    Clear-TempFiles
    Optimize-Services
    Optimize-SystemPerformance
    
    # Apply profile-specific optimizations
    if ($Profile -ne 'Balanced') {
        Apply-ProfileOptimizations -ProfileName $Profile
    }
    
    if (-not $QuickMode) {
        # Full optimization mode
        Remove-BloatwareApps
        Optimize-NetworkSettings
        Optimize-StartupPrograms
        Optimize-WindowsSearch
        Invoke-DiskCleanup
        Update-SystemDrivers
        
        # Defragmentation
        if (-not $SkipDefrag) {
            Write-ColorOutput "Starting disk defragmentation (this may take a while)..." -Type Info
            if ($PSCmdlet.ShouldProcess("C: Drive", "Defragment")) {
                Optimize-Volume -DriveLetter C -Defrag -Verbose
                Write-ColorOutput "Defragmentation completed" -Type Success
            }
        }
    }
    
    # Show summary
    Show-Summary -StartTime $Script:StartTime -HealthChecks $healthChecks
    
    # Handle reboot
    if ($AutoReboot) {
        Write-ColorOutput "System will restart in 30 seconds..." -Type Warning
        if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Restart")) {
            Start-Sleep -Seconds 30
            Restart-Computer -Force
        }
    } elseif (-not $NoReboot) {
        Write-Host "`nRestart recommended to apply all changes." -ForegroundColor Yellow
        $response = Read-Host "Restart now? (Y/N)"
        if ($response -eq 'Y') {
            if ($PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Restart")) {
                Restart-Computer -Force
            }
        }
    }
    
} catch {
    Write-ColorOutput "Critical error: $_" -Type Error
    Write-ColorOutput "Stack trace: $($_.ScriptStackTrace)" -Type Debug
    exit 1
} finally {
    # Restore original execution policy
    if ($Script:OriginalExecutionPolicy) {
        Set-ExecutionPolicy -ExecutionPolicy $Script:OriginalExecutionPolicy -Scope Process -Force -ErrorAction SilentlyContinue
    }
    
    Write-ColorOutput "`nDeep Clean Pro execution completed" -Type Success
}

#endregion