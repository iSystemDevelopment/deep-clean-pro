# 🔧 ADVANCED USER GUIDE - Deep Clean Pro v2.2.0

## 📊 Technical Overview

Deep Clean Pro is a PowerShell-based Windows optimization framework with profile-based optimization strategies, comprehensive testing suite, and CI/CD integration.

### Architecture
```
┌─────────────────────────────────────────┐
│         User Interface Layer            │
│  (CLI / Shortcuts / Scheduled Tasks)    │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│         Core Optimization Engine        │
│    (DeepCleanPro.ps1 - Main Script)     │
├─────────────────────────────────────────┤
│  • Profile Manager (Gaming/Dev/Music)   │
│  • Backup System (Registry/Services)    │
│  • Safety Layer (WhatIf/ShouldProcess)  │
└────────────┬────────────────────────────┘
             │
┌────────────▼────────────────────────────┐
│      System Modification Layer          │
│   (Registry / Services / Files / GPO)   │
└─────────────────────────────────────────┘
```

## 🎯 Profile-Based Optimization

### Gaming Profile
```powershell
.\DeepCleanPro.ps1 -Profile Gaming [-QuickMode] [-NoReboot]
```

**Technical Changes:**
- `HKCU:\System\GameConfigStore` → GameDVR_Enabled = 0
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers` → HwSchMode = 2
- Power Plan → 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c (High Performance)
- Fullscreen Optimizations → Disabled
- WDDM GPU Scheduling → Hardware Accelerated

### Development Profile
```powershell
.\DeepCleanPro.ps1 -Profile Development [-QuickMode]
```

**Technical Changes:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem` → LongPathsEnabled = 1
- `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock` → AllowDevelopmentWithoutDevLicense = 1
- Windows Defender Exclusions:
  - `%USERPROFILE%\source`
  - `%USERPROFILE%\projects`
  - `%USERPROFILE%\.npm`
  - `%USERPROFILE%\.nuget`
  - Node.js and Python paths

### Music Production Profile
```powershell
.\DeepCleanPro.ps1 -Profile Music
```

**Technical Changes:**
- `HKCU:\AppEvents\Schemes` → (Default) = ".None"
- USB Selective Suspend → Disabled
- Audio Enhancements → Disabled via FxProperties
- DPC Latency optimizations
- MMCSS Priority → High

### Video Editing Profile
```powershell
.\DeepCleanPro.ps1 -Profile Video
```

**Technical Changes:**
- `HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers` → TdrDelay = 60
- File System Cache → memoryusage = 2
- Disable Last Access timestamps
- Large File Transfer optimizations

## 🛠️ Advanced Installation Methods

### Method 1: Git with Specific Branch
```powershell
git clone -b development https://github.com/Dr-Diodac/deep-clean-pro.git
cd deep-clean-pro
.\DEPLOY.ps1 -TargetPath "C:\Tools\DCP" -CreateScheduledTask -NonInteractive
```

### Method 2: Direct Script Execution with Parameters
```powershell
$params = @{
    Profile = 'Gaming'
    QuickMode = $true
    NoReboot = $true
}
& ([scriptblock]::Create((irm 'https://raw.githubusercontent.com/Dr-Diodac/deep-clean-pro/main/DeepCleanPro.ps1'))) @params
```

### Method 3: Custom Gist Integration
```powershell
# Create custom launcher with authentication
$launcher = @'
param([string]$Token)
$headers = @{ Authorization = "Bearer $Token" }
$script = Invoke-RestMethod -Uri "YOUR_PRIVATE_REPO_URL" -Headers $headers
Invoke-Expression $script
'@
$launcher | Out-File -FilePath "CustomLauncher.ps1"
```

## 📡 Remote Deployment

### Deploy via Group Policy
```powershell
# Create GPO startup script
$gpoScript = @'
if (Test-NetConnection -ComputerName github.com -Port 443 -InformationLevel Quiet) {
    Start-Process powershell.exe -ArgumentList "-ExecutionPolicy Bypass -Command `"irm 'GIST_URL' | iex`"" -WindowStyle Hidden
}
'@
```

### Deploy via SCCM/Intune
```xml
<Package>
  <Name>Deep Clean Pro</Name>
  <Version>2.2.0</Version>
  <CommandLine>powershell.exe -ExecutionPolicy Bypass -File DeepCleanPro.ps1 -Profile Office -QuickMode</CommandLine>
  <DetectionMethod>
    <RegistryKey>HKLM\SOFTWARE\DeepCleanPro</RegistryKey>
    <Value>Version</Value>
    <Data>2.2.0</Data>
  </DetectionMethod>
</Package>
```

## 🔒 Security Hardening

### Implement Signature Verification
```powershell
# Add to launcher
$scriptHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new([Text.Encoding]::UTF8.GetBytes($scriptContent)))).Hash
$trustedHashes = @(
    'YOUR_SCRIPT_HASH_HERE'
)
if ($scriptHash -notin $trustedHashes) {
    throw "Script integrity check failed"
}
```

### Add Logging and Auditing
```powershell
# Enhanced logging
$Script:AuditLog = @{
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
    StartTime = Get-Date
    Parameters = $PSBoundParameters
    Changes = @()
}

# Log each change
function Add-AuditEntry {
    param($Action, $Target, $Result)
    $Script:AuditLog.Changes += @{
        Timestamp = Get-Date
        Action = $Action
        Target = $Target
        Result = $Result
    }
}

# Export audit log
$Script:AuditLog | ConvertTo-Json -Depth 10 | Out-File "$LogPath\Audit_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
```

## 🧪 Testing Framework

### Run Specific Test Suites
```powershell
# Unit tests only
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -Tag Unit

# Integration tests
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -Tag Integration

# Performance benchmarks
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -Tag Performance

# Security tests
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -Tag Security
```

### Create Custom Test Cases
```powershell
Describe "Custom Optimization Tests" {
    Context "Profile Validation" {
        It "Should apply Gaming profile correctly" {
            Mock Set-ItemProperty {}
            Apply-ProfileOptimizations -ProfileName 'Gaming'
            Assert-MockCalled Set-ItemProperty -Times 4 -Exactly
        }
    }
}
```

## ⚡ Performance Tuning

### Parallel Execution
```powershell
# Run cleanup tasks in parallel
$jobs = @()
$jobs += Start-Job -ScriptBlock { Clear-TempFiles }
$jobs += Start-Job -ScriptBlock { Optimize-Services }
$jobs += Start-Job -ScriptBlock { Clean-RegistryKeys }
$jobs | Wait-Job | Receive-Job
```

### Memory-Optimized Operations
```powershell
# Process large datasets in chunks
Get-ChildItem -Path C:\ -Recurse -File |
    Select-Object -First 1000 |
    ForEach-Object -Parallel {
        # Process file
    } -ThrottleLimit 4
```

## 🔄 CI/CD Integration

### GitHub Actions Matrix Testing
```yaml
strategy:
  matrix:
    os: [windows-2019, windows-2022]
    profile: [Gaming, Development, Music, Video, Office]
    mode: [Quick, Full]
```

### Pre-commit Hooks
```bash
#!/bin/sh
# .git/hooks/pre-commit
powershell -Command "
    Invoke-ScriptAnalyzer -Path . -Recurse -Severity Error
    if ($LASTEXITCODE -ne 0) { exit 1 }
    Invoke-Pester -Path .\Tests -PassThru | Select -ExpandProperty FailedCount
"
```

## 📊 Monitoring and Analytics

### Performance Metrics Collection
```powershell
$metrics = @{
    ExecutionTime = (Measure-Command { .\DeepCleanPro.ps1 -QuickMode }).TotalSeconds
    SpaceFreed = (Get-PSDrive C).Free - $initialFree
    ServicesOptimized = (Get-Service | Where-Object StartType -eq 'Disabled').Count
    RegistryKeysModified = $Script:RegistryChanges.Count
}

# Send to monitoring service
Invoke-RestMethod -Uri "https://your-metrics-api.com/collect" -Method Post -Body ($metrics | ConvertTo-Json)
```

## 🎯 Custom Modules

### Create Your Own Profile
```powershell
# Add to DeepCleanPro.ps1
'CustomProfile' {
    Write-ColorOutput "Applying custom optimizations..." -Type Info
    
    # Your custom optimizations here
    Set-ItemProperty -Path "HKCU:\YourPath" -Name "YourSetting" -Value 1
    
    # Import external module
    Import-Module .\Modules\CustomOptimizations.psm1
    Invoke-CustomOptimization
}
```

### Extension System
```powershell
# Load extensions dynamically
$extensions = Get-ChildItem -Path ".\Extensions\*.ps1"
foreach ($ext in $extensions) {
    Write-ColorOutput "Loading extension: $($ext.Name)" -Type Info
    . $ext.FullName
}
```

## 🔐 Enterprise Deployment

### Domain-Wide Deployment
```powershell
# Deploy to all domain computers
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
$scriptPath = "\\FileServer\Scripts\DeepCleanPro.ps1"

Invoke-Command -ComputerName $computers -ScriptBlock {
    & $using:scriptPath -Profile Office -QuickMode
} -ThrottleLimit 10
```

### Compliance Reporting
```powershell
# Generate compliance report
$report = foreach ($computer in $computers) {
    Test-Connection -ComputerName $computer -Count 1 -Quiet
    [PSCustomObject]@{
        Computer = $computer
        Optimized = Test-Path "\\$computer\C$\DeepCleanPro\Logs"
        LastRun = Get-Item "\\$computer\C$\DeepCleanPro\Logs\*.log" | 
                  Select-Object -Last 1 -ExpandProperty LastWriteTime
    }
}
$report | Export-Csv -Path "OptimizationCompliance.csv"
```

## 📈 Advanced Troubleshooting

### Debug Mode
```powershell
$DebugPreference = 'Continue'
.\DeepCleanPro.ps1 -Profile Gaming -WhatIf
```

### Trace Execution
```powershell
Set-PSDebug -Trace 2
.\DeepCleanPro.ps1 -QuickMode
Set-PSDebug -Off
```

### Performance Profiling
```powershell
$profile = Measure-Script -Path .\DeepCleanPro.ps1 -Expression { 
    .\DeepCleanPro.ps1 -QuickMode 
}
$profile | Select-Object Line, HitCount, Duration | Sort-Object Duration -Descending
```

## 🚀 API Integration

### REST API for Remote Control
```powershell
# Create simple API endpoint
$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://+:8080/deepclean/")
$listener.Start()

while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response
    
    if ($request.HttpMethod -eq "POST") {
        $body = [System.IO.StreamReader]::new($request.InputStream).ReadToEnd()
        $params = $body | ConvertFrom-Json
        
        Start-Job -ScriptBlock {
            & .\DeepCleanPro.ps1 @using:params
        }
        
        $response.StatusCode = 200
        $response.Close()
    }
}
```

---

## 📚 Additional Resources

- [PowerShell Best Practices](https://docs.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)
- [Windows Registry Reference](https://docs.microsoft.com/windows/win32/sysinfo/registry)
- [Group Policy Reference](https://docs.microsoft.com/windows/deployment/group-policy/)
- [Performance Tuning Guidelines](https://docs.microsoft.com/windows-server/administration/performance-tuning/)

---

**For Enterprise Support**: Contact Dr-Diodac for custom implementations and enterprise features.
