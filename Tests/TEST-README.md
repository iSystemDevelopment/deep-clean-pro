# 🧪 **Deep Clean Pro – Testing & Quality Assurance Guide**

### *Ensuring stability, safety, performance, and correctness across the entire optimization engine.*

Deep Clean Pro ships with a **comprehensive, multi-layered testing system** designed to identify:

* Logic errors
* Security vulnerabilities
* Regression bugs
* Platform inconsistencies
* Documentation mistakes
* PowerShell compatibility issues
* CI/CD validation failures

This document describes how testing works, how to run tests, how to write tests, and how Deep Clean Pro ensures **enterprise-grade reliability**.

> This guide fully replaces the legacy testing file based on the uploaded version .

---

# 🏗️ **1. Testing Architecture Overview**

Deep Clean Pro uses several testing layers to ensure full code integrity:

```
Testing Pipeline
│
├── Static Analysis (PSScriptAnalyzer)
│   ├── Best practices
│   ├── Security issues
│   └── Common logic errors
│
├── Syntax Validation
│   ├── PowerShell 5.1 syntax
│   ├── PS 7.x syntax
│   └── Parser integrity
│
├── Pester Unit Tests
│   ├── Function behavior
│   ├── Parameter tests
│   ├── Edge cases
│   └── Error handling
│
├── Integration Tests
│   ├── Registry simulation
│   ├── Filesystem operations
│   ├── Module interaction
│   └── Safety system testing
│
├── Security Tests
│   ├── Credential scanning
│   ├── Dangerous pattern detection
│   └── Input sanitization verification
│
└── Documentation Tests
    ├── Validate PowerShell code blocks
    ├── Ensure examples run without error
    └── Detect missing parameters
```

---

# 🧩 **2. Test Files & Responsibilities**

## ✔ `Tests/DeepCleanPro.Tests.ps1`

Full suite covering:

* Script existence
* Parameter definitions
* Function correctness
* Safety model compliance
* Backup logic
* Service optimization logic
* Windows Update maintenance logic
* JSON/CSV export consistency
* Profile system logic
* Environment variable overrides
* Error propagation

## ✔ `Tests/CheckMarkdownPSBlocks.ps1`

Ensures documentation stays correct by checking:

* PowerShell code blocks
* Markdown indentation
* Real examples running without error
* No outdated parameters
* No deprecated command patterns

This prevents outdated docs from drifting.

## ✔ `Scripts/VALIDATE.ps1`

Runtime safety validator includes:

* OS compatibility
* PowerShell compatibility
* Backup/logging read/write
* CIM subsystem health
* GitHub connectivity
* ExecutionPolicy checks
* Directory structure

This ensures Deep Clean Pro will not run in unsafe conditions.

---

# 🛠️ **3. Running All Tests Locally**

### Install prerequisites:

```powershell
Install-Module Pester -MinimumVersion 5.0.0 -Force
Install-Module PSScriptAnalyzer -Force
```

### Run Pester + Analyzer:

```powershell
Invoke-Pester -Path .\Tests\
Invoke-ScriptAnalyzer -Path . -Recurse
```

### Validate system configuration:

```powershell
.\Scripts\VALIDATE.ps1
```

### Validate documentation PowerShell:

```powershell
.\Tests\CheckMarkdownPSBlocks.ps1 -Recurse
```

---

# 🎚️ **4. Running Test Categories**

### Unit Only

```powershell
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -Tag Filter 'Unit'
```

### Integration Only

```powershell
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -TagFilter 'Integration'
```

### Performance Benchmarks

```powershell
Invoke-Pester -Tag 'Performance'
```

### Security Tests

```powershell
Invoke-Pester -Tag 'Security'
```

---

# 📊 **5. Code Coverage Reporting**

Generate a coverage report:

```powershell
$config = New-PesterConfiguration
$config.Run.Path = ".\Tests"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(".\DeepCleanPro.ps1")
$config.CodeCoverage.OutputPath = ".\coverage.xml"
$config.CodeCoverage.OutputFormat = "CoverageGutters"

Invoke-Pester -Configuration $config
```

---

# ⚠️ **6. Common Logic Problems Found by Tests**

## ❌ Missing Error Handling

```powershell
try { Remove-Item $file } catch {}    # BAD
```

### ✔ Correct:

```powershell
try {
    Remove-Item $file -ErrorAction Stop
} catch {
    Write-ColorOutput "Failed to remove file: $_" -Type Error
    throw
}
```

## ❌ Incorrect Parameter Validation

Hardcoded or unchecked paths cause breakages.

✔ VALIDATE & Pester catch this.

## ❌ Race Conditions

Using `Test-Path` → `Remove-Item` without catch logic.

✔ Tests enforce proper safe removal behavior.

## ❌ Hardcoded Constants

Values must come from environment or config.

## ❌ Missing `ShouldProcess` / `WhatIf` Support

All destructive operations MUST follow DCP’s safety model.

Pester verifies this.

---

# 🔒 **7. Security Testing**

Security-specific tests validate:

* No use of `Invoke-Expression` with untrusted input
* No hardcoded credentials
* All paths sanitized
* No external dependencies except GitHub Raw
* Proper handling of windows policies write operations
* No dangerous registry operations without backups

---

# 🤖 **8. GitHub Actions CI/CD Integration**

Deep Clean Pro includes an automated test pipeline:

### On every **push** or **pull request**:

1. Syntax validation
2. Script Analyzer (PSSA)
3. Full Pester test suite
4. Documentation validation
5. Security scan
6. WhatIf simulation
7. Launch script static check

### On **release**:

* Regenerate coverage report
* Package scripts
* Generate release ZIP
* Attach logs, checksums
* Integrity validation

This prevents broken code from reaching users.

---

# ✍️ **9. Writing New Tests**

### Basic Structure

```powershell
Describe 'My Function' {
    Context 'When doing X' {
        It 'Should return expected result' {
            $result = My-Function -Input 123
            $result | Should -Be 123
        }
    }
}
```

### Best Practices

* Test one thing per test
* Use meaningful test names
* Use Arrange → Act → Assert structure
* Mock external dependencies
* Include error-path tests
* Validate WhatIf behavior
* Test edge cases (empty inputs, nonexistent paths, invalid types)
* Use Pester tags (`Unit`, `Integration`, `Performance`, `Security`)

---

# 🏆 **10. Test Coverage Goals**

| Category               | Goal | Status      |
| ---------------------- | ---- | ----------- |
| Core Engine            | 90%  | ✔ Achieved  |
| Safety Model           | 100% | ✔ Achieved  |
| Error Handling         | 100% | ✔ Achieved  |
| Modules                | 90%  | ✔ Achieved  |
| Extension Hooks        | 75%  | In Progress |
| Documentation Examples | 100% | ✔ Achieved  |

---

# 🔧 **11. Troubleshooting Test Failures**

### **PSScriptAnalyzer Warnings**

Fix code or suppress justified cases:

```powershell
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
```

### **Pester Failures**

Run with detailed view:

```powershell
Invoke-Pester -Output Detailed
```

### **Path or Module Resolution Errors**

Use `$PSScriptRoot` consistently.

### **Inconsistent Behavior Across Machines**

Check:

* ExecutionPolicy
* Admin privileges
* Windows version
* Network access
* Permissions in working directory

---

# 🚀 **12. Continuous Improvement Philosophy**

Deep Clean Pro uses:

* Test-Driven Development (where feasible)
* Regression auditing
* Static analysis as a quality gate
* Cross-Windows-version validation
* Documentation-as-code testing

Every new feature must include:

* Unit tests
* Integration tests
* Validation tests
* Documentation updates

---

# 🎉 Final Notes

