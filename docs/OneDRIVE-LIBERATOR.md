# ☁️ **OneDrive Liberator (OneDrive Nuke Tool)**

### *Safely remove OneDrive, reclaim your files, and take back control of Windows.*

OneDrive Liberator is an **optional advanced tool** included in Deep Clean Pro.
It completely removes Microsoft OneDrive from your PC — **permanently**, **safely**, and **cleanly**.

This tool is perfect for users who:

* Want **OneDrive gone forever**
* Have issues with forced sync or duplicate folders
* Are tired of OneDrive hijacking Desktop/Documents/Pictures
* Need to free system resources
* Want predictable, local-only file storage
* Want privacy without cloud syncing

---

# ⚠️ **Important Warning — This is Permanent**

OneDrive Liberator:

* Removes OneDrive completely
* Deletes all OneDrive-related components
* Prevents OneDrive from reinstalling
* Moves your OneDrive-backed Desktop/Documents/Pictures back to local folders
* Breaks all cloud sync permanently (until manually reinstalled)

**Your personal files are safe** — they are moved locally.

If you need OneDrive sync in the future, you must install it manually from:
[https://www.microsoft.com/en-us/microsoft-365/onedrive/download](https://www.microsoft.com/en-us/microsoft-365/onedrive/download)

---

# 🧠 **What OneDrive Liberator Actually Does (Step-by-Step)**

Here is the **exact**, transparent process:

---

## 1️⃣ Auto-Elevates to Administrator

If not already elevated, it securely relaunches itself with:

* The same script
* The same parameters
* Preserved state

Unlike Deep Clean Pro (run via URL), this tool **must be local**, so auto-elevation is 100% reliable.

---

## 2️⃣ Shows a Big Red Warning

The user must type:

```
YES
```

to continue.

This protects users from accidental removal.

---

## 3️⃣ Detects OneDrive Installation

It checks all known paths:

```
%LOCALAPPDATA%\Microsoft\OneDrive
%PROGRAMFILES%\Microsoft OneDrive
%PROGRAMFILES(x86)%\Microsoft OneDrive
```

If OneDrive isn't detected → it exits safely.

---

## 4️⃣ Backs Up All OneDrive Files

If OneDrive contains files, Liberator:

* Recursively scans and counts them
* Calculates total size (GB)
* Copies everything to:

```
C:\Users\<You>\Documents\OneDrive-Backup-YYYY-MM-DD
```

This backup ensures **no data is lost**.

Includes:

* Files
* Desktop items
* Documents
* Pictures
* Videos
* Music
* Any custom OneDrive paths

Progress is shown while copying large sets.

---

## 5️⃣ Moves Shell Folders Back to Local Storage

Some Windows installations redirect:

* Desktop
* Documents
* Pictures
* Videos
* Music

…to OneDrive paths like:

```
C:\Users\<You>\OneDrive\Desktop
```

Liberator:

* Detects any redirected folders
* Creates proper local replacements
* Moves content safely
* Updates registry keys:

```
HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders
```

Result: Your PC becomes **OneDrive-independent again**.

---

## 6️⃣ Stops All Running OneDrive Processes

Using both PowerShell and Windows commands:

```
Stop-Process OneDrive*
taskkill /f /im OneDrive.exe
taskkill /f /im OneDriveStandaloneUpdater.exe
```

Ensures no files are locked before removal.

---

## 7️⃣ Uninstalls OneDrive

Primary uninstall path:

```
OneDriveSetup.exe /uninstall
```

Fallback if missing:

* Remove Appx package
* Remove provisioning package

Ensures complete removal regardless of Windows edition.

---

## 8️⃣ Removes All OneDrive Remnants

Deletes:

```
%LOCALAPPDATA%\Microsoft\OneDrive
%PROGRAMDATA%\Microsoft OneDrive
C:\OneDriveTemp
```

Cleans Explorer integration:

```
HKCR\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}
HKCR\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}
```

Removes startup entries:

```
HKCU\...\Run\OneDrive
```

---

## 9️⃣ Blocks OneDrive from Reinstalling Automatically

Creates Group Policy keys:

```
HKLM\SOFTWARE\Policies\Microsoft\Windows\OneDrive
    DisableFileSyncNGSC = 1
    DisableFileSync      = 1
```

This prevents:

* Silent reinstall via Windows Update
* Store-based reinstall
* New account auto-activation

---

## 🔟 Displays Final Summary

Shows:

* Backup location
* Completed actions
* Reinstall block confirmation
* Reminder to restart

---

## 🔁 Optionally Asks to Restart

You can reboot immediately or later.

Restart is **highly recommended**.

---

# 🧰 **Usage**

### Standard (Safe) Mode

```
.\OneDriveNuke.ps1
```

You will be prompted to type `YES` to continue.

### Force everything (for technicians)

```
.\OneDriveNuke.ps1 -Force
```

Skips confirmation.

Backup always runs first (files are copied under `Documents\OneDrive-Backup-YYYY-MM-DD`). There is no “skip backup” switch.

---

# 🎯 **Who Should Use This?**

### Great for:

* Offline-only users
* Privacy-focused users
* Gaming PCs
* Workstations with large projects
* VMs / sandboxes
* Users sick of OneDrive taking over Desktop/Documents

### Not recommended for:

* Users who rely on cloud syncing
* Shared family computers
* Enterprise-managed systems (unless approved)

---

# 🔒 **Security Notes**

* The script uses **no telemetry**
* All backups stay local
* All operations are logged
* Auto-elevation uses verified PowerShell APIs
* No external URLs except Windows paths
* No files are ever uploaded or transmitted

---

# 📝 **Included in Shortcut Pack**

The Shortcut Pack includes a desktop icon:

### ☁️ *Deep Clean – OneDrive Liberator*

with:

* Auto-admin elevation
* Custom icon
* User-friendly name
* Safe defaults
* Built-in warnings

---

# 🤝 **Support & Reporting**

* Bugs: [https://github.com/iSystemDevelopment/deep-clean-pro/issues](https://github.com/iSystemDevelopment/deep-clean-pro/issues)
* Discussions: [https://github.com/iSystemDevelopment/deep-clean-pro/discussions](https://github.com/iSystemDevelopment/deep-clean-pro/discussions)
* Security issues: [security@isystem.app](mailto:security@isystem.app)

---

# 🎉 **You’re in Control Again**

