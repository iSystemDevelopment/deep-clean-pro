# 📘 **Deep Clean Pro – API Reference (v2.2.x)**

### *Complete function, parameter, and behavior documentation for developers & integrators.*

Deep Clean Pro exposes a collection of **stable, script-level APIs** through PowerShell functions and modules.
These functions follow strict rules:

* Full **WhatIf** support
* Full **ShouldProcess** compliance
* Safe file/registry/service operations
* Backup-before-change mechanisms
* Descriptive, color-coded logging
* Idempotent behavior when possible
* Error-safe execution with try/catch

This reference lists all core APIs.

---

# 📑 **Index of APIs**

### Core Engine

* `Initialize-Environment`
* `Get-SystemInfo`
* `Show-Summary`
* `Write-ColorOutput`

### Optimization Modules

* `Clear-TempFiles`
* `Optimize-Services`
* `Optimize-SystemPerformance`
* `Remove-BloatwareApps`
* `Optimize-NetworkSettings`
* `Optimize-StartupPrograms`
* `Invoke-DiskCleanup`
* `Optimize-WindowsSearch`
* `Update-SystemDrivers`
* `Optimize-WindowsUpdates`

### Profile Engine

* `Apply-ProfileOptimizations`

### Backup & Safety

* `Backup-RegistryKey`

### Repair Modules

* `Fix-WindowsPolicies.ps1` (external tool)
* `OneDriveNuke.ps1` (external tool)

### Extension System

* `Register-ExtensionHook`

---

# 🧱 **CORE ENGINE**

---

## 🟦 **Initialize-Environment**

### **Synopsis**

Initializes Deep Clean Pro execution environment, validates admin rights, and prepares directories/logging.

### **Signature**

```powershell
Initialize-Environment
```

### **Behavior**

* Ensures Admin privileges
* Creates:

  * Base directory
  * Backups directory
  * Logs directory
  * Temp directory
* Sets session execution policy
* Enforces TLS 1.2
* Logs initialization steps

### **Errors**

Throws if:

* Not running as Admin
* Cannot create required directories

---

## 🟦 **Get-SystemInfo**

### **Synopsis**

Collects system-wide data for summaries.

### **Signature**

```powershell
Get-SystemInfo
```

### **Returns**

A hashtable containing:

```
ComputerName  
Username  
OS  
Build  
Architecture  
RAM  
FreeSpace  
LastBoot
```

### **Usage**

Used in the summary footer.

---

## 🟦 **Show-Summary**

### **Synopsis**

Displays a post-execution summary.

### **Signature**

```powershell
Show-Summary -StartTime <DateTime> -HealthChecks <Object[]>
```

### **Parameters**

| Name           | Type     | Description                    |
| -------------- | -------- | ------------------------------ |
| `StartTime`    | DateTime | When DCP started running       |
| `HealthChecks` | Array    | Results from Test-SystemHealth |

---

## 🟦 **Write-ColorOutput**

### **Synopsis**

Global logging utility with standardized color-coded output.

### **Signature**

```powershell
Write-ColorOutput -Message <string> [-Type <Info|Success|Warning|Error|Debug>]
```

### **Behavior**

* Writes message in appropriate color
* Logs message to daily log file
* Used across all modules

---

# ⚙️ **OPTIMIZATION MODULES**

---

## 🟧 **Clear-TempFiles**

### **Synopsis**

Removes temporary files from Windows temp directories.

### **Signature**

```powershell
Clear-TempFiles [-WhatIf]
```

### **Folders Cleaned**

* `%TEMP%`
* `%LOCALAPPDATA%\Temp`
* `%WINDIR%\Temp`
* `%WINDIR%\Prefetch`
* Explorer thumbnail cache

### **Supports**

✔ ShouldProcess
✔ WhatIf

---

## 🟧 **Optimize-Services**

### **Synopsis**

Configures select Windows services for performance and stability.

### **Signature**

```powershell
Optimize-Services [-WhatIf]
```

### **Behavior**

* Backs up service configuration to CSV
* Uses `Get-CimInstance` (never WMI)
* Modifies services:

  * `DiagTrack` → Disabled
  * `dmwappushservice` → Disabled
  * `SysMain` → Manual
  * `WSearch` → Manual
  * `Spooler` → Manual

### **Supports**

✔ ShouldProcess
✔ WhatIf
✔ Soft-failure logging

---

## 🟧 **Optimize-SystemPerformance**

### **Synopsis**

Applies general system performance tweaks.

### **Signature**

```powershell
Optimize-SystemPerformance [-WhatIf]
```

### **Features**

* Registry modifications
* Memory management tuning
* Visual effects tuning
* Prefetcher configuration

### **Backups**

Registry keys backed up before modification.

---

## 🟧 **Remove-BloatwareApps**

### **Synopsis**

Removes preinstalled Microsoft bloat apps.

### **Signature**

```powershell
Remove-BloatwareApps [-WhatIf]
```

### **Behavior**

Attempts to remove Appx + AppxProvisioned packages for:

* Bing News
* Bing Weather
* Mixed Reality Portal
* Xbox Game Bar components
* Onboarding / Tips
* 3D Viewer
* SkypeApp
* Zune Music / Video
  …and more.

### **Supports**

✔ ShouldProcess
✔ WhatIf
✔ Graceful skipping if not installed

---

## 🟧 **Optimize-NetworkSettings**

### **Synopsis**

Improves network responsiveness for gaming and workstation use.

### **Signature**

```powershell
Optimize-NetworkSettings [-WhatIf]
```

### **Registry Keys Modified**

* `TcpAckFrequency`
* `TCPNoDelay`
* `DefaultTTL`

### **Backups created automatically**

---

## 🟧 **Optimize-StartupPrograms**

### **Synopsis**

Analyzes and reports startup programs; recommends disables.

### **Signature**

```powershell
Optimize-StartupPrograms
```

### **Behavior**

* Checks Run keys in registry
* Detects known heavy startup items
* Provides recommendations (non-destructive)

---

## 🟧 **Invoke-DiskCleanup**

### **Synopsis**

Runs extended Windows Disk Cleanup.

### **Signature**

```powershell
Invoke-DiskCleanup [-WhatIf]
```

### **Behavior**

* Sets cleanup flags under
  `HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches`
* Runs:

  ```
  cleanmgr.exe /sagerun:100
  ```

### **Supports**

✔ ShouldProcess
✔ WhatIf

---

## 🟧 **Optimize-WindowsSearch**

### **Synopsis**

Rebuilds and optimizes Windows Search index.

### **Signature**

```powershell
Optimize-WindowsSearch [-WhatIf]
```

### **Behavior**

* Stops WSearch service
* Clears index database
* Restarts service

---

## 🟧 **Update-SystemDrivers**

### **Synopsis**

Checks for Windows driver updates.

### **Signature**

```powershell
Update-SystemDrivers
```

### **Behavior**

Uses:

```
pnputil /scan-devices
```

Logs whether drivers are current.

---

## 🟥 **Optimize-WindowsUpdates**

### **Synopsis**

Fully manages Windows Updates: detection, download, installation, cleanup.

### **Signature**

```powershell
Optimize-WindowsUpdates [-WhatIf]
```

### **Behavior**

* Detects updates
* Downloads updates
* Installs updates
* Cleans:

  * `SoftwareDistribution\Download`
  * `Windows.old`
* Runs DISM Cleanup:

  ```
  DISM.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
  ```

### **Supports**

✔ ShouldProcess
✔ WhatIf
✔ Error-safe with warnings

---

# 🎛️ **PROFILE ENGINE**

---

## 🟦 **Apply-ProfileOptimizations**

### **Synopsis**

Applies targeted profile-specific optimizations.

### **Signature**

```powershell
Apply-ProfileOptimizations -ProfileName <string>
```

### **Supported Profiles**

* Gaming
* Development
* Music
* Video
* Office
* Balanced (default)
* Custom extension profiles

### **Behavior**

Each profile defines:

* Registry changes
* Power plan tuning
* GPU scheduling
* Audio/Video settings
* Developer mode settings
* Defender exclusions
* Latency tuning

Each operation is WhatIf-safe.

---

# 📦 **BACKUP & SAFETY MODULES**

---

## 🟦 **Backup-RegistryKey**

### **Synopsis**

Exports selected registry keys to `.reg` files.

### **Signature**

```powershell
Backup-RegistryKey -Path <string> [-BackupName <string>]
```

### **Behavior**

* Converts HKLM/HKCU paths
* Uses `reg.exe export`
* Stores backup in:

  ```
  C:\DeepCleanPro\Backups\Registry\
  ```

### **Returns**

Full backup file path.

---

# 🛠️ **REPAIR MODULES**

External standalone tools but considered part of API.

---

## 🟪 **Fix-WindowsPolicies.ps1**

### **Purpose**

Repairs broken Windows policies:

* Windows Update
* Windows Defender
* Explorer restrictions
* Network telemetry corruption
* Registry corruption in policy keys

### **Signature**

```powershell
.\Fix-WindowsPolicies.ps1 [-Force] [-BackupPath <path>]
```

### **Behavior**

* Backs up policy keys
* Repairs corrupted values
* Removes invalid entries
* Restores system defaults
* Does not modify domain GPO

---

## 🟪 **OneDriveNuke.ps1 (OneDrive Liberator)**

### **Purpose**

Safely remove OneDrive and reclaim shell folders.

### **Signature**

```powershell
.\OneDriveNuke.ps1 [-KeepFiles] [-Force]
```

### **Behavior**

* Backs up all OneDrive files
* Moves Desktop/Documents/Pictures back to local
* Uninstalls OneDrive
* Removes registry traces
* Prevents reinstall via Group Policy

---

# 🧩 **EXTENSION SYSTEM**

---

## 🟦 **Register-ExtensionHook**

### **Synopsis**

Registers a script block to run at specific lifecycle stages.

### **Signature**

```powershell
Register-ExtensionHook -Stage <string> -ScriptBlock <ScriptBlock>
```

### **Stages**

* `BeforeStart`
* `AfterHealthCheck`
* `BeforeOptimize`
* `AfterOptimize`
* `BeforeSummary`
* `AfterSummary`

### **Used For**

* Enterprise integrations
* Custom cleanup modules
* Custom logging
* Hardware vendor tuning

---

# 🎯 **STABILITY GUARANTEES**

Deep Clean Pro guarantees:

### ✔ Non-destructive by default

### ✔ Full logs

### ✔ Full WhatIf compliance

### ✔ No WMI usage (CIM only)

### ✔ Reversible changes (backups)

### ✔ Safe concurrent execution

### ✔ No telemetry

### ✔ Secure HTTPS-only downloads

---

# 📘 **API Reference Complete**

