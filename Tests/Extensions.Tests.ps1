<#
.SYNOPSIS
    Pester tests for Deep Clean Pro extension hooks (static + light structure).
#>

$Script:RootPath = Split-Path -Parent $PSScriptRoot
$Script:MainScript = Join-Path $Script:RootPath 'DeepCleanPro.ps1'

Describe 'Extension hooks - Engine surface' -Tag 'Unit' {

    It 'DeepCleanPro.ps1 should define Register-ExtensionHook' {
        (Get-Content $Script:MainScript -Raw) | Should -Match 'function\s+Register-ExtensionHook'
    }

    It 'DeepCleanPro.ps1 should define Import-DcpExtensions' {
        (Get-Content $Script:MainScript -Raw) | Should -Match 'function\s+Import-DcpExtensions'
    }

    It 'DeepCleanPro.ps1 should define Invoke-DcpExtensionHooks' {
        (Get-Content $Script:MainScript -Raw) | Should -Match 'function\s+Invoke-DcpExtensionHooks'
    }

    It 'Should declare all documented lifecycle stages' {
        $content = Get-Content $Script:MainScript -Raw
        foreach ($stage in @('BeforeStart', 'AfterHealthCheck', 'BeforeOptimize', 'AfterOptimize', 'BeforeSummary', 'AfterSummary')) {
            $content | Should -Match [regex]::Escape("'$stage'")
        }
    }

    It 'Should invoke hooks from main execution flow' {
        $content = Get-Content $Script:MainScript -Raw
        $content | Should -Match 'Invoke-DcpExtensionHooks -Stage BeforeStart'
        $content | Should -Match 'Invoke-DcpExtensionHooks -Stage AfterOptimize'
        $content | Should -Match 'Invoke-DcpExtensionHooks -Stage AfterSummary'
    }

    It 'Should support SkipExtensions / DCP_SKIP_EXTENSIONS' {
        $content = Get-Content $Script:MainScript -Raw
        $content | Should -Match '\$SkipExtensions'
        $content | Should -Match 'DCP_SKIP_EXTENSIONS'
    }

    It 'Should support CustomProfiles hashtable' {
        (Get-Content $Script:MainScript -Raw) | Should -Match '\$Script:CustomProfiles'
    }

    It 'Extensions folder should exist' {
        Test-Path (Join-Path $Script:RootPath 'Extensions') | Should -BeTrue
    }

    It 'Example extension template should exist' {
        Test-Path (Join-Path $Script:RootPath 'Extensions\ExampleExtension.ps1.example') | Should -BeTrue
    }
}

Describe 'Extension hooks - Register API (dot-source helpers)' -Tag 'Unit' {

    # Minimal isolated reimplementation of hook register/invoke (mirrors engine contract)
    BeforeAll {
        $script:hooks = @{
            'AfterOptimize' = New-Object System.Collections.Generic.List[scriptblock]
        }
        function Register-ExtensionHook {
            param(
                [ValidateSet('AfterOptimize')][string]$Stage,
                [scriptblock]$ScriptBlock
            )
            $script:hooks[$Stage].Add($ScriptBlock)
        }
        function Invoke-TestHooks {
            param([string]$Stage)
            foreach ($h in $script:hooks[$Stage]) { & $h }
        }
    }

    It 'Should collect and run a registered hook' {
        $script:fired = $false
        Register-ExtensionHook -Stage AfterOptimize -ScriptBlock { $script:fired = $true }
        Invoke-TestHooks -Stage AfterOptimize
        $script:fired | Should -BeTrue
    }
}
