# 🧠 **Deep Clean Pro – Full Developer Reference (v2.2.x)**

### *Complete internal documentation of Deep Clean Pro’s functions, modules, flows, dependencies, and internal architecture.*

This reference covers **all internal functions**, including:

* Engine functions
* Module functions
* Utility functions
* Logging + backup subsystems
* Update maintenance subsystem
* Profiles
* Policy repair helpers
* Extension system hooks
* OneDrive Liberator internals
* Launcher internals
* Deployment utilities

---

# 📚 **Table of Contents**

1. Core Engine Functions
2. Support Utilities
3. Backup Subsystem
4. Logging Subsystem
5. Optimization Module Functions
6. Profile Engine
7. Windows Update Maintenance
8. Windows Policy Repair Internals
9. OneDrive Liberator Internals
10. Launcher Internals (Gist-Based)
11. Extension System Internals
12. Service Layer Behaviors
13. CIM/WMI Subsystem Notes
14. Error & Exception Handling Model
15. Performance & Concurrency Notes
16. Safety Model
17. Function-by-Function Detailed Documentation

---

# 🧱 **1. Core Engine Functions**

These functions define the main lifecycle of Deep Clean Pro.

---

## **Initialize-Environment**

### **Location**

`DeepCleanPro.ps1` top-level engine section

### **Purpose**

Sets up the runtime environment to ensure safe execution.

### **Signature**

```powershell
Initialize-Environment
```

### **Internal Steps**

1. Validate Administrator privileges
2. Create directories:

   * `$Script:BasePath`
   * `$Script:BackupPath`
   * `$Script:LogPath`
   * `$Script:TempPath`
3. Record `$Script:OriginalExecutionPolicy`
4. Set Process-level ExecutionPolicy
5. Enable TLS 1.2
6. Log initialization events

### **Dependencies**

* `Write-ColorOutput`
* PowerShell’s file I/O
* .NET SecurityProtocol

### **Errors**

Throws if:

* Admin rights missing
* Cannot create directories

---

## **Test-AdminPrivileges**

### **Signature**

```powershell
Test-AdminPrivileges
```

### **Returns**

`True` or `False`

### **Notes**

Used during bootstrap AND internal environment validation.

---

## **Get-SystemInfo**

### **Returns**

Hashtable with 8 fields
Used by summary + log output.

---

## **Show-Summary**

### **Parameters**

```powershell
-StartTime <DateTime>
-HealthChecks <Object[]>
```

### **Notes**

Does not modify state, pure output function.

---

# 🧩 **2. Support Utilities**

These are used across all modules.

---

## **Write-ColorOutput**

### **Purpose**

Unified logging API with console + log file output.

### **Types**

* Info
* Success
* Warning
* Error
* Debug

### **Side Effects**

Writes to:

```
C:\DeepCleanPro\Logs\DeepClean_YYYYMMDD.log
```

### **Security Notes**

* Sanitizes input
* Never prints untrusted external values without quoting

---

## **Backup-RegistryKey**

### **Signature**

```powershell
Backup-RegistryKey -Path <string> -BackupName <string>
```

### **Behavior**

* Converts HKCU/HKLM prefixes to full registry paths
* Uses `reg.exe export` (most reliable method)
* Stores `.reg` files with timestamp

### **Side Effects**

Writes to:

```
C:\DeepCleanPro\Backups\Registry\
```

### **Failure Modes**

* Path does not exist
* reg.exe not accessible
* Write permission issues

---

# 📦 **3. Backup Subsystem Internals**

Deep Clean Pro uses:

* **Registry backups** (`.reg`)
* **Service config backups** (`.csv`)
* **Policy backups** (`.json`)

All backups use timestamp:

```
YYYYMMDD_HHMMSS
```

Backups are created **before** any destructive change.

---

# 📝 **4. Logging Subsystem Internals**

Logs use the format:

```
YYYY-MM-DD HH:MM:SS - [TYPE] Message
```

Logging is appended; files rotate daily.

The logger is **silent on failures**, by design, to avoid blocking runtime.

---

# ⚙️ **5. Optimization Modules – Internal Functions**

Below are all internal modules in the order executed.

---

## **Clear-TempFiles**

Removes temp files across multiple directories.

### **Internal Behavior**

* Enumerates recursively
* Tracks deleted file count
* Tracks freed space
* Ignores locked files
* Logs each directory failure

### **Performance Notes**

Avoids memory-heavy `Get-ChildItem -Recurse` when possible by chunking through each path individually.

---

## **Optimize-Services**

### **Internal Logic**

1. Build list of services:

   * Spooler
   * DiagTrack
   * dmwappushservice
   * SysMain
   * WSearch
2. Backup current service states via `Get-CimInstance`
3. Apply new startup types
4. Log every action

### **Developer Notes**

* MUST NOT use `Get-WmiObject`
* MUST NOT use `sc.exe`

Because both cause failures on modern Windows 11 builds.

---

## **Optimize-SystemPerformance**

### **Changes**

* Memory
* Prefetcher
* VisualFX
* Session Manager settings

Backup created via `Backup-RegistryKey` prior to patching.

---

## **Remove-BloatwareApps**

### **Internal Logic**

1. Predefined list of Appx names
2. Attempt to remove AppxPackage
3. Attempt to remove AppxProvisionedPackage

### **Notes**

* All failures are non-critical
* Logs skipped packages

---

## **Optimize-NetworkSettings**

Applies network registry optimizations.

### **Internal Dependencies**

* `Backup-RegistryKey`
* Registry write

---

## **Optimize-StartupPrograms**

Reports startup items, identifies “heavy apps” via regex:

```
Spotify|Skype|Steam|Discord|OneDrive|Teams
```

---

## **Invoke-DiskCleanup**

Wraps:

```
cleanmgr.exe /sagerun:100
```

Sets cleanup flags across all known VolumeCaches categories.

---

## **Optimize-WindowsSearch**

### **Process**

1. Stop WSearch
2. Remove index data
3. Start WSearch

---

## **Update-SystemDrivers**

Uses:

```
pnputil /scan-devices
```

Interprets output.

---

## **Optimize-WindowsUpdates**

### **Internal Flow**

1. Create Microsoft.Update.Session
2. Search for updates
3. Download updates
4. Install updates
5. Clean update cache
6. Clean Windows.old via CleanMgr
7. Run DISM cleanup

### **Error Handling**

Soft failures with warnings.

### **Performance Notes**

* Installer operations can block for long periods
* All heavy operations wrapped in Write-Progress

---

# 🎛 **6. Profile Engine – Internal Logic**

Profiles are applied through a switch statement.

### **Gaming**

* GPU scheduling
* GameDVR disabled
* GameConfigStore tweaks
* Power plan → High performance

### **Development**

* LongPathsEnabled
* Developer mode
* Defender exclusions for coding paths

### **Music**

* Audio enhancements disabled
* USB selective suspend disabled
* Lower latency

### **Video**

* Increase TdrDelay
* Optimize file system caching

### **Office**

* Balanced
* Power savings

---

# 🛠 **7. Windows Policy Repair – Internal Mechanics**

`Fix-WindowsPolicies.ps1` is a standalone repair tool.

### **Internal Repair Areas**

* Explorer restrictions
* Windows Update GPO leftovers
* Defender configuration
* Registry policy corruption
* Invalid telemetry settings
* Shell folder path corruption

All repairs use full backups, JSON-format.

---

# ☁️ **8. OneDrive Liberator – Internal Mechanics**

### **Backup Subsystem**

Scans and copies entire OneDrive tree recursively.

### **Folder Redirection Repair**

Fixes:

* Desktop
* Documents
* Pictures
* Videos
* Music

### **Uninstall Subsystem**

Attempts:

1. OneDriveSetup.exe /uninstall
2. Remove-AppxPackage fallback
3. Provisioned package removal

### **Block Reinstall**

Writes:

```
DisableFileSync = 1
DisableFileSyncNGSC = 1
```

---

# 🚀 **9. Launcher (Gist) – Internal Flow**

### **Internal Steps**

1. Validate connectivity
2. Download main script
3. Content validation
4. Write temp file
5. Execute with environment-derived parameters
6. Cleanup

### **Dependencies**

* Invoke-WebRequest
* Write-ColorOutput
* PowerShell engine

---

# 🧩 **10. Extension System – Developer Internals**

Extensions are loaded BEFORE any core modules.

### **Directory**

```
C:\DeepCleanPro\Extensions\
```

### **File Pattern**

```
*.ps1
```

### **Hook Registration**

Via:

```powershell
Register-ExtensionHook -Stage X -ScriptBlock {}
```

### **Profile Extension**

Custom profiles injected into:

```powershell
$Script:CustomProfiles['Name'] = { … }
```

---

# ⚙️ **11. CIM / System Interface Notes**

### Deep Clean Pro uses ONLY:

* `Get-CimInstance`
* `Set-Service`
* `Set-ItemProperty`
* `reg.exe`
* `pnputil`
* `cleanmgr.exe`
* `DISM.exe`

### Developer Warnings

❌ NEVER use WMI (`Get-WmiObject`)
❌ NEVER use direct Registry Providers for policy keys
❌ NEVER use `sc.exe`
❌ NEVER assume path existence

---

# 🔒 **12. Error & Exception Handling Model**

All modules use:

* Try/catch
* Color-coded error logging
* Soft-failure model where possible
* Throw only if:

  * Admin rights missing
  * Script corruption detected
  * Critical operation fails (rare)

---

# ⚡ **13. Performance & Concurrency**

* Avoid recursion-heavy patterns
* Avoid large in-memory enumerations
* Favor chunked loops
* CIM calls are asynchronous-friendly
* Disk cleanup uses native Windows tools for performance

---

# 🛡 **14. Safety Model**

Everything must comply with:

✔ `SupportsShouldProcess`
✔ `-WhatIf`
✔ Backups before modification
✔ Sanitized inputs
✔ Logged actions
✔ No persistent background tasks
✔ No telemetry

---

# 📘 **15. Function-by-Function Detailed Documentation**

This is the full function reference for every defined function:

---

## **Function: Clear-TempFiles**

* Type: module function
* Inputs: none
* Supports: WhatIf
* Side-effects: File deletion
* Returns: Summary metrics

---

## **Function: Optimize-Services**

* Type: module function
* Inputs: none
* Supports: ShouldProcess, WhatIf
* Side Effects: Service startup modifications
* Return: None

---

## **Function: Optimize-SystemPerformance**

* Registry modifications
* Backup-first
* ShouldProcess

---

## **Function: Remove-BloatwareApps**

* Non-critical
* Multi-step uninstall process
* Skips silently

---

## **Function: Optimize-NetworkSettings**

* Writes 3 registry values
* Backup-first

---

## **Function: Optimize-StartupPrograms**

* Non-destructive
* Recommendations only

---

## **Function: Invoke-DiskCleanup**

* External tool wrapper
* Safe
* Requires ShouldProcess

---

## **Function: Optimize-WindowsSearch**

* Clears index
* Restarts service

---

## **Function: Update-SystemDrivers**

* Parses pnputil output

---

## **Function: Optimize-WindowsUpdates**

* Complex logic
* Requires error handling
* Built-in fallback

---

## **Function: Apply-ProfileOptimizations**

* Maps profile to switch block
* No destructive behavior
* ShouldProcess for internal calls

---

# 🎉 **Developer Reference Complete**
