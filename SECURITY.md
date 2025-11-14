# 🛡️ **Deep Clean Pro – Security Policy**

### *Protecting users, systems, and contributors through transparency & best practices.*

Deep Clean Pro is designed with **security first**: no telemetry, no analytics, no hidden network traffic, and strict safety controls around all system-modifying operations.

This document explains:

* Supported versions
* Built-in security features
* Secure development practices
* Vulnerability reporting process
* How users can protect themselves
* Future security improvements

---

# ✔️ **Supported Versions**

We provide security updates and patches for:

| Version   | Supported       | Notes                                |
| --------- | --------------- | ------------------------------------ |
| **2.2.x** | ✅ Active       | Current stable series                |
| **2.1.x** | ⏳ Partial      | Security fixes only until June 2025  |
| **2.0.x** | ⚠️ Limited      | Only critical fixes until March 2025 |
| **< 2.0** | ❌ Unsupported  | Upgrade required                     |

---

# 🔒 **1. Built-In Security Features**

Deep Clean Pro includes multiple protective layers.

## 🧩 **Backup & Recovery System**

Before modifying anything:

* Registry keys → exported to `.reg`
* Services → startup mode saved to CSV
* Policies → exported to JSON
* Windows Update cache state → logged
* Backups timestamped & stored under:

  ```
  C:\DeepCleanPro\Backups\
  ```

## 🔐 **Execution Safety**

* Requires **Administrator** privileges
* All destructive steps require **ShouldProcess**
* **WhatIf mode** simulates the entire run without changes
* Full error catching with meaningful messaging

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

## 🌐 **Secure Web Downloads**

* TLS 1.2+ enforced
* No remote code except official installer
* GitHub raw URLs only (no third parties)
* URL domain allowlist:

  * github.com
  * raw.githubusercontent.com
  * gist.githubusercontent.com

## 🧹 **No Telemetry**

Deep Clean Pro **never** collects or sends:

* System info
* Hardware identifiers
* Logs
* Personal data
* Usage analytics

All logs stay on your machine only.

## 🪪 **Audit Logging**

All actions logged to:

```
C:\DeepCleanPro\Logs\
```

Including:

* Timestamps
* Actions performed
* Success / failure
* Registry + services touched

No sensitive data is ever written to logs.

## 🩺 **Static & Runtime Validation**

* PSScriptAnalyzer
* Strict parameter validation
* Input sanitization
* Path canonicalization
* Prevents path traversal
* Prevents injection via unsafe parameters

---

# 🚨 **2. Reporting a Vulnerability**

We strongly encourage **responsible disclosure**.

## ❗ DO NOT open a public GitHub Issue

This exposes users before a fix is ready.

## Secure ways to report:

### 🔐 **Preferred: GitHub Security Advisory**

👉 [https://github.com/iSystemDevelopment/deep-clean-pro/security/advisories](https://github.com/iSystemDevelopment/deep-clean-pro/security/advisories)

### 📧 **Alternative: Email**

* [security@isystem.app](mailto:security@isystem.app) (secure inbox)
* PGP key available on request

### What to include:

* Description of vulnerability
* Impact analysis
* Steps to reproduce
* Affected versions
* PoC (if safe)
* Suggested fix (optional)
* Environment details:

  * Windows version
  * PowerShell version
  * Deep Clean Pro version
  * Execution context (admin/normal)

### Example Template

````markdown
## Vulnerability Summary
[Clear description]

## Severity
Critical / High / Medium / Low

## Steps to Reproduce
1. …
2. …
3. …

## Proof of Concept
```powershell
# PoC here
````

## Impact

[What can attacker achieve?]

## Environment

* Windows 11 23H2
* PowerShell 5.1
* Deep Clean Pro 2.2.0

## Suggested Fix

[optional]

````

---

# ⏱️ **3. Response Timeline**

We commit to:

| Stage | Timeline |
|-------|----------|
| Initial Response | within **48 hours** |
| Assessment | within **5 business days** |
| Patch (Critical) | 24–48 hours |
| Patch (High) | 3–5 days |
| Patch (Medium) | 1–2 weeks |
| Patch (Low) | Next planned release |
| Public advisory | After fix + coordinated disclosure |

---

# 🛠️ **4. Security Best Practices for Users**

## ✔ Always run latest version
```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
````

## ✔ Verify script integrity (optional)

```powershell
Get-FileHash -Algorithm SHA256 -Path "C:\DeepCleanPro\DeepCleanPro.ps1"
```

## ✔ Test in WhatIf mode first

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

## ✔ Review logs

Check for unusual activity:

```
C:\DeepCleanPro\Logs\
```

## ✔ Restrict folder permissions

Only administrators should have write access to:

```
C:\DeepCleanPro\
```

---

# 👨‍💻 **5. Security Best Practices for Developers**

## Code Requirements

* No hardcoded secrets
* No plaintext passwords
* Strict parameter validation
* No untrusted `Invoke-Expression`
* WhatIf compliance for destructive operations

## Secure Coding Example

**Good**

```powershell
$path = [System.IO.Path]::GetFullPath($UserPath)
```

**Bad**

```powershell
Invoke-Expression $UserInput
```

## Required Security Testing

Before merge:

* All PSScriptAnalyzer checks must pass
* WhatIf mode must not cause errors
* No external calls except GitHub raw HTTPS
* CI/CD must pass all security checks

---

# 🤖 **6. Automated Security Tools Used**

* **GitHub Security Scanning**
* **GitHub Dependabot**
* **PSScriptAnalyzer** for static analysis
* **Pester Security Tests**
* Custom validation logic in `VALIDATE.ps1`

---

# 🧭 **7. Security Roadmap**

Upcoming features (public roadmap):

* [ ] Script signing (code-sign certificate)
* [ ] Fully automated security tests in CI/CD
* [ ] Optional verification prompt for downloaded scripts
* [ ] Policy lockdown module (Windows hardening)
* [ ] Encrypted backup archives
* [ ] Enterprise compliance dashboard

---

# 🤝 **8. Acknowledgments**

Thank you to:

* Security researchers reporting responsibly
* Contributors improving internal safeguards
* Users who follow safe usage recommendations

Deep Clean Pro remains free and open because of your support.

---

# 📬 **9. Contact**

* **Security team:** [security@isystem.app](mailto:security@isystem.app)
* **General inquiries:** [info@isystem.app](mailto:info@isystem.app)
* **GitHub Security Advisories:** recommended for all disclosures
* **Discussions:** [https://github.com/iSystemDevelopment/deep-clean-pro/discussions](https://github.com/iSystemDevelopment/deep-clean-pro/discussions)

---

