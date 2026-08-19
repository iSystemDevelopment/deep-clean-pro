<#
.SYNOPSIS
    Pester test suite for DeepCleanPro.ps1 and core safety / structure.

.DESCRIPTION
    This suite focuses on:
      - Script existence and syntax correctness
      - Parameter and attribute validation
      - Safety guarantees (SupportsShouldProcess, WhatIf)
      - Prohibition of deprecated APIs (Get-WmiObject)
      - Repository URL correctness (no Dr-Diodac references)
      - Presence of key helper functions (Write-ColorOutput)
#>

# Resolve path to DeepCleanPro.ps1 relative to Tests directory
$Script:RootPath    = Split-Path -Parent $PSScriptRoot
$Script:MainScript  = Join-Path $Script:RootPath 'DeepCleanPro.ps1'

Describe 'DeepCleanPro.ps1 - Script structure' -Tag 'Unit' {

    It 'Should exist at the expected path' {
        Test-Path $Script:MainScript | Should -BeTrue
    }

    It 'Should be syntactically valid PowerShell' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Script:MainScript,
            [ref]$null,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }

    It 'Should be decorated with CmdletBinding and SupportsShouldProcess' {
        $ast    = [System.Management.Automation.Language.Parser]::ParseFile($Script:MainScript, [ref]$null, [ref]$null)
        $scriptBlock = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.ScriptBlockAst] }, $true)

        $bindingAttr = $scriptBlock.Attributes |
            Where-Object { $_.TypeName.GetText() -eq 'CmdletBinding' }

        $bindingAttr | Should -Not -BeNullOrEmpty

        # Check for SupportsShouldProcess in attribute arguments
        $hasSupportsShouldProcess = $false
        foreach ($namedArg in $bindingAttr.NamedArguments) {
            if ($namedArg.ArgumentName -eq 'SupportsShouldProcess' -and $namedArg.Argument.Value.ToString().ToLower() -eq 'true') {
                $hasSupportsShouldProcess = $true
                break
            }
        }

        $hasSupportsShouldProcess | Should -BeTrue
    }
}

Describe 'DeepCleanPro.ps1 - Parameters' -Tag 'Unit' {

    # Parse AST once
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Script:MainScript, [ref]$null, [ref]$null)
    $paramBlock = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.ParamBlockAst] }, $true)

    It 'Should define expected parameters' {
        $paramNames = $paramBlock.Parameters.Name.VariablePath.UserPath

        $expected = @(
            'QuickMode',
            'NoReboot',
            'AutoReboot',
            'FixPolicies',
            'SkipHealth',
            'SkipDefrag',
            'Profile',
            'RunWindowsUpdates',
            'SkipExtensions',
            'SkipRestorePoint',
            'SkipAppCaches',
            'DeepComponentCleanup',
            'Harden',
            'HardenStrict',
            'HardenOnly',
            'DisableRdp',
            'DisableWinRm',
            'DisableLlmnr',
            'DisablePowershellV2',
            'EnableAsrRules'
        )

        foreach ($name in $expected) {
            $paramNames | Should -Contain $name
        }
    }

    It 'Should allow extension custom profiles (no hard ValidateSet on Profile)' {
        $content = Get-Content $Script:MainScript -Raw
        $content | Should -Match '\$Script:CustomProfiles'
        $content | Should -Match 'Assert-DcpProfile'
        # Profile is a plain [string] so extensions can register names
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($Script:MainScript, [ref]$null, [ref]$null)
        $paramBlock = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.ParamBlockAst] }, $true)
        $profileParam = $paramBlock.Parameters |
            Where-Object { $_.Name.VariablePath.UserPath -eq 'Profile' }
        $profileParam | Should -Not -BeNullOrEmpty
        $validateSetAttr = $profileParam.Attributes |
            Where-Object { $_.TypeName.GetText() -eq 'ValidateSet' }
        $validateSetAttr | Should -BeNullOrEmpty
    }

    It 'Should define expanded cleaning helpers' {
        $content = Get-Content $Script:MainScript -Raw
        foreach ($fn in @(
            'New-DcpRestorePoint',
            'Clear-AppCaches',
            'Clear-DeliveryOptimizationCache',
            'Clear-PrefetchCache',
            'Clear-WindowsUpdateDownloadCache',
            'Invoke-ComponentStoreCleanup',
            'Clear-RecycleBinSafe',
            'Invoke-SecurityHardening',
            'Confirm-DcpStrictChoice',
            'Disable-DcpSmbV1',
            'Set-DcpFirewallEnabled'
        )) {
            $content | Should -Match ("function\s+{0}" -f [regex]::Escape($fn))
        }
    }

    It 'Should document builtin profiles including Gaming and Balanced' {
        $content = Get-Content $Script:MainScript -Raw
        $content | Should -Match "BuiltinProfiles"
        $content | Should -Match "'Gaming'"
        $content | Should -Match "'Balanced'"
    }
}

Describe 'DeepCleanPro.ps1 - Safety & Deprecated APIs' -Tag 'Security','Unit' {

    $content = Get-Content $Script:MainScript -Raw

    It 'Should not use Get-WmiObject anywhere (CIM only)' {
        $matches = Select-String -InputObject $content -Pattern 'Get-WmiObject' -SimpleMatch
        $matches | Should -BeNullOrEmpty
    }

    It 'Should not contain Invoke-Expression on untrusted user input' {
        # We allow `| iex` from trusted raw GitHub URLs (launcher pattern),
        # but we disallow obvious untrusted patterns.
        $matches = Select-String -InputObject $content -Pattern 'Invoke-Expression' -SimpleMatch
        $matches | Should -BeNullOrEmpty
    }
}

Describe 'DeepCleanPro.ps1 - Repository URLs' -Tag 'Unit','Security' {

    $content = Get-Content $Script:MainScript -Raw

    It 'Should not contain old Dr-Diodac repository references' {
        $patterns = @(
            'Dr-Diodac/deep-clean-pro',
            'https://github.com/Dr-Diodac/deep-clean-pro',
            'https://raw.githubusercontent.com/Dr-Diodac/deep-clean-pro'
        )

        foreach ($p in $patterns) {
            (Select-String -InputObject $content -Pattern [Regex]::Escape($p) -SimpleMatch) |
                Should -BeNullOrEmpty
        }
    }

    It 'Should reference iSystemDevelopment/deep-clean-pro if any GitHub repo URLs exist' {
        $rawMatches = Select-String -InputObject $content -Pattern 'https://raw\.githubusercontent\.com/' -AllMatches
        $urlMatches = Select-String -InputObject $content -Pattern 'https://github\.com/' -AllMatches

        if ($rawMatches -or $urlMatches) {
            # If there are any URLs, they must point at iSystemDevelopment/deep-clean-pro
            $content | Should -Match 'iSystemDevelopment/deep-clean-pro'
        }
    }
}

Describe 'DeepCleanPro.ps1 - Helper functions' -Tag 'Unit' {

    It 'Should define Write-ColorOutput logging helper' {
        $content = Get-Content $Script:MainScript -Raw
        $content | Should -Match 'function\s+Write-ColorOutput'
    }
}

Describe 'DeepCleanPro.ps1 - Integration Sanity (non-executing)' -Tag 'Integration' {

    It 'Should be parsable with full AST and no errors (again, integration-level)' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Script:MainScript,
            [ref]$null,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }

    It 'Should not contain obvious hard-coded Dr-Diodac raw URLs in comments or examples' {
        $content = Get-Content $Script:MainScript -Raw
        $content | Should -Not -Match 'gist\.githubusercontent\.com/Dr-Diodac'
    }
}
