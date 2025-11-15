<#
.SYNOPSIS
    Pester tests for Gist / GitHub launcher script (gist-launcher.ps1).

.DESCRIPTION
    Static tests verifying that the launcher:
      - Exists and parses
      - Points to the correct repository
      - Handles environment variables for profiles / quick mode / no reboot
      - Uses safe APIs (no Invoke-Expression)
      - Performs admin checks and basic connectivity checks
#>

# Resolve path to gist-launcher.ps1 relative to Tests directory
$Script:RootPath      = Split-Path -Parent $PSScriptRoot
$Script:LauncherPath  = Join-Path (Join-Path $Script:RootPath 'Gist-Setup') 'gist-launcher.ps1'

Describe 'gist-launcher.ps1 - Script structure' -Tag 'Unit' {

    It 'Should exist at Gist-Setup\gist-launcher.ps1' {
        Test-Path $Script:LauncherPath | Should -BeTrue
    }

    It 'Should be syntactically valid PowerShell' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Script:LauncherPath,
            [ref]$null,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }

    It 'Should be decorated with CmdletBinding' {
        $ast    = [System.Management.Automation.Language.Parser]::ParseFile($Script:LauncherPath, [ref]$null, [ref]$null)
        $scriptBlock = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.ScriptBlockAst] }, $true)

        $bindingAttr = $scriptBlock.Attributes |
            Where-Object { $_.TypeName.GetText() -eq 'CmdletBinding' }

        $bindingAttr | Should -Not -BeNullOrEmpty
    }
}

Describe 'gist-launcher.ps1 - Config & repository URL' -Tag 'Unit','Security' {

    $content = Get-Content $Script:LauncherPath -Raw

    It 'Should define a $Script:Config hashtable with RepoUrl' {
        $content | Should -Match '\$Script:Config\s*=\s*@\{'
        $content | Should -Match 'RepoUrl'
    }

    It 'RepoUrl should point to iSystemDevelopment/deep-clean-pro on raw.githubusercontent.com' {
        $content | Should -Match 'https://raw\.githubusercontent\.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro\.ps1'
    }

    It 'Should not contain old Dr-Diodac repository references' {
        $patterns = @(
            'Dr-Diodac/deep-clean-pro',
            'https://github.com/Dr-Diodac/deep-clean-pro',
            'https://raw.githubusercontent.com/Dr-Diodac/deep-clean-pro',
            'gist\.githubusercontent\.com/Dr-Diodac'
        )

        foreach ($p in $patterns) {
            (Select-String -InputObject $content -Pattern [Regex]::Escape($p) -SimpleMatch) |
                Should -BeNullOrEmpty
        }
    }
}

Describe 'gist-launcher.ps1 - Network & download behavior' -Tag 'Unit','Security' {

    $content = Get-Content $Script:LauncherPath -Raw

    It 'Should use Invoke-WebRequest to download the script' {
        $content | Should -Match 'Invoke-WebRequest'
    }

    It 'Should implement retry logic via RetryCount / RetryDelay' {
        $content | Should -Match 'RetryCount'
        $content | Should -Match 'RetryDelay'
        $content | Should -Match 'while\s*\(\$attempt\s*-lt\s*\$Script:Config\.RetryCount'
    }

    It 'Should include a basic internet connectivity check' {
        $content | Should -Match 'Test-InternetConnection'
        $content | Should -Match 'raw\.githubusercontent\.com'
    }
}

Describe 'gist-launcher.ps1 - Admin + argument handling' -Tag 'Unit','Security' {

    $content = Get-Content $Script:LauncherPath -Raw

    It 'Should check for Administrator privileges' {
        $content | Should -Match 'WindowsBuiltInRole::Administrator'
    }

    It 'Should build arguments from environment variables: DCP_PROFILE, DCP_QUICK_MODE, DCP_NO_REBOOT' {
        $content | Should -Match '\$env:DCP_PROFILE'
        $content | Should -Match '\$env:DCP_QUICK_MODE'
        $content | Should -Match '\$env:DCP_NO_REBOOT'
    }

    It 'Should respect WhatIfPreference when building arguments' {
        $content | Should -Match '\$WhatIfPreference'
        $content | Should -Match '-WhatIf'
    }
}

Describe 'gist-launcher.ps1 - Safety: no Invoke-Expression internally' -Tag 'Security','Unit' {

    $content = Get-Content $Script:LauncherPath -Raw

    It 'Should not use Invoke-Expression inside the launcher implementation' {
        # The launcher itself should not call Invoke-Expression; usage examples are outside.
        $content | Should -Not -Match 'Invoke-Expression'
        $content | Should -Not -Match 'iex\s'
    }
}
