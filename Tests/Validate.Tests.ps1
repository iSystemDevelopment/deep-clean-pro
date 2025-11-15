<#
.SYNOPSIS
    Pester tests for Scripts/VALIDATE.ps1.

.DESCRIPTION
    Static tests that validate the structure, parameters, and safety properties
    of the Deep Clean Pro validation script, without actually modifying the system.
#>

# Resolve path to VALIDATE.ps1 relative to Tests directory
$Script:RootPath     = Split-Path -Parent $PSScriptRoot
$Script:ValidatePath = Join-Path (Join-Path $Script:RootPath 'Scripts') 'VALIDATE.ps1'

Describe 'VALIDATE.ps1 - Script structure' -Tag 'Unit' {

    It 'Should exist at Scripts\VALIDATE.ps1' {
        Test-Path $Script:ValidatePath | Should -BeTrue
    }

    It 'Should be syntactically valid PowerShell' {
        $errors = $null
        [void][System.Management.Automation.Language.Parser]::ParseFile(
            $Script:ValidatePath,
            [ref]$null,
            [ref]$errors
        )

        $errors | Should -BeNullOrEmpty
    }
}

Describe 'VALIDATE.ps1 - Parameters' -Tag 'Unit' {

    $ast = [System.Management.Automation.Language.Parser]::ParseFile($Script:ValidatePath, [ref]$null, [ref]$null)
    $paramBlock = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.ParamBlockAst] }, $true)

    It 'Should define expected parameters: RootPath, SkipNetwork, Silent' {
        $paramNames = $paramBlock.Parameters.Name.VariablePath.UserPath

        $paramNames | Should -Contain 'RootPath'
        $paramNames | Should -Contain 'SkipNetwork'
        $paramNames | Should -Contain 'Silent'
    }

    It 'Should set default RootPath to C:\DeepCleanPro' {
        $content = Get-Content $Script:ValidatePath -Raw
        $content | Should -Match 'RootPath\s*=\s*"C:\\DeepCleanPro"'
    }
}

Describe 'VALIDATE.ps1 - Safety & APIs' -Tag 'Security','Unit' {

    $content = Get-Content $Script:ValidatePath -Raw

    It 'Should not use Get-WmiObject (use Get-CimInstance instead)' {
        $content | Should -Not -Match 'Get-WmiObject'
    }

    It 'Should use Get-CimInstance for OS checks' {
        $content | Should -Match 'Get-CimInstance\s+-ClassName\s+Win32_OperatingSystem'
    }

    It 'Should configure TLS 1.2 via ServicePointManager' {
        $content | Should -Match 'ServicePointManager'
        $content | Should -Match 'Tls12'
    }
}

Describe 'VALIDATE.ps1 - Paths & Structure Awareness' -Tag 'Unit' {

    $content = Get-Content $Script:ValidatePath -Raw

    It 'Should check Backups, Logs, and Scripts directories beneath RootPath' {
        $content | Should -Match 'Backups'
        $content | Should -Match 'Logs'
        $content | Should -Match 'Scripts'
    }

    It 'Should mention DeepCleanPro root directory in comments or messages' {
        $content | Should -Match 'C:\\DeepCleanPro'
    }
}

Describe 'VALIDATE.ps1 - Repository URL & branding correctness' -Tag 'Security','Unit' {

    $content = Get-Content $Script:ValidatePath -Raw

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

    It 'If any GitHub URLs are present, they should reference iSystemDevelopment/deep-clean-pro' {
        $urlMatches = Select-String -InputObject $content -Pattern 'https://github\.com/' -AllMatches
        $rawMatches = Select-String -InputObject $content -Pattern 'https://raw\.githubusercontent\.com/' -AllMatches

        if ($urlMatches -or $rawMatches) {
            $content | Should -Match 'iSystemDevelopment/deep-clean-pro'
        }
    }
}
