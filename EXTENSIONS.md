# 🧩 **Deep Clean Pro – Extension & Module System**

### *Extend, customize, and enhance Deep Clean Pro without modifying core code.*

Deep Clean Pro includes a **plugin-like extension system** that allows developers, technicians, and advanced users to add functionality **without altering the main script**.

Extensions enable you to:

* Add new optimizations
* Add new profiles
* Integrate enterprise tools
* Add custom cleanup modules
* Add hardware/vendor-specific tuning
* Create reusable building blocks
* Keep customizations safe during upgrades

This guide explains how the system works and how to build your own extensions.

---

# 📁 **Folder Structure**

Deep Clean Pro looks for extensions in:

```
C:\DeepCleanPro\Extensions\
```

Or when running from source:

```
.\Extensions\
```

Typical structure:

```
Extensions/
├── Optimize-Nvidia.ps1
├── Clean-TempChrome.ps1
├── Set-LowLatencyAudio.ps1
└── MyCompany-Enterprise.ps1
```

Each `.ps1` file is automatically imported at runtime.

---

# 🔍 **How Extension Loading Works**

During startup, Deep Clean Pro executes:

```powershell
$extensions = Get-ChildItem -Path ".\Extensions\*.ps1"
foreach ($ext in $extensions) {
    Write-ColorOutput "Loading extension: $($ext.Name)" -Type Info
    . $ext.FullName
}
```

✔ All `.ps1` files are loaded dynamically
✔ Functions inside become part of runtime
✔ No need to modify DeepCleanPro.ps1
✔ Loaded before profile-specific optimizations

---

# 🛠️ **What Extensions Can Do**

Extensions can:

### ✔ Add new PowerShell functions

Any function you define becomes automatically available:

```powershell
function Optimize-IntelGPU { ... }
```

### ✔ Add new cleanup modules

```powershell
function Clean-ChromeCache { ... }
```

### ✔ Add enterprise integrations

```powershell
function Sync-ConfigFromServer { ... }
```

### ✔ Add post-clean tasks

```powershell
Register-ExtensionHook -Stage "AfterOptimize" -ScriptBlock { ... }
```

### ✔ Override or wrap existing behavior

(Recommended: wrap, don’t override)

### ✔ Add new Deep Clean Pro profiles

(covered below)

---

# 🧱 **Adding a New Profile via Extension**

You can seamlessly add your own profile by extending the `Apply-ProfileOptimizations` switch logic.

Create an extension:

```
Extensions/MyCustomProfile.ps1
```

Add:

```powershell
function Invoke-CustomProfileOptimizations {
    Write-ColorOutput "Applying Custom Profile..." -Type Info
    
    # Your custom logic here
    Set-ItemProperty "HKCU:\Software\MyApp" -Name "Mode" -Value 1 -ErrorAction SilentlyContinue
}
```

Then register it:

```powershell
$Script:CustomProfiles['MyCustom'] = { Invoke-CustomProfileOptimizations }
```

Now you can run:

```powershell
.\DeepCleanPro.ps1 -Profile MyCustom
```

Or via environment variable:

```powershell
$env:DCP_PROFILE = "MyCustom"
```

---

# 🔧 **Optional: Extension Hooks**

Deep Clean Pro exposes lifecycle hooks:

| Stage              | Runs At                      |
| ------------------ | ---------------------------- |
| `BeforeStart`      | Before any optimization step |
| `AfterHealthCheck` | After system health scan     |
| `BeforeOptimize`   | Before core modules run      |
| `AfterOptimize`    | After all modules complete   |
| `BeforeSummary`    | Before final report          |
| `AfterSummary`     | After everything             |

### Register a hook:

```powershell
Register-ExtensionHook -Stage "AfterOptimize" -ScriptBlock {
    Write-ColorOutput "Running extension task after core optimization..." -Type Info
}
```

Extensions can add multiple hooks.

---

# 🧩 **Extension Template (Recommended)**

Create a new file:

```
Extensions/MyExtension.ps1
```

Paste this template:

```powershell
<#
.SYNOPSIS
    Example Deep Clean Pro extension
.DESCRIPTION
    Explain what your extension does here.
.NOTES
    Author: Your Name
    Version: 1.0
#>

# --- Functions provided by this extension ---

function Invoke-MyTune {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-ColorOutput "Running MyTune extension..." -Type Info

    if ($PSCmdlet.ShouldProcess("MyTune", "Optimize")) {
        # Example registry tweak
        Set-ItemProperty -Path "HKCU:\Software\MyCompany" -Name "FastMode" -Value 1 -ErrorAction SilentlyContinue
    }
}

# --- Hook registration (optional) ---
Register-ExtensionHook -Stage "AfterOptimize" -ScriptBlock {
    Invoke-MyTune
}
```

---

# 🔒 **Security Guidelines for Extensions**

### ✔ Follow Deep Clean Pro safety rules

* Use `ShouldProcess` for changes
* Implement `-WhatIf` behavior
* Use `Try/Catch` for external operations
* Avoid WMI (`Get-WmiObject`)
* Prefer CIM (`Get-CimInstance`)
* No `Invoke-Expression` with untrusted input

### ✔ No credential storage

Never save passwords or secrets in plain text.

### ✔ No forced execution policy changes

Extensions must not modify machine-wide settings.

### ✔ Keep code readable and auditable

Extensions should be easy to review and secure.

---

# 🔐 **Enterprise Extensions**

Extensions can integrate:

* AD/LDAP checks
* Compliance reporting
* Software inventory
* Security hardening
* Remote server sync
* Corporate deployment steps

Example enterprise extension:

```powershell
function Invoke-EnterpriseAudit {
    Write-ColorOutput "Collecting enterprise diagnostics..." -Type Info
    # gather workspace, versions, compliance, etc.
}

Register-ExtensionHook -Stage "BeforeSummary" -ScriptBlock {
    Invoke-EnterpriseAudit
}
```

---

# 💡 **Examples of Useful Extensions**

### ✔ GPU Vendor Tuning

`Optimize-Nvidia.ps1`
`Optimize-AMD.ps1`
`Optimize-IntelGPU.ps1`

### ✔ Browser Cleanup

`Clean-Chrome.ps1`
`Clean-Firefox.ps1`

### ✔ Enterprise Policy Reset

`Fix-CorpPolicy.ps1`

### ✔ Game-Specific Profiles

`Profile-Fortnite.ps1`
`Profile-Valorant.ps1`

### ✔ Audio/Video Workflows

`Optimize-ASIO.ps1`
`Tune-OBS.ps1`

---

# 🧪 **Testing Extensions**

### Run extension alone

```powershell
.\Extensions\MyExtension.ps1
Invoke-MyTune
```

### Run via Deep Clean Pro

```powershell
.\DeepCleanPro.ps1 -Profile MyCustom
```

### Simulate (no changes)

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

### Debug loading

```powershell
$DebugPreference = 'Continue'
.\DeepCleanPro.ps1
```

---

# 🚀 **Why Use Extensions Instead of Editing the Main Script?**

✔ Updates won’t overwrite your modifications
✔ Cleaner versioning & collaboration
✔ Easier troubleshooting
✔ Safe & modular
✔ Enterprise integration without forking
✔ Custom profiles without touching core logic
✔ Minimal maintenance

---

# 🎉 **Extensions Make Deep Clean Pro Infinitely Expandable**

