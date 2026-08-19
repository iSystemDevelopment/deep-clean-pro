# 🛠️ **Deep Clean Pro – Deployment Script Guide (DEPLOY.ps1)**

### *Automated installer for full local installation, shortcuts, tasks, and environment setup.*

`DEPLOY.ps1` is the **official installer** for Deep Clean Pro when downloaded as a full ZIP or cloned via Git.
It prepares your environment, validates your system, installs the application to a permanent location, and sets up optional integrations like scheduled tasks and shortcuts.

This document explains:

* What the deployment script does
* How to run it
* Command-line options
* How technicians can silently deploy it
* How it works internally
* Troubleshooting and best practices

---

# ⚙️ **1. What DEPLOY.ps1 Does**

When executed, the deployment script performs:

### ✔ Environment Validation

* Checks PowerShell version
* Confirms Administrator privileges
* Validates Windows 10/11 compatibility
* Ensures execution policy allows the setup
* Confirms required directories are writable

### ✔ Installs Deep Clean Pro

Default install path:

```
C:\DeepCleanPro
```

Creates:

```
C:\DeepCleanPro\
    Backups\
    Logs\
    Scripts\
    Modules\  (reserved for future)
```

### ✔ Installs Script Files

Automatically deploys:

* `DeepCleanPro.ps1` (main engine)
* `Fix-WindowsPolicies.ps1`
* `OneDriveNuke.ps1`
* `Scripts\VALIDATE.ps1`
* `Scripts\CreateDesktopShortcuts.ps1`
* Optional additions: Extensions, modules, enterprise files

### ✔ Creates Optional Desktop Shortcuts

If requested, installer generates:

* Quick Fix
* Gaming Mode
* Dev Mode
* Music Mode
* Video Mode
* Office Mode
* Test Mode
* Full Optimization
* OneDrive Liberator

### ✔ Creates Scheduled Task (Optional)

Ideal for technicians or enterprise deployment.

Scheduled task can:

* Run weekly
* Run silently in the background
* Use Quick Mode to prevent long run times

### ✔ Configures Execution Policy (Session Only)

DEPLOY.ps1 **does not modify system-level execution policy**.
It temporarily sets:

```
Set-ExecutionPolicy RemoteSigned -Scope Process
```

Safe, clean, and temporary.

### ✔ Logs Everything

Installer logs to:

```
C:\DeepCleanPro\Logs\Deploy_YYYYMMDD.log
```

---

# ▶️ **2. How to Run DEPLOY.ps1**

### Run as Administrator

```powershell
cd path\to\deep-clean-pro
.\DEPLOY.ps1
```

If not elevated, the script stops and tells the user to restart it with admin rights.

---

# 🔧 **3. Deployment Parameters**

These switches give you full control.

## **`-TargetPath`**

Specify a custom installation directory.

```powershell
.\DEPLOY.ps1 -TargetPath "D:\Tools\DeepCleanPro"
```

## **`-CreateShortcuts`**

Automatically creates desktop shortcuts.

```powershell
.\DEPLOY.ps1 -CreateShortcuts
```

## **`-CreateScheduledTask`**

Creates a weekly optimization task (Quick Mode by default).

```powershell
.\DEPLOY.ps1 -CreateScheduledTask
```

## **`-NonInteractive`**

Runs without any prompts — ideal for:

* MDT
* SCCM
* Intune
* GPO
* Silent technician deployment

```powershell
.\DEPLOY.ps1 -NonInteractive -CreateShortcuts -CreateScheduledTask
```

## **Combine Multiple Args**

```powershell
.\DEPLOY.ps1 -TargetPath "C:\DeepCleanPro" -CreateShortcuts -CreateScheduledTask -NonInteractive
```

---

# 📦 **4. Deployment Methods**

## Method A — Local Installation (Most Common)

```powershell
git clone https://github.com/iSystemDevelopment/deep-clean-pro.git
cd deep-clean-pro
.\DEPLOY.ps1 -CreateShortcuts
```

## Method B — Portable Installation (ZIP Release)

1. Download release ZIP
2. Extract to a folder
3. Run:

```powershell
.\DEPLOY.ps1
```

## Method C — Technician Install (Silent / Automated)

```powershell
powershell.exe -ExecutionPolicy Bypass -File DEPLOY.ps1 -NonInteractive -CreateShortcuts -CreateScheduledTask
```

## Method D — Enterprise / Domain Deployment

```powershell
Invoke-Command -ComputerName (Get-ADComputer -Filter *).Name `
    -ScriptBlock {
        & "\\Server\Share\DeepCleanPro\DEPLOY.ps1" -NonInteractive -CreateScheduledTask
    }
```

---

# 🧱 **5. Internal Architecture**

`DEPLOY.ps1` is divided into structured modules:

### **1. Validation Layer**

* Checks system requirements
* Verifies PowerShell version
* Confirms admin rights
* Ensures network connectivity if needed

### **2. Installation Layer**

* Creates directories
* Copies files
* Sets up environment variables
* Prepares module load paths

### **3. Shortcut System**

Uses `WScript.Shell` COM automation to create `.lnk` files with:

* Custom icons
* Administrator flag (0x20 bit)
* Easy-to-read names
* Automatic profile environment variables

### **4. Scheduled Task Layer**

Creates a task under:

```
Task Scheduler → Task Scheduler Library → Deep Clean Pro
```

Configured with:

* Highest privileges
* Hidden window
* Weekly trigger
* QuickMode by default

### **5. Logging Layer**

Writes detailed logs for audit & troubleshooting.

---

# 🛠️ **6. Technician Best Practices**

### ✔ Use `-NonInteractive` for silent rollout

### ✔ Add scheduled tasks for unattended maintenance

### ✔ Pre-stage files on a network share

### ✔ Use environment variables for profiles:

```
$env:DCP_PROFILE = 'Office'
```

### ✔ Test via WhatIf before production:

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

---

# 🧪 **7. Validation After Deployment**

Run:

```powershell
C:\DeepCleanPro\Scripts\VALIDATE.ps1
```

Expected output:

```
✅ Administrator privileges confirmed
✅ PowerShell 5.1+ Compatible
✅ Execution policy OK
✅ Backup system OK
✅ Logging system OK
```

---

# ⚠️ **8. Troubleshooting DEPLOY.ps1**

### ❗ “ExecutionPolicy Blocked”

Run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### ❗ “Access Denied”

Must be run as Administrator.

### ❗ “Cannot create scheduled task”

* Ensure Task Scheduler service is running
* Check domain policies restricting task creation

### ❗ Shortcuts missing icons

Your AV may have blocked file extraction — re-extract ZIP.

---

# 🔒 **9. Security Notes**

* DEPLOY.ps1 uses **no telemetry**
* Only modifies directories it owns
* Does not write to system paths except scheduled task API
* Validates all user input
* Uses safe temporary execution policy scope
* Logs troubleshooting information without personal data

---

# 🎉 **10. Deployment Complete!**
