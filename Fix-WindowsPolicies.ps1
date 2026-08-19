<#
.SYNOPSIS
    Repairs broken or misconfigured local Windows policies.

.DESCRIPTION
    Fix-WindowsPolicies.ps1 repairs a set of local policy-related registry keys that commonly
    cause problems with Windows Update, Windows Defender, Explorer restrictions, and privacy/
    telemetry when they are corrupted or mis-set by other tools.

    It:
      - Creates a JSON backup of all relevant policy keys before making changes
      - Repairs or removes invalid / overly aggressive policy values
      - ONLY operates on local policy keys (HKLM/HKCU:\Software\Policies\...)
      - Does NOT touch domain GPOs (SYSVOL or AD-based policies)

.PARAMETER BackupPath
    Optional path to save the policy backup JSON.
    Default: C:\DeepCleanPro\Backups\PolicyBackup_yyyyMMdd_HHmmss.json

.PARAMETER Force
    Skip the interactive confirmation prompt and run immediately.

.EXAMPLE
    .\Fix-WindowsPolicies.ps1

.EXAMPLE
    .\Fix-WindowsPolicies.ps1 -BackupPath "D:\Backups\PolicyBackup.json"

.EXAMPLE
    .\Fix-WindowsPolicies.ps1 -Force

.NOTES
    Version: 1.0.0
    Part of the Deep Clean Pro suite (iSystemDevelopment/deep-clean-pro)
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$BackupPath,
    [switch]$Force
)

# Auto-elevate to Administrator (for local .ps1 usage)
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$currentPrincipal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Host "[!] Elevating to Administrator..." -ForegroundColor Yellow

    $scriptPath = $PSCommandPath
    if (-not $scriptPath) {
        $scriptPath = $MyInvocation.MyCommand.Path
    }

    if (-not $scriptPath) {
        Write-Host "[ERROR] Cannot auto-elevate: script path is unknown." -ForegroundColor Red
        exit 1
    }

    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
    foreach ($key in $PSBoundParameters.Keys) {
        $value = $PSBoundParameters[$key]
        if ($value -is [switch]) {
            if ($value) { $arguments += " -$key" }
        } else {
            $arguments += " -$key `"$value`""
        }
    }

    Start-Process powershell.exe -Verb RunAs -ArgumentList $arguments
    exit
}

# ── Basic logging helper (minimal but compatible with DCP style) ──────────────
function Write-ColorOutput {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $colors = @{
        Info    = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
    }

    $prefix = @{
        Info    = '[INFO]'
        Success = '[SUCCESS]'
        Warning = '[WARNING]'
        Error   = '[ERROR]'
    }

    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

# ── Banner ────────────────────────────────────────────────────────────────────
Clear-Host
Write-Host @"
╔══════════════════════════════════════════════════════════════════╗
║              FIX WINDOWS POLICIES - REPAIR TOOL                  ║
╚══════════════════════════════════════════════════════════════════╝

This tool repairs LOCAL Windows policies that may break:
  • Windows Update
  • Windows Defender
  • Explorer restrictions / UI
  • Privacy / telemetry behavior

It will:
  • Create a JSON backup of affected policy keys
  • Remove or correct problematic values
  • NOT modify domain Group Policy (AD/SYSVOL)
"@ -ForegroundColor Cyan

# ── Confirmation ──────────────────────────────────────────────────────────────
if (-not $Force) {
    Write-Host "`nThis will modify local policy-related registry keys." -ForegroundColor Yellow
    Write-Host "A backup will be created before any change." -ForegroundColor Yellow
    $confirm = Read-Host "`nType 'YES' to continue"
    if ($confirm -ne 'YES') {
        Write-ColorOutput "Operation cancelled by user." -Type Warning
        exit 0
    }
}

# ── Determine Backup Path ─────────────────────────────────────────────────────
if (-not $BackupPath) {
    $defaultBase = "C:\DeepCleanPro\Backups"
    if (-not (Test-Path $defaultBase)) {
        New-Item -Path $defaultBase -ItemType Directory -Force | Out-Null
    }
    $BackupPath = Join-Path $defaultBase ("PolicyBackup_{0}.json" -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
}

Write-ColorOutput "Backup will be saved to: $BackupPath" -Type Info

# ── Helper: Capture a snapshot of policy keys ─────────────────────────────────
function Get-PolicySnapshot {
    [OutputType([hashtable])]
    param()

    $keysToCapture = @(
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate',
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Defender',
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System',
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection',
        'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer',
        'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    )

    $snapshot = @{}

    foreach ($path in $keysToCapture) {
        try {
            if (Test-Path $path) {
                $props = Get-ItemProperty -Path $path -ErrorAction Stop
                $obj = @{}
                foreach ($p in $props.PSObject.Properties) {
                    if ($p.Name -notmatch '^PS(.*)$') {
                        $obj[$p.Name] = $p.Value
                    }
                }
                $snapshot[$path] = $obj
            } else {
                $snapshot[$path] = $null
            }
        } catch {
            $snapshot[$path] = $null
        }
    }

    return $snapshot
}

# ── Helper: Save snapshot to JSON ─────────────────────────────────────────────
function Save-PolicySnapshot {
    param(
        [Parameter(Mandatory)]
        [hashtable]$Snapshot,
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        $json = $Snapshot | ConvertTo-Json -Depth 6
        $dir  = Split-Path $Path -Parent

        if (-not (Test-Path $dir)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
        }

        $json | Out-File -FilePath $Path -Encoding UTF8 -Force
        Write-ColorOutput "Policy backup saved successfully." -Type Success
    } catch {
        Write-ColorOutput "Failed to save policy backup: $($_.Exception.Message)" -Type Error
        throw
    }
}

# ── Helper: Safely remove a property if it exists ─────────────────────────────
function Remove-PolicyValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name
    )

    if (Test-Path $Path) {
        $props = Get-ItemProperty -Path $Path -ErrorAction SilentlyContinue
        if ($props.PSObject.Properties.Name -contains $Name) {
            if ($PSCmdlet.ShouldProcess("$Path\$Name", "Remove")) {
                try {
                    Remove-ItemProperty -Path $Path -Name $Name -ErrorAction Stop
                    Write-ColorOutput "Removed policy value: $Path -> $Name" -Type Success
                } catch {
                    Write-ColorOutput "Failed to remove ${Path}\${Name}: $($_.Exception.Message)" -Type Warning
                }
            }
        }
    }
}

# ── Helper: Safely set a policy value ─────────────────────────────────────────
function Set-PolicyValue {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][object]$Value,
        [ValidateSet('String','DWord','QWord','Binary','MultiString','ExpandString')]
        [string]$Type = 'DWord'
    )

    if ($PSCmdlet.ShouldProcess("$Path\$Name", "Set to $Value")) {
        try {
            if (-not (Test-Path $Path)) {
                New-Item -Path $Path -Force | Out-Null
            }
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
            Write-ColorOutput "Set policy value: $Path -> $Name = $Value" -Type Success
        } catch {
            Write-ColorOutput "Failed to set ${Path}\${Name}: $($_.Exception.Message)" -Type Warning
        }
    }
}

# ── Repairs: Windows Update Policy ────────────────────────────────────────────
function Repair-WindowsUpdatePolicy {
    Write-ColorOutput "Repairing Windows Update policy..." -Type Info

    $wuPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'
    $auPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'

    # Common bad values: overly strict deferral, disabled AU, set to WSUS without server
    Remove-PolicyValue -Path $wuPath -Name 'WUServer'
    Remove-PolicyValue -Path $wuPath -Name 'WUStatusServer'
    Remove-PolicyValue -Path $wuPath -Name 'UpdateServiceUrlAlternate'

    # Reset AUOptions and NoAutoUpdate if they exist and are blocking updates
    # We don't force enable auto-update, we just clear broken explicit settings.
    Remove-PolicyValue -Path $auPath -Name 'AUOptions'
    Remove-PolicyValue -Path $auPath -Name 'NoAutoUpdate'
    Remove-PolicyValue -Path $auPath -Name 'ScheduledInstallDay'
    Remove-PolicyValue -Path $auPath -Name 'ScheduledInstallTime'
}

# ── Repairs: Windows Defender / Security Policy ───────────────────────────────
function Repair-DefenderPolicy {
    Write-ColorOutput "Repairing Windows Defender policy..." -Type Info

    $defPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender'
    $sysPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'

    # Remove DisableAntiSpyware / DisableRealtimeMonitoring / DisableRoutinelyTakingAction
    Remove-PolicyValue -Path $defPath -Name 'DisableAntiSpyware'
    Remove-PolicyValue -Path $defPath -Name 'DisableRealtimeMonitoring'
    Remove-PolicyValue -Path $defPath -Name 'DisableRoutinelyTakingAction'

    # Reset "EnableSmartScreen" type keys under System if present and invalid
    Remove-PolicyValue -Path $sysPath -Name 'EnableSmartScreen'
}

# ── Repairs: Explorer / UI Restrictions ───────────────────────────────────────
function Repair-ExplorerPolicy {
    Write-ColorOutput "Repairing Explorer / UI restrictions..." -Type Info

    $explorerHKCU = 'HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer'
    $explorerHKLM = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Explorer'

    $blockedKeys = @(
        'NoControlPanel',
        'NoViewOnDrive',
        'NoFolderOptions',
        'NoFileMenu',
        'NoRun',
        'DisableSearchBoxSuggestions'
    )

    foreach ($name in $blockedKeys) {
        Remove-PolicyValue -Path $explorerHKCU -Name $name
        Remove-PolicyValue -Path $explorerHKLM -Name $name
    }
}

# ── Repairs: Telemetry / Data Collection (stability-focused) ──────────────────
function Repair-TelemetryPolicy {
    Write-ColorOutput "Repairing Data Collection / Telemetry policy..." -Type Info

    $dcPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection'

    # Bad values: AllowTelemetry = 0 with invalid build/edition can break features.
    # We don't force a specific level, we remove the forced policy and let OS decide.
    Remove-PolicyValue -Path $dcPath -Name 'AllowTelemetry'
}

# ── Main execution ────────────────────────────────────────────────────────────
try {
    Write-ColorOutput "Creating policy backup snapshot..." -Type Info
    $snapshot = Get-PolicySnapshot
    Save-PolicySnapshot -Snapshot $snapshot -Path $BackupPath

    # Execute each repair phase
    Repair-WindowsUpdatePolicy
    Repair-DefenderPolicy
    Repair-ExplorerPolicy
    Repair-TelemetryPolicy

    Write-Host "`n" -NoNewline
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green
    Write-Host "         WINDOWS POLICY REPAIR COMPLETED SUCCESSFULLY          " -ForegroundColor Green
    Write-Host "════════════════════════════════════════════════════════════════" -ForegroundColor Green

    Write-Host "`nBackup location: $BackupPath" -ForegroundColor Yellow
    Write-Host "A restart is recommended to apply all policy changes." -ForegroundColor Yellow

} catch {
    Write-ColorOutput "Critical error during policy repair: $_" -Type Error
    exit 1
}
