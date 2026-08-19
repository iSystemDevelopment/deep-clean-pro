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
.PARAMETER Harden
    Apply safe attack-surface reductions (firewall, SMBv1, AutoPlay, Guest, UAC, Defender check).
    Does not claim to stop determined attackers — reduces common exposure.
.PARAMETER HardenStrict
    Also offer stricter choices (RDP, WinRM, LLMNR, PowerShell v2, ASR). Prompts unless you pass the matching switch.
.PARAMETER HardenOnly
    Run hardening only (skip cleanup / performance). Implies -Harden.
.PARAMETER DisableRdp
.PARAMETER DisableWinRm
.PARAMETER DisableLlmnr
.PARAMETER DisablePowershellV2
.PARAMETER EnableAsrRules
.EXAMPLE
    .\DeepCleanPro.ps1 -HardenOnly -WhatIf
.EXAMPLE
    .\DeepCleanPro.ps1 -HardenStrict -DisableRdp -NoReboot
.NOTES
    Version: 2.5.0
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
    [switch]$RunWindowsUpdates,
    [switch]$SkipExtensions,
    [switch]$SkipRestorePoint,
    [switch]$SkipAppCaches,
    [switch]$DeepComponentCleanup,
    [switch]$Harden,
    [switch]$HardenStrict,
    [switch]$HardenOnly,
    [switch]$DisableRdp,
    [switch]$DisableWinRm,
    [switch]$DisableLlmnr,
    [switch]$DisablePowershellV2,
    [switch]$EnableAsrRules,
    
    # Built-in + extension-registered profiles (validated after extension load)
    [string]$Profile = 'Balanced'
)

#Requires -Version 5.1
#Requires -RunAsAdministrator

# Script Configuration
$Script:Version = "2.5.0"
$Script:StartTime = Get-Date
$Script:BasePath = if ($env:DEEPCLEANPRO_BASE_PATH) { $env:DEEPCLEANPRO_BASE_PATH } else { "C:\DeepCleanPro" }
$Script:BackupPath = if ($env:DEEPCLEANPRO_BACKUP_PATH) { $env:DEEPCLEANPRO_BACKUP_PATH } else { "$Script:BasePath\Backups" }
$Script:LogPath = "$Script:BasePath\Logs"
$Script:TempPath = "$env:TEMP\DeepCleanPro"
$Script:BuiltinProfiles = @('Balanced', 'Gaming', 'Development', 'Music', 'Video', 'Office')
$Script:CustomProfiles = @{}
$Script:ExtensionHooks = @{
    'BeforeStart'      = [System.Collections.Generic.List[scriptblock]]::new()
    'AfterHealthCheck' = [System.Collections.Generic.List[scriptblock]]::new()
    'BeforeOptimize'   = [System.Collections.Generic.List[scriptblock]]::new()
    'AfterOptimize'    = [System.Collections.Generic.List[scriptblock]]::new()
    'BeforeSummary'    = [System.Collections.Generic.List[scriptblock]]::new()
    'AfterSummary'     = [System.Collections.Generic.List[scriptblock]]::new()
}

# Security Configuration
$Script:AllowedHosts = @(
    'github.com',
    'raw.githubusercontent.com',
    'gist.githubusercontent.com',
    'microsoft.com',
    'windows.com'
)

# Initialize environment from shortcut / launcher if set
if ($env:DCP_QUICK_MODE -eq 'true' -and -not $PSBoundParameters.ContainsKey('QuickMode')) {
    $QuickMode = $true
}
if ($env:DCP_NO_REBOOT -eq 'true' -and -not $PSBoundParameters.ContainsKey('NoReboot')) {
    $NoReboot = $true
}
if ($env:DCP_RUN_UPDATES -eq 'true' -and -not $PSBoundParameters.ContainsKey('RunWindowsUpdates')) {
    $RunWindowsUpdates = $true
}
if ($env:DCP_PROFILE -and -not $PSBoundParameters.ContainsKey('Profile')) {
    $Profile = $env:DCP_PROFILE
}
if ($env:DCP_SKIP_EXTENSIONS -eq 'true') {
    $SkipExtensions = $true
}
if ($env:DCP_HARDEN -eq 'true' -and -not $PSBoundParameters.ContainsKey('Harden')) {
    $Harden = $true
}
if ($env:DCP_HARDEN_STRICT -eq 'true') {
    $HardenStrict = $true
}
if ($HardenOnly) { $Harden = $true }
if ($HardenStrict) { $Harden = $true }

#region Extension System

function Register-ExtensionHook {
    <#
    .SYNOPSIS
        Registers a scriptblock to run at a Deep Clean Pro lifecycle stage.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('BeforeStart', 'AfterHealthCheck', 'BeforeOptimize', 'AfterOptimize', 'BeforeSummary', 'AfterSummary')]
        [string]$Stage,

        [Parameter(Mandatory)]
        [scriptblock]$ScriptBlock
    )

    if (-not $Script:ExtensionHooks.ContainsKey($Stage)) {
        Write-Warning "Unknown extension stage: $Stage"
        return
    }

    $Script:ExtensionHooks[$Stage].Add($ScriptBlock) | Out-Null
}

function Invoke-DcpExtensionHooks {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('BeforeStart', 'AfterHealthCheck', 'BeforeOptimize', 'AfterOptimize', 'BeforeSummary', 'AfterSummary')]
        [string]$Stage
    )

    if (-not $Script:ExtensionHooks.ContainsKey($Stage)) { return }
    $hooks = $Script:ExtensionHooks[$Stage]
    if (-not $hooks -or $hooks.Count -eq 0) { return }

    Write-ColorOutput "Running extension hooks: $Stage ($($hooks.Count))" -Type Debug
    foreach ($hook in $hooks) {
        try {
            & $hook
        } catch {
            Write-ColorOutput "Extension hook at $Stage failed: $_" -Type Warning
        }
    }
}

function Import-DcpExtensions {
    param([switch]$Skip)

    if ($Skip) {
        Write-ColorOutput "Extension loading skipped" -Type Info
        return
    }

    $searchRoots = @(
        (Join-Path $PSScriptRoot 'Extensions'),
        (Join-Path $Script:BasePath 'Extensions')
    ) | Select-Object -Unique

    $loaded = 0
    foreach ($root in $searchRoots) {
        if (-not (Test-Path -LiteralPath $root)) { continue }

        Get-ChildItem -Path $root -Filter '*.ps1' -File -ErrorAction SilentlyContinue |
            Sort-Object Name |
            ForEach-Object {
                try {
                    Write-ColorOutput "Loading extension: $($_.Name)" -Type Info
                    . $_.FullName
                    $loaded++
                } catch {
                    Write-ColorOutput "Failed to load extension $($_.Name): $_" -Type Warning
                }
            }
    }

    if ($loaded -eq 0) {
        Write-ColorOutput "No extensions loaded (optional). Place .ps1 files in Extensions\" -Type Debug
    } else {
        Write-ColorOutput "Loaded $loaded extension(s)" -Type Success
    }
}

function Assert-DcpProfile {
    param([string]$Name)

    $allowed = @($Script:BuiltinProfiles) + @($Script:CustomProfiles.Keys)
    if ($allowed -contains $Name) { return $true }

    Write-ColorOutput "Unknown profile '$Name'. Allowed: $($allowed -join ', ')" -Type Warning
    return $false
}

#endregion

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
        @{Name = 'DiagTrack';        StartupType = 'Disabled'; Description = 'Connected User Experiences and Telemetry'},
        @{Name = 'dmwappushservice'; StartupType = 'Disabled'; Description = 'Device Management WAP Push'},
        @{Name = 'WSearch';          StartupType = 'Manual';   Description = 'Windows Search'},
        @{Name = 'SysMain';          StartupType = 'Manual';   Description = 'SysMain (Superfetch)'},
        @{Name = 'Spooler';          StartupType = 'Manual';   Description = 'Print Spooler'}  # actual service name
    )
    
    # Backup current service configurations
    $serviceBackup = @()
    foreach ($svc in $services) {
        $currentService = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue
        if ($currentService) {
            $startMode = $null
            try {
                $cimSvc = Get-CimInstance -ClassName Win32_Service -Filter "Name='$($svc.Name)'" -ErrorAction SilentlyContinue
                if ($cimSvc) {
                    $startMode = $cimSvc.StartMode
                }
            } catch {
                # don't crash on backup read problems
            }

            $serviceBackup += [PSCustomObject]@{
                Name        = $svc.Name
                StartupType = $startMode
                Status      = $currentService.Status
            }
        }
    }
    
    # Save backup
    try {
        $backupFile = "$Script:BackupPath\Services\ServiceConfig_$(Get-Date -Format 'yyyyMMdd_HHmmss').csv"
        $backupDir  = Split-Path $backupFile -Parent
        if (-not (Test-Path $backupDir)) {
            New-Item -Path $backupDir -ItemType Directory -Force | Out-Null
        }
        $serviceBackup | Export-Csv -Path $backupFile -NoTypeInformation
        Write-ColorOutput "Saved service configuration backup to: $backupFile" -Type Success
    } catch {
        Write-ColorOutput "Warning: Failed to save service backup. Details: $($_.Exception.Message)" -Type Warning
    }
    
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
            Write-ColorOutput "Failed to configure $($service.Name): $($_.Exception.Message)" -Type Warning
        }
    }
}


function Get-DcpFolderSizeBytes {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) { return [long]0 }
    try {
        $sum = (Get-ChildItem -LiteralPath $Path -Recurse -Force -File -ErrorAction SilentlyContinue |
            Measure-Object -Property Length -Sum).Sum
        if ($null -eq $sum) { return [long]0 }
        return [long]$sum
    } catch {
        return [long]0
    }
}

function Clear-DcpPathContents {
    param(
        [Parameter(Mandatory)][string]$Path,
        [string]$Label = $Path,
        [int]$MinAgeDays = 0
    )

    if (-not (Test-Path -LiteralPath $Path)) { return @{ Deleted = 0; Bytes = [long]0 } }

    $deleted = 0
    [long]$bytes = 0
    $cutoff = if ($MinAgeDays -gt 0) { (Get-Date).AddDays(-$MinAgeDays) } else { $null }

    if (-not $PSCmdlet.ShouldProcess($Label, "Clean path contents")) {
        $preview = Get-DcpFolderSizeBytes -Path $Path
        Write-ColorOutput ("[WhatIf] Would clean {0} (~{1:N1} MB)" -f $Label, ($preview / 1MB)) -Type Warning
        return @{ Deleted = 0; Bytes = $preview }
    }

    Get-ChildItem -LiteralPath $Path -Force -ErrorAction SilentlyContinue | ForEach-Object {
        if ($cutoff -and $_.LastWriteTime -gt $cutoff) { return }
        try {
            if (-not $_.PSIsContainer) { $bytes += $_.Length }
            else { $bytes += (Get-DcpFolderSizeBytes -Path $_.FullName) }
            Remove-Item -LiteralPath $_.FullName -Force -Recurse -ErrorAction Stop
            $deleted++
        } catch {
            # locked / in use
        }
    }

    return @{ Deleted = $deleted; Bytes = $bytes }
}

function New-DcpRestorePoint {
    Write-ColorOutput "Creating system restore point..." -Type Info

    if ($SkipRestorePoint) {
        Write-ColorOutput "Restore point skipped (-SkipRestorePoint)" -Type Info
        return
    }

    if (-not $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Create system restore point")) {
        Write-ColorOutput "[WhatIf] Would create restore point 'DeepCleanPro'" -Type Warning
        return
    }

    try {
        # Checkpoint-Computer requires SystemRestore enable; fails quietly on some SKUs
        Enable-ComputerRestore -Drive "$env:SystemDrive\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "DeepCleanPro_$($Script:Version)_$(Get-Date -Format 'yyyyMMdd_HHmmss')" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-ColorOutput "System restore point created" -Type Success
    } catch {
        Write-ColorOutput "Could not create restore point: $_" -Type Warning
        Write-ColorOutput "Tip: System Protection may be off for this drive" -Type Debug
    }
}

function Clear-TempFiles {
    Write-ColorOutput "Cleaning temporary files..." -Type Info

    # Prefer Windows\Temp + user Temp. Prefetch cleaned separately (age-gated).
    $tempPaths = @(
        @{ Path = $env:TEMP; Label = 'User TEMP' },
        @{ Path = "$env:LOCALAPPDATA\Temp"; Label = 'LocalAppData TEMP' },
        @{ Path = "$env:WINDIR\Temp"; Label = 'Windows TEMP' }
    )

    $totalBytes = [long]0
    $deletedFiles = 0

    foreach ($entry in $tempPaths) {
        $result = Clear-DcpPathContents -Path $entry.Path -Label $entry.Label
        $totalBytes += $result.Bytes
        $deletedFiles += $result.Deleted
    }

    # Thumbnail / icon caches (safe)
    $thumb = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
    if (Test-Path $thumb) {
        Get-ChildItem -Path $thumb -Filter 'thumbcache_*.db' -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, "Remove thumbnail cache")) {
                try {
                    $totalBytes += $_.Length
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                    $deletedFiles++
                } catch { }
            }
        }
        Get-ChildItem -Path $thumb -Filter 'iconcache_*.db' -Force -ErrorAction SilentlyContinue | ForEach-Object {
            if ($PSCmdlet.ShouldProcess($_.FullName, "Remove icon cache")) {
                try {
                    $totalBytes += $_.Length
                    Remove-Item -LiteralPath $_.FullName -Force -ErrorAction Stop
                    $deletedFiles++
                } catch { }
            }
        }
    }

    $freedSpace = [math]::Round($totalBytes / 1MB, 2)
    Write-ColorOutput "Temp cleanup: $deletedFiles items, ~$freedSpace MB" -Type Success
}

function Clear-PrefetchCache {
    Write-ColorOutput "Cleaning Prefetch (files older than 30 days)..." -Type Info
    $path = Join-Path $env:WINDIR 'Prefetch'
    $result = Clear-DcpPathContents -Path $path -Label 'Prefetch' -MinAgeDays 30
    Write-ColorOutput ("Prefetch: {0} items, ~{1:N1} MB" -f $result.Deleted, ($result.Bytes / 1MB)) -Type Success
}

function Clear-DeliveryOptimizationCache {
    Write-ColorOutput "Cleaning Delivery Optimization cache..." -Type Info

    $paths = @(
        "$env:WINDIR\SoftwareDistribution\DeliveryOptimization\Cache",
        "$env:WINDIR\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"
    )

    [long]$bytes = 0
    $count = 0
    foreach ($p in $paths) {
        $r = Clear-DcpPathContents -Path $p -Label "DeliveryOptimization:$p"
        $bytes += $r.Bytes
        $count += $r.Deleted
    }

    # Also try DOSvc API-ish cleanup via cleanmgr state is heavy; delete content only.
    Write-ColorOutput ("Delivery Optimization: {0} items, ~{1:N1} MB" -f $count, ($bytes / 1MB)) -Type Success
}

function Clear-RecycleBinSafe {
    Write-ColorOutput "Emptying Recycle Bin..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('Recycle Bin', 'Empty')) {
        Write-ColorOutput '[WhatIf] Would empty Recycle Bin' -Type Warning
        return
    }
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-ColorOutput 'Recycle Bin emptied' -Type Success
    } catch {
        # Fallback COM
        try {
            (New-Object -ComObject Shell.Application).NameSpace(0xA).Items() | ForEach-Object {
                Remove-Item -LiteralPath $_.Path -Recurse -Force -ErrorAction SilentlyContinue
            }
            Write-ColorOutput 'Recycle Bin emptied (fallback)' -Type Success
        } catch {
            Write-ColorOutput "Recycle Bin clean failed: $_" -Type Warning
        }
    }
}

function Clear-AppCaches {
    <#
    .SYNOPSIS
        Clears known app / toolchain caches under LocalAppData with size preview.
        Does NOT wipe whole AppData — only listed cache folders.
    #>
    if ($SkipAppCaches) {
        Write-ColorOutput 'App cache clean skipped (-SkipAppCaches)' -Type Info
        return
    }

    Write-ColorOutput 'Scanning app / toolchain caches...' -Type Info

    $la = $env:LOCALAPPDATA
    $targets = @(
        @{ Name = 'Edge Cache'; Path = "$la\Microsoft\Edge\User Data\Default\Cache" },
        @{ Name = 'Edge Code Cache'; Path = "$la\Microsoft\Edge\User Data\Default\Code Cache" },
        @{ Name = 'Chrome Cache'; Path = "$la\Google\Chrome\User Data\Default\Cache" },
        @{ Name = 'Teams Cache (classic)'; Path = "$la\Microsoft\Teams\Cache" },
        @{ Name = 'Teams blob_storage'; Path = "$la\Microsoft\Teams\blob_storage" },
        @{ Name = 'Teams GPUCache'; Path = "$la\Microsoft\Teams\GPUCache" },
        @{ Name = 'Discord Cache'; Path = "$la\Discord\Cache" },
        @{ Name = 'Discord Code Cache'; Path = "$la\Discord\Code Cache" },
        @{ Name = 'npm cache'; Path = "$la\npm-cache" },
        @{ Name = 'NuGet cache'; Path = "$la\NuGet\v3-cache" },
        @{ Name = 'pip cache'; Path = "$la\pip\Cache" },
        @{ Name = 'VS Code Cache'; Path = "$la\Programs\Microsoft VS Code\Cache" },
        @{ Name = 'VS Code CachedData'; Path = "$la\Programs\Microsoft VS Code\CachedData" },
        @{ Name = 'Windows Package Manager'; Path = "$la\Microsoft\WinGet\Packages" },
        @{ Name = 'CrashDumps'; Path = "$la\CrashDumps" },
        @{ Name = 'D3DSCache'; Path = "$la\D3DSCache" },
        @{ Name = 'FontCache'; Path = "$env:WINDIR\ServiceProfiles\LocalService\AppData\Local\FontCache" }
    )

    $report = @()
    foreach ($t in $targets) {
        if (-not (Test-Path -LiteralPath $t.Path)) { continue }
        $size = Get-DcpFolderSizeBytes -Path $t.Path
        if ($size -lt 1MB) { continue }
        $report += [PSCustomObject]@{ Name = $t.Name; Path = $t.Path; MB = [math]::Round($size / 1MB, 1); Bytes = $size }
    }

    if ($report.Count -eq 0) {
        Write-ColorOutput 'No large app caches found (>1 MB)' -Type Success
        return
    }

    Write-ColorOutput 'Cache candidates:' -Type Info
    $report | Sort-Object MB -Descending | ForEach-Object {
        Write-ColorOutput ("  {0,8:N1} MB  {1}" -f $_.MB, $_.Name) -Type Info
    }
    $totalMb = [math]::Round((($report | Measure-Object Bytes -Sum).Sum / 1MB), 1)
    Write-ColorOutput "Total reclaimable (listed): ~$totalMb MB" -Type Warning

    # Never delete WinGet Packages folder contents wholesale — only report
    $deletable = $report | Where-Object { $_.Name -ne 'Windows Package Manager' }

    foreach ($item in $deletable) {
        $null = Clear-DcpPathContents -Path $item.Path -Label $item.Name
    }

    Write-ColorOutput 'App / toolchain cache clean finished' -Type Success
}

function Clear-WindowsUpdateDownloadCache {
    Write-ColorOutput 'Cleaning Windows Update download cache (SoftwareDistribution\Download)...' -Type Info

    $svc = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    $wasRunning = ($svc -and $svc.Status -eq 'Running')

    if ($PSCmdlet.ShouldProcess('wuauserv', 'Stop for cache clean')) {
        if ($wasRunning) {
            Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        }
        $path = Join-Path $env:WINDIR 'SoftwareDistribution\Download'
        $null = Clear-DcpPathContents -Path $path -Label 'WU Download'
        if ($wasRunning) {
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }
        Write-ColorOutput 'Windows Update download cache cleaned' -Type Success
    } else {
        Write-ColorOutput '[WhatIf] Would stop wuauserv, clear Download, restart service' -Type Warning
    }
}

function Invoke-ComponentStoreCleanup {
    <#
    .SYNOPSIS
        Optional DISM component store cleanup. Gated: Full mode + -DeepComponentCleanup.
        Does NOT use /ResetBase (too aggressive / breaks uninstall of updates).
    #>
    if (-not $DeepComponentCleanup) {
        return
    }

    Write-ColorOutput 'Running DISM component store cleanup (StartComponentCleanup)...' -Type Warning
    Write-ColorOutput 'This can take a long time and needs free disk space.' -Type Info

    if (-not $PSCmdlet.ShouldProcess('DISM Component Store', 'StartComponentCleanup')) {
        Write-ColorOutput '[WhatIf] Would run: DISM /Online /Cleanup-Image /StartComponentCleanup' -Type Warning
        return
    }

    try {
        $p = Start-Process -FilePath 'DISM.exe' -ArgumentList '/Online','/Cleanup-Image','/StartComponentCleanup' -Wait -PassThru -NoNewWindow
        if ($p.ExitCode -eq 0) {
            Write-ColorOutput 'DISM component cleanup completed' -Type Success
        } else {
            Write-ColorOutput "DISM exited with code $($p.ExitCode)" -Type Warning
        }
    } catch {
        Write-ColorOutput "DISM cleanup failed: $_" -Type Warning
    }
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

    # Extension-registered custom profiles
    if ($Script:CustomProfiles.ContainsKey($ProfileName)) {
        try {
            & $Script:CustomProfiles[$ProfileName]
            Write-ColorOutput "Custom profile '$ProfileName' applied" -Type Success
        } catch {
            Write-ColorOutput "Custom profile '$ProfileName' failed: $_" -Type Warning
        }
        return
    }
    
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
            Status = if ($defenderStatus.RealTimeProtectionEnabled) { "[OK] Enabled" } else { "[!!] Disabled" }
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
            Status = if ($searchResult.Updates.Count -eq 0) { "[OK] Up to date" } else { "[!!] $($searchResult.Updates.Count) updates available" }
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
        Status = if ($diskHealth.Count -eq 0) { "[OK] All disks healthy" } else { "[!!] Issues detected" }
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

function Optimize-WindowsUpdates {
    <#
    .SYNOPSIS
        Searches for pending Windows Updates; installs when -RunWindowsUpdates is set.
        Always reports count. Respects -WhatIf for install (search still runs for reporting).
    #>
    Write-ColorOutput "Checking Windows Updates..." -Type Info

    try {
        $updateSession  = New-Object -ComObject Microsoft.Update.Session
        $updateSearcher = $updateSession.CreateUpdateSearcher()
        # Software updates, not yet installed, not hidden
        $searchResult   = $updateSearcher.Search("IsInstalled=0 and Type='Software' and IsHidden=0")

        $count = [int]$searchResult.Updates.Count
        if ($count -eq 0) {
            Write-ColorOutput "No pending Windows Updates" -Type Success
            return
        }

        Write-ColorOutput "Found $count pending Windows Update(s)" -Type Warning

        # List titles (cap for readability)
        $shown = 0
        foreach ($update in $searchResult.Updates) {
            if ($shown -ge 15) {
                Write-ColorOutput "  ... and $($count - $shown) more" -Type Info
                break
            }
            Write-ColorOutput ("  - {0}" -f $update.Title) -Type Info
            $shown++
        }

        if (-not $RunWindowsUpdates) {
            if ($Host.Name -eq 'ConsoleHost' -and -not $WhatIfPreference) {
                $answer = Read-Host "Install $count Windows Update(s) now? (Y/N)"
                if ($answer -ne 'Y' -and $answer -ne 'y') {
                    Write-ColorOutput "Skipped Windows Update install" -Type Info
                    return
                }
            } else {
                Write-ColorOutput "Updates not installed (pass -RunWindowsUpdates or set DCP_RUN_UPDATES=true)" -Type Info
                return
            }
        }

        if (-not $PSCmdlet.ShouldProcess("Windows Update ($count packages)", "Download and install")) {
            Write-ColorOutput "[WhatIf] Would download and install $count update(s)" -Type Warning
            return
        }

        Write-ColorOutput "Downloading $count update(s)..." -Type Info
        $updatesToInstall = New-Object -ComObject Microsoft.Update.UpdateColl
        foreach ($update in $searchResult.Updates) {
            # Skip when reboot required mid-flight / not downloadable
            if ($update.InstallationBehavior.CanRequestUserInput) {
                Write-ColorOutput "Skipping interactive update: $($update.Title)" -Type Warning
                continue
            }
            if ($update.EulaAccepted -eq $false) {
                try { $update.AcceptEula() | Out-Null } catch { }
            }
            [void]$updatesToInstall.Add($update)
        }

        if ($updatesToInstall.Count -eq 0) {
            Write-ColorOutput "No non-interactive updates left to install" -Type Warning
            return
        }

        $downloader = $updateSession.CreateUpdateDownloader()
        $downloader.Updates = $updatesToInstall
        $downloadResult = $downloader.Download()
        # ResultCode: 2 = Succeeded, 3 = SucceededWithErrors
        if ($downloadResult.ResultCode -notin 2, 3) {
            Write-ColorOutput "Windows Update download result code: $($downloadResult.ResultCode)" -Type Warning
            return
        }

        Write-ColorOutput "Installing updates..." -Type Info
        $installer = $updateSession.CreateUpdateInstaller()
        $installer.Updates = $updatesToInstall
        $installResult = $installer.Install()

        $ok = ($installResult.ResultCode -in 2, 3)
        Write-ColorOutput "Windows Update install result code: $($installResult.ResultCode)" -Type $(if ($ok) { 'Success' } else { 'Warning' })

        if ($installResult.RebootRequired) {
            Write-ColorOutput "A reboot is required to finish Windows Updates" -Type Warning
        }
    } catch {
        Write-ColorOutput "Windows Update step failed: $_" -Type Warning
        Write-ColorOutput "Tip: ensure Windows Update service is running and COM access is allowed" -Type Debug
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

#region Security Hardening (honest attack-surface reduction — not "hacker-proof")

function Confirm-DcpStrictChoice {
    param(
        [Parameter(Mandatory)][string]$Title,
        [Parameter(Mandatory)][string]$Impact,
        [switch]$AlreadyYes
    )

    if ($AlreadyYes) { return $true }
    if ($WhatIfPreference) {
        Write-ColorOutput "[WhatIf] Would prompt for: $Title" -Type Warning
        return $true  # preview strict options in WhatIf
    }
    if ($Host.Name -ne 'ConsoleHost') {
        Write-ColorOutput "Skip '$Title' (non-interactive — pass matching switch to enable)" -Type Info
        return $false
    }

    Write-Host ""
    Write-Host "  STRICT CHOICE: $Title" -ForegroundColor Yellow
    Write-Host "  Impact: $Impact" -ForegroundColor Gray
    Write-Host "  This is optional. Many home/office setups need the feature left ON." -ForegroundColor Gray
    $answer = Read-Host "  Enable this change? Type YES to apply"
    return ($answer -eq 'YES')
}

function Set-DcpFirewallEnabled {
    Write-ColorOutput "Ensuring Windows Firewall is on (all profiles)..." -Type Info
    foreach ($profile in @('Domain', 'Private', 'Public')) {
        if ($PSCmdlet.ShouldProcess("Firewall $profile", "Set-NetFirewallProfile -Enabled True")) {
            try {
                Set-NetFirewallProfile -Profile $profile -Enabled True -ErrorAction Stop
                Write-ColorOutput "Firewall ${profile}: Enabled" -Type Success
            } catch {
                # Fallback netsh for older tooling
                try {
                    $netshProfile = switch ($profile) {
                        'Domain'  { 'domainprofile' }
                        'Private' { 'privateprofile' }
                        'Public'  { 'publicprofile' }
                        default   { 'allprofiles' }
                    }
                    netsh advfirewall set $netshProfile state on | Out-Null
                    Write-ColorOutput "Firewall ${profile}: Enabled (netsh)" -Type Success
                } catch {
                    Write-ColorOutput "Firewall ${profile} failed: $_" -Type Warning
                }
            }
        }
    }
}

function Disable-DcpSmbV1 {
    Write-ColorOutput "Disabling SMBv1 (legacy protocol)..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('SMBv1', 'Disable')) { return }

    try {
        if (Get-Command Disable-WindowsOptionalFeature -ErrorAction SilentlyContinue) {
            $feat = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
            if ($feat -and $feat.State -eq 'Enabled') {
                Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction Stop | Out-Null
                Write-ColorOutput "SMBv1 optional feature disabled (reboot may finish removal)" -Type Success
            } else {
                Write-ColorOutput "SMBv1 optional feature already off / not present" -Type Success
            }
        }
    } catch {
        Write-ColorOutput "SMBv1 feature change: $_" -Type Warning
    }

    try {
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue
    } catch { }

    # Client-side policy keys (best-effort)
    $smbClient = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
    if (Test-Path $smbClient) {
        Set-ItemProperty -Path $smbClient -Name 'SMB1' -Value 0 -Type DWord -ErrorAction SilentlyContinue
    }
}

function Disable-DcpAutoPlay {
    Write-ColorOutput "Hardening AutoPlay / AutoRun..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('AutoPlay', 'Disable')) { return }

    $paths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer'
    )
    foreach ($p in $paths) {
        if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
        # 255 = disable AutoRun on all drives
        Set-ItemProperty -Path $p -Name 'NoDriveTypeAutoRun' -Value 255 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    # Explorer Autoplay handler
    $exp = 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers'
    if (-not (Test-Path $exp)) { New-Item -Path $exp -Force | Out-Null }
    Set-ItemProperty -Path $exp -Name 'DisableAutoplay' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "AutoPlay/AutoRun restricted" -Type Success
}

function Disable-DcpGuestAccount {
    Write-ColorOutput "Ensuring Guest account is disabled..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('Guest', 'Disable local account')) { return }
    try {
        $guest = Get-LocalUser -Name 'Guest' -ErrorAction SilentlyContinue
        if ($guest -and $guest.Enabled) {
            Disable-LocalUser -Name 'Guest' -ErrorAction Stop
            Write-ColorOutput "Guest account disabled" -Type Success
        } else {
            Write-ColorOutput "Guest already disabled / not present" -Type Success
        }
    } catch {
        # net user fallback
        try {
            net user Guest /active:no | Out-Null
            Write-ColorOutput "Guest disabled (net user)" -Type Success
        } catch {
            Write-ColorOutput "Guest disable: $_" -Type Warning
        }
    }
}

function Set-DcpUacSecure {
    Write-ColorOutput "Setting UAC to a secure default (ConsentPromptBehaviorAdmin=5)..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('UAC', 'Secure prompt behavior')) { return }

    $path = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System'
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    # 5 = Prompt for consent on the secure desktop (Windows default "Notify")
    Set-ItemProperty -Path $path -Name 'EnableLUA' -Value 1 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'ConsentPromptBehaviorAdmin' -Value 5 -Type DWord -Force
    Set-ItemProperty -Path $path -Name 'PromptOnSecureDesktop' -Value 1 -Type DWord -Force
    Write-ColorOutput "UAC policies applied" -Type Success
}

function Disable-DcpRemoteAssistance {
    Write-ColorOutput "Disabling Remote Assistance invitations..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('Remote Assistance', 'Disable')) { return }
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Remote Assistance'
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name 'fAllowToGetHelp' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    Write-ColorOutput "Remote Assistance disabled" -Type Success
}

function Restrict-DcpAnonymousShares {
    Write-ColorOutput "Restricting anonymous / null-session share access..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('LanmanServer', 'Restrict anonymous')) { return }
    $p = 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa'
    Set-ItemProperty -Path $p -Name 'RestrictAnonymous' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $p -Name 'RestrictAnonymousSAM' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    $lan = 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
    if (Test-Path $lan) {
        Set-ItemProperty -Path $lan -Name 'RestrictNullSessAccess' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
    }
    Write-ColorOutput "Anonymous share restrictions set" -Type Success
}

function Assert-DcpDefenderBasics {
    Write-ColorOutput "Checking Microsoft Defender basics..." -Type Info
    try {
        $status = Get-MpComputerStatus -ErrorAction Stop
        if (-not $status.RealTimeProtectionEnabled) {
            Write-ColorOutput "Defender real-time protection is OFF — enabling if possible..." -Type Warning
            if ($PSCmdlet.ShouldProcess('Defender', 'Enable realtime')) {
                Set-MpPreference -DisableRealtimeMonitoring $false -ErrorAction SilentlyContinue
            }
        } else {
            Write-ColorOutput "Defender real-time protection: ON" -Type Success
        }

        if ($PSCmdlet.ShouldProcess('Defender', 'Enable PUA + cloud')) {
            Set-MpPreference -PUAProtection Enabled -ErrorAction SilentlyContinue
            Set-MpPreference -MAPSReporting Advanced -ErrorAction SilentlyContinue
            Set-MpPreference -SubmitSamplesConsent SendSafeSamples -ErrorAction SilentlyContinue
            Write-ColorOutput "Defender PUA / cloud preferences set (best-effort)" -Type Success
        }
    } catch {
        Write-ColorOutput "Defender API unavailable (third-party AV?): $_" -Type Warning
    }
}

function Disable-DcpNetworkDiscoveryNoise {
    # Safe-ish: disable LLT for Homegroup remnants; keep NetBIOS decision for Strict
    Write-ColorOutput "Tightening common network discovery leftovers..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('FDResPub/SSDPSRV', 'Disable discovery helpers if unused')) { return }
    foreach ($svc in @('FDResPub', 'SSDPSRV', 'upnphost')) {
        $s = Get-Service -Name $svc -ErrorAction SilentlyContinue
        if ($s -and $s.StartType -ne 'Disabled') {
            # Don't force-stop if active dependency; only set Manual on safe set
            try {
                Set-Service -Name $svc -StartupType Manual -ErrorAction SilentlyContinue
            } catch { }
        }
    }
    Write-ColorOutput "Discovery helper services set to Manual (best-effort)" -Type Success
}

# --- Strict / user-choice actions ---

function Disable-DcpRemoteDesktop {
    Write-ColorOutput "Disabling Remote Desktop (RDP)..." -Type Warning
    if (-not $PSCmdlet.ShouldProcess('Terminal Services', 'Disable RDP')) { return }

    $ts = 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server'
    Set-ItemProperty -Path $ts -Name 'fDenyTSConnections' -Value 1 -Type DWord -Force
    try {
        Disable-NetFirewallRule -DisplayGroup 'Remote Desktop' -ErrorAction SilentlyContinue
    } catch { }
    Write-ColorOutput "RDP disabled (fDenyTSConnections=1). Re-enable via System Properties if needed." -Type Success
}

function Disable-DcpWinRm {
    Write-ColorOutput "Disabling WinRM (remote PowerShell)..." -Type Warning
    if (-not $PSCmdlet.ShouldProcess('WinRM', 'Disable service')) { return }
    try {
        Stop-Service -Name WinRM -Force -ErrorAction SilentlyContinue
        Set-Service -Name WinRM -StartupType Disabled -ErrorAction Stop
        Write-ColorOutput "WinRM service Disabled" -Type Success
    } catch {
        Write-ColorOutput "WinRM change failed: $_" -Type Warning
    }
}

function Disable-DcpLlmnr {
    Write-ColorOutput "Disabling LLMNR (Link-Local Multicast Name Resolution)..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('LLMNR', 'Disable')) { return }
    $p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient'
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name 'EnableMulticast' -Value 0 -Type DWord -Force
    Write-ColorOutput "LLMNR disabled via policy (EnableMulticast=0)" -Type Success
}

function Disable-DcpPowershellV2 {
    Write-ColorOutput "Disabling PowerShell 2.0 engine (legacy)..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('PowerShell v2', 'Disable-WindowsOptionalFeature')) { return }
    try {
        $feat = Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -ErrorAction SilentlyContinue
        if ($feat -and $feat.State -eq 'Enabled') {
            Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart -ErrorAction Stop | Out-Null
            Write-ColorOutput "PowerShell v2 disabled" -Type Success
        } else {
            # Try sibling feature name
            Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2 -NoRestart -ErrorAction SilentlyContinue | Out-Null
            Write-ColorOutput "PowerShell v2 feature already off / attempted" -Type Success
        }
    } catch {
        Write-ColorOutput "PowerShell v2 disable: $_" -Type Warning
    }
}

function Enable-DcpAsrBaseRules {
    Write-ColorOutput "Enabling a small Microsoft Defender ASR rule set..." -Type Info
    Write-ColorOutput "ASR can block legitimate software — review Event Viewer if apps break." -Type Warning
    if (-not $PSCmdlet.ShouldProcess('Defender ASR', 'Enable base rules')) { return }

    # Guids from Microsoft docs — enable mode (1). Keep list small & commonly useful.
    $rules = @(
        'D4F940AB-401B-4EFC-AADC-AD5F3C50688A', # Block Office child processes
        '3B576869-A4EC-4529-8536-B80A7769E899', # Block Office from creating executable content
        '75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84', # Block Office from injecting into other processes
        'BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550', # Block executable content from email/webmail
        '5BEB7EFE-FD9A-4556-801D-275E5FFC04CC'  # Block execution of potentially obfuscated scripts
    )

    try {
        foreach ($id in $rules) {
            Add-MpPreference -AttackSurfaceReductionRules_Ids $id -AttackSurfaceReductionRules_Actions Enabled -ErrorAction SilentlyContinue
        }
        Write-ColorOutput "ASR base rules requested (Enabled). Verify with Get-MpPreference." -Type Success
    } catch {
        Write-ColorOutput "ASR not applied: $_" -Type Warning
    }
}

function Enable-DcpScriptBlockLogging {
    Write-ColorOutput "Enabling PowerShell Script Block Logging (detection aid)..." -Type Info
    if (-not $PSCmdlet.ShouldProcess('ScriptBlockLogging', 'Enable')) { return }
    $p = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging'
    if (-not (Test-Path $p)) { New-Item -Path $p -Force | Out-Null }
    Set-ItemProperty -Path $p -Name 'EnableScriptBlockLogging' -Value 1 -Type DWord -Force
    Write-ColorOutput "Script Block Logging enabled (Event Viewer > PowerShell)" -Type Success
}

function Invoke-SecurityHardening {
    <#
    .SYNOPSIS
        Reduces common Windows attack surface. Not a guarantee against compromise.
    #>
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor DarkYellow
    Write-Host "  SECURITY HARDENING — attack-surface reduction" -ForegroundColor Yellow
    Write-Host "  Not 'hacker-proof'. Updates, MFA, and caution still matter." -ForegroundColor Gray
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor DarkYellow
    Write-Host ""

    if (-not $Harden -and -not $HardenStrict -and -not $HardenOnly) {
        return
    }

    # Always take a restore point for harden-only / strict; Full flow may already have one
    if ($HardenOnly -or $HardenStrict -or $QuickMode) {
        New-DcpRestorePoint
    }

    # --- Safe set (always when -Harden) ---
    Assert-DcpDefenderBasics
    Set-DcpFirewallEnabled
    Disable-DcpSmbV1
    Disable-DcpAutoPlay
    Disable-DcpGuestAccount
    Set-DcpUacSecure
    Disable-DcpRemoteAssistance
    Restrict-DcpAnonymousShares
    Disable-DcpNetworkDiscoveryNoise
    Enable-DcpScriptBlockLogging

    # --- Strict: user choices ---
    if ($HardenStrict) {
        Write-Host ""
        Write-ColorOutput "Strict options — each requires YES (or a dedicated switch)." -Type Warning

        if (Confirm-DcpStrictChoice -Title 'Disable Remote Desktop (RDP)' -Impact 'Blocks remote GUI login. Do NOT use if you rely on RDP.' -AlreadyYes:$DisableRdp) {
            Disable-DcpRemoteDesktop
        }

        if (Confirm-DcpStrictChoice -Title 'Disable WinRM' -Impact 'Breaks remote PowerShell / some management tools.' -AlreadyYes:$DisableWinRm) {
            Disable-DcpWinRm
        }

        if (Confirm-DcpStrictChoice -Title 'Disable LLMNR' -Impact 'Can affect name resolution on small LANs without DNS.' -AlreadyYes:$DisableLlmnr) {
            Disable-DcpLlmnr
        }

        if (Confirm-DcpStrictChoice -Title 'Disable PowerShell v2' -Impact 'Removes legacy engine (good); rare old tools may need it.' -AlreadyYes:$DisablePowershellV2) {
            Disable-DcpPowershellV2
        }

        if (Confirm-DcpStrictChoice -Title 'Enable Defender ASR base rules' -Impact 'May block Office macros / scripts that you use daily.' -AlreadyYes:$EnableAsrRules) {
            Enable-DcpAsrBaseRules
        }
    } else {
        # Allow single switches without full Strict mode
        if ($DisableRdp) { Disable-DcpRemoteDesktop }
        if ($DisableWinRm) { Disable-DcpWinRm }
        if ($DisableLlmnr) { Disable-DcpLlmnr }
        if ($DisablePowershellV2) { Disable-DcpPowershellV2 }
        if ($EnableAsrRules) { Enable-DcpAsrBaseRules }
    }

    Write-ColorOutput "Hardening pass finished. Reboot recommended for feature removals (SMBv1 / PSv2)." -Type Success
    Write-ColorOutput "Review firewall / RDP / WinRM if you manage this PC remotely." -Type Info
}

#endregion

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
    Import-DcpExtensions -Skip:$SkipExtensions

    if (-not (Assert-DcpProfile -Name $Profile)) {
        $Profile = 'Balanced'
        Write-ColorOutput "Falling back to profile: Balanced" -Type Warning
    }

    Invoke-DcpExtensionHooks -Stage BeforeStart
    
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

    # Hardening-only path (skip cleanup)
    if ($HardenOnly) {
        Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "               DEEP CLEAN PRO v$Script:Version  [HARDEN ONLY]   " -ForegroundColor White
        Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "Strict mode: $HardenStrict" -ForegroundColor Yellow
        Write-Host "WhatIf: $(if ($WhatIfPreference) { 'Enabled' } else { 'Disabled' })" -ForegroundColor $(if ($WhatIfPreference) { 'Yellow' } else { 'Green' })
        Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan

        Invoke-SecurityHardening
        Invoke-DcpExtensionHooks -Stage AfterOptimize
        Show-Summary -StartTime $Script:StartTime -HealthChecks $null
        Invoke-DcpExtensionHooks -Stage AfterSummary
        exit 0
    }
    
    # Display header
    Write-Host "`n════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "               DEEP CLEAN PRO v$Script:Version                 " -ForegroundColor White
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "Mode: $(if ($QuickMode) { 'Quick Optimization' } else { 'Full Optimization' })" -ForegroundColor Yellow
    Write-Host "Profile: $Profile" -ForegroundColor Yellow
    Write-Host "Harden: $(if ($HardenStrict) { 'Yes (Strict choices)' } elseif ($Harden) { 'Yes (safe set)' } else { 'No' })" -ForegroundColor Yellow
    Write-Host "Windows Updates: $(if ($RunWindowsUpdates) { 'Check + Install' } else { 'Check only' })" -ForegroundColor Yellow
    Write-Host "WhatIf: $(if ($WhatIfPreference) { 'Enabled (No changes will be made)' } else { 'Disabled' })" -ForegroundColor $(if ($WhatIfPreference) { 'Yellow' } else { 'Green' })
    Write-Host "════════════════════════════════════════════════════════════════`n" -ForegroundColor Cyan
    
    # System health check
    $healthChecks = $null
    if (-not $SkipHealth) {
        $healthChecks = Test-SystemHealth
        Invoke-DcpExtensionHooks -Stage AfterHealthCheck
    }

    Invoke-DcpExtensionHooks -Stage BeforeOptimize

    # Safety: restore point before Full (or when not Quick)
    if (-not $QuickMode) {
        New-DcpRestorePoint
    }
    
    # Core cleanup / optimizations
    Clear-TempFiles
    Clear-PrefetchCache
    Clear-DeliveryOptimizationCache
    Clear-RecycleBinSafe
    Clear-AppCaches
    Optimize-Services
    Optimize-SystemPerformance
    
    # Apply profile-specific optimizations
    if ($Profile -ne 'Balanced') {
        Apply-ProfileOptimizations -ProfileName $Profile
    }
    
    if (-not $QuickMode) {
        # Full optimization mode
        Clear-WindowsUpdateDownloadCache
        Remove-BloatwareApps
        Optimize-NetworkSettings
        Optimize-StartupPrograms
        Optimize-WindowsSearch
        Invoke-DiskCleanup
        Invoke-ComponentStoreCleanup
        Update-SystemDrivers
        
        # Defragmentation
        if (-not $SkipDefrag) {
            Write-ColorOutput "Starting disk defragmentation (this may take a while)..." -Type Info
            if ($PSCmdlet.ShouldProcess("C: Drive", "Defragment")) {
                Optimize-Volume -DriveLetter C -Defrag -Verbose
                Write-ColorOutput "Defragmentation completed" -Type Success
            }
        }
    } else {
        # Quick: still clear app caches + DO (already called above); skip aggressive WU download wipe / DISM
    }

    # Always check / report updates; install only when -RunWindowsUpdates
    Optimize-WindowsUpdates

    if ($Harden -or $HardenStrict) {
        Invoke-SecurityHardening
    }

    Invoke-DcpExtensionHooks -Stage AfterOptimize
    Invoke-DcpExtensionHooks -Stage BeforeSummary
    
    # Show summary
    Show-Summary -StartTime $Script:StartTime -HealthChecks $healthChecks

    Invoke-DcpExtensionHooks -Stage AfterSummary
    
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
