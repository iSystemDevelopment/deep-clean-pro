# ⚡ **Deep Clean Pro – Power User CLI Guide**

### *Master Deep Clean Pro from the terminal. Fast, flexible, scriptable.*

Deep Clean Pro exposes a rich, predictable, scriptable command-line interface (CLI) designed for:

* Automation
* Custom tooling
* Technician workflows
* Scheduled tasks
* Remote execution
* Power users who want full control

This guide teaches **everything you can do using CLI** — from simple optimization to enterprise-scale automation.

---

# 📌 **1. Core CLI Syntax**

Run Deep Clean Pro:

```powershell
.\DeepCleanPro.ps1 [parameters]
```

Run from the web (zero install):

```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

Run with arguments:

```powershell
& ([ScriptBlock]::Create((irm 'RAW_URL'))) @params
```

---

# 🎮 **2. Profiles (Performance Modes)**

### Default (Balanced)

```powershell
.\DeepCleanPro.ps1
```

### Gaming Profile

```powershell
.\DeepCleanPro.ps1 -Profile Gaming
```

### Development

```powershell
.\DeepCleanPro.ps1 -Profile Development
```

### Music / Audio Production

```powershell
.\DeepCleanPro.ps1 -Profile Music
```

### Video Editing

```powershell
.\DeepCleanPro.ps1 -Profile Video
```

### Office

```powershell
.\DeepCleanPro.ps1 -Profile Office
```

---

# 🚀 **3. Modes**

### Quick Mode (fast, non-invasive)

```powershell
.\DeepCleanPro.ps1 -QuickMode
```

### Full Optimization (default)

```powershell
.\DeepCleanPro.ps1
```

### Simulate everything (safe)

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

### Skip health check (advanced)

```powershell
.\DeepCleanPro.ps1 -SkipHealth
```

### Skip defrag (SSD-safe or hybrid use)

```powershell
.\DeepCleanPro.ps1 -SkipDefrag
```

### No reboot prompt

```powershell
.\DeepCleanPro.ps1 -NoReboot
```

### Auto reboot when done

```powershell
.\DeepCleanPro.ps1 -AutoReboot
```

---

# 🔧 **4. Windows Update Maintenance (Advanced)**

Trigger Windows Update maintenance manually:

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates
```

Run Deep Clean Pro with forced update run:

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates -Profile Office
```

Run updates only (same switch — run when you want the update step):

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates -NoReboot
```

`-RunWindowsUpdates` is off unless you pass the switch or set `$env:DCP_RUN_UPDATES='true'`.

---

# 🧩 **5. Combining Parameters (Power User Patterns)**

### Gaming + QuickMode + No Reboot

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -QuickMode -NoReboot
```

### Development + simulate only (risk-free)

```powershell
.\DeepCleanPro.ps1 -Profile Development -WhatIf
```

### Music Profile + Full Update Maintenance + AutoReboot

```powershell
.\DeepCleanPro.ps1 -Profile Music -RunWindowsUpdates -AutoReboot
```

### Balanced + Full Clean + Skip Defrag

```powershell
.\DeepCleanPro.ps1 -SkipDefrag
```

---

# 🖥️ **6. Using Environment Variables (Shortcut / Automation Mode)**

Shortcuts and launchers rely on environment variables.

You can use them too:

### Pre-load a profile:

```powershell
$env:DCP_PROFILE = 'Gaming'
```

Then run:

```powershell
irm 'RAW_URL' | iex
```

### Enable QuickMode:

```powershell
$env:DCP_QUICK_MODE = 'true'
```

### Disable auto reboot:

```powershell
$env:DCP_NO_REBOOT = 'true'
```

---

# 🧪 **7. CLI Testing & Debugging**

### Run in verbose mode

```powershell
$VerbosePreference = 'Continue'
.\DeepCleanPro.ps1 -Profile Gaming
```

### Debug mode (tracing PowerShell lines)

```powershell
Set-PSDebug -Trace 2
.\DeepCleanPro.ps1 -QuickMode
Set-PSDebug -Off
```

### Validate environment before running

```powershell
.\Scripts\VALIDATE.ps1
```

### Test internal functions manually

Example:

```powershell
Clear-TempFiles -WhatIf
Optimize-Services -WhatIf
Optimize-NetworkSettings -WhatIf
```

---

# 🔥 **8. OneDrive Liberator Commands**

### Run with confirmation

```powershell
.\OneDriveNuke.ps1
```

### Run silently (skip YES)

```powershell
.\OneDriveNuke.ps1 -Force
```

Backup always runs to `Documents\OneDrive-Backup-YYYY-MM-DD` first.

---

# 🛠️ **9. Fix Windows Policies Tool (CLI)**

Run standalone:

```powershell
.\Fix-WindowsPolicies.ps1
```

Run inside Deep Clean Pro:

```powershell
.\DeepCleanPro.ps1 -FixPolicies
```

Store backup elsewhere:

```powershell
.\Fix-WindowsPolicies.ps1 -BackupPath "D:\Backup\Policy.json"
```

---

# 📦 **10. Deployment & Automation CLI**

### Local deployment

```powershell
.\DEPLOY.ps1 -CreateShortcuts
```

### Silent technician install

```powershell
.\DEPLOY.ps1 -CreateShortcuts -CreateScheduledTask -NonInteractive
```

### Enterprise GPO deployment

```powershell
if (Test-NetConnection github.com -Port 443 -Quiet) {
    $path = "$env:TEMP\DeepCleanPro.ps1"
    irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
    & $path -QuickMode
}
```

### SCCM / Intune deployment

```powershell
powershell.exe -ExecutionPolicy Bypass -File DeepCleanPro.ps1 -Profile Office -QuickMode
```

---

# 🌍 **11. Remote Execution**

### Single remote PC

```powershell
Invoke-Command -ComputerName PC01 -ScriptBlock {
    & "C:\DeepCleanPro\DeepCleanPro.ps1" -Profile Office
}
```

### Bulk across domain

```powershell
$PCs = Get-ADComputer -Filter * | Select -Expand Name
Invoke-Command -ComputerName $PCs -ScriptBlock {
    & "C:\DeepCleanPro\DeepCleanPro.ps1" -QuickMode
}
```

---

# 🧩 **12. Extensions via CLI**

Extensions are automatically loaded from:

```
C:\DeepCleanPro\Extensions\
```

### Test an extension directly

```powershell
.\Extensions\MyExtension.ps1
Invoke-MyExtension
```

### Add custom profile override

```powershell
$env:DCP_PROFILE = "MyStudio"
irm 'RAW_URL' | iex
```

---

# 🔐 **13. CLI Security Best Practices**

* Always run elevated (Admin)
* Never run untrusted scripts via `irm | iex`
* Validate script hash (optional)
* Use `-WhatIf` to test safely
* Keep backups & logs enabled
* Avoid running on unstable OS builds (Insider)

Check hash:

```powershell
Get-FileHash .\DeepCleanPro.ps1 -Algorithm SHA256
```

---

# 🧱 **14. Advanced Developer CLI Patterns**

### Load raw script into memory and manipulate

```powershell
$script = irm 'RAW_URL'
$sb     = [ScriptBlock]::Create($script)
& $sb -Profile Gaming
```

### Time the execution

```powershell
Measure-Command { .\DeepCleanPro.ps1 -QuickMode }
```

### Profile script performance

```powershell
Measure-Script -Path .\DeepCleanPro.ps1 -Expression { .\DeepCleanPro.ps1 }
```

### Run specific module independently

```powershell
Optimize-WindowsUpdates -WhatIf
```

---

# 🎉 **15. CLI Mastery Achieved**
