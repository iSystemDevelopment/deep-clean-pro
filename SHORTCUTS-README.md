# 🎯 **Deep Clean Pro – Shortcuts Pack**

### *Fast, safe, optimized Windows cleanup — without typing anything.*

Welcome!
This Shortcut Pack gives you **easy, one-click access** to every mode of Deep Clean Pro — with custom icons, safe defaults, and automatic Administrator elevation.

No command line needed.
No technical knowledge required.

---

# 📥 **How to Install the Shortcuts**

1. Download the ZIP file
   👉 **DeepClean-Shortcuts.zip**

2. Right-click it → **Extract All**

3. Open the extracted folder

4. Double-click **Install-Shortcuts.bat**

This will automatically copy all shortcuts to your Desktop.

✔ Requires Administrator
✔ Safe, fast, automatic
✔ No internet prompts
✔ Each shortcut already includes icons & settings

---

# 🖥️ **Included Shortcuts & What They Do**

Below is everything included in your Shortcut Pack.

---

## 🚀 **1. Deep Clean – Quick Fix**

**Time:** 5 minutes
**Safety:** Very safe
**Best for:** Daily/weekly cleaning

This mode:

* Cleans temporary files
* Frees disk space
* Fixes common slowdowns
* Doesn’t reboot
* Doesn’t modify deep system settings

Ideal when you just need a quick speed boost.

---

## 🎮 **2. Deep Clean – Gaming Mode**

**Time:** 10–15 minutes
**Best for:** Gamers, streamers, FPS improvement

Optimizes:

* GPU scheduling
* CPU responsiveness
* Gaming services
* Fullscreen optimizations
* Background processes

This shortcut automatically loads:

```
-Profile Gaming
```

---

## 💻 **3. Deep Clean – Dev Mode**

**Best for:** Programmers, developers, IT students

Optimizes:

* Long path support
* Developer Mode
* Defender exclusions for:

  * .npm, .nuget
  * source/projects folders
  * Node, Python installs

Shortcut automatically loads:

```
-Profile Development
```

---

## 🎵 **4. Deep Clean – Music Mode**

**Best for:** FL Studio, Ableton, Reaper, OBS, audio engineers

Optimizes:

* DPC latency
* USB audio stability
* Disables sound enhancements
* Reduces audio dropouts

Loads automatically:

```
-Profile Music
```

---

## 📹 **5. Deep Clean – Video Mode**

**Best for:** Adobe Premiere, DaVinci Resolve, Vegas

Optimizes:

* GPU timeout values
* Disk caching for large files
* File system performance

Loads:

```
-Profile Video
```

---

## 💼 **6. Deep Clean – Office Mode**

**Best for:** Everyday users, work laptops, home PCs

Optimizes:

* Battery usage
* Power management
* Startup behavior
* General responsiveness

Loads:

```
-Profile Office
```

---

## 🧪 **7. Deep Clean – Test Mode**

**Safety:** 100% safe, no changes made
**Best for:** Nervous first-timers

This mode **shows** what will happen but does **not apply** anything.

Shortcut runs:

```
-WhatIf
```

Nothing changes on your PC — perfect for reviewing before running a real clean.

---

## 🔥 **8. Deep Clean – Full Optimization**

**Time:** 20–30+ minutes
**Best for:** Monthly deep maintenance
**Recommended for:** First-time users

This performs:

* Full cleanup
* Deep service optimization
* Registry tuning
* Startup tuning
* Bloatware removal
* Windows Search optimization
* Disk optimization
* Optional Windows Update maintenance

Shortcut runs the full engine with no profile override.

---

## ☁️ **9. Deep Clean – OneDrive Liberator**

**Danger Level:** Medium (permanent removal)
**Best for:** Users who want OneDrive **gone forever**

This tool:

* Moves all OneDrive files to:

  ```
  C:\Users\<You>\Documents\OneDrive-Backup-YYYY-MM-DD
  ```
* Restores Desktop / Documents / Pictures to **local folders**
* Uninstalls OneDrive
* Removes OneDrive from File Explorer
* Deletes leftover OneDrive files
* Blocks OneDrive from reinstalling via Windows Update

You MUST type `YES` to confirm.
Safe, but **not reversible** without reinstalling OneDrive manually.

---

# 🔐 **Automatic Administrator Elevation**

Every shortcut:

✔ Opens PowerShell as Administrator
✔ Handles permissions automatically
✔ Ensures the optimization engine runs safely

If Windows prompts:
**Click “Yes” — this is required.**

---

# 🎨 **Icons**

All shortcuts come with built-in, high-resolution icons for:

* Gaming
* Development
* Music
* Video
* Office
* Quick Fix
* Full Optimization
* OneDrive Liberator
* Test Mode

No separate download required.

---

# 📁 **Files Installed**

Inside the folder:

| File                                 | Purpose                     |
| ------------------------------------ | --------------------------- |
| `.lnk` shortcuts                     | Ready-to-run tools          |
| `DeepCleanPro.ico`                   | Icon used by shortcuts      |
| `Install-Shortcuts.bat`              | Copies shortcuts to Desktop |
| *(optional future)* OneDriveNuke.ps1 | If packaged locally         |

No executables, no installers, no hidden scripts.

---

# 🧪 **Testing Shortcuts**

You can test functionality safely with:

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

Test Mode shortcut already does this.

---

# ❓ **Troubleshooting**

### ❗ PowerShell window closes instantly

Run shortcut again → Right-click → **Run as administrator**

### ❗ “Cannot run scripts”

Run this:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### ❗ Nothing happens

Disable antivirus real-time scanning temporarily (rare).

### ❗ OneDrive shortcut warns about permanent removal

This is intentional — OneDrive Liberator is **forceful**.

---

# 🧩 **Advanced Usage**

You can use shortcuts AND advanced parameters together:

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -QuickMode -NoReboot
```

or with direct raw URL:

```powershell
$env:DCP_PROFILE='Gaming'
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

---

# 📞 **Support & Community**

* 🐛 Report bugs:
  [https://github.com/iSystemDevelopment/deep-clean-pro/issues](https://github.com/iSystemDevelopment/deep-clean-pro/issues)

* 💬 Ask questions:
  [https://github.com/iSystemDevelopment/deep-clean-pro/discussions](https://github.com/iSystemDevelopment/deep-clean-pro/discussions)

* ⭐ Star the project if it helped you!

---

# 🎉 **Enjoy your faster PC!**

