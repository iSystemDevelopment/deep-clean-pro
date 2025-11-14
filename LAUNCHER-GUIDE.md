# 🚀 **Deep Clean Pro – Gist Launcher Guide**

### *Lightweight, secure, zero-install entry point for Deep Clean Pro.*

The **Gist Launcher** is the recommended way for users to run Deep Clean Pro with **one command**, without downloading, installing, or extracting anything.

It acts as a **bootstrap loader** that:

* Downloads the latest DeepCleanPro.ps1
* Validates the script
* Applies environment variables for profiles
* Passes through flags and settings
* Executes safely with proper logging
* Handles retries, network issues, and validation

This file explains how the launcher works and how to customize it safely.

---

# 📌 **What the Launcher Does**

When a user runs:

```powershell
irm 'https://gist.githubusercontent.com/.../raw/gist-launcher.ps1' | iex
```

The launcher will:

---

## ✔️ 1. Check System Preconditions

The launcher verifies:

* Internet connectivity
* PowerShell version
* Admin privileges (with warning if not elevated)
* Ability to reach GitHub (`raw.githubusercontent.com`)

---

## ✔️ 2. Download the Latest Deep Clean Pro Script

Uses a configured endpoint:

```
RepoUrl = "https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1"
```

It supports:

* Main branch
* Feature branches
* Forks
* Private mirrors (when auth headers are added)

The launcher retries intelligently if GitHub rate-limits or drops TLS.

---

## ✔️ 3. Validate Downloaded Script

Checks:

* HTTP status
* Content size (>1000 bytes)
* Keyword signatures such as `"Deep Clean Pro"`
* Optional SHA256 verification (if configured)

If validation fails:

* User receives a readable error
* Script will **never execute invalid content**

---

## ✔️ 4. Execute Deep Clean Pro in a Temporary Workspace

Launcher writes the downloaded script to a temp `.ps1` with:

```
$env:TEMP\DeepCleanPro\tmpXXXX.ps1
```

Then executes:

```powershell
& $tempFile @arguments
```

### Environment variables supported:

* `$env:DCP_PROFILE`
* `$env:DCP_QUICK_MODE`
* `$env:DCP_NO_REBOOT`

This is how your shortcut pack automatically preloads profiles.

---

## ✔️ 5. Cleanup Temporary Files

After execution, the launcher **automatically deletes** the temp script unless the user enables debug mode.

---

# ⚙️ **Launcher Configuration**

Inside `gist-launcher.ps1`, you have:

```powershell
$Script:Config = @{
    RepoUrl    = "https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1"
    ValidateUrl = "https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/Scripts/VALIDATE.ps1"
    Timeout     = 30
    RetryCount  = 3
    RetryDelay  = 2
}
```

### You may safely change:

| Key           | Purpose                                   |
| ------------- | ----------------------------------------- |
| `RepoUrl`     | Where DeepCleanPro.ps1 is downloaded from |
| `ValidateUrl` | Optional validation endpoint              |
| `Timeout`     | HTTP timeout seconds                      |
| `RetryCount`  | How many times to retry failed downloads  |
| `RetryDelay`  | Seconds between retries                   |

### Supported customizations:

✔ Switch to your `development` branch
✔ Point to a corporate Git server
✔ Redirect to a private fork
✔ Inject tokens for protected URLs
✔ Replace validation script with a corporate policy tool

---

# 🧱 **Internal Launcher Workflow**

The Gist launcher is intentionally **minimal**, **secure**, and **transparent**:

```
User runs irm/iex → Gist launcher → Validates →
Downloads DCP → Writes temp script →
Builds argument list → Executes DCP →
Cleans up → Exits gracefully
```

### Key internals:

* Uses **Invoke-WebRequest** (not Invoke-Expression on unknown content)
* Does not modify system settings directly
* Does not require installation
* Does not persist files
* Does not write to registry

---

# 🔒 **Security Features**

The launcher includes:

### ✔ TLS 1.2 enforcement

Ensures secure HTTPS communication.

### ✔ GitHub domain allowlists

Prevents MITM attacks via alternate hosts.

### ✔ Content-size checks

Rejects truncated content (common in MITM fail-open proxies).

### ✔ Keyword-based validation

Confirms downloaded script is the correct codebase.

### ✔ Optional SHA256 signatures

You may embed a whitelist of trusted script hashes.

### ✔ WhatIf compliance

If the user appends `-WhatIf`, the main script activates simulation mode.

---

# 🔐 **Adding Script Integrity Protection (Optional)**

You can enable extra security:

```powershell
$TrustedHashes = @(
   "YOUR_DEEPCLEANPRO_SHA256_HASH_HERE"
)

if ($downloadedHash -notin $TrustedHashes) {
    throw "Script integrity verification failed."
}
```

---

# 🌍 **Distributing Your Own Branded Launcher**

You can create:

* A second Gist (Beta channel)
* A corporate Gist (Enterprise channel)
* A localized launcher (different languages)

Simply update:

```powershell
RepoUrl = "https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1"
```

or point to your fork:

```powershell
RepoUrl = "https://raw.githubusercontent.com/MyOrg/DeepCleanPro/main/DeepCleanPro.ps1"
```

---

# 🖥️ **Running the Launcher (End User Guide)**

### Standard Run (default)

```powershell
irm "GIST_URL" | iex
```

### With gaming profile:

```powershell
$env:DCP_PROFILE='Gaming'
irm "GIST_URL" | iex
```

### With Quick Mode:

```powershell
$env:DCP_QUICK_MODE='true'
irm "GIST_URL" | iex
```

### WhatIf simulation (no changes made):

```powershell
irm "GIST_URL" | iex -WhatIf
```

---

# 🧪 **Testing the Launcher**

Technicians can use:

```powershell
.\gist-launcher.ps1 -Debug
```

or simulate failures:

* Disconnect network
* Change RepoUrl to an invalid address
* Remove "Deep Clean Pro" string
* Reduce `RetryCount = 1`

---

# 🆘 **Troubleshooting**

### ❗ “Admin privileges required”

User must right-click → Run as Administrator
OR the launcher warns and exits gracefully.

### ❗ “Could not download script”

Possible reasons:

* GitHub blocked by firewall
* Internet connection unstable
* TLS handshake failure
* Corporate proxy stripping content

### ❗ Script downloaded but fails validation

Fix:

* Update RepoUrl
* Ensure valid DeepCleanPro.ps1 exists
* Check branch name
* Check raw URL

### ❗ OneDrive paths missing

Occurs if user has no OneDrive installed — safe to ignore.

---

# 🏆 **Why Use the Launcher Instead of Manual Download?**

* Zero installation
* Always current version
* No ZIP extraction
* No file clutter
* Perfect for tutorials
* Perfect for social media “1-click” shares
* Perfect for enterprise machines with read-only system partitions
* Perfect for kiosk / classroom / test environments

---

# 🤝 **Contributing to the Launcher**

If you want to extend the launcher:

* Keep it **small**
* Keep it **secure**
* Avoid adding heavy modules
* Do not embed Deep Clean Pro code
* Avoid storing state on disk
* Ask in Discussions before major changes

---

# 🎉 **The Gist Launcher Makes Deep Clean Pro Instantly Accessible**

