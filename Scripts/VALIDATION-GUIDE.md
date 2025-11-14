# 🧪 **Deep Clean Pro – Validation Tool (VALIDATE.ps1)**

### *System readiness checker for Deep Clean Pro. Ensures safety, compatibility, and reliability.*

`VALIDATE.ps1` is the official **pre-flight diagnostic tool** for Deep Clean Pro.
It is designed for:

* Technicians
* Power users
* Developers
* CI/CD automation
* Enterprise deployments
* Anyone who wants to confirm system compatibility before running Deep Clean Pro

This script performs **27+ checks** across system configuration, permissions, dependencies, filesystem, logging, and security.

---

# 📌 **What VALIDATE.ps1 Does**

The validator performs checks in the following categories:

---

## ✔️ **1. Environment & OS Checks**

Ensures the operating system supports Deep Clean Pro.

Checks include:

* Windows version (10/11 required)
* Build number (1607+)
* PowerShell version (5.1+)
* Architecture (x64 strongly recommended)
* Execution Policy (allows temporary script execution)

---

## ✔️ **2. Administrator Privilege Check**

Deep Clean Pro requires admin rights.

VALIDATE verifies:

* Current user token elevation
* UAC elevation status
* Capability to create scheduled tasks
* Capability to modify services
* Capability to write to root-level directories

If not elevated, VALIDATE instructs the user to relaunch as admin.

---

## ✔️ **3. PowerShell Runtime Checks**

Ensures the PowerShell environment is healthy:

* ScriptBlock invocation support
* TLS 1.2 availability
* Module load capability
* Memory & heap availability
* CIM/WMI subsystem functioning

This prevents failures during optimization, especially for service tuning.

---

## ✔️ **4. Network & GitHub Checks**

Deep Clean Pro depends on GitHub for:

* Updates
* Documentation
* Shortcut icons
* Installer scripts (for raw execution)

VALIDATE checks:

* DNS resolution for github.com
* HTTPS reachability
* TLS handshake
* Certificate validation
* Raw content access tests

If offline mode is needed, it warns accordingly.

---

## ✔️ **5. Directory Structure Checks**

Confirms the expected installation path exists:

```
C:\DeepCleanPro\
  Backups\
  Logs\
  Scripts\
  Modules\
```

If missing, VALIDATE can prepare the structure or recommend running DEPLOY.ps1.

---

## ✔️ **6. Backup Subsystem Test**

Deep Clean Pro requires backup safety.

VALIDATE checks:

* Registry backup folder accessibility
* Write permissions
* Disk space
* Service backup CSV write test
* Cleanup of temporary backup files

This ensures Deep Clean Pro can run safely without risk to user settings.

---

## ✔️ **7. Logging System Tests**

Ensures:

* Log folder exists
* Log file can be created
* Log file can be appended to
* File write locks are not blocking DCP

This is critical for traceability and recovery.

---

## ✔️ **8. Integrity Checks**

VALIDATE can detect:

* Corrupted installation
* Missing scripts
* Missing modules
* Deleted or renamed components
* Unintended modifications

If anything is missing, it suggests:

```
.\DEPLOY.ps1 -Repair
```

(This feature is optional depending on DEPLOY implementation.)

---

## ✔️ **9. Optional: Windows Update Subsystem Check**

Since Deep Clean Pro has a new Windows Update maintenance module, VALIDATE tests:

* Microsoft.Update.Session availability
* Ability to enumerate updates
* DISM readiness
* Cleanmgr integration (for Windows.old cleanup)

If something is broken, VALIDATE warns before Deep Clean Pro is run.

---

## ✔️ **10. Summary & Pass/Fail Report**

At the end you get a simple summary:

```
==========================================
 Deep Clean Pro - Validation Summary
==========================================

✔ Windows 11 detected
✔ PowerShell 5.1 OK
✔ Administrator privileges present
✔ Execution policy compatible
✔ Backup system operational
✔ Logging directory OK
✔ Network access to GitHub OK
✔ CIM subsystem responsive

All checks passed!  
You are ready to run Deep Clean Pro.
```

If something is wrong, you get clear guidance to fix it.

---

# ▶️ **How to Use VALIDATE.ps1**

### **Option 1 — From installed location**

```powershell
C:\DeepCleanPro\Scripts\VALIDATE.ps1
```

### **Option 2 — From source repo**

```powershell
.\Scripts\VALIDATE.ps1
```

### **Option 3 — Before running Deep Clean Pro**

```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
# (Deep Clean Pro will automatically run its own validations)
```

---

# 🔍 **Interpreting Results**

## ✔ Green checks

Everything is working perfectly — you’re safe to run Deep Clean Pro.

## ⚠ Yellow warnings

DCP will still run, but:

* Some features may be skipped
* Some optimizations may be less effective
* You may experience partial cleanup

Example warnings:

* “GitHub unreachable — using offline mode.”
* “Cannot validate update subsystem — skipping update maintenance.”

## ❌ Red failures

Deep Clean Pro will refuse to run until fixed.

Common failures:

| Failure                      | Fix                                                   |
| ---------------------------- | ----------------------------------------------------- |
| Not running as Administrator | Restart PowerShell → Run as Administrator             |
| PowerShell < 5.1             | Install via `winget install Microsoft.PowerShell`     |
| ExecutionPolicy blocked      | `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser` |
| Write permissions denied     | Fix folder ACLs                                       |
| CIM subsystem offline        | Restart WMI service or reboot                         |

VALIDATE explains fixes clearly.

---

# 🏗️ **Technician / Enterprise Use**

VALIDATE is safe to run across:

* Domain-joined computers
* SCCM/Intune environments
* GPO deployment scenarios
* Technician workstations
* Imaging/MDT environments

### Use with Invoke-Command:

```powershell
Invoke-Command -ComputerName PC123 -ScriptBlock {
    C:\DeepCleanPro\Scripts\VALIDATE.ps1
}
```

### Bulk validation (domain):

```powershell
$pcs = Get-ADComputer -Filter * | Select -ExpandProperty Name
Invoke-Command -ComputerName $pcs -ScriptBlock {
    & "C:\DeepCleanPro\Scripts\VALIDATE.ps1"
}
```

Great for rollout planning.

---

# 🔐 **Security Notes**

* No telemetry
* No remote execution beyond GitHub GET requests
* No data is sent to servers
* Logs remain local
* Safe to run on offline systems
* Does not modify system state

---

# 🚀 **When Should You Run VALIDATE.ps1?**

### ✔ Before running Deep Clean Pro for the first time

### ✔ After Windows reinstall

### ✔ When encountering errors

### ✔ Before deploying across an organization

### ✔ After cloning the GitHub repo

### ✔ After manual modifications to the DCP directory

### ✔ As part of a CI/CD pipeline

---

# 🆘 **Troubleshooting**

### ❗ “ExecutionPolicy prohibits running scripts”

Fix:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### ❗ “Not running as Admin”

Right-click PowerShell → **Run as administrator**

### ❗ “GitHub unreachable”

Check:

* Firewall
* VPN
* Proxy
* Corporate restrictions

### ❗ “CIM or WMI invalid”

Try:

```powershell
Restart-Service Winmgmt
```

or restart PC.

---

# 🎉 **VALIDATE.ps1 is Your Safety Net**

