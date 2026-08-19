<#
.SYNOPSIS
    Deep Clean Pro - GitHub Gist launcher

.DESCRIPTION
    Downloads and runs the latest DeepCleanPro.ps1 from GitHub.
    Publish this file to your Gist as DeepCleanPro-Launcher.ps1:

        irm 'https://gist.githubusercontent.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7/raw/DeepCleanPro-Launcher.ps1' | iex

    Environment variables (optional, set before irm):
      DCP_PROFILE          Balanced | Gaming | Development | Music | Video | Office
      DCP_QUICK_MODE       true
      DCP_NO_REBOOT        true
      DCP_RUN_UPDATES      true
      DCP_SKIP_EXTENSIONS  true
      DCP_HARDEN           true
      DCP_HARDEN_STRICT    true
      DCP_NO_PAUSE         true  (skip Enter-to-exit)

.NOTES
    Launcher: 1.0.3  |  Deep Clean Pro target: 2.5.0+
    Gist: https://gist.github.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7
#>

[CmdletBinding(SupportsShouldProcess)]
param()

$Script:Config = @{
    RepoUrl    = 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'
    Timeout    = 30
    RetryCount = 3
    RetryDelay = 2
    MinBytes   = 1000
    GistUrl    = 'https://gist.githubusercontent.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7/raw/DeepCleanPro-Launcher.ps1'
}

function Write-LauncherMessage {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $prefix = @{
        Info    = '[LAUNCHER]'
        Success = '[SUCCESS]'
        Warning = '[WARNING]'
        Error   = '[ERROR]'
    }
    $colors = @{
        Info    = 'Cyan'
        Success = 'Green'
        Warning = 'Yellow'
        Error   = 'Red'
    }

    Write-Host "$($prefix[$Type]) $Message" -ForegroundColor $colors[$Type]
}

function Test-AdminPrivileges {
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri 'https://raw.githubusercontent.com' -Method Head -TimeoutSec 5 -UseBasicParsing -ErrorAction Stop
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Get-ScriptFromGitHub {
    param(
        [Parameter(Mandatory)]
        [string]$Url,
        [string]$Description = 'script'
    )

    $attempt = 0
    $content = $null

    while ($attempt -lt $Script:Config.RetryCount) {
        $attempt++
        try {
            Write-LauncherMessage "Downloading $Description (attempt $attempt/$($Script:Config.RetryCount))..." -Type Info

            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec $Script:Config.Timeout -ErrorAction Stop

            if ($response.StatusCode -eq 200 -and $response.Content) {
                $content = $response.Content
                Write-LauncherMessage "Downloaded $Description ($($content.Length) bytes)" -Type Success
                return $content
            }

            throw 'Invalid response from server'
        } catch {
            Write-LauncherMessage "Download failed: $_" -Type Warning
            if ($attempt -lt $Script:Config.RetryCount) {
                Start-Sleep -Seconds $Script:Config.RetryDelay
            }
        }
    }

    throw "Failed to download $Description after $($Script:Config.RetryCount) attempts"
}

function Get-DcpLaunchArguments {
    $arguments = @()

    if ($env:DCP_PROFILE) {
        $arguments += '-Profile'
        $arguments += $env:DCP_PROFILE
        Write-LauncherMessage "Profile: $($env:DCP_PROFILE)" -Type Info
    }

    if ($env:DCP_QUICK_MODE -eq 'true') {
        $arguments += '-QuickMode'
        Write-LauncherMessage 'Quick Mode enabled' -Type Info
    }

    if ($env:DCP_NO_REBOOT -eq 'true') {
        $arguments += '-NoReboot'
        Write-LauncherMessage 'Auto-reboot disabled' -Type Info
    }

    if ($env:DCP_RUN_UPDATES -eq 'true') {
        $arguments += '-RunWindowsUpdates'
        Write-LauncherMessage 'Windows Updates enabled' -Type Info
    }

    if ($env:DCP_SKIP_EXTENSIONS -eq 'true') {
        $arguments += '-SkipExtensions'
        Write-LauncherMessage 'Extensions skipped' -Type Info
    }

    if ($env:DCP_HARDEN -eq 'true') {
        $arguments += '-Harden'
        Write-LauncherMessage 'Security hardening enabled' -Type Info
    }

    if ($env:DCP_HARDEN_STRICT -eq 'true') {
        $arguments += '-HardenStrict'
        Write-LauncherMessage 'Strict hardening enabled' -Type Info
    }

    if ($WhatIfPreference) {
        $arguments += '-WhatIf'
        Write-LauncherMessage 'WhatIf mode - no changes will be made' -Type Warning
    }

    return $arguments
}

function Invoke-DeepCleanPro {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptContent
    )

    $tempFile = Join-Path $env:TEMP ("DeepCleanPro_" + [guid]::NewGuid().ToString('N') + '.ps1')

    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($tempFile, $ScriptContent, $utf8NoBom)

        $arguments = Get-DcpLaunchArguments

        Write-LauncherMessage 'Executing Deep Clean Pro...' -Type Info
        Write-Host '================================================================' -ForegroundColor Cyan

        if ($arguments.Count -gt 0) {
            & $tempFile @arguments
        } else {
            & $tempFile
        }

        Write-Host '================================================================' -ForegroundColor Cyan
        Write-LauncherMessage 'Deep Clean Pro finished' -Type Success
    } catch {
        Write-LauncherMessage "Execution failed: $_" -Type Error
        throw
    } finally {
        if (Test-Path $tempFile) {
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
        }
    }
}

function Show-LauncherHeader {
    Write-Host @'
================================================================
        DEEP CLEAN PRO - GIST LAUNCHER v1.0.3
        Target engine: v2.5.0+ on GitHub main
================================================================
'@ -ForegroundColor Cyan
}

function Show-ErrorHelp {
    Write-Host ''
    Write-Host 'Troubleshooting:' -ForegroundColor Yellow
    Write-Host "  1. Run PowerShell as Administrator" -ForegroundColor Gray
    Write-Host '  2. Check internet / corporate firewall for raw.githubusercontent.com' -ForegroundColor Gray
    Write-Host "  3. Open engine URL: $($Script:Config.RepoUrl)" -ForegroundColor Gray
    Write-Host "  4. Gist launcher: $($Script:Config.GistUrl)" -ForegroundColor Gray
    Write-Host '  5. Profiles: Balanced, Gaming, Development, Music, Video, Office' -ForegroundColor Gray
}

function Test-DownloadedScript {
    param([string]$Content)

    if ($Content.Length -lt $Script:Config.MinBytes) {
        throw 'Downloaded script too small - likely truncated or blocked'
    }

    if ($Content -notmatch 'Deep Clean Pro') {
        throw 'Downloaded content does not look like Deep Clean Pro'
    }

    if ($Content -notmatch '\$Script:Version\s*=\s*"[2-9]\.') {
        Write-LauncherMessage 'Version marker not recognized - continuing anyway' -Type Warning
    }
}

# --- Main ---
try {
    Clear-Host
    Show-LauncherHeader

    Write-LauncherMessage 'Checking prerequisites...' -Type Info

    if (-not (Test-AdminPrivileges)) {
        Write-LauncherMessage 'Administrator privileges required' -Type Warning
        Write-Host ''
        Write-Host 'Right-click PowerShell and choose Run as administrator.' -ForegroundColor Yellow
        if (-not $env:DCP_NO_PAUSE) { Read-Host 'Press Enter to exit' }
        exit 1
    }

    Write-LauncherMessage 'Administrator OK' -Type Success

    if (-not (Test-InternetConnection)) {
        throw 'Cannot reach raw.githubusercontent.com - check network or proxy'
    }

    Write-LauncherMessage 'Network OK' -Type Success

    $scriptContent = Get-ScriptFromGitHub -Url $Script:Config.RepoUrl -Description 'DeepCleanPro.ps1'
    Test-DownloadedScript -Content $scriptContent
    Invoke-DeepCleanPro -ScriptContent $scriptContent

    if (-not $env:DCP_NO_PAUSE) {
        Write-Host ''
        Read-Host 'Press Enter to exit'
    }

    exit 0
} catch {
    Write-LauncherMessage "Critical error: $_" -Type Error
    Show-ErrorHelp
    Write-Host ''
    Read-Host 'Press Enter to exit'
    exit 1
}
