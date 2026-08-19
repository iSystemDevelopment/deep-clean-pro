<#
.SYNOPSIS
    Pester tests for OneDriveNuke.ps1 (OneDrive Liberator).

.DESCRIPTION
    Static tests that validate the structure, safety, and scope of the
    OneDrive removal tool, without actually uninstalling OneDrive or
    touching the filesystem/registry.
#>

# Resolve path to OneDriveNuke.ps1 relative to Tests directory
$Script:RootPath       = Split-Path -Parent $PSScriptRoot
$Script:OneDriveScript = Join-Path $Script:RootPath 'OneDriveNuke.ps1'

Describe 'OneDriveNuke.ps1 - Script structure' -Tag 'Unit' {

    It 'Should exist at the expected path' {
        Test-Path $Script:OneDriveScript | Should -BeTrue
    }

    It 'Should be syntactically valid PowerShell' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Script:OneDriveScript,
            [ref]$null,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }

    It 'Should be decorated with CmdletBinding and SupportsShouldProcess' {
        $ast    = [System.Management.Automation.Language.Parser]::ParseFile($Script:OneDriveScript, [ref]$null, [ref]$null)
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

Describe 'OneDriveNuke.ps1 - Core functions present' -Tag 'Unit' {

    $content = Get-Content $Script:OneDriveScript -Raw

    It 'Should define Write-ColorOutput helper' {
        $content | Should -Match 'function\s+Write-ColorOutput'
    }

    It 'Should define Show-Header function' {
        $content | Should -Match 'function\s+Show-Header'
    }

    It 'Should define Test-OneDriveInstalled' {
        $content | Should -Match 'function\s+Test-OneDriveInstalled'
    }

    It 'Should define Backup-OneDriveFiles' {
        $content | Should -Match 'function\s+Backup-OneDriveFiles'
    }

    It 'Should define Move-ShellFolders' {
        $content | Should -Match 'function\s+Move-ShellFolders'
    }

    It 'Should define Stop-OneDriveProcess' {
        $content | Should -Match 'function\s+Stop-OneDriveProcess'
    }

    It 'Should define Uninstall-OneDrive' {
        $content | Should -Match 'function\s+Uninstall-OneDrive'
    }

    It 'Should define Remove-OneDriveRemnants' {
        $content | Should -Match 'function\s+Remove-OneDriveRemnants'
    }

    It 'Should define Block-OneDriveReinstall' {
        $content | Should -Match 'function\s+Block-OneDriveReinstall'
    }

    It 'Should define Show-Summary' {
        $content | Should -Match 'function\s+Show-Summary'
    }
}

Describe 'OneDriveNuke.ps1 - Safety & scope' -Tag 'Security','Unit' {

    $content = Get-Content $Script:OneDriveScript -Raw

    It 'Should include an auto-elevation check for Administrator privileges' {
        $content | Should -Match 'WindowsBuiltInRole::Administrator'
        $content | Should -Match 'Start-Process powershell\.exe -Verb RunAs'
    }

    It 'Should not use Get-WmiObject (use CIM or native tools instead)' {
        $content | Should -Not -Match 'Get-WmiObject'
    }

    It 'Should not use Invoke-Expression' {
        $content | Should -Not -Match 'Invoke-Expression'
    }

    It 'Should operate on OneDrive-specific locations and paths' {
        $content | Should -Match 'OneDrive'
        $content | Should -Match 'OneDriveSetup\.exe'
    }

    It 'Should configure Group Policy keys to block OneDrive reinstall' {
        $content | Should -Match 'HKLM:\\SOFTWARE\\Policies\\Microsoft\\Windows\\OneDrive'
        $content | Should -Match 'DisableFileSync'
    }
}

Describe 'OneDriveNuke.ps1 - Repo & branding correctness' -Tag 'Security','Unit' {

    $content = Get-Content $Script:OneDriveScript -Raw

    It 'Should not contain old Dr-Diodac references' {
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

    It 'If any GitHub URLs are present, they should use iSystemDevelopment/deep-clean-pro' {
        $urlMatches = Select-String -InputObject $content -Pattern 'https://github\.com/' -AllMatches
        $rawMatches = Select-String -InputObject $content -Pattern 'https://raw\.githubusercontent\.com/' -AllMatches

        if ($urlMatches -or $rawMatches) {
            $content | Should -Match 'iSystemDevelopment/deep-clean-pro'
        }
    }
}
