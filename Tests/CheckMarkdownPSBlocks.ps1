<#
.SYNOPSIS
    Validates PowerShell code blocks in Markdown documentation
.DESCRIPTION
    Parses Markdown files and checks all PowerShell code blocks for syntax errors.
    This ensures documentation examples are valid and won't cause errors when users copy them.
.PARAMETER Path
    Path to the Markdown file to check (default: README.md)
.PARAMETER Recurse
    Check all .md files in repository
.EXAMPLE
    .\CheckMarkdownPSBlocks.ps1 -Path README.md
    Check PowerShell blocks in README.md
.EXAMPLE
    .\CheckMarkdownPSBlocks.ps1 -Recurse
    Check all Markdown files in repository
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = 'README.md',
    
    [switch]$Recurse,
    
    [switch]$Detailed,
    
    [switch]$FailOnWarning
)

# Initialize counters
$Script:TotalFiles = 0
$Script:TotalBlocks = 0
$Script:ErrorBlocks = 0
$Script:WarningBlocks = 0

function Test-PowerShellBlock {
    param(
        [string]$Code,
        [string]$File,
        [int]$BlockNumber
    )
    
    $tokens = $null
    $errors = $null
    
    # Parse the code block
    [void][System.Management.Automation.Language.Parser]::ParseInput(
        $Code,
        [ref]$tokens,
        [ref]$errors
    )
    
    if ($errors -and $errors.Count -gt 0) {
        Write-Host "  ❌ Block $BlockNumber has syntax errors:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host "     Line $($error.Extent.StartLineNumber): $($error.Message)" -ForegroundColor Red
            if ($Detailed) {
                Write-Host "     Code: $($error.Extent.Text)" -ForegroundColor Gray
            }
        }
        return $false
    }
    
    # Check for common issues that aren't syntax errors
    $warnings = @()
    
    # Check for incomplete examples (placeholders)
    if ($Code -match '<.*?>|\[.*?\]|YOUR-.*?|PLACEHOLDER') {
        $warnings += "Contains placeholder text that needs to be replaced"
    }
    
    # Check for hardcoded paths that might not exist
    if ($Code -match 'C:\\DeepCleanPro' -and $Code -notmatch '\$env:') {
        $warnings += "Contains hardcoded path that might not exist on all systems"
    }
    
    # Check for missing error handling in examples
    if ($Code -match 'Invoke-WebRequest|Invoke-RestMethod' -and $Code -notmatch 'try|catch|-ErrorAction') {
        $warnings += "Web request without error handling"
    }
    
    if ($warnings.Count -gt 0) {
        Write-Host "  ⚠️  Block $BlockNumber has warnings:" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "     $warning" -ForegroundColor Yellow
        }
        $Script:WarningBlocks++
        return -not $FailOnWarning
    }
    
    Write-Host "  ✅ Block $BlockNumber is valid" -ForegroundColor Green
    return $true
}

function Test-MarkdownFile {
    param(
        [string]$FilePath
    )
    
    if (-not (Test-Path -LiteralPath $FilePath)) {
        Write-Error "File not found: $FilePath"
        return $false
    }
    
    $Script:TotalFiles++
    $fileName = Split-Path -Leaf $FilePath
    Write-Host "`nChecking: $fileName" -ForegroundColor Cyan
    
    $content = Get-Content -Raw -LiteralPath $FilePath
    $blocks = @()
    $inBlock = $false
    $buffer = New-Object System.Text.StringBuilder
    $lineNumber = 0
    $blockStartLine = 0
    
    # Parse the Markdown file for PowerShell blocks
    foreach ($line in ($content -split "`n")) {
        $lineNumber++
        
        if (-not $inBlock) {
            # Check for PowerShell block start
            if ($line -match '^```(powershell|ps1?)\s*$') {
                $inBlock = $true
                $blockStartLine = $lineNumber
                [void]$buffer.Clear()
                continue
            }
        }
        else {
            # Check for block end
            if ($line -match '^```\s*$') {
                $blockContent = $buffer.ToString().Trim()
                if ($blockContent) {
                    $blocks += @{
                        Code = $blockContent
                        StartLine = $blockStartLine
                    }
                }
                $inBlock = $false
                continue
            }
            [void]$buffer.AppendLine($line)
        }
    }
    
    if ($blocks.Count -eq 0) {
        Write-Host "  No PowerShell blocks found" -ForegroundColor Gray
        return $true
    }
    
    Write-Host "  Found $($blocks.Count) PowerShell block(s)" -ForegroundColor Gray
    
    $fileValid = $true
    $blockNumber = 0
    
    foreach ($block in $blocks) {
        $blockNumber++
        $Script:TotalBlocks++
        
        if ($Detailed) {
            Write-Host "`n  Checking block $blockNumber (line $($block.StartLine))..." -ForegroundColor Gray
        }
        
        $isValid = Test-PowerShellBlock -Code $block.Code -File $fileName -BlockNumber $blockNumber
        
        if (-not $isValid) {
            $Script:ErrorBlocks++
            $fileValid = $false
        }
    }
    
    return $fileValid
}

# Main execution
Write-Host "PowerShell Code Block Validator for Markdown Documentation" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$allValid = $true

if ($Recurse) {
    # Find all Markdown files
    $repoRoot = Get-Location
    $mdFiles = Get-ChildItem -Path $repoRoot -Filter "*.md" -Recurse -File |
               Where-Object { $_.DirectoryName -notmatch 'node_modules|\.git|build|dist' }
    
    Write-Host "`nFound $($mdFiles.Count) Markdown file(s) to check" -ForegroundColor Yellow
    
    foreach ($file in $mdFiles) {
        $isValid = Test-MarkdownFile -FilePath $file.FullName
        if (-not $isValid) {
            $allValid = $false
        }
    }
}
else {
    # Check single file
    $fullPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    } else {
        Join-Path (Get-Location) $Path
    }
    
    $isValid = Test-MarkdownFile -FilePath $fullPath
    if (-not $isValid) {
        $allValid = $false
    }
}

# Summary report
Write-Host "`n==========================================================" -ForegroundColor Cyan
Write-Host "Summary Report" -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Files Checked:        $Script:TotalFiles" -ForegroundColor White
Write-Host "PowerShell Blocks:    $Script:TotalBlocks" -ForegroundColor White
Write-Host "Blocks with Errors:   $Script:ErrorBlocks" -ForegroundColor $(if ($Script:ErrorBlocks -gt 0) { 'Red' } else { 'Green' })
Write-Host "Blocks with Warnings: $Script:WarningBlocks" -ForegroundColor $(if ($Script:WarningBlocks -gt 0) { 'Yellow' } else { 'Green' })

if ($allValid) {
    Write-Host "`n✅ All PowerShell code blocks are valid!" -ForegroundColor Green
    exit 0
}
else {
    Write-Host "`n❌ Found invalid PowerShell code blocks in documentation" -ForegroundColor Red
    Write-Host "Please fix the syntax errors before committing." -ForegroundColor Yellow
    exit 1
}