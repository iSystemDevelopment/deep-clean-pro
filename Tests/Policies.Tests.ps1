<#
.SYNOPSIS
    Pester tests for Fix-WindowsPolicies.ps1.

.DESCRIPTION
    Validates structure, safety and key behaviors of the Windows policy repair tool.
    Tests are static (AST/content-based) and do NOT execute registry changes.
#>

# Resolve path to Fix-WindowsPolicies.ps1 relative to Tests directory
$Script:RootPath   = Split-Path -Parent $PSScriptRoot
$Script:PolicyPath = Join-Path $Script:RootPath 'Fix-WindowsPolicies.ps1'

Describe 'Fix-WindowsPolicies.ps1 - Script structure' -Tag 'Unit' {

    It 'Should exist at the expected path' {
        Test-Path $Script:PolicyPath | Should -BeTrue
    }

    It 'Should be syntactically valid PowerShell' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Script:PolicyPath,
            [ref]$null,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }

    It 'Should be decorated with CmdletBinding and SupportsShouldProcess' {
        $ast    = [System.Management.Automation.Language.Parser]::ParseFile($Script:PolicyPath, [ref]$null, [ref]$null)
        $scriptBlock = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.ScriptBlockAst] }, $true)

        $bindingAttr = $scriptBlock.Attributes |
            Where-Object { $_.TypeName.GetText() -eq 'CmdletBinding' }

        $bindingAttr | Should -Not -BeNullOrEmpty

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

Describe 'Fix-WindowsPolicies.ps1 - Core functions present' -Tag 'Unit' {

    $content = Get-Content $Script:PolicyPath -Raw

    It 'Should define Repair-WindowsUpdatePolicy' {
        $content | Should -Match 'function\s+Repair-WindowsUpdatePolicy'
    }

    It 'Should define Repair-DefenderPolicy' {
        $content | Should -Match 'function\s+Repair-DefenderPolicy'
    }

    It 'Should define Repair-ExplorerPolicy' {
        $content | Should -Match 'function\s+Repair-ExplorerPolicy'
    }

    It 'Should define Repair-TelemetryPolicy' {
        $content | Should -Match 'function\s+Repair-TelemetryPolicy'
    }

    It 'Should define Get-PolicySnapshot helper' {
        $content | Should -Match 'function\s+Get-PolicySnapshot'
    }

    It 'Should define Save-PolicySnapshot helper' {
        $content | Should -Match 'function\s+Save-PolicySnapshot'
    }
}

Describe 'Fix-WindowsPolicies.ps1 - Policy scope & safety' -Tag 'Security','Unit' {

    $content = Get-Content $Script:PolicyPath -Raw

    It 'Should only touch SOFTWARE\Policies keys (local policy), not domain GPO paths' {
        # Expect local policy roots
        $content | Should -Match 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows'
        $content | Should -Match 'HKCU:\\SOFTWARE\\Policies\\Microsoft\\Windows'

        # Must NOT reference SYSVOL, Group Policy folders, or PolicyDefinitions paths
        $content | Should -Not -Match 'SYSVOL'
        $content | Should -Not -Match 'GroupPolicy'
        $content | Should -Not -Match 'PolicyDefinitions'
    }

    It 'Should have an auto-elevation check for Administrator privileges' {
        $content | Should -Match 'WindowsBuiltInRole::Administrator'
        $content | Should -Match 'Start-Process powershell\.exe -Verb RunAs'
    }

    It 'Should not use Invoke-Expression' {
        $content | Should -Not -Match 'Invoke-Expression'
    }
}

Describe 'Fix-WindowsPolicies.ps1 - Repository & branding correctness' -Tag 'Security','Unit' {

    $content = Get-Content $Script:PolicyPath -Raw

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

    It 'If any GitHub URLs are present, they should reference iSystemDevelopment/deep-clean-pro' {
        $urlMatches = Select-String -InputObject $content -Pattern 'https://github\.com/' -AllMatches
        $rawMatches = Select-String -InputObject $content -Pattern 'https://raw\.githubusercontent\.com/' -AllMatches

        if ($urlMatches -or $rawMatches) {
            $content | Should -Match 'iSystemDevelopment/deep-clean-pro'
        }
    }
}

Describe 'Fix-WindowsPolicies.ps1 - Backup behavior markers' -Tag 'Unit' {

    $content = Get-Content $Script:PolicyPath -Raw

    It 'Should mention backup JSON creation in comments or messages' {
        $content | Should -Match 'PolicyBackup'
        $content | Should -Match 'ConvertTo-Json'
    }

    It 'Should call Get-PolicySnapshot and Save-PolicySnapshot before repairs (order sanity)' {
        # This is a loose check: snapshot helpers must appear before Repair-* calls
        $snapshotIndex = $content.IndexOf('Get-PolicySnapshot')
        $repairIndex   = $content.IndexOf('Repair-WindowsUpdatePolicy')

        $snapshotIndex | Should -BeGreaterThan -1
        $repairIndex   | Should -BeGreaterThan -1
        $snapshotIndex | Should -BeLessThan $repairIndex
    }
}
