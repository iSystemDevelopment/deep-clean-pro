# Contributing to Deep Clean Pro

First off, thank you for considering contributing to Deep Clean Pro! It's people like you that make Deep Clean Pro such a great tool. 🎉

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Style Guidelines](#style-guidelines)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Security](#security)

## 📜 Code of Conduct

This project and everyone participating in it is governed by our Code of Conduct. By participating, you are expected to uphold this code:

- **Be Respectful**: Treat everyone with respect. No harassment, discrimination, or inappropriate behavior.
- **Be Collaborative**: Work together towards common goals.
- **Be Professional**: Maintain professionalism in all interactions.
- **Be Constructive**: Provide helpful feedback and accept criticism gracefully.

## 🤝 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, please include:

- **Clear title and description**
- **Steps to reproduce**
- **Expected behavior**
- **Actual behavior**
- **System information** (Windows version, PowerShell version)
- **Screenshots** if applicable
- **Error messages** and logs

**Template:**
```markdown
## Bug Description
Brief description of the bug

## Steps to Reproduce
1. Run command '...'
2. Select option '...'
3. See error

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## System Information
- Windows Version: [e.g., Windows 10 21H2]
- PowerShell Version: [e.g., 5.1.19041.1682]
- Deep Clean Pro Version: [e.g., 2.2.0]

## Additional Context
Any other relevant information
```

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Use case**: Why is this enhancement needed?
- **Proposed solution**: How should it work?
- **Alternatives considered**: What other solutions did you consider?
- **Additional context**: Any other relevant information

### Code Contributions

1. **Fork the Repository**
2. **Create a Feature Branch**
3. **Make Your Changes**
4. **Test Thoroughly**
5. **Submit a Pull Request**

## 🛠️ Development Setup

### Prerequisites

- Windows 10+ with PowerShell 5.1+
- Git for version control
- Administrator privileges for testing
- Visual Studio Code (recommended) with PowerShell extension

### Setting Up Your Development Environment

```powershell
# 1. Fork and clone the repository
git clone https://github.com/YOUR-USERNAME/deep-clean-pro.git
cd deep-clean-pro

# 2. Create a feature branch
git checkout -b feature/your-feature-name

# 3. Set up development environment
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# 4. Install development dependencies (if any)
Install-Module -Name PSScriptAnalyzer -Scope CurrentUser
Install-Module -Name Pester -Scope CurrentUser

# 5. Run validation
.\Scripts\VALIDATE.ps1
```

### Project Structure

```
deep-clean-pro/
├── DeepCleanPro.ps1           # Main script
├── Fix-WindowsPolicies.ps1    # Policy helper
├── DEPLOY.ps1                 # Deployment script
├── Scripts/                   # Utility scripts
│   ├── VALIDATE.ps1
│   └── CreateDesktopShortcuts.ps1
├── Gist-Setup/                # Gist launcher files
├── Tests/                     # Test files
├── Docs/                      # Documentation
└── .github/                   # GitHub specific files
```

## 📝 Style Guidelines

### PowerShell Coding Standards

Follow the [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/):

#### Naming Conventions
```powershell
# Functions: Verb-Noun (Approved Verbs)
function Get-SystemInfo { }

# Variables: PascalCase for script/global, camelCase for local
$Script:Version = "2.2.0"
$localVariable = "value"

# Constants: UPPERCASE with underscores
$MAXIMUM_RETRIES = 3
```

#### Code Structure
```powershell
# Function template
function Verb-Noun {
    <#
    .SYNOPSIS
        Brief description
    .DESCRIPTION
        Detailed description
    .PARAMETER ParameterName
        Parameter description
    .EXAMPLE
        Example usage
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ParameterName
    )
    
    begin {
        # Initialization
    }
    
    process {
        # Main logic
    }
    
    end {
        # Cleanup
    }
}
```

#### Best Practices
- **Use approved verbs** from `Get-Verb`
- **Add comment-based help** to all functions
- **Use `[CmdletBinding()]`** for advanced functions
- **Implement `-WhatIf`** for destructive operations
- **Use proper error handling** with try/catch
- **Write verbose output** for debugging
- **Validate parameters** with validation attributes

### Documentation Standards

- Use **Markdown** for all documentation
- Include **examples** for all features
- Keep **README** updated with changes
- Document **breaking changes** prominently
- Add **inline comments** for complex logic

### Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): subject

body

footer
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(cleanup): add Windows Search index optimization

fix(services): correct service backup path validation

docs(readme): update installation instructions

refactor(validation): improve error handling in Test-Requirement
```

## 🧪 Testing

### Running Tests

```powershell
# Run all tests
Invoke-Pester -Path .\Tests\

# Run specific test file
Invoke-Pester -Path .\Tests\DeepCleanPro.Tests.ps1

# Run with coverage
Invoke-Pester -Path .\Tests\ -CodeCoverage .\DeepCleanPro.ps1

# Run validation
.\Scripts\VALIDATE.ps1
```

### Writing Tests

Create test files in the `Tests` directory following the naming convention `*.Tests.ps1`:

```powershell
Describe "Function-Name" {
    Context "When valid input is provided" {
        It "Should return expected output" {
            $result = Function-Name -Parameter "Value"
            $result | Should -Be "ExpectedValue"
        }
    }
    
    Context "When invalid input is provided" {
        It "Should throw an error" {
            { Function-Name -Parameter $null } | Should -Throw
        }
    }
}
```

### Testing Requirements

Before submitting a PR, ensure:
- [ ] All existing tests pass
- [ ] New features have tests
- [ ] Code coverage is maintained or improved
- [ ] WhatIf mode works correctly
- [ ] No PSScriptAnalyzer warnings

## 🔄 Pull Request Process

### Before Submitting

1. **Update documentation** for any changed functionality
2. **Add tests** for new features
3. **Run validation** and ensure all checks pass
4. **Test on multiple Windows versions** if possible
5. **Update CHANGELOG** if applicable

### PR Guidelines

1. **Title**: Use conventional commit format
2. **Description**: Clearly describe what and why
3. **Link Issues**: Reference related issues
4. **Small PRs**: Keep changes focused and minimal
5. **Screenshots**: Include for UI changes

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Tested on Windows 10
- [ ] Tested on Windows 11
- [ ] All tests pass
- [ ] Added new tests

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings
- [ ] Version bumped if needed

## Related Issues
Fixes #(issue number)

## Screenshots (if applicable)
```

### Review Process

1. **Automated checks** run on all PRs
2. **Code review** by maintainers
3. **Testing** in different environments
4. **Approval** from at least one maintainer
5. **Merge** using squash and merge

## 🔒 Security

### Security Considerations

When contributing, please:
- **Never commit** sensitive data or credentials
- **Validate all inputs** to prevent injection attacks
- **Use secure APIs** and avoid deprecated methods
- **Follow principle of least privilege**
- **Test security implications** of changes

### Security Checklist

- [ ] No hardcoded credentials
- [ ] Input validation implemented
- [ ] No execution of untrusted code
- [ ] Proper error handling (no info leakage)
- [ ] Secure file operations
- [ ] No unnecessary privileges required

## 🎯 Areas Needing Help

We're particularly looking for help in these areas:

- **Testing**: More comprehensive test coverage
- **Documentation**: Tutorials and guides
- **Localization**: Multi-language support
- **Performance**: Optimization suggestions
- **Compatibility**: Testing on different Windows versions
- **Features**: New optimization modules

## 📚 Resources

### Helpful Links
- [PowerShell Documentation](https://docs.microsoft.com/powershell/)
- [PowerShell Gallery](https://www.powershellgallery.com/)
- [Windows System Administration](https://docs.microsoft.com/windows-server/administration/windows-commands/windows-commands)

### Learning Resources
- [PowerShell Best Practices](https://docs.microsoft.com/powershell/scripting/developer/cmdlet/strongly-encouraged-development-guidelines)
- [Git Workflow](https://www.atlassian.com/git/tutorials/comparing-workflows)
- [Markdown Guide](https://www.markdownguide.org/)

## 🙏 Recognition

Contributors will be recognized in:
- The project README
- Release notes
- Special thanks section

## 📬 Contact

- **GitHub Issues**: For bugs and features
- **Discussions**: For questions and ideas
- **Email**: dev@isystem.app for private concerns

---

Thank you for contributing to Deep Clean Pro! Your efforts help make Windows optimization accessible to everyone. 🚀