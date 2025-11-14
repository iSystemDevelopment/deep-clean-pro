# 🤝 Contributing to **Deep Clean Pro**

Thank you for considering contributing to **Deep Clean Pro**!
This project exists because of developers, sysadmins, testers, and power users like you.
Whether you’re fixing bugs, improving docs, or adding features — **you’re appreciated**. ❤️

This guide explains:

* How to report bugs
* How to suggest features
* How to contribute code
* Development environment setup
* Testing requirements
* Security expectations
* Pull request guidelines

---

# 📜 Code of Conduct

By participating in this project, you agree to:

* **Be respectful** — No harassment, abuse, or discrimination
* **Be constructive** — Help others, give actionable feedback
* **Be professional** — Keep communication clear and polite
* **Be collaborative** — Work together for a better project

Failure to follow the code may result in moderation actions.

---

# 🐛 Reporting Bugs

Before reporting, please:

1. Check **existing issues**
2. Try the **latest version**
3. Run **Test Mode** (`-WhatIf`)
4. Run validator:

   ```powershell
   C:\DeepCleanPro\Scripts\VALIDATE.ps1
   ```

### ❗ Do NOT report security issues publicly.

Use the private process described in **SECURITY.md**.

### ✔ Bug Report Template

```markdown
## Bug Description
Clear summary of the issue.

## Steps to Reproduce
1. Run …
2. Choose …
3. Observe …

## Expected Behavior
What should happen.

## Actual Behavior
What actually happened.

## Logs / Screenshots
Attach logs from C:\DeepCleanPro\Logs if applicable.

## System Info
- Windows version:
- PowerShell version:
- Deep Clean Pro version:
- Execution method (shortcut / raw / git clone):
```

---

# 💡 Suggesting Enhancements

Enhancement suggestions are welcome!
When submitting a feature request, include:

* **Use case** — Why is this needed?
* **Proposed behavior** — How should it work?
* **Alternatives considered** — Why this approach?
* **Potential impact** — Risks or complexity

---

# 🧑‍💻 Contributing Code

## 1. Fork the repository

```bash
git fork https://github.com/iSystemDevelopment/deep-clean-pro
git clone https://github.com/YOUR-USERNAME/deep-clean-pro
cd deep-clean-pro
```

## 2. Create a feature branch

```bash
git checkout -b feature/your-feature-name
```

## 3. Set up the development environment

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

Install-Module PSScriptAnalyzer -Scope CurrentUser
Install-Module Pester -Scope CurrentUser
```

## 4. Make your changes

Follow the **style guidelines** below.

## 5. Validate your work

```powershell
.\Scripts\VALIDATE.ps1
Invoke-Pester -Path .\Tests\
```

## 6. Open a Pull Request

Follow the PR template below.

---

# 🧪 Testing Requirements

Before submitting a PR:

* [ ] All existing tests must pass
* [ ] New features must include tests
* [ ] WhatIf mode must behave correctly
* [ ] No PSScriptAnalyzer warnings
* [ ] Code must run cleanly on Windows 10 & 11
* [ ] CIM-based functions must not call deprecated WMI

---

# 🧹 Style Guidelines

### ✔ PowerShell Standards

We follow the **PowerShell Practice & Style Guide**.

### Naming Conventions

```powershell
# Functions: Verb-Noun
function Optimize-Services {}

# Globals (script scope)
$Script:Version = "2.2.0"

# Local variables
$serviceList = @()

# Constants
$MAX_RETRIES = 3
```

### Function Structure

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
        Short description
    .DESCRIPTION
        Full detailed description
    .PARAMETER ExampleParam
        Explanation
    .EXAMPLE
        Verb-Noun -ExampleParam value
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$ExampleParam
    )

    try {
        # Work
    }
    catch {
        Write-Error "Error: $_"
    }
}
```

### Required Practices

* ✔ All destructive functions **must support** `-WhatIf`
* ✔ Use **CIM** instead of WMI (`Get-CimInstance`)
* ✔ All functions must include **comment-based help**
* ✔ Use `ShouldProcess` for:

  * Registry writes
  * Service modifications
  * File deletions
* ✔ Use `Try/Catch` for ALL external calls
* ✔ Use `Write-ColorOutput` logging functions
* ✔ Keep code readable and commented

### Forbidden Patterns

❌ `Invoke-Expression <untrusted>`
❌ Hardcoded credentials
❌ Silently ignoring exceptions
❌ WMI (`Get-WmiObject`)
❌ Manipulating execution policy globally
❌ Unnecessary admin elevation

---

# 🔬 Testing Guide

### Run full test suite:

```powershell
Invoke-Pester -Path .\Tests\
```

### Validate system requirements:

```powershell
.\Scripts\VALIDATE.ps1
```

### Test specific file:

```powershell
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1
```

### Test with coverage:

```powershell
Invoke-Pester -CodeCoverage .\DeepCleanPro.ps1
```

### Manual Test Examples

```powershell
.\DeepCleanPro.ps1 -QuickMode -WhatIf
.\DeepCleanPro.ps1 -Profile Gaming
.\DeepCleanPro.ps1 -RunWindowsUpdates
.\OneDriveNuke.ps1 -Force
```

---

# 🔄 Pull Request Process

## Before Submitting

1. Update documentation if needed
2. Add or update tests
3. Verify cross-version compatibility
4. Run PSSA + Pester
5. Keep your PR focused (one feature / one fix)

## PR Template

```markdown
## Description
Brief summary of the changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Enhancement
- [ ] Documentation update
- [ ] Breaking change

## Testing Performed
- [ ] Windows 10 tested
- [ ] Windows 11 tested
- [ ] Pester tests passed
- [ ] VALIDATE.ps1 passed
- [ ] WhatIf tested

## Checklist
- [ ] Code follows style guidelines
- [ ] Added documentation
- [ ] Added tests
- [ ] No warnings from PSScriptAnalyzer
- [ ] Backwards compatible (unless breaking change)
```

---

# 🔒 Security Expectations

For all contributions:

* **Never** commit secrets or tokens
* Validate ALL inputs
* Use safe file operations
* Handle exceptions without revealing sensitive data
* Follow principle of least privilege
* Changes must not weaken security controls

See **SECURITY.md** for full policy.

---

# 🌍 Areas You Can Contribute

We welcome help in:

* Testing on more Windows builds
* New optimization profiles
* Windows Update module improvements
* OneDrive Liberator enhancements
* Documentation & tutorials
* UX improvements
* Localization (multi-language support)
* Performance tuning

---

# 📚 Helpful Resources

* PowerShell Docs:
  [https://learn.microsoft.com/powershell](https://learn.microsoft.com/powershell)
* PSScriptAnalyzer:
  [https://github.com/PowerShell/PSScriptAnalyzer](https://github.com/PowerShell/PSScriptAnalyzer)
* Pester Testing:
  [https://pester.dev](https://pester.dev)
* GitHub Flow:
  [https://guides.github.com/introduction/flow](https://guides.github.com/introduction/flow)

---

# 🙏 Thank You

