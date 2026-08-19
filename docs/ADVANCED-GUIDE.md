# 🔧 ADVANCED USER GUIDE

### Deep Clean Pro — Power User & Hybrid Enterprise Edition

This guide is for **power users**, **technicians**, **admins**, and anyone who wants to go deeper than the basic shortcuts and beginner instructions.

If you are looking for one-click shortcuts or simple instructions, read the **BEGINNERS-GUIDE.md** instead.

---

# 📐 1. Technical Overview of Deep Clean Pro

Deep Clean Pro is a **modular PowerShell optimization engine** with:

* Profile-based optimization
* Safety system (WhatIf, ShouldProcess, backups)
* Service tuning
* Registry tuning
* Windows Update maintenance
* Logging & recovery
* Policy enforcement
* Expansion module support
* Optional enterprise deployment tools

### 🧱 Architecture

```
┌─────────────────────────────────────────────┐
│           User Interface Layer              │
│   (Shortcuts / CLI / Scheduled Tasks)       │
└───────────────────────┬─────────────────────┘
                        │
┌───────────────────────▼─────────────────────┐
│          Core Optimization Engine           │
│           DeepCleanPro.ps1 (v2.2+)          │
│                                             │
│  • Profile Manager (Gaming/Dev/Music…)      │
│  • Backup System (services, registry, etc.) │
│  • Safety Layer (WhatIf, rollback)          │
│  • Windows Update Maintenance Module        │
└───────────────────────┬─────────────────────┘
                        │
┌───────────────────────▼─────────────────────┐
│      System Modification Layer              │
│   (Services, Registry, Filesystem, GPO)     │
└─────────────────────────────────────────────┘
```

---

# 🎛️ 2. Advanced Profile-Based Optimization

Each profile is designed with **specific workloads** in mind.
All profiles can be triggered either via CLI or via desktop shortcuts.

You can also use:

```powershell
$env:DCP_PROFILE = 'Gaming'
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

Profiles override the default “Balanced” mode.

---

## 🎮 Gaming Profile

```powershell
.\DeepCleanPro.ps1 -Profile Gaming
```

### Technical Changes

* Disable Xbox Game Bar / DVR
* Disable Game Mode fullscreen optimizations
* Enable HW accelerated GPU scheduling (`HwSchMode=2`)
* Set high-performance power plan
* Reduce input latency
* Optimize GPU timeout behavior

---

## 💻 Development Profile

```powershell
.\DeepCleanPro.ps1 -Profile Development
```

### Technical Changes

* Enable long path support
* Enable Developer Mode
* Add Defender exclusions for:

  * `%USERPROFILE%\source`
  * `%USERPROFILE%\projects`
  * `%USERPROFILE%\.npm`
  * `%USERPROFILE%\.nuget`
  * Node.js + Python
* Improve disk and indexing performance for coding workflows

---

## 🎵 Music Production Profile

```powershell
.\DeepCleanPro.ps1 -Profile Music
```

### Technical Changes

* Disable system sounds
* Reduce DPC latency
* Disable audio “enhancements” (FxProperties)
* Optimize USB selective suspend
* Set performance power plan

---

## 📹 Video Editing Profile

```powershell
.\DeepCleanPro.ps1 -Profile Video
```

### Technical Changes

* Increase GPU rendering timeout (TdrDelay = 60)
* Optimize disk caching for large media operations
* Disable last access timestamps
* Improve RAM usage for encoding workloads

---

## 💼 Office Profile

```powershell
.\DeepCleanPro.ps1 -Profile Office
```

### Technical Changes

* Balanced performance power plan
* Battery and standby optimizations
* Fast Startup enabled
* Removes distractive bloatware

---

# ⚙️ 3. Advanced Control via Parameters

Every feature in Deep Clean Pro is available through parameters:

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -QuickMode -NoReboot
```

### Core Parameters

| Parameter     | Description                                         |
| ------------- | --------------------------------------------------- |
| `-Profile`    | Gaming, Development, Music, Video, Office, Balanced |
| `-QuickMode`  | Skip heavy tasks (defrag, update cleanup)           |
| `-WhatIf`     | Simulation mode (no changes applied)                |
| `-NoReboot`   | Don’t ask for reboot                                |
| `-AutoReboot` | Reboot automatically at end                         |
| `-SkipHealth` | Skip initial system health check                    |
| `-SkipDefrag` | Disable disk optimization step                      |

---

# 🔄 4. Windows Update Maintenance (Advanced)

Starting with v2.2.x, Deep Clean Pro includes:

### ✔ Update Detection

### ✔ Update Download

### ✔ Update Installation

### ✔ Update Cache Cleanup

### ✔ Windows.old Cleanup

### ✔ DISM /StartComponentCleanup

### ✔ Optional user prompt at startup

### Trigger manually:

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates
```

(In Full mode, the script asks **Y/N** by default.)

---

# 📁 5. Backup & Logging System (Deep Internals)

Deep Clean Pro maintains:

### ✔ Service configuration backups

Saved to:

```
C:\DeepCleanPro\Backups\Services\ServiceConfig_YYYYMMDD_HHMMSS.csv
```

### ✔ Registry backups

Example:

```
C:\DeepCleanPro\Backups\Registry\MemoryManagement_YYYYMMDD_HHMMSS.reg
```

### ✔ Logs

```
C:\DeepCleanPro\Logs\DeepClean_YYYYMMDD.log
```

### ✔ Temp staging directory

```
%TEMP%\DeepCleanPro\
```

This system ensures the tool is **safe**, **auditable**, and **recoverable**.

---

# ☁️ 6. OneDrive Liberator (Advanced Removal Tool)

Deep Clean Pro ships with **OneDrive Liberator** — a tool for **complete, permanent OneDrive removal**.

### What it does:

* Backs up all OneDrive files
* Moves Desktop/Documents/Pictures **out of OneDrive**
* Uninstalls OneDrive
* Removes Explorer sidebar entries
* Deletes leftover folders
* Blocks OneDrive from reinstalling via Windows Update or Store
* Prompts for restart

### Run it:

```powershell
.\OneDriveNuke.ps1   # or the Desktop shortcut
```

### Safe Defaults:

Use `-Force` to skip the interactive YES confirmation. A local backup is always attempted first.

---

# 📦 7. Advanced Installation Methods

## Method A — Git + DEPLOY.ps1

Ideal for technicians, power users, and contributors.

```powershell
git clone https://github.com/iSystemDevelopment/deep-clean-pro.git
cd deep-clean-pro

.\DEPLOY.ps1 -CreateShortcuts -CreateScheduledTask
```

---

## Method B — Raw Script With Parameters

Download and execute entirely in memory:

```powershell
$params = @{
    Profile   = 'Gaming'
    QuickMode = $true
    NoReboot  = $true
}

& ([ScriptBlock]::Create(
    (irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1')
)) @params
```

---

## Method C — Custom Launcher (Your own Logic)

Use your own auth, Gist, private Git, or custom delivery.

Example template:

```powershell
param([string]$Token)
$headers = @{ Authorization = "Bearer $Token" }
$script  = Invoke-RestMethod -Uri "YOUR_PRIVATE_REPO_URL" -Headers $headers
Invoke-Expression $script
```

---

# 🌐 8. Remote & Enterprise Deployment (Lightweight Section)

This section provides light enterprise usage.
For full enterprise deployment, see the **ENTERPRISE.md** (optional future file).

---

## A) Group Policy Startup Script

Deploy silently across an OU:

```powershell
$gpoScript = @'
if (Test-NetConnection github.com -Port 443 -InformationLevel Quiet) {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex`""
}
'@
```

---

## B) Intune / SCCM Package

```xml
<Package>
  <Name>Deep Clean Pro</Name>
  <Version>2.2.0</Version>
  <CommandLine>
    powershell.exe -ExecutionPolicy Bypass -File DeepCleanPro.ps1 -Profile Office -QuickMode
  </CommandLine>
  <DetectionMethod>
    <RegistryKey>HKLM\SOFTWARE\DeepCleanPro</RegistryKey>
    <Value>Version</Value>
    <Data>2.2.0</Data>
  </DetectionMethod>
</Package>
```

---

## C) Domain-Wide Execution

```powershell
$computers = Get-ADComputer -Filter * | Select-Object -ExpandProperty Name
$script    = "\\FileServer\Scripts\DeepCleanPro.ps1"

Invoke-Command -ComputerName $computers -ScriptBlock {
    & $using:script -Profile Office -QuickMode
} -ThrottleLimit 10
```

---

# 🧪 9. Testing & Validation (Advanced)

### Validation Script

```powershell
C:\DeepCleanPro\Scripts\VALIDATE.ps1
```

### Unit tests

```powershell
Invoke-Pester -Path .\Tests\
```

### WhatIf global debugging

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -WhatIf
```

### Trace execution

```powershell
Set-PSDebug -Trace 2
```

---

# ⚡ 10. Performance Techniques for Power Users

### Run modules in parallel

```powershell
$jobs = @()
$jobs += Start-Job -ScriptBlock { Clear-TempFiles }
$jobs += Start-Job -ScriptBlock { Optimize-Services }
$jobs | Wait-Job | Receive-Job
```

### Chunk processing large dir trees

```powershell
Get-ChildItem C:\ -Recurse -File |
    Select -First 1000 |
    ForEach-Object { /* logic */ }
```

---

# 🔌 11. Extension & Customization System

## Load your own modules

```powershell
# Extensions/*.ps1 will auto-load
$extensions = Get-ChildItem ".\Extensions\*.ps1"
foreach ($ext in $extensions) {
    . $ext.FullName
}
```

## Create a custom profile

```powershell
'CustomProfile' {
    Write-ColorOutput "Applying custom optimizations..." -Type Info
    Import-Module .\Modules\CustomOptimizations.psm1
    Invoke-CustomOptimization
}
```

---

# 🔒 12. Security Hardening

### Script integrity validation

```powershell
$scriptHash = (Get-FileHash -Algorithm SHA256 -InputStream ([IO.MemoryStream]::new(
    [Text.Encoding]::UTF8.GetBytes($scriptContent)
))).Hash

$trusted = @("PUT YOUR HASH HERE")

if ($scriptHash -notin $trusted) {
    throw "Script integrity check failed"
}
```

### Audit logging

```powershell
$Script:AuditLog = @{
    User = $env:USERNAME
    Computer = $env:COMPUTERNAME
    Start = Get-Date
    Changes = @()
}
```

---

# 📚 13. Resources for Advanced Users

* PowerShell Docs: [https://learn.microsoft.com/powershell](https://learn.microsoft.com/powershell)
* Windows Registry Reference
* Performance Tuning Guidelines
* GitHub Actions Docs
* Pester Testing Framework

---

# 🎉 Done!
