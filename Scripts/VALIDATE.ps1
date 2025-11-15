<#
.SYNOPSIS
    Deep Clean Pro - Environment & System Validator

.DESCRIPTION
    VALIDATE.ps1 checks whether the current system is ready to safely run Deep Clean Pro.
    It performs non-destructive checks only:

      - OS version (Windows 10 / 11)
      - PowerShell version (5.1+)
      - Administrator privileges
      - Execution policy compatibility
      - TLS 1.2 availability
      - Folder & file structure (DeepCleanPro.ps1, helpers, Backups, Logs)
      - Optional network connectivity to GitHub

    At the end it prints a summary and exits with:

      - 0 if all critical checks pass
      - 1 if any critical check fails

.PARAMETER RootPath
    Path to the Deep Clean Pro installation directory.
    Default: C:\DeepCleanPro

.PARAMETER SkipNetwork
    Skip network connectivity checks (useful for offline environments).

.PARAMETER Silent
    Suppress detailed output, show only final summary (useful for CI).

.EXAMPLE
    C:\DeepCleanPro\Scripts\VALIDATE.ps1

.EXAMPLE
    .\VALIDATE.ps1 -SkipNetwork

.EXAMPLE
    .\VALIDATE.ps1 -RootPath "D:\Tools\DeepCleanPro" -Silent
#>

[CmdletBinding()]
param(
    [string]$RootPath = "C:\DeepCleanPro",
    [switch]$SkipNetwork,
    [switch]$Silent
)

#Requires -Version 5.1

# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

$Script:Checks       = @()
$Script:CriticalFail = $false

function Add-CheckResult {
    param(
        [string]$Name,
        [ValidateSet('Pass','Warn','Fail')]
        [string]$Status,
        [string]$Detail = ''
    )

    $Script:Checks += [PSCustomObject]@{
        Name   = $Name
        Status = $Status
        Detail = $Detail
    }

    if ($Status -eq 'Fail') {
        $Script:CriticalFail = $true
    }

    if ($Silent) { return }

    switch ($Status) {
        'Pass' { $color = 'Green';  $icon = '✅' }
        'Warn' { $color = 'Yellow'; $icon = '⚠ ' }
        'Fail' { $color = 'Red';    $icon = '❌' }
    }

    if ($Detail) {
        Write-Host ("{0} {1} - {2}" -f $icon, $Name, $Detail) -ForegroundColor $color
    } else {
        Write-Host ("{0} {1}" -f $icon, $Name) -ForegroundColor $color
    }
}

function Write-Header {
    if ($Silent) { return }

    Clear-Host
    Write-Host "╔══════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║              DEEP CLEAN PRO - VALIDATION TOOL                ║" -ForegroundColor Cyan
    Write-Host "╚══════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Root path: $RootPath" -ForegroundColor Gray
    if ($SkipNetwork) {
        Write-Host "Network checks: SKIPPED" -ForegroundColor Yellow
    } else {
        Write-Host "Network checks: ENABLED" -ForegroundColor Gray
    }
    Write-Host ""
}

# ─────────────────────────────────────────────────────────────────────────────
# Checks
# ─────────────────────────────────────────────────────────────────────────────

Write-Header

# 1) OS Version
try {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
    $caption = $os.Caption
    $version = [version]$os.Version

    if ($caption -notmatch 'Windows 10|Windows 11') {
        Add-CheckResult -Name "OS Version" -Status Fail -Detail "Unsupported OS: $caption ($($os.Version)). Windows 10 or 11 required."
    } elseif ($version.Major -lt 10) {
        Add-CheckResult -Name "OS Version" -Status Fail -Detail "Unsupported OS version: $($os.Version). Windows 10 or 11 required."
    } else {
        Add-CheckResult -Name "OS Version" -Status Pass -Detail "$caption ($($os.Version))"
    }
} catch {
    Add-CheckResult -Name "OS Version" -Status Warn -Detail "Could not query OS version: $($_.Exception.Message)"
}

# 2) PowerShell Version
try {
    $psv = $PSVersionTable.PSVersion
    if ($psv.Major -lt 5 -or ($psv.Major -eq 5 -and $psv.Minor -lt 1)) {
        Add-CheckResult -Name "PowerShell Version" -Status Fail -Detail "Found $psv. PowerShell 5.1 or later is required."
    } else {
        Add-CheckResult -Name "PowerShell Version" -Status Pass -Detail "PowerShell $psv"
    }
} catch {
    Add-CheckResult -Name "PowerShell Version" -Status Warn -Detail "Could not read PSVersionTable: $($_.Exception.Message)"
}

# 3) Administrator Privileges
try {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin   = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    if ($isAdmin) {
        Add-CheckResult -Name "Administrator Privileges" -Status Pass -Detail "Running as Administrator"
    } else {
        Add-CheckResult -Name "Administrator Privileges" -Status Fail -Detail "Not running as Administrator. Deep Clean Pro requires admin rights."
    }
} catch {
    Add-CheckResult -Name "Administrator Privileges" -Status Warn -Detail "Could not determine admin status: $($_.Exception.Message)"
}

# 4) Execution Policy (CurrentUser / Process)
try {
    $epProcess = Get-ExecutionPolicy -Scope Process -ErrorAction SilentlyContinue
    $epUser    = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction SilentlyContinue

    # We don't enforce a specific policy, just warn if it's too restrictive
    if ($epProcess -eq 'Undefined') {
        Add-CheckResult -Name "Execution Policy (Process)" -Status Pass -Detail "Undefined (Deep Clean Pro sets a safe process-level policy)"
    } else {
        Add-CheckResult -Name "Execution Policy (Process)" -Status Pass -Detail $epProcess
    }

    if ($epUser -in 'Restricted','AllSigned') {
        Add-CheckResult -Name "Execution Policy (CurrentUser)" -Status Warn -Detail "$epUser (scripts may require Bypass/RemoteSigned in this session)"
    } else {
        Add-CheckResult -Name "Execution Policy (CurrentUser)" -Status Pass -Detail $epUser
    }
} catch {
    Add-CheckResult -Name "Execution Policy" -Status Warn -Detail "Could not query ExecutionPolicy: $($_.Exception.Message)"
}

# 5) TLS 1.2 Availability
try {
    # Try to enable TLS 1.2 for this session
    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol `
        -bor [Net.SecurityProtocolType]::Tls12

    if ([Net.ServicePointManager]::SecurityProtocol -band [Net.SecurityProtocolType]::Tls12) {
        Add-CheckResult -Name "TLS 1.2 Support" -Status Pass -Detail "TLS 1.2 is enabled for this session"
    } else {
        Add-CheckResult -Name "TLS 1.2 Support" -Status Warn -Detail "TLS 1.2 could not be enabled. Online features may fail."
    }
} catch {
    Add-CheckResult -Name "TLS 1.2 Support" -Status Warn -Detail "Error while checking TLS: $($_.Exception.Message)"
}

# 6) Root Path & Core Files
try {
    if (-not (Test-Path $RootPath)) {
        Add-CheckResult -Name "Root Path" -Status Fail -Detail "Directory does not exist: $RootPath"
    } else {
        Add-CheckResult -Name "Root Path" -Status Pass -Detail $RootPath
    }

    $coreFiles = @(
        'DeepCleanPro.ps1',
        'Fix-WindowsPolicies.ps1',
        'OneDriveNuke.ps1',
        'Scripts\VALIDATE.ps1'
    )

    foreach ($rel in $coreFiles) {
        $full = Join-Path $RootPath $rel
        if (Test-Path $full) {
            Add-CheckResult -Name "File: $rel" -Status Pass -Detail "Found"
        } else {
            Add-CheckResult -Name "File: $rel" -Status Fail -Detail "Missing at $full"
        }
    }
} catch {
    Add-CheckResult -Name "Root Path / Files" -Status Warn -Detail "Error checking files: $($_.Exception.Message)"
}

# 7) Folders: Backups, Logs, Scripts
try {
    $folders = @(
        'Backups',
        'Logs',
        'Scripts'
    )

    foreach ($f in $folders) {
        $full = Join-Path $RootPath $f
        if (Test-Path $full) {
            # Also check write access
            try {
                $testFile = Join-Path $full "validate_test_$([guid]::NewGuid().ToString('N')).tmp"
                'test' | Out-File -FilePath $testFile -Encoding ASCII -Force
                Remove-Item $testFile -Force -ErrorAction SilentlyContinue
                Add-CheckResult -Name "Folder: $f" -Status Pass -Detail "Exists and writable"
            } catch {
                Add-CheckResult -Name "Folder: $f" -Status Warn -Detail "Exists but write failed: $($_.Exception.Message)"
            }
        } else {
            Add-CheckResult -Name "Folder: $f" -Status Warn -Detail "Missing: $full (will be created on first run)"
        }
    }
} catch {
    Add-CheckResult -Name "Folder Structure" -Status Warn -Detail "Error checking folders: $($_.Exception.Message)"
}

# 8) Optional: Network Connectivity (GitHub)
if (-not $SkipNetwork) {
    try {
        $ok = $false
        $targets = @(
            'https://raw.githubusercontent.com',
            'https://github.com'
        )

        foreach ($t in $targets) {
            try {
                $resp = Invoke-WebRequest -Uri $t -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
                if ($resp.StatusCode -ge 200 -and $resp.StatusCode -lt 400) {
                    $ok = $true
                    break
                }
            } catch {
                # Ignore individual host failures, we only care if ALL fail
            }
        }

        if ($ok) {
            Add-CheckResult -Name "Network / GitHub" -Status Pass -Detail "GitHub reachable"
        } else {
            Add-CheckResult -Name "Network / GitHub" -Status Warn -Detail "Could not reach GitHub. Online features may not work."
        }
    } catch {
        Add-CheckResult -Name "Network / GitHub" -Status Warn -Detail "Error during network check: $($_.Exception.Message)"
    }
} else {
    Add-CheckResult -Name "Network / GitHub" -Status Warn -Detail "Network checks skipped by user"
}

# 9) Optional: Pester / PSScriptAnalyzer presence (soft checks)
try {
    $pester = Get-Module -ListAvailable -Name Pester | Select-Object -First 1
    if ($pester) {
        Add-CheckResult -Name "Pester Module" -Status Pass -Detail "Found: $($pester.Version)"
    } else {
        Add-CheckResult -Name "Pester Module" -Status Warn -Detail "Pester not installed. Tests may be unavailable."
    }
} catch {
    Add-CheckResult -Name "Pester Module" -Status Warn -Detail "Error checking Pester: $($_.Exception.Message)"
}

try {
    $pssa = Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1
    if ($pssa) {
        Add-CheckResult -Name "PSScriptAnalyzer Module" -Status Pass -Detail "Found: $($pssa.Version)"
    } else {
        Add-CheckResult -Name "PSScriptAnalyzer Module" -Status Warn -Detail "PSScriptAnalyzer not installed. Static analysis may be unavailable."
    }
} catch {
    Add-CheckResult -Name "PSScriptAnalyzer Module" -Status Warn -Detail "Error checking PSScriptAnalyzer: $($_.Exception.Message)"
}

# ─────────────────────────────────────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────────────────────────────────────

if (-not $Silent) {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                    VALIDATION SUMMARY                         " -ForegroundColor White
    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

    $pass = $Script:Checks | Where-Object Status -eq 'Pass'
    $warn = $Script:Checks | Where-Object Status -eq 'Warn'
    $fail = $Script:Checks | Where-Object Status -eq 'Fail'

    Write-Host ("Passed : {0}" -f $pass.Count) -ForegroundColor Green
    Write-Host ("Warnings: {0}" -f $warn.Count) -ForegroundColor Yellow
    Write-Host ("Failed : {0}" -f $fail.Count) -ForegroundColor Red

    Write-Host "═══════════════════════════════════════════════════════════════" -ForegroundColor Cyan

    if ($fail.Count -eq 0) {
        Write-Host "`n✅ Deep Clean Pro can run on this system." -ForegroundColor Green

        if ($warn.Count -gt 0) {
            Write-Host "⚠ Some non-critical issues were detected. Review the warnings above." -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n❌ One or more critical issues detected. Fix them before running Deep Clean Pro." -ForegroundColor Red
    }
}

if ($Script:CriticalFail) {
    exit 1
} else {
    exit 0
}
