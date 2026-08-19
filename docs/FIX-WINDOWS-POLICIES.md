# 🛡️ **Fix-WindowsPolicies.ps1 – Windows Policy Repair Tool**

### *Restore broken Windows policies, fix misconfigurations, and repair Windows restrictions safely.*

**Fix-WindowsPolicies.ps1** is an **optional repair tool** included in Deep Clean Pro.
It restores essential Windows policies that may become corrupted, misconfigured, or altered by:

* Previous “tweak tools”
* Malware
* Group Policy remnants
* Registry corruption
* Failed Windows updates
* Over-aggressive privacy scripts
* Damaged user profiles

This tool is **safe**, **backed up**, and **designed to restore stable defaults**.

---

# 🎯 **Purpose of Fix-WindowsPolicies**

This module exists because many Windows systems have policy-level issues that cause:

### ❌ Settings not responding

### ❌ Windows Update errors

### ❌ Defender not updating

### ❌ System components disabled

### ❌ Missing features due to corruption

### ❌ Broken start menu / search restrictions

### ❌ Network restrictions

### ❌ Telemetry misconfiguration causing instability

The tool **does not modify security-hardening policies**, only **repairs broken or invalid ones**.

---

# 🔒 **Safety First — Backups Always**

Before making any changes, the tool:

✔ Exports relevant registry policy keys
✔ Saves backup to:

```
C:\DeepCleanPro\Backups\PolicyBackup_YYYYMMDD_HHMMSS.json
```

✔ Uses `ShouldProcess` (safe PowerShell pattern)
✔ Has full error handling
✔ Does NOT modify domain-managed GPOs (AD-joined machines stay intact)

This guarantees **you can restore previous settings** if needed.

---

# 💼 **What Policies Does This Tool Fix?**

Fix-WindowsPolicies.ps1 focuses on **core Windows functionality**, not preference-based tweaks.

Below is what it repairs.

---

## 🛠️ **1. Windows Update Policy Repairs**

Fixes policies blocking:

* Windows Update
* Feature updates
* Quality updates
* Delivery Optimization
* Update restart notifications

Clears invalid or corrupted keys under:

```
HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate
```

and subkeys like:

* `AU`
* `UX`
* `WindowsUpdatePolicy`

Restores standard defaults so Windows Update works normally again.

---

## 🧰 **2. Windows Defender / Security Center Repairs**

Fixes broken settings that may cause:

* Defender disabled unexpectedly
* Real-time protection stuck
* Tamper Protection errors
* Security Center not opening

Repairs keys under:

```
HKLM\SOFTWARE\Policies\Microsoft\Windows Defender
HKLM\SOFTWARE\Policies\Microsoft\Windows\System
```

Does **not** weaken security or permanently disable protection.

---

## 🔎 **3. Privacy / Telemetry Restore (Stability Mode)**

Some privacy tools break essential components by setting invalid policies.

This script repairs:

* DiagTrack policy corruption
* Telemetry misconfigurations
* Missing core consent settings
* WMI consistency issues

It **does not** force telemetry on — it restores safe defaults required for OS stability.

---

## 🏷️ **4. Explorer / Shell Restrictions Repair**

Fixes policies that break UX:

* Missing Control Panel
* Greyed-out Task Manager
* Hidden File Explorer options
* Search bar disabled
* Windows Settings app blocked

Repairs subkeys under:

```
HKCU\Software\Policies\Microsoft\Windows\Explorer
HKLM\Software\Policies\Microsoft\Windows\Explorer
```

---

## 🌐 **5. Network & Connectivity Policies**

Restores:

* TLS settings
* Network Location Awareness keys
* Proxy policy cleanup
* Broken connection restrictions

Ensures Windows can communicate properly for updates, Defender, and services.

---

## 👤 **6. User Profile Policy Repairs**

Fixes:

* Broken profile loading
* Redirected folder settings
* Old GPO leftovers
* Invalid roaming profile settings

Useful after:

* Profile corruption
* Resetting Windows
* Removing OneDrive
* Third-party “cleanup” tools

---

# 📦 **How to Run Fix-WindowsPolicies.ps1**

### ✔ Run manually

```powershell
.\Fix-WindowsPolicies.ps1
```

### ✔ Run from Deep Clean Pro

Deep Clean Pro provides a parameter:

```powershell
.\DeepCleanPro.ps1 -FixPolicies
```

This triggers the policy repair tool automatically with backup creation.

---

# 🔧 **Optional Parameters**

## `-BackupPath`

Specify a custom backup location.

```powershell
.\Fix-WindowsPolicies.ps1 -BackupPath "D:\Backups\PolicyBackup.json"
```

## `-Force`

Skip confirmation (technician mode):

```powershell
.\Fix-WindowsPolicies.ps1 -Force
```

---

# 📝 **Example Output**

```
[INFO] Backing up current policy keys...
[SUCCESS] Backup saved to C:\DeepCleanPro\Backups\PolicyBackup_20250212_141021.json

[INFO] Repairing Windows Update policy...
[SUCCESS] Repaired update deferral policy

[INFO] Repairing Windows Defender policy...
[SUCCESS] Restored Defender default configuration

[INFO] Cleaning privacy/telemetry remnants...
[SUCCESS] Removed invalid tracking entries

[INFO] Fixing Explorer restrictions...
[SUCCESS] Restored full access to Task Manager

[INFO] Fixing network configuration...
[SUCCESS] Network policy restored

All policy repairs complete.
A restart is recommended.
```

---

# 🧩 **Integration with Deep Clean Pro**

When run using:

```powershell
.\DeepCleanPro.ps1 -FixPolicies
```

Deep Clean Pro:

1. Validates system environment
2. Calls Fix-WindowsPolicies
3. Logs all changes
4. Continues with the selected profile / cleaning
5. Shows repair summary in final report

This makes policy repair **seamlessly integrated** into the main workflow.

---

# 🏢 **Enterprise Use Cases**

Great for:

* Repairing systems altered by old GPO remnants
* Resetting local group policies on non-domain PCs
* Repairing Windows Update across many machines
* Fixing broken Defender / Security Center
* Post-imaging cleanup

Admins can push it using:

```powershell
Invoke-Command -ComputerName $PC -ScriptBlock {
    & "C:\DeepCleanPro\Fix-WindowsPolicies.ps1" -Force
}
```

---

# 🛡️ **Security Notes**

* All changes are logged
* Backups are created **before** modifications
* No telemetry, no external calls
* Does NOT change enterprise GPO if machine is domain-joined
* 100% offline-capable
* Does not weaken security posture

---

# ❓ **FAQ**

### **Does this reset all Windows policies?**

❌ No — only **broken** or **corrupted** keys relevant to OS stability.

### **Will it undo corporate/group policies?**

❌ No — domain GPO is protected.

### **Do I need to restart afterward?**

✔ Yes, recommended for full effect.

### **Is this dangerous?**

❌ No — backups ensure you can revert at any time.

---

# 🎉 **Fix-WindowsPolicies.ps1 Keeps Windows Healthy**

