# 🚀 **Deep Clean Pro – Installation Guide**

### *The Complete Setup Guide for Windows 10 & Windows 11*

Deep Clean Pro offers **multiple installation methods**, from simple one-click commands to enterprise deployment.
Choose the one that fits your experience level.

---

# 📋 1. System Requirements

### ✔ Supported Windows Versions

* Windows 10 (1607 or newer)
* Windows 11 (all versions)

### ✔ Required Software

* **PowerShell 5.1+** (pre-installed on Windows 10/11)
* **Administrator access**
* **Internet connection** (for script updates and maintenance)

### Optional (Advanced Users)

* Git
* VS Code
* Pester testing framework

---

# ⭐ 2. Method 1 — One-Click Install (Recommended)

This is the **fastest and easiest** way to run Deep Clean Pro.
No downloads. No files. No installers.

### Step 1 — Open PowerShell as Administrator

1. Press **Windows Key**
2. Type `PowerShell`
3. Right-click **Windows PowerShell**
4. Select **Run as administrator**
5. Click **Yes**

### Step 2 — Paste the command below:

```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

### ✔ Done!

Deep Clean Pro will start immediately, perform health checks, and guide you through the optimization process.

---

# 🖥️ 3. Method 2 — Control Center / Shortcuts (Beginner Friendly)

If you don’t want to type commands, use the in-repo BAT pack.

### Includes (`Shortcuts\` + `Control-center.bat`):

* 🚀 Quick Fix
* 🎮 Gaming Mode
* 💻 Dev Mode
* 🎵 Music Mode
* 📹 Video Mode
* 💼 Office Mode
* 🧪 Test Mode
* 🔥 Full Optimization
* ☁️ OneDrive Liberator

### Install:

1. Clone or download this repository (or run `.\DEPLOY.ps1`)
2. Use **`Control-center.bat`** / **`Shortcuts\*.bat`**, *or* create Desktop links:

```powershell
.\Scripts\CreateDesktopShortcuts.ps1
```

3. Double-click any mode and approve UAC

All shortcuts:

* Auto-elevate via `Scripts\Invoke-DcpElevated.ps1`
* Pass real `-Profile` / `-QuickMode` / `-WhatIf` parameters
* Prefer a local `C:\DeepCleanPro` install when present

---

# 🧩 4. Method 3 — Git Clone (Advanced Users)

Ideal for developers, technicians, and contributors.

```powershell
git clone https://github.com/iSystemDevelopment/deep-clean-pro.git
cd deep-clean-pro
```

### Install Deep Clean Pro locally:

```powershell
.\DEPLOY.ps1 -CreateShortcuts -CreateScheduledTask
```

### Run with parameters:

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -QuickMode
```

### Update:

```powershell
git pull
```

---

# 📦 5. Method 4 — Manual Download (Portable Install)

1. Visit releases:
   [https://github.com/iSystemDevelopment/deep-clean-pro/releases](https://github.com/iSystemDevelopment/deep-clean-pro/releases)
2. Download the ZIP (e.g., `DeepCleanPro-v2.2.0.zip`)
3. Extract to:

   ```
   C:\DeepCleanPro
   ```
4. Run:

   ```powershell
   .\DeepCleanPro.ps1
   ```

---

# ⚙️ 6. Installation Options & Flags

### **Profiles**

```powershell
-Profile Gaming
-Profile Development
-Profile Music
-Profile Video
-Profile Office
```

### **Control Flow**

```powershell
-QuickMode
-NoReboot
-AutoReboot
-WhatIf
-SkipHealth
-SkipDefrag
```

### **Windows Update Maintenance**

Now part of installation flow:

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates
```

Or when running Full Mode, DCP asks:

> "Run Windows Update maintenance? (Y/N)"

---

# ☁️ 7. OneDrive Liberator Installation

Included in the shortcut pack and full Git install.

To run manually:

```powershell
.\OneDriveNuke.ps1
```

### What it does:

* Moves all your OneDrive files to:
  `C:\Users\<You>\Documents\OneDrive-Backup-YYYY-MM-DD`
* Moves Desktop/Documents/Pictures back to local storage
* Fully uninstalls OneDrive
* Removes Explorer integration
* Prevents OneDrive reinstall

Ideal for users who want **OneDrive permanently removed**.

---

# 🏢 8. Enterprise / Technician Deployment

### Group Policy Startup Script

```powershell
if (Test-NetConnection github.com -Port 443 -Quiet) {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex`""
}
```

### Intune / SCCM Command

```xml
powershell.exe -ExecutionPolicy Bypass -File DeepCleanPro.ps1 -Profile Office -QuickMode
```

### Domain-Wide Execution

```powershell
$pcs = Get-ADComputer -Filter * | Select -Expand Name
Invoke-Command -ComputerName $pcs -ScriptBlock {
    & "C:\DeepCleanPro\DeepCleanPro.ps1" -Profile Office -QuickMode
}
```

---

# 🔎 9. Verify Installation

### Check logs:

```
C:\DeepCleanPro\Logs
```

### Check backups:

```
C:\DeepCleanPro\Backups
```

### Run validation:

```powershell
C:\DeepCleanPro\Scripts\VALIDATE.ps1
```

---

# 🛠️ 10. Troubleshooting

### “Running scripts is disabled”

Run:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### “Access denied”

Run PowerShell **as Administrator**.

### PowerShell closes instantly

Use:

* Shortcut pack
* Or run inside existing PowerShell session

### No internet

Ensure GitHub is reachable from your network.

More help:
[https://github.com/iSystemDevelopment/deep-clean-pro/discussions](https://github.com/iSystemDevelopment/deep-clean-pro/discussions)

---

# 📚 11. Next Steps

### ✔ Run Quick Fix

### ✔ Try a profile

### ✔ Use Full Optimization monthly

### ✔ Clean up OneDrive (optional)

### ✔ Share Deep Clean Pro with friends

---

# 🎉 Installation Complete

Deep Clean Pro is now ready to use.

