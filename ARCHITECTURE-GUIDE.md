# 🧱 **Deep Clean Pro – Developer Architecture Guide**

### *Internal design, execution flow, module architecture, and extensibility for maintainers & contributors.*

Deep Clean Pro is not just a script — it is a **modular Windows optimization engine** with:

* Profile-based behaviors
* A complete safety system
* Internal extension support
* Backup/recovery layers
* Lifecycle hooks
* Update maintenance capabilities
* Enterprise-grade integration paths
* CI/CD validation
* A universal installer/launcher

This document explains **how the engine works internally** and how to extend or modify it safely.

---

# 📐 **1. System Architecture Overview**

## High-Level Architecture

```
┌──────────────────────────────────────────────┐
│            User Entry Points                 │
│  (Shortcuts, Gist Launcher, CLI, DEPLOY)     │
└───────────────────────────┬──────────────────┘
                            │
┌───────────────────────────▼──────────────────┐
│           Execution Controller               │
│       DeepCleanPro.ps1 (Main Engine)         │
├──────────────────────────────────────────────┤
│  ✔ Argument Parser / Parameter Binding       │
│  ✔ Profile Manager                           │
│  ✔ Safety Layer (WhatIf / ShouldProcess)     │
│  ✔ Backup & Recovery                         │
│  ✔ Logging System                            │
│  ✔ Validation System                         │
│  ✔ Submodule Orchestration                   │
└───────────────────────────┬──────────────────┘
                            │
┌───────────────────────────▼──────────────────┐
│           Optimization Modules                │
│ (Services, Registry, Updates, Bloatware, etc.)│
└───────────────────────────┬──────────────────┘
                            │
┌───────────────────────────▼──────────────────┐
│            Extension System                  │
│     (Dynamic plugin .ps1 files)              │
└───────────────────────────┬──────────────────┘
                            │
┌───────────────────────────▼──────────────────┐
│          System Modification Layer           │
│     (Registry, Services, GPO, Cleanup)       │
└──────────────────────────────────────────────┘
```

Deep Clean Pro is structured to remain:

* Safe
* Extensible
* Maintainable
* Predictable
* Update-friendly

---

# ⚙️ **2. Main Script: DeepCleanPro.ps1**

This is the core of the system.

### Responsibilities:

### ✔ Parameter Handling

DeepCleanPro.ps1 accepts parameters:

* `-Profile`
* `-QuickMode`
* `-WhatIf`
* `-NoReboot`
* `-AutoReboot`
* `-FixPolicies`
* `-RunWindowsUpdates`
* `-SkipHealth`
* `-SkipDefrag`

### ✔ Environment Initialization

Includes:

* TLS 1.2
* ExecutionPolicy (process-safe)
* Directory creation
* Log creation
* Temp workspace
* Admin privilege verification

### ✔ Safety System

Implements:

* `ShouldProcess`
* WhatIf (`-WhatIfPreference`)
* Backup-before-change
* Temporary working file system
* Abort-on-critical-error

### ✔ Lifecycle Controller

Manages the execution phases:

```
Initialize → HealthCheck → Updates (optional) →
Core Optimizations → Profile → Optional Modules →
Summary → Reboot Logic
```

### ✔ Module Dispatcher

Calls functions in an organized, safe, predictable order.

---

# 🎛️ **3. Module Architecture**

Each major subsystem in Deep Clean Pro is its own module function:

| Module                     | Function                     |
| -------------------------- | ---------------------------- |
| Temp Cleanup               | `Clear-TempFiles`            |
| Services                   | `Optimize-Services`          |
| System Performance         | `Optimize-SystemPerformance` |
| Network                    | `Optimize-NetworkSettings`   |
| Startup                    | `Optimize-StartupPrograms`   |
| Windows Search             | `Optimize-WindowsSearch`     |
| Disk Cleanup               | `Invoke-DiskCleanup`         |
| Bloatware Removal          | `Remove-BloatwareApps`       |
| Windows Update Maintenance | `Optimize-WindowsUpdates`    |
| Summary                    | `Show-Summary`               |
| Policies                   | `Fix-WindowsPolicies.ps1`    |

### Design Principles

Each module must:

* Support `ShouldProcess`
* Honor WhatIf
* Provide user-friendly output
* Be reversible where possible
* Log actions

---

# 🎚️ **4. Profiles System**

Profiles are implemented inside a central function:

```
Apply-ProfileOptimizations
```

Profiles modify:

* Power plan
* GPU settings
* Disk behavior
* CPU scheduling
* Audio/video latency
* Developer environment configuration

Profiles include:

* Gaming
* Development
* Music
* Video
* Office
* Balanced (default)

### Environment Variable Override

Shortcuts can set:

```
$env:DCP_PROFILE = 'Gaming'
```

and DeepCleanPro.ps1 will detect this.

---

# 🌐 **5. Windows Update Maintenance Engine**

A standalone subsystem:

`Optimize-WindowsUpdates`

It performs:

* Update discovery
* Update download
* Update install
* DISM cleanup
* Windows.old cleanup
* Update cache flush
* Post-update validation

Enabled via:

* Full mode (asks user)
* `-RunWindowsUpdates`
* `-QuickMode` = disables by default

---

# 🔐 **6. Backup & Logging Architecture**

Before any change:

### ✔ Registry backup

Using `reg.exe export`.

### ✔ Service backup

Stored in CSV:

```
C:\DeepCleanPro\Backups\Services\ServiceConfig_YYYYMMDD.csv
```

### ✔ Policy backup

Stored in JSON.

### ✔ Logging

Daily log file:

```
C:\DeepCleanPro\Logs\DeepClean_YYYYMMDD.log
```

Logs include:

* Timestamp
* Action type
* Summary of change
* Errors/warnings
* Module name

---

# 🧪 **7. Validation System (VALIDATE.ps1)**

The validation script runs 27+ checks:

* OS version
* PowerShell version
* Permissions
* Network
* GitHub availability
* Backup system
* Logging
* CIM subsystem
* ExecutionPolicy
* WinRM/WMI health

DeepClean Pro optionally calls VALIDATE internally.

---

# 🚀 **8. Launcher Architecture (gist-launcher.ps1)**

The launcher is intentionally minimal and safe.

### Workflow:

```
irm | iex → Launcher loads → Validates → Downloads DeepCleanPro.ps1 →
Saves temp file → Applies env vars → Executes → Cleans up
```

### Guarantees:

* TLS enforced
* No permanent file writes
* Memory-safe execution
* Retry logic
* Content validation
* No secret storage
* No execution of unknown code

---

# 🧩 **9. Extension System Architecture**

Extensions are dynamically loaded `.ps1` modules:

```
.\Extensions\*.ps1
```

Deep Clean Pro discovers and loads them before optimizations.

### Extension capabilities:

* Add custom modules
* Add new profiles
* Register hooks
* Add enterprise behavior
* Override non-core functions (if necessary)

### Hooks:

| Stage            | Description               |
| ---------------- | ------------------------- |
| BeforeStart      | Before anything runs      |
| AfterHealthCheck | After system diagnostics  |
| BeforeOptimize   | Before core modules       |
| AfterOptimize    | After core modules        |
| BeforeSummary    | Before summary generation |
| AfterSummary     | Final step                |

---

# 🧵 **10. Execution Flow Chart**

```
User Input / Shortcut / Launcher
        │
        ▼
Initialize-Environment
        │
        ▼
Test-SystemHealth (optional)
        │
        ▼
WindowsUpdateMaintenance (Full mode optional)
        │
        ▼
Clear-TempFiles
        │
Optimize-Services
        │
Optimize-SystemPerformance
        │
Profile Optimizations
        │
Remove-BloatwareApps
        │
Optimize-NetworkSettings
        │
Optimize-StartupPrograms
        │
Optimize-WindowsSearch
        │
Invoke-DiskCleanup
        │
Update-SystemDrivers
        │
Defrag (HDD only)
        │
Summary
        │
        ▼
Reboot logic
```

---

# 🔒 **11. Security Architecture**

Deep Clean Pro enforces:

* No elevated execution unless required
* No untrusted code execution
* TLS-only downloads
* WhatIf-compliance
* Strict parameter validation
* Sanitized paths
* File integrity checks (optional)
* No telemetry
* No analytics
* No persistent background tasks

Launcher + DCP core are fully open-source and auditable.

---

# 🏢 **12. Enterprise Architecture**

Deep Clean Pro supports enterprise usage via:

### ✔ Scheduled tasks

### ✔ IMP/MDT/SCCM/Intune deployment

### ✔ Domain-wide execution via PS Remoting

### ✔ Central configuration via Extensions

### ✔ Compliance reporting modules

### ✔ Offline-only operation (optional)

---

# 🪛 **13. CI/CD Architecture**

GitHub Actions (CI/CD pipeline):

* Runs PSScriptAnalyzer
* Runs Pester tests
* Lints all PowerShell files
* Performs basic security checks
* Builds release artifacts
* Checks installer integrity
* Version tagging automation (optional)

---

# 🧩 **14. Developer Guidelines**

Developers must:

### ✔ Use CIM (`Get-CimInstance`) — NOT WMI

### ✔ Wrap external calls with Try/Catch

### ✔ Support WhatIf

### ✔ Support ShouldProcess

### ✔ Provide descriptive logging

### ✔ Avoid untrusted `Invoke-Expression`

### ✔ Never break backward compatibility without notice

### ✔ Document all new parameters

### ✔ Write Pester tests for new modules

---

# 🎉 **Deep Clean Pro Is Designed to Be Extendable, Safe, and Maintainable**

