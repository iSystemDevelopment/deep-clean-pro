<#
.SYNOPSIS
    Pester tests for CreateDesktopShortcuts.ps1.

.DESCRIPTION
    Static tests that verify:
      - Script exists and parses
      - Expected parameters are present
      - Core helper function New-DCPShortcut exists
      - No old Dr-Diodac URLs remain
#>

# Resolve path to CreateDesktopShortcuts.ps1 relative to Tests directory
$Script:RootPath   = Split-Path -Parent $PSScriptRoot
$Script:ScriptPath = Join-Path $Script:RootPath 'CreateDesktopShortcuts.ps1'

Describe 'CreateDesktopShortcuts.ps1 - Script structure' -Tag 'Unit' {

    It 'Should exist in the repository root' {
        Test-Path $Script:ScriptPath | Should -BeTrue
    }

    It 'Should be syntactically valid PowerShell' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Script:ScriptPath,
            [ref]$null,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }
}

Describe 'CreateDesktopShortcuts.ps1 - Parameters and helpers' -Tag 'Unit' {

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Script:ScriptPath, [ref]$null, [ref]$null)
    $paramBlock = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.ParamBlockAst] }, $true)
    $content = Get-Content $Script:ScriptPath -Raw

    It 'Should define parameters: TargetPath, GistLauncherURL, Silent' {
        $paramNames = $paramBlock.Parameters.Name.VariablePath.UserPath

        $paramNames | Should -Contain 'TargetPath'
        $paramNames | Should -Contain 'GistLauncherURL'
        $paramNames | Should -Contain 'Silent'
    }

    It 'Should define New-DCPShortcut helper function' {
        $content | Should -Match 'function\s+New-DCPShortcut'
    }
}

Describe 'CreateDesktopShortcuts.ps1 - Branding & URLs' -Tag 'Security','Unit' {

    $content = Get-Content $Script:ScriptPath -Raw

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
