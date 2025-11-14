# 🚀 **Deep Clean Pro**

### **The FREE Windows Optimization Suite that Actually Works**

**Fast. Safe. Open-source. No ads. No “Pro” version. No BS.**

<div align="center">

![Version](https://img.shields.io/badge/version-2.2.0-blue.svg)
![Windows](https://img.shields.io/badge/Windows-10%20%2F%2011-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green)
![Free Forever](https://img.shields.io/badge/Price-FREE-brightgreen)

</div>

---

# 📌 **What Is Deep Clean Pro?**

Deep Clean Pro is a **complete Windows optimization engine** designed for:

* Gamers 🎮
* Developers 💻
* Music producers 🎵
* Video editors 📹
* Office & productivity users 💼
* Technicians & sysadmins 🛠️
* Everyday users who want a **faster PC** 🚀

Built with **safety-first** design:

* Automatic backups
* Full WhatIf simulation
* Service + registry rollback
* Windows Update maintenance
* Profiles for different workloads
* Logging for all changes

**No telemetry. No ads. No trackers. No paywalls.**

---

# ⭐ **1. One-Click Installation (Fastest Method)**

## 💡 Step 1 — Run PowerShell as Administrator

1. Press **Windows Key**
2. Type **PowerShell**
3. Right-click **Windows PowerShell**
4. Click **Run as Administrator**

## 💡 Step 2 — Paste this command

```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

✔ No downloads
✔ No installation
✔ Runs directly from GitHub
✔ Fully safe & open-source

---

# 🖱️ **2. Download Shortcut Pack (Easiest for Most Users)**

Don’t want to use commands?
Download the pre-made shortcuts:

### 📥 **Download All Shortcuts**

👉 [https://github.com/iSystemDevelopment/deep-clean-pro/releases/latest/download/DeepClean-Shortcuts.zip](https://github.com/iSystemDevelopment/deep-clean-pro/releases/latest/download/DeepClean-Shortcuts.zip)

Includes:

| Shortcut              | Purpose                               |
| --------------------- | ------------------------------------- |
| 🚀 Quick Fix          | 5-minute cleanup                      |
| 🎮 Gaming Mode        | Maximum FPS & reduced lag             |
| 💻 Dev Mode           | Boosts coding tools & build time      |
| 🎵 Music Mode         | Low-latency audio production          |
| 📹 Video Mode         | Smooth editing & rendering            |
| 💼 Office Mode        | Stable productivity profile           |
| 🧪 Test Mode          | Preview changes with no risk          |
| 🔥 Full Optimization  | Deepest cleanup (recommended monthly) |
| ☁️ OneDrive Liberator | Remove OneDrive safely & permanently  |

All shortcuts automatically:

* Run as administrator
* Load the correct profile
* Use custom icons
* Apply safe defaults

Run `Install-Shortcuts.bat` to add them to your Desktop.

---

# ⚙️ **3. Features & Capabilities**

## ✔ Complete Optimization Engine

* System health diagnostics
* Windows Update maintenance (optional)
* Deep cleaning of temporary files
* Registry performance tweaks
* Service optimization (CIM-safe implementation)
* Disk optimization & defragmentation
* Startup program analysis
* Search index rebuild
* Driver update checks
* GPO policy fixes (optional)

## ✔ Profiles for Every PC Type

* 🎮 **Gaming** — FPS boost, low-latency, GPU tuning
* 💻 **Development** — VS Code, JetBrains, Node, Python optimizations
* 🎵 **Music** — DPC latency, USB/audio tweaks
* 📹 **Video Editing** — file cache tuning, GPU timeouts
* 💼 **Office** — balanced, low-noise, fast startup
* 🚀 **Quick Fix** — safe 5-minute run
* 🔥 **Full Optimization** — deepest cleanup

## ✔ Safety Features

* Automatic registry backups
* Service configuration backups
* Built-in WhatIf mode
* Logging of all actions
* Rollback-friendly design

---

# ☁️ **4. OneDrive Liberator (Optional)**

Want to remove OneDrive completely?
Deep Clean Pro includes **OneDrive Liberator**, which:

* Moves ALL your OneDrive files to a local backup folder
* Restores Desktop/Documents/Pictures to LOCAL folders
* Uninstalls OneDrive fully
* Removes Explorer sidebar
* Deletes leftovers & cache
* Blocks Microsoft from reinstalling it
* Prompts for restart

Your files remain safe here:

```
C:\Users\<YourName>\Documents\OneDrive-Backup-YYYY-MM-DD
```

Run via shortcut or:

```powershell
.\OneDriveNuke.ps1
```

---

# 🧠 **5. Advanced Usage**

## Run with parameters

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -QuickMode -NoReboot
```

## Run from internet with parameters

```powershell
$env:DCP_PROFILE='Gaming'
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

## Invoke full Windows Update maintenance

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates
```

## Simulate everything (no changes)

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

---

# 🧩 **6. For Power Users & Technicians**

Deep Clean Pro supports:

### ✔ Parallel job execution

### ✔ Custom modules (Extensions/*.ps1)

### ✔ Custom profiles

### ✔ Remote execution via PowerShell Remoting

### ✔ Local or domain deployment

### ✔ SCCM / Intune packaging

### ✔ Group Policy startup scripts

### ✔ Compliance reporting

See **ADVANCED-GUIDE.md** for full details.

---

# 🏢 **7. Light Enterprise Deployment**

### ✔ Group Policy Startup Script

```powershell
if (Test-NetConnection github.com -Port 443 -Quiet) {
    Start-Process powershell.exe -WindowStyle Hidden -ArgumentList "-ExecutionPolicy Bypass -Command `"irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex`""
}
```

### ✔ Intune / SCCM Package

```xml
<CommandLine>
  powershell.exe -ExecutionPolicy Bypass -File DeepCleanPro.ps1 -Profile Office -QuickMode
</CommandLine>
```

### ✔ Domain-Wide Execution

```powershell
$computers = Get-ADComputer -Filter * | Select Name
Invoke-Command -ComputerName $computers.Name -ScriptBlock {
    & "C:\DeepCleanPro\DeepCleanPro.ps1" -Profile Office -QuickMode
}
```

---

# 🧪 **8. Testing & Validation**

### Validate system compatibility

```powershell
C:\DeepCleanPro\Scripts\VALIDATE.ps1
```

### Run unit tests

```powershell
Invoke-Pester -Path .\Tests\
```

---

# 🔒 **9. Security**

Deep Clean Pro implements:

* TLS 1.2 enforced
* Script integrity validation (optional module)
* Strict WhatIf support
* No remote code execution except installer
* No telemetry, no analytics, no data sent anywhere
* Full transparency (open-source MIT)

Report security issues privately:
📧 **[security@isystem.app](mailto:security@isystem.app)**

---

# 🤝 **10. Contributing**

We welcome PRs!

* Follow the style guidelines
* Include tests for new features
* Document changes
* Submit PRs via GitHub

See **CONTRIBUTING.md**.

---

# 📚 **11. Documentation**

* **Beginner Guide** – simple, non-technical
* **Advanced Guide** – power users + enterprise
* **Security Policy** – vulnerability reporting
* **Wiki** – troubleshooting, FAQs, more

---

# ⭐ **12. Support the Project**

If Deep Clean Pro helped you:

* ⭐ Star the repository
* 🫶 Share it with friends
* 🐛 Report bugs
* 💡 Suggest features
* 🔧 Contribute improvements

**Your support keeps it free for everyone.**

---

# 🏁 **13. License**

MIT License — free to use, modify, and distribute.

---

# 🎉 **Enjoy Your Faster PC!**

Deep Clean Pro exists for one reason:

> **Because you shouldn’t have to pay for software that simply makes your PC fast again.**
