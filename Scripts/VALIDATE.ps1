<#
.SYNOPSIS
    Deep Clean Pro - Comprehensive Validation Script
.DESCRIPTION
    Validates system compatibility, prerequisites, and Deep Clean Pro installation integrity.
.PARAMETER Silent
    Run without displaying detailed output
.PARAMETER ReturnResults
    Return results as an object instead of displaying
.EXAMPLE
    .\VALIDATE.ps1
    Run interactive validation with detailed output
.EXAMPLE
    .\VALIDATE.ps1 -Silent -ReturnResults
    Run silent validation and return results object
#>

[CmdletBinding()]
param(
    [switch]$Silent,
    [switch]$ReturnResults
)

# Validation configuration
$Script:Version = "1.0.0"
$Script:TestResults = @()
$Script:FailedTests = @()
$Script:Warnings = @()

function Write-ValidationOutput {
    param(
        [string]$Message,
        [ValidateSet('Header', 'Info', 'Success', 'Warning', 'Error', 'Test')]
        [string]$Type = 'Info'
    )
    
    if ($Silent) { return }
    
    switch ($Type) {
        'Header' {
            Write-Host $Message -ForegroundColor Cyan
        }
        'Info' {
            Write-Host "ℹ️  $Message" -ForegroundColor Gray
        }
        'Success' {
            Write-Host "✅ $Message" -ForegroundColor Green
        }
        'Warning' {
            Write-Host "⚠️  $Message" -ForegroundColor Yellow
        }
        'Error' {
            Write-Host "❌ $Message" -ForegroundColor Red
        }
        'Test' {
            Write-Host "🔍 $Message" -ForegroundColor Cyan
        }
    }
}

function Test-Requirement {
    param(
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [scriptblock]$Test,
        [string]$Description = "",
        [switch]$Critical,
        [switch]$Warning
    )
    
    Write-ValidationOutput "Testing: $Name" -Type Test
    
    try {
        $result = & $Test
        $passed = [bool]$result
        
        $testResult = [PSCustomObject]@{
            Name = $Name
            Description = $Description
            Passed = $passed
            Critical = $Critical
            Warning = $Warning
            Error = $null
        }
        
        if ($passed) {
            Write-ValidationOutput "$Name - PASSED" -Type Success
        } else {
            if ($Critical) {
                Write-ValidationOutput "$Name - FAILED (Critical)" -Type Error
                $Script:FailedTests += $Name
            } elseif ($Warning) {
                Write-ValidationOutput "$Name - FAILED (Warning)" -Type Warning
                $Script:Warnings += $Name
            } else {
                Write-ValidationOutput "$Name - FAILED" -Type Error
                $Script:FailedTests += $Name
            }
        }
        
        $Script:TestResults += $testResult
        return $passed
    } catch {
        $testResult = [PSCustomObject]@{
            Name = $Name
            Description = $Description
            Passed = $false
            Critical = $Critical
            Warning = $Warning
            Error = $_.Exception.Message
        }
        
        Write-ValidationOutput "$Name - ERROR: $_" -Type Error
        $Script:TestResults += $testResult
        $Script:FailedTests += $Name
        return $false
    }
}

# Start validation
if (-not $Silent) {
    Clear-Host
    Write-ValidationOutput @"
╔══════════════════════════════════════════════════════════════╗
║        DEEP CLEAN PRO - SYSTEM VALIDATION v$($Script:Version)         ║
╚══════════════════════════════════════════════════════════════╝
"@ -Type Header
}

Write-ValidationOutput "`n=== SYSTEM REQUIREMENTS ===" -Type Header

# 1. Administrator Privileges
Test-Requirement -Name "Administrator Privileges" -Critical -Test {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} -Description "Script requires administrator privileges to function"

# 2. PowerShell Version
Test-Requirement -Name "PowerShell Version" -Critical -Test {
    $PSVersionTable.PSVersion.Major -ge 5 -and $PSVersionTable.PSVersion.Minor -ge 1
} -Description "PowerShell 5.1 or higher required"

# 3. Operating System
Test-Requirement -Name "Windows OS" -Critical -Test {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    $os.Caption -match "Windows" -and [int]$os.BuildNumber -ge 14393  # Windows 10 1607 minimum
} -Description "Windows 10 version 1607 or higher required"

# 4. .NET Framework
Test-Requirement -Name ".NET Framework" -Warning -Test {
    $release = Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full\" -Name Release -ErrorAction SilentlyContinue
    $release.Release -ge 461808  # .NET 4.7.2
} -Description ".NET Framework 4.7.2 or higher recommended"

Write-ValidationOutput "`n=== POWERSHELL CONFIGURATION ===" -Type Header

# 5. Execution Policy
Test-Requirement -Name "Execution Policy" -Test {
    $policy = Get-ExecutionPolicy -Scope CurrentUser
    $policy -in @('RemoteSigned', 'Unrestricted', 'Bypass')
} -Description "Execution policy must allow script execution"

# 6. Script Block Logging
Test-Requirement -Name "Script Block Logging" -Warning -Test {
    $regPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging"
    if (Test-Path $regPath) {
        $value = Get-ItemProperty -Path $regPath -Name "EnableScriptBlockLogging" -ErrorAction SilentlyContinue
        $value.EnableScriptBlockLogging -eq 1
    } else {
        $false  # Not configured is acceptable
    }
} -Description "Script block logging recommended for security"

# 7. Environment Variables
Test-Requirement -Name "Environment Variable Support" -Test {
    # Test setting and reading environment variable
    $testVar = "DCP_TEST_$(Get-Random)"
    [System.Environment]::SetEnvironmentVariable($testVar, "test", "Process")
    $result = [System.Environment]::GetEnvironmentVariable($testVar, "Process") -eq "test"
    [System.Environment]::SetEnvironmentVariable($testVar, $null, "Process")
    $result
} -Description "Environment variables required for configuration"

Write-ValidationOutput "`n=== SYSTEM RESOURCES ===" -Type Header

# 8. Disk Space
Test-Requirement -Name "Disk Space" -Test {
    $drive = Get-PSDrive -Name C
    ($drive.Free / 1GB) -gt 1  # At least 1GB free
} -Description "Minimum 1GB free disk space required"

# 9. Memory
Test-Requirement -Name "Available Memory" -Warning -Test {
    $os = Get-CimInstance -ClassName Win32_OperatingSystem
    ($os.FreePhysicalMemory / 1MB) -gt 500  # At least 500MB free
} -Description "Minimum 500MB free memory recommended"

# 10. CPU Architecture
Test-Requirement -Name "CPU Architecture" -Test {
    $env:PROCESSOR_ARCHITECTURE -in @('AMD64', 'x64', 'IA64')
} -Description "64-bit processor required"

Write-ValidationOutput "`n=== REQUIRED FEATURES ===" -Type Header

# 11. Windows Management Framework
Test-Requirement -Name "WMF/PowerShell Core Features" -Test {
    Get-Command -Name Get-CimInstance -ErrorAction SilentlyContinue
} -Description "Windows Management Framework required"

# 12. NuGet Provider
Test-Requirement -Name "NuGet Package Provider" -Warning -Test {
    Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
} -Description "NuGet provider recommended for module installation"

# 13. Windows Defender
Test-Requirement -Name "Windows Defender Access" -Warning -Test {
    Get-Command -Name Get-MpComputerStatus -ErrorAction SilentlyContinue
} -Description "Windows Defender cmdlets recommended for security checks"

Write-ValidationOutput "`n=== NETWORK & SECURITY ===" -Type Header

# 14. TLS 1.2 Support
Test-Requirement -Name "TLS 1.2 Support" -Test {
    try {
        [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
        $true
    } catch {
        $false
    }
} -Description "TLS 1.2 required for secure downloads"

# 15. Internet Connectivity
Test-Requirement -Name "Internet Connectivity" -Warning -Test {
    Test-Connection -ComputerName "8.8.8.8" -Count 1 -Quiet -ErrorAction SilentlyContinue
} -Description "Internet connection recommended for updates"

# 16. GitHub Access
Test-Requirement -Name "GitHub Access" -Warning -Test {
    try {
        $response = Invoke-WebRequest -Uri "https://api.github.com" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
        $response.StatusCode -eq 200
    } catch {
        $false
    }
} -Description "GitHub access recommended for updates"

Write-ValidationOutput "`n=== FILE SYSTEM ACCESS ===" -Type Header

# 17. Temp Directory Access
Test-Requirement -Name "Temp Directory Access" -Test {
    $testFile = Join-Path $env:TEMP "dcp_test_$(Get-Random).txt"
    try {
        "test" | Out-File -FilePath $testFile -Force
        Remove-Item -Path $testFile -Force
        $true
    } catch {
        $false
    }
} -Description "Write access to temp directory required"

# 18. Program Files Access
Test-Requirement -Name "System Directory Access" -Warning -Test {
    # Check if we can read from system directories
    Test-Path "$env:ProgramFiles"
} -Description "Access to system directories recommended"

# 19. Registry Access
Test-Requirement -Name "Registry Access" -Test {
    try {
        Get-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -Name CurrentBuild -ErrorAction Stop
        $true
    } catch {
        $false
    }
} -Description "Registry read access required"

Write-ValidationOutput "`n=== DEEP CLEAN PRO FILES ===" -Type Header

# 20. Main Script
$scriptPath = Join-Path (Split-Path $PSScriptRoot -Parent) "DeepCleanPro.ps1"
Test-Requirement -Name "Main Script Present" -Critical -Test {
    Test-Path $scriptPath
} -Description "DeepCleanPro.ps1 must be present"

# 21. Policy Helper Script
$policyScript = Join-Path (Split-Path $PSScriptRoot -Parent) "Fix-WindowsPolicies.ps1"
Test-Requirement -Name "Policy Helper Script" -Warning -Test {
    Test-Path $policyScript
} -Description "Fix-WindowsPolicies.ps1 recommended"

# 22. Script Syntax Validation
if (Test-Path $scriptPath) {
    Test-Requirement -Name "Script Syntax Valid" -Critical -Test {
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize((Get-Content $scriptPath -Raw), [ref]$errors)
        $errors.Count -eq 0
    } -Description "Main script must have valid PowerShell syntax"
}

Write-ValidationOutput "`n=== WINDOWS SERVICES ===" -Type Header

# 23. Windows Update Service
Test-Requirement -Name "Windows Update Service" -Warning -Test {
    $service = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
    $service -and $service.Status -ne 'Disabled'
} -Description "Windows Update service should be available"

# 24. Task Scheduler
Test-Requirement -Name "Task Scheduler Service" -Warning -Test {
    $service = Get-Service -Name Schedule -ErrorAction SilentlyContinue
    $service -and $service.Status -eq 'Running'
} -Description "Task Scheduler required for automated runs"

# 25. WMI Service
Test-Requirement -Name "WMI Service" -Test {
    $service = Get-Service -Name Winmgmt -ErrorAction SilentlyContinue
    $service -and $service.Status -eq 'Running'
} -Description "Windows Management Instrumentation required"

Write-ValidationOutput "`n=== DESKTOP SHORTCUTS ===" -Type Header

# 26. Desktop Access
Test-Requirement -Name "Desktop Access" -Warning -Test {
    $desktop = [Environment]::GetFolderPath("Desktop")
    Test-Path $desktop
} -Description "Desktop access needed for shortcuts"

# 27. Shortcut Creation Test
Test-Requirement -Name "COM Object Support" -Warning -Test {
    try {
        $shell = New-Object -ComObject WScript.Shell
        [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
        $true
    } catch {
        $false
    }
} -Description "COM support needed for shortcut creation"

# Calculate results
$totalTests = $Script:TestResults.Count
$passedTests = ($Script:TestResults | Where-Object { $_.Passed }).Count
$criticalFailed = ($Script:TestResults | Where-Object { $_.Critical -and -not $_.Passed }).Count
$warningCount = $Script:Warnings.Count

# Display summary
if (-not $Silent) {
    Write-ValidationOutput "`n" -Type Info
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "                      VALIDATION SUMMARY                      " -ForegroundColor White
    Write-Host "══════════════════════════════════════════════════════════════" -ForegroundColor Cyan
    
    Write-Host "`n📊 Results:" -ForegroundColor Yellow
    Write-Host "   Total Tests: $totalTests" -ForegroundColor White
    Write-Host "   Passed: $passedTests" -ForegroundColor Green
    Write-Host "   Failed: $($totalTests - $passedTests)" -ForegroundColor $(if ($totalTests - $passedTests -gt 0) { "Red" } else { "Green" })
    Write-Host "   Critical Failures: $criticalFailed" -ForegroundColor $(if ($criticalFailed -gt 0) { "Red" } else { "Green" })
    Write-Host "   Warnings: $warningCount" -ForegroundColor $(if ($warningCount -gt 0) { "Yellow" } else { "Green" })
    
    if ($criticalFailed -gt 0) {
        Write-Host "`n❌ VALIDATION FAILED" -ForegroundColor Red
        Write-Host "Critical requirements not met. Please address the following:" -ForegroundColor Red
        $Script:TestResults | Where-Object { $_.Critical -and -not $_.Passed } | ForEach-Object {
            Write-Host "  - $($_.Name): $($_.Description)" -ForegroundColor Red
        }
    } elseif ($Script:FailedTests.Count -gt 0) {
        Write-Host "`n⚠️  VALIDATION PASSED WITH WARNINGS" -ForegroundColor Yellow
        Write-Host "Some optional features may not work correctly:" -ForegroundColor Yellow
        $Script:Warnings | ForEach-Object {
            Write-Host "  - $_" -ForegroundColor Yellow
        }
    } else {
        Write-Host "`n✅ ALL VALIDATION CHECKS PASSED" -ForegroundColor Green
        Write-Host "System is fully compatible with Deep Clean Pro!" -ForegroundColor Green
    }
    
    Write-Host "`n📝 Log saved to: $env:TEMP\DeepCleanValidation_$(Get-Date -Format 'yyyyMMdd').log" -ForegroundColor Gray
}

# Export results if requested
if ($ReturnResults) {
    return [PSCustomObject]@{
        AllPassed = ($criticalFailed -eq 0)
        TotalTests = $totalTests
        PassedTests = $passedTests
        FailedTests = $Script:FailedTests
        Warnings = $Script:Warnings
        CriticalFailures = $criticalFailed
        Results = $Script:TestResults
    }
}

# Exit with appropriate code
if ($criticalFailed -gt 0) {
    exit 1
} else {
    exit 0
}