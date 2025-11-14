# 🧪 Deep Clean Pro - Testing Documentation

## Overview

Deep Clean Pro includes a comprehensive testing suite designed to catch logic problems, syntax errors, and potential security issues before they reach production. This multi-layered testing approach ensures code quality and reliability.

## Why Testing Matters for Logic Problems

Tests are essential for catching:
- **Logic Errors**: Conditions that don't behave as expected
- **Edge Cases**: Unusual inputs or states that break the code
- **Regression Bugs**: Changes that break existing functionality
- **Security Vulnerabilities**: Dangerous patterns or exposed data
- **Performance Issues**: Inefficient code that impacts user experience

## Testing Architecture

```
Testing Pipeline
│
├── Static Analysis (PSScriptAnalyzer)
│   ├── Code style violations
│   ├── Best practice violations
│   └── Potential bugs
│
├── Syntax Validation
│   ├── PowerShell 5.1 compatibility
│   ├── PowerShell 7.x compatibility
│   └── Parser-level validation
│
├── Unit Tests (Pester)
│   ├── Function behavior
│   ├── Parameter validation
│   └── Error handling
│
├── Integration Tests
│   ├── Script interactions
│   ├── File system operations
│   └── Registry operations
│
├── Security Scans
│   ├── Credential detection
│   ├── Dangerous patterns
│   └── Input validation
│
└── Documentation Tests
    ├── PowerShell examples
    └── Code block validation
```

## Test Files

### 1. `Tests/DeepCleanPro.Tests.ps1`
Main Pester test suite covering:
- Script existence and structure
- Parameter validation
- Function definitions
- Security requirements
- Logic validation

### 2. `Tests/CheckMarkdownPSBlocks.ps1`
Validates PowerShell code in documentation:
- Syntax checking in README examples
- Placeholder detection
- Error handling validation

### 3. `Scripts/VALIDATE.ps1`
Runtime validation script:
- System requirements
- Environment configuration
- Prerequisites checking

## Running Tests Locally

### Prerequisites
```powershell
# Install required modules
Install-Module -Name Pester -MinimumVersion 5.0.0 -Force
Install-Module -Name PSScriptAnalyzer -Force
```

### Run All Tests
```powershell
# From repository root
cd deep-clean-pro

# Run Pester tests
Invoke-Pester -Path .\Tests\

# Run PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path . -Recurse

# Check documentation
.\Tests\CheckMarkdownPSBlocks.ps1 -Recurse

# Run validation
.\Scripts\VALIDATE.ps1
```

### Run Specific Test Categories
```powershell
# Only unit tests
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -TagFilter 'Unit'

# Only integration tests
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -TagFilter 'Integration'

# Only performance tests
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1 -TagFilter 'Performance'
```

### Test Coverage Report
```powershell
# Generate coverage report
$config = New-PesterConfiguration
$config.Run.Path = ".\Tests"
$config.CodeCoverage.Enabled = $true
$config.CodeCoverage.Path = @(".\DeepCleanPro.ps1")
$config.CodeCoverage.OutputPath = ".\coverage.xml"
$config.CodeCoverage.OutputFormat = "CoverageGutters"

Invoke-Pester -Configuration $config
```

## Common Logic Problems Detected

### 1. Missing Error Handling
**Problem**: Empty catch blocks or no error handling
```powershell
# BAD - Test will fail
try {
    Remove-Item $file
} catch {
    # Empty catch - errors silently swallowed
}

# GOOD - Test will pass
try {
    Remove-Item $file -ErrorAction Stop
} catch {
    Write-ColorOutput "Failed to remove file: $_" -Type Error
    throw
}
```

### 2. Incorrect Parameter Validation
**Problem**: Not checking if parameters are valid
```powershell
# BAD - Test will fail
function Set-Configuration {
    param([string]$Path)
    Set-Content -Path $Path -Value "config"  # No validation
}

# GOOD - Test will pass
function Set-Configuration {
    param([string]$Path)
    if (-not (Test-Path (Split-Path $Path -Parent))) {
        throw "Parent directory does not exist"
    }
    Set-Content -Path $Path -Value "config"
}
```

### 3. Race Conditions
**Problem**: Not handling concurrent access
```powershell
# BAD - Test may fail intermittently
if (Test-Path $file) {
    Remove-Item $file  # File might be deleted between check and removal
}

# GOOD - Test will pass consistently
try {
    Remove-Item $file -ErrorAction Stop
} catch [System.IO.FileNotFoundException] {
    # File already gone, that's okay
}
```

### 4. Hardcoded Values
**Problem**: Using hardcoded paths or credentials
```powershell
# BAD - Test will fail
$backupPath = "C:\Backup"  # Hardcoded path

# GOOD - Test will pass
$backupPath = if ($env:DEEPCLEANPRO_BACKUP_PATH) { 
    $env:DEEPCLEANPRO_BACKUP_PATH 
} else { 
    "$env:TEMP\Backup" 
}
```

### 5. Missing WhatIf Support
**Problem**: Destructive operations without WhatIf
```powershell
# BAD - Test will fail
function Remove-OldFiles {
    Get-ChildItem -Path $Path | Remove-Item -Force
}

# GOOD - Test will pass
function Remove-OldFiles {
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)
    
    Get-ChildItem -Path $Path | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.Name, "Remove")) {
            Remove-Item $_ -Force
        }
    }
}
```

## GitHub Actions CI/CD

The repository includes comprehensive GitHub Actions workflows that run automatically:

### On Push/PR
1. **Lint & Syntax Check** - Validates code quality
2. **Pester Tests** - Runs all unit and integration tests
3. **Validation Script** - Checks system requirements
4. **Markdown Validation** - Verifies documentation examples
5. **Security Scan** - Checks for vulnerabilities
6. **WhatIf Test** - Ensures safe mode works

### On Release
- Creates release package with checksums
- Uploads artifacts to GitHub release

## Test Writing Guidelines

### Structure
```powershell
Describe 'Component Name' {
    Context 'Scenario' {
        BeforeAll {
            # Setup
        }
        
        It 'Should do specific thing' {
            # Arrange
            $input = "test"
            
            # Act
            $result = Function-Under-Test -Input $input
            
            # Assert
            $result | Should -Be "expected"
        }
        
        AfterAll {
            # Cleanup
        }
    }
}
```

### Best Practices
1. **Test One Thing**: Each test should verify a single behavior
2. **Use Descriptive Names**: Test names should clearly state what they test
3. **Arrange-Act-Assert**: Structure tests consistently
4. **Mock External Dependencies**: Use Pester mocks for external calls
5. **Test Edge Cases**: Include tests for boundary conditions
6. **Test Error Cases**: Verify error handling works correctly

## Continuous Improvement

### Adding New Tests
When adding new features:
1. Write tests first (TDD approach)
2. Ensure tests fail initially
3. Implement feature until tests pass
4. Add integration tests if needed

### Monitoring Test Health
- Review test coverage regularly
- Update tests when requirements change
- Remove obsolete tests
- Keep test execution time reasonable

## Troubleshooting Test Failures

### Common Issues

**PSScriptAnalyzer Warnings**
```powershell
# Suppress specific warnings if justified
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '')]
```

**Pester Test Failures**
```powershell
# Run with detailed output
Invoke-Pester -Path .\Tests\ -Output Detailed
```

**Path Resolution Issues**
```powershell
# Use $PSScriptRoot for reliable paths
$scriptPath = Join-Path $PSScriptRoot "..\DeepCleanPro.ps1"
```

## Test Coverage Goals

| Component | Target Coverage | Current |
|-----------|----------------|---------|
| Core Functions | 90% | ✅ |
| Error Handlers | 100% | ✅ |
| Parameters | 100% | ✅ |
| Security Checks | 100% | ✅ |
| Integration Points | 80% | ✅ |

## Benefits of This Testing Approach

1. **Early Bug Detection**: Catch issues before users encounter them
2. **Regression Prevention**: Ensure changes don't break existing features
3. **Documentation**: Tests serve as usage examples
4. **Confidence**: Deploy with assurance that code works correctly
5. **Quality Gates**: Automated checks prevent bad code from merging

## Resources

- [Pester Documentation](https://pester.dev/docs/quick-start)
- [PSScriptAnalyzer Rules](https://github.com/PowerShell/PSScriptAnalyzer/blob/master/docs/Rules)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [PowerShell Testing Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/dev-cross-plat/create-standard-library-module)

---

**Remember**: Tests are not just about finding bugs - they're about preventing them from happening in the first place!