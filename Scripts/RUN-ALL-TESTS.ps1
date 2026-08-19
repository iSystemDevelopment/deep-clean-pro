<#
.SYNOPSIS
    One-click test runner for Deep Clean Pro.

.DESCRIPTION
    Runs, in order:
      1. VALIDATE.ps1 (system / environment checks)
      2. Pester test suite in .\Tests
      3. PSScriptAnalyzer static analysis

    Produces a summary and exits with:
      0 on success, 1 if any step fails.
#>

[CmdletBinding()]
param(
    [switch]$SkipNetwork,     # Pass-through to VALIDATE.ps1 if needed
    [switch]$SkipAnalyzer,    # Skip PSScriptAnalyzer step
    [switch]$SilentValidate   # Run VALIDATE in silent mode
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$validateScript = Join-Path (Join-Path $root 'Scripts') 'VALIDATE.ps1'
$testsPath      = Join-Path $root 'Tests'

$overallFail = $false

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor White
    Write-Host "============================================================" -ForegroundColor Cyan
}

Write-Section "Deep Clean Pro - FULL TEST RUN"

# 1) VALIDATE.ps1
if (Test-Path $validateScript) {
    Write-Section "1) Running VALIDATE.ps1"

    $validateArgs = @()
    if ($SkipNetwork)   { $validateArgs += '-SkipNetwork' }
    if ($SilentValidate){ $validateArgs += '-Silent' }

    try {
        & $validateScript @validateArgs
        $validateExit = $LASTEXITCODE
    } catch {
        Write-Host "❌ VALIDATE.ps1 threw an exception: $($_.Exception.Message)" -ForegroundColor Red
        $validateExit = 1
    }

    if ($validateExit -ne 0) {
        Write-Host "❌ VALIDATE.ps1 reported failures (exit code $validateExit)." -ForegroundColor Red
        $overallFail = $true
    } else {
        Write-Host "✅ VALIDATE.ps1 completed successfully." -ForegroundColor Green
    }
} else {
    Write-Host "⚠ VALIDATE.ps1 not found at: $validateScript" -ForegroundColor Yellow
    $overallFail = $true
}

# 2) Pester tests
Write-Section "2) Running Pester tests (.\Tests)"

if (Test-Path $testsPath) {
    try {
        $pesterResult = Invoke-Pester -Path $testsPath -Output Detailed -PassThru
        if ($pesterResult.FailedCount -gt 0) {
            Write-Host "❌ Pester tests failed: $($pesterResult.FailedCount) test(s) failed." -ForegroundColor Red
            $overallFail = $true
        } else {
            Write-Host "✅ All Pester tests passed." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Error while running Pester tests: $($_.Exception.Message)" -ForegroundColor Red
        $overallFail = $true
    }
} else {
    Write-Host "⚠ Tests folder not found at: $testsPath" -ForegroundColor Yellow
    $overallFail = $true
}

# 3) PSScriptAnalyzer
Write-Section "3) Running PSScriptAnalyzer (static analysis)"

if (-not $SkipAnalyzer) {
    try {
        $analysis = Invoke-ScriptAnalyzer -Path $root -Recurse -ErrorAction Stop
        if ($analysis -and $analysis.Count -gt 0) {
            Write-Host "⚠ PSScriptAnalyzer reported $($analysis.Count) issue(s):" -ForegroundColor Yellow
            $analysis | Format-Table -AutoSize
            # Not treating analyzer warnings as fatal by default
        } else {
            Write-Host "✅ PSScriptAnalyzer found no issues." -ForegroundColor Green
        }
    } catch {
        Write-Host "❌ Error while running PSScriptAnalyzer: $($_.Exception.Message)" -ForegroundColor Red
        # Analyzer failures are not considered critical for exit code unless you want them to be
        # $overallFail = $true
    }
} else {
    Write-Host "⏭ Skipping PSScriptAnalyzer (per parameter)." -ForegroundColor Yellow
}

# Final summary
Write-Section "FINAL SUMMARY"

if ($overallFail) {
    Write-Host "❌ One or more critical checks/tests failed." -ForegroundColor Red
    Write-Host "   - Check VALIDATE output and Pester results above." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "✅ All critical checks/tests passed." -ForegroundColor Green
    Write-Host "   Deep Clean Pro is READY for release / use." -ForegroundColor Green
    exit 0
}
