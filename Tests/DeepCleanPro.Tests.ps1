# Pester v5 Tests for Deep Clean Pro
# Tests script syntax, parameters, security, and logic
# Version: 2.2.0

#Requires -Modules Pester

# --- Helper Functions -------------------------------------------------------

function Get-RepoRoot {
    # Find repository root by looking for key files
    $candidates = @()
    
    # Method 1: From PSScriptRoot
    if ($PSScriptRoot) {
        # If running from Tests directory
        if ($PSScriptRoot -match 'Tests$') {
            $candidates += (Split-Path -Parent $PSScriptRoot)
        }
        # If running from .github/tests directory  
        elseif ($PSScriptRoot -match '\.github[\\\/]tests$') {
            $candidates += (Join-Path $PSScriptRoot '..\..')
        }
        else {
            $candidates += $PSScriptRoot
        }
    }
    
    # Method 2: From current working directory
    $candidates += $PWD
    
    # Method 3: From GitHub Actions workspace
    if ($env:GITHUB_WORKSPACE) {
        $candidates += $env:GITHUB_WORKSPACE
    }
    
    # Try each candidate and verify it's the repo root
    foreach ($candidate in $candidates) {
        if ($candidate -and (Test-Path $candidate)) {
            try {
                $resolved = (Resolve-Path -LiteralPath $candidate).ProviderPath
                # Check if this is the repo root (has DeepCleanPro.ps1)
                if (Test-Path (Join-Path $resolved 'DeepCleanPro.ps1')) {
                    return $resolved
                }
            } catch {
                continue
            }
        }
    }
    
    # Last resort: current directory
    return $PWD
}

function Test-Syntax {
    param([string]$Path)
    
    $tokens = $null
    $errors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $Path,
        [ref]$tokens,
        [ref]$errors
    )
    return ($errors.Count -eq 0)
}

function Get-ScriptContent {
    param([string]$Path)
    
    if (Test-Path $Path) {
        return Get-Content -LiteralPath $Path -Raw
    }
    return $null
}

# --- Path Resolution --------------------------------------------------------

BeforeAll {
    $Script:RepoRoot = Get-RepoRoot
    $Script:ScriptsDir = Join-Path $Script:RepoRoot 'Scripts'
    
    # Core script paths
    $Script:MainScript = Join-Path $Script:RepoRoot 'DeepCleanPro.ps1'
    $Script:PolicyScript = Join-Path $Script:RepoRoot 'Fix-WindowsPolicies.ps1'
    $Script:DeployScript = Join-Path $Script:RepoRoot 'DEPLOY.ps1'
    $Script:ValidateScript = Join-Path $Script:ScriptsDir 'VALIDATE.ps1'
    $Script:ShortcutScript = Join-Path $Script:ScriptsDir 'CreateDesktopShortcuts.ps1'
    
    # Display debug info if verbose
    if ($VerbosePreference -eq 'Continue') {
        Write-Host "=== Test Environment ===" -ForegroundColor Yellow
        Write-Host "Repo Root: $Script:RepoRoot" -ForegroundColor Cyan
        Write-Host "Scripts Directory: $Script:ScriptsDir" -ForegroundColor Cyan
        Write-Host "Main Script Exists: $(Test-Path $Script:MainScript)" -ForegroundColor Green
    }
}

# --- Core Script Tests ------------------------------------------------------

Describe 'DeepCleanPro.ps1' {
    
    Context 'File Validation' {
        It 'Should exist in repository root' {
            Test-Path -LiteralPath $Script:MainScript | Should -BeTrue
        }
        
        It 'Should have valid PowerShell syntax' {
            Test-Syntax $Script:MainScript | Should -BeTrue
        }
        
        It 'Should require administrator privileges' {
            $content = Get-ScriptContent $Script:MainScript
            $content | Should -Match '#Requires\s+-RunAsAdministrator'
        }
        
        It 'Should specify minimum PowerShell version' {
            $content = Get-ScriptContent $Script:MainScript
            $content | Should -Match '#Requires\s+-Version\s+5\.1'
        }
    }
    
    Context 'Parameters' {
        BeforeAll {
            $Script:MainContent = Get-ScriptContent $Script:MainScript
        }
        
        It 'Should have QuickMode parameter' {
            $Script:MainContent | Should -Match '\[switch\]\$QuickMode'
        }
        
        It 'Should have NoReboot parameter' {
            $Script:MainContent | Should -Match '\[switch\]\$NoReboot'
        }
        
        It 'Should have AutoReboot parameter' {
            $Script:MainContent | Should -Match '\[switch\]\$AutoReboot'
        }
        
        It 'Should have FixPolicies parameter' {
            $Script:MainContent | Should -Match '\[switch\]\$FixPolicies'
        }
        
        It 'Should have SkipHealth parameter' {
            $Script:MainContent | Should -Match '\[switch\]\$SkipHealth'
        }
        
        It 'Should have SkipDefrag parameter' {
            $Script:MainContent | Should -Match '\[switch\]\$SkipDefrag'
        }
        
        It 'Should support WhatIf (SupportsShouldProcess)' {
            $Script:MainContent | Should -Match 'SupportsShouldProcess'
        }
    }
    
    Context 'Core Functions' {
        BeforeAll {
            $Script:MainContent = Get-ScriptContent $Script:MainScript
        }
        
        It 'Should define Write-ColorOutput function' {
            $Script:MainContent | Should -Match 'function\s+Write-ColorOutput'
        }
        
        It 'Should define Test-AdminPrivileges function' {
            $Script:MainContent | Should -Match 'function\s+Test-AdminPrivileges'
        }
        
        It 'Should define Initialize-Environment function' {
            $Script:MainContent | Should -Match 'function\s+Initialize-Environment'
        }
        
        It 'Should define Backup-RegistryKey function' {
            $Script:MainContent | Should -Match 'function\s+Backup-RegistryKey'
        }
        
        It 'Should define Clear-TempFiles function' {
            $Script:MainContent | Should -Match 'function\s+Clear-TempFiles'
        }
        
        It 'Should define Optimize-Services function' {
            $Script:MainContent | Should -Match 'function\s+Optimize-Services'
        }
    }
    
    Context 'Security Checks' {
        BeforeAll {
            $Script:MainContent = Get-ScriptContent $Script:MainScript
        }
        
        It 'Should not contain hardcoded passwords' {
            $Script:MainContent | Should -Not -Match '(?i)password\s*=\s*[''"][^''"]+[''"]'
        }
        
        It 'Should not contain hardcoded API keys' {
            $Script:MainContent | Should -Not -Match '(?i)(apikey|token|secret)\s*=\s*[''"][A-Za-z0-9_\-]{16,}[''"]'
        }
        
        It 'Should not use Invoke-Expression carelessly' {
            # Check for iex usage (should only be in controlled scenarios)
            if ($Script:MainContent -match '(iex|Invoke-Expression)') {
                # If found, ensure it's not with user input
                $Script:MainContent | Should -Not -Match '(iex|Invoke-Expression).*\$.*input'
            }
        }
        
        It 'Should implement proper error handling' {
            $Script:MainContent | Should -Match 'try\s*\{[\s\S]*?\}\s*catch'
        }
        
        It 'Should not have empty catch blocks' {
            ([regex]::Matches($Script:MainContent, 'catch\s*\{\s*\}')).Count | Should -Be 0
        }
    }
    
    Context 'Logic Validation' {
        BeforeAll {
            $Script:MainContent = Get-ScriptContent $Script:MainScript
        }
        
        It 'Should validate admin privileges before execution' {
            $Script:MainContent | Should -Match 'Test-AdminPrivileges.*throw.*Administrator'
        }
        
        It 'Should create backup directories before use' {
            $Script:MainContent | Should -Match 'New-Item.*-ItemType\s+Directory.*BackupPath'
        }
        
        It 'Should check if paths exist before operations' {
            $Script:MainContent | Should -Match 'Test-Path'
        }
        
        It 'Should restore execution policy in finally block' {
            $Script:MainContent | Should -Match 'finally[\s\S]*?Set-ExecutionPolicy.*OriginalExecutionPolicy'
        }
        
        It 'Should implement ShouldProcess for destructive operations' {
            $Script:MainContent | Should -Match '\$PSCmdlet\.ShouldProcess'
        }
    }
}

# --- Policy Helper Script Tests ---------------------------------------------

Describe 'Fix-WindowsPolicies.ps1' {
    
    Context 'File Validation' {
        It 'Should exist in repository root' {
            Test-Path -LiteralPath $Script:PolicyScript | Should -BeTrue
        }
        
        It 'Should have valid PowerShell syntax' {
            Test-Syntax $Script:PolicyScript | Should -BeTrue
        }
        
        It 'Should require administrator privileges' {
            $content = Get-ScriptContent $Script:PolicyScript
            $content | Should -Match '#Requires\s+-RunAsAdministrator'
        }
    }
    
    Context 'Security Features' {
        BeforeAll {
            $Script:PolicyContent = Get-ScriptContent $Script:PolicyScript
        }
        
        It 'Should create backups before changes' {
            $Script:PolicyContent | Should -Match 'Backup-Policies'
        }
        
        It 'Should support restoration from backup' {
            $Script:PolicyContent | Should -Match '\[switch\]\$RestoreBackup'
        }
        
        It 'Should NOT enable PowerShell Remoting' {
            $Script:PolicyContent | Should -Not -Match 'Enable-PSRemoting'
        }
        
        It 'Should NOT add antivirus exclusions' {
            $Script:PolicyContent | Should -Not -Match 'Add-MpPreference.*ExclusionPath'
        }
    }
}

# --- Deployment Script Tests ------------------------------------------------

Describe 'DEPLOY.ps1' {
    
    Context 'File Validation' {
        It 'Should exist in repository root' {
            Test-Path -LiteralPath $Script:DeployScript | Should -BeTrue
        }
        
        It 'Should have valid PowerShell syntax' {
            Test-Syntax $Script:DeployScript | Should -BeTrue
        }
        
        It 'Should require administrator privileges' {
            $content = Get-ScriptContent $Script:DeployScript
            $content | Should -Match '#Requires\s+-RunAsAdministrator'
        }
    }
    
    Context 'Parameters' {
        BeforeAll {
            $Script:DeployContent = Get-ScriptContent $Script:DeployScript
        }
        
        It 'Should have TargetPath parameter' {
            $Script:DeployContent | Should -Match '\[string\]\$TargetPath'
        }
        
        It 'Should have CreateScheduledTask switch' {
            $Script:DeployContent | Should -Match '\[switch\]\$CreateScheduledTask'
        }
        
        It 'Should have NonInteractive switch' {
            $Script:DeployContent | Should -Match '\[switch\]\$NonInteractive'
        }
    }
}

# --- Validation Script Tests ------------------------------------------------

Describe 'VALIDATE.ps1' {
    
    Context 'File Validation' {
        It 'Should exist in Scripts directory' {
            Test-Path -LiteralPath $Script:ValidateScript | Should -BeTrue
        }
        
        It 'Should have valid PowerShell syntax' {
            Test-Syntax $Script:ValidateScript | Should -BeTrue
        }
    }
    
    Context 'Functionality' {
        BeforeAll {
            $Script:ValidateContent = Get-ScriptContent $Script:ValidateScript
        }
        
        It 'Should have Test-Requirement function' {
            $Script:ValidateContent | Should -Match 'function\s+Test-Requirement'
        }
        
        It 'Should test PowerShell version' {
            $Script:ValidateContent | Should -Match 'PSVersionTable\.PSVersion'
        }
        
        It 'Should test administrator privileges' {
            $Script:ValidateContent | Should -Match 'Administrator.*IsInRole'
        }
        
        It 'Should return results when requested' {
            $Script:ValidateContent | Should -Match '\[switch\]\$ReturnResults'
        }
    }
}

# --- Integration Tests ------------------------------------------------------

Describe 'Integration Tests' {
    
    Context 'File System Operations' {
        BeforeAll {
            $Script:TestDir = Join-Path $TestDrive 'DeepCleanTest'
            New-Item -ItemType Directory -Path $Script:TestDir -Force | Out-Null
        }
        
        It 'Should create test directory successfully' {
            Test-Path -LiteralPath $Script:TestDir | Should -BeTrue
        }
        
        It 'Should create and write to log files' {
            $logFile = Join-Path $Script:TestDir 'test.log'
            'Test log entry' | Set-Content -LiteralPath $logFile
            Get-Content -LiteralPath $logFile | Should -Be 'Test log entry'
        }
        
        It 'Should handle paths with spaces' {
            $spacePath = Join-Path $Script:TestDir 'Path With Spaces'
            New-Item -ItemType Directory -Path $spacePath -Force | Out-Null
            Test-Path -LiteralPath $spacePath | Should -BeTrue
        }
    }
    
    Context 'Repository Structure' {
        It 'Should have required directories' {
            Test-Path (Join-Path $Script:RepoRoot 'Scripts') | Should -BeTrue
            Test-Path (Join-Path $Script:RepoRoot 'Gist-Setup') | Should -BeTrue
        }
        
        It 'Should have documentation files' {
            Test-Path (Join-Path $Script:RepoRoot 'README.md') | Should -BeTrue
            Test-Path (Join-Path $Script:RepoRoot 'LICENSE') | Should -BeTrue
            Test-Path (Join-Path $Script:RepoRoot 'SECURITY.md') | Should -BeTrue
        }
        
        It 'Should have GitHub Actions workflow' {
            $workflowPath = Join-Path $Script:RepoRoot '.github\workflows'
            if (Test-Path $workflowPath) {
                Get-ChildItem -Path $workflowPath -Filter '*.yml' | Should -Not -BeNullOrEmpty
            }
        }
    }
}

# --- Performance Tests ------------------------------------------------------

Describe 'Performance Tests' -Tag 'Performance' {
    
    Context 'Script Loading' {
        It 'Main script should parse in reasonable time' {
            $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
            Test-Syntax $Script:MainScript | Out-Null
            $stopwatch.Stop()
            $stopwatch.ElapsedMilliseconds | Should -BeLessThan 5000
        }
    }
}

# --- Summary Report ---------------------------------------------------------

AfterAll {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Repository Root: $Script:RepoRoot" -ForegroundColor Gray
    Write-Host "All tests completed!" -ForegroundColor Green
}