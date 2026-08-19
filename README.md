# 🚀 **Deep Clean Pro**

### **The FREE Windows Optimization Suite that Actually Works**

**Fast. Safe. Open-source. No ads. No “Pro” version. No BS.**

<div align="center">

![Version](https://img.shields.io/badge/version-2.5.0-blue.svg)
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
* Office users 💼
* Technicians & sysadmins 🛠️
* Everyday users who want a **faster PC** 🚀

Built with **safety-first** design:

* Automatic backups
* Full WhatIf simulation
* Service + registry rollback
* Windows Update maintenance
* Specialized performance profiles
* Extensive logging

**No telemetry. No ads. No paywall. Always free.**

---

# ⭐ 1. One-Click Installation (Fastest)

## Step 1 — Run PowerShell as Administrator

1. Press **Windows Key**
2. Type **PowerShell**
3. Right-click **Windows PowerShell**
4. Select **Run as administrator**

## Step 2 — Paste and run:
```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path
```
or

```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

✔ No downloads
✔ No installers
✔ Always the latest version
✔ Fully open-source

---

# 🧠 Quick Quiz: What Do You Want to Fix?

Not sure which Deep Clean Pro mode to use?
Answer these quick questions and pick the best option:

### **1️⃣ Is your PC mainly for gaming?**

✔ Yes → **🎮 [Gaming PC](#-gaming-pc)**
✖ No → Continue ↓

---

### **2️⃣ Do you use programming tools?**

(VS Code, Visual Studio, Node, Python, JetBrains, etc.)

✔ Yes → **💻 [Development PC](#-development-pc)**
✖ No → Continue ↓

---

### **3️⃣ Do you make music (DAW, ASIO, USB audio)?**

✔ Yes → **🎵 [Music Production PC](#-music-production-pc)**
✖ No → Continue ↓

---

### **4️⃣ Do you edit or render videos?**

✔ Yes → **📹 [Video Editing PC](#-video-editing-pc)**
✖ No → Continue ↓

---

### **5️⃣ Just want it faster and cleaner?**

✔ Yes → **🚀 [Quick Fix Mode](#-quick-fix-mode)**
✖ I want everything → **🔥 [Full Optimization](#-full-optimization)**

---

### 🧪 First time or nervous?

Use **🧪 [Test Mode](#-test-mode-safe-preview)** — it shows everything **without making changes**.

---

### ☁️ Want to remove OneDrive completely?

→ **☁️ [OneDrive Liberator](#-onedrive-liberator)**

---

# 🖥️ 2. Shortcut Pack / Control Center (Beginner Friendly)

**Recommended (from a local clone or deploy):**

1. Open `Control-center.bat` for a menu, **or**
2. Double-click a file under `Shortcuts\` (each BAT elevates via `Scripts\Invoke-DcpElevated.ps1`)

To place desktop `.lnk` shortcuts after install:

```powershell
.\Scripts\CreateDesktopShortcuts.ps1
```

(Or run `.\DEPLOY.ps1 -CreateShortcuts`.)

| Shortcut              | Purpose                  |
| --------------------- | ------------------------ |
| 🚀 Quick Fix          | 5-minute safe cleanup    |
| 🎮 Gaming Mode        | Increase FPS, reduce lag |
| 💻 Dev Mode           | For coders & IDEs        |
| 🎵 Music Mode         | Low-latency audio        |
| 📹 Video Mode         | Smooth editing/rendering |
| 💼 Office Mode        | Productivity tuning      |
| 🧪 Test Mode          | No-change preview        |
| 🔥 Full Optimization  | Deep monthly clean       |
| ☁️ OneDrive Liberator | Safely remove OneDrive   |

Details: [Scripts/SHORTCUTS-README.md](Scripts/SHORTCUTS-README.md)

---

# 🎛️ 3. Choose Your Optimization Type

Run **PowerShell as Administrator**. The reliable pattern is: **download to a temp file, then call with parameters** (do not append `DeepCleanPro.ps1 -...` after `irm | iex` — that does not work).

## 🎮 **Gaming PC**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -Profile Gaming
```

---

## 💻 **Development PC**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -Profile Development
```

---

## 🎵 **Music Production PC**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -Profile Music
```

---

## 📹 **Video Editing PC**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -Profile Video
```

---

## 💼 **Office PC**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -Profile Office
```

---

## 🚀 **Quick Fix Mode**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -QuickMode -NoReboot
```

---

## 🔥 **Full Optimization**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path
```

(`irm ... | iex` also works for the default Balanced full run when you need no parameters.)

---

## 🧪 **Test Mode (Safe Preview)**

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -WhatIf
```

---

# ☁️ OneDrive Liberator

Safely remove OneDrive forever:

* Moves files to local backup
* Restores Desktop/Documents/Pictures
* Removes OneDrive completely
* Blocks it from reinstalling
* 100% safe, backed up before changes

Requires a local copy (repo root or `C:\DeepCleanPro` after deploy):

```powershell
.\OneDriveNuke.ps1
```

Or use `Shortcuts\Deep-Clean-OneDrive-Liberator.bat` / Control Center option 7.

---

# 🔧 Advanced Usage

### Security hardening (v2.5) — attack-surface reduction

Not a guarantee against attackers. Reduces common Windows exposure (firewall, SMBv1, AutoPlay, Guest, UAC, Defender check). Risky options (RDP / WinRM / LLMNR / PSv2 / ASR) are **user choices**.

```powershell
.\DeepCleanPro.ps1 -HardenOnly -WhatIf -NoReboot
.\DeepCleanPro.ps1 -HardenOnly -NoReboot
.\DeepCleanPro.ps1 -HardenOnly -HardenStrict -NoReboot
.\DeepCleanPro.ps1 -HardenOnly -DisableRdp -DisableWinRm -NoReboot
```

Details: [docs/SECURITY-HARDENING.md](docs/SECURITY-HARDENING.md)

### Expanded cleaning (v2.4)

Quick + Full now also clean: Prefetch (30+ days), Delivery Optimization, Recycle Bin, and known app caches (Edge/Chrome/Teams/Discord/npm/pip/NuGet…) with a size preview first.

```powershell
# Full clean + restore point + install updates
.\DeepCleanPro.ps1 -RunWindowsUpdates -NoReboot

# Preview reclaimable space without deleting
.\DeepCleanPro.ps1 -QuickMode -WhatIf -NoReboot

# Skip restore point / skip app caches
.\DeepCleanPro.ps1 -SkipRestorePoint -SkipAppCaches -NoReboot

# Optional DISM component cleanup (slow; Full mode only)
.\DeepCleanPro.ps1 -DeepComponentCleanup -NoReboot
```

### Run with no reboot:

```powershell
.\DeepCleanPro.ps1 -NoReboot
```

### Auto reboot when done:

```powershell
.\DeepCleanPro.ps1 -AutoReboot
```

### Run full update maintenance:

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates
```

More advanced commands:
👉 [docs/CLI-MASTERS.md](docs/CLI-MASTERS.md)
👉 [docs/EXAMPLES.md](docs/EXAMPLES.md)
👉 Full index: [INDEX.md](INDEX.md)

---

# 🏢 Enterprise Deployment

Supports:

* GPO startup scripts
* Intune / SCCM packages
* Remote execution via PowerShell Remoting
* Offline corporate mode
* Weekly scheduled maintenance

Full documentation:
👉 [docs/ADVANCED-GUIDE.md](docs/ADVANCED-GUIDE.md)
👉 [docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md)

---

# 🔒 Security

* No telemetry
* TLS 1.2 enforced
* Every change backed up
* Supports `-WhatIf` for safe testing
* Validated by PSScriptAnalyzer & Pester

See:
👉 [SECURITY.md](SECURITY.md)

---

# 🤝 Contributing

We welcome contributions!

Please read:
👉 [CONTRIBUTING.md](CONTRIBUTING.md)

---


# 🎉 Enjoy Your Faster PC!

