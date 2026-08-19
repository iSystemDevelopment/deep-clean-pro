<#
.SYNOPSIS
    Elevates and runs Deep Clean Pro using a temp download (no iex).

.DESCRIPTION
    Shared launcher used by Control-center.bat and Shortcuts\*.bat.
    Prefers local C:\DeepCleanPro\DeepCleanPro.ps1 when present; otherwise downloads
    the script to a temp file and Start-Process -Verb RunAs -File.

.NOTES
    Version: 1.0.0
#>

[CmdletBinding()]
param(
    [ValidateSet('Balanced', 'Gaming', 'Development', 'Music', 'Video', 'Office')]
    [string]$Profile,

    [switch]$QuickMode,
    [switch]$NoReboot,
    [switch]$RunWindowsUpdates,
    [switch]$WhatIf,
    [switch]$LocalOnly,
    [switch]$Harden,
    [switch]$HardenStrict,
    [switch]$HardenOnly,
    [switch]$DisableRdp,
    [switch]$DisableWinRm,
    [switch]$DisableLlmnr,
    [switch]$DisablePowershellV2,
    [switch]$EnableAsrRules
)

$ErrorActionPreference = 'Stop'
$repoUrl = 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'
$localPath = 'C:\DeepCleanPro\DeepCleanPro.ps1'

function Test-IsAdmin {
    $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

try {
    $scriptFile = $null

    if (Test-Path -LiteralPath $localPath) {
        $scriptFile = $localPath
    } elseif (-not $LocalOnly) {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $scriptFile = Join-Path $env:TEMP ("DeepCleanPro_{0}.ps1" -f [guid]::NewGuid().ToString('N'))
        Invoke-WebRequest -Uri $repoUrl -OutFile $scriptFile -UseBasicParsing
    }

    if (-not $scriptFile -or -not (Test-Path -LiteralPath $scriptFile)) {
        throw "DeepCleanPro.ps1 not found (local missing and download skipped/failed)."
    }

    $passArgs = @()
    if ($Profile)              { $passArgs += @('-Profile', $Profile) }
    if ($QuickMode)            { $passArgs += '-QuickMode' }
    if ($NoReboot)             { $passArgs += '-NoReboot' }
    if ($RunWindowsUpdates)    { $passArgs += '-RunWindowsUpdates' }
    if ($WhatIf)               { $passArgs += '-WhatIf' }
    if ($Harden)               { $passArgs += '-Harden' }
    if ($HardenStrict)         { $passArgs += '-HardenStrict' }
    if ($HardenOnly)           { $passArgs += '-HardenOnly' }
    if ($DisableRdp)           { $passArgs += '-DisableRdp' }
    if ($DisableWinRm)         { $passArgs += '-DisableWinRm' }
    if ($DisableLlmnr)         { $passArgs += '-DisableLlmnr' }
    if ($DisablePowershellV2)  { $passArgs += '-DisablePowershellV2' }
    if ($EnableAsrRules)       { $passArgs += '-EnableAsrRules' }

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $scriptFile) + $passArgs

    if (Test-IsAdmin) {
        & powershell.exe @argList
    } else {
        # Quote file path for elevated cmdline
        $quoted = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$scriptFile`"") + $passArgs
        Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList ($quoted -join ' ') -Wait:$false
    }

    Write-Host '[OK] Deep Clean Pro launch requested.' -ForegroundColor Green
    exit 0
}
catch {
    Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
    Start-Sleep -Seconds 4
    exit 1
}
