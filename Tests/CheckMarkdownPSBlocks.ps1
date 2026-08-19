<#
.SYNOPSIS
    Validates PowerShell code blocks in Markdown documentation.

.DESCRIPTION
    Scans Markdown files for fenced PowerShell code blocks (```powershell, ```ps, ```ps1)
    and validates them using the PowerShell parser. This ensures that documentation
    examples are syntactically valid and safe to copy-paste.

    Additionally, it emits warnings for:
      - Placeholder text (YOUR-..., <PLACEHOLDER>, etc.)
      - Hardcoded C:\DeepCleanPro paths without environment variables
      - Old Dr-Diodac repo links in examples

.PARAMETER Path
    Path to a Markdown file or directory to check.
    Default: current directory (.)

.PARAMETER Recurse
    When specified, recurses into subdirectories and checks all .md files.

.PARAMETER Detailed
    When specified, prints detailed information for each code block, including
    warnings and success messages. Otherwise, only errors are shown.

.PARAMETER FailOnWarning
    When specified, any warning will cause the script to exit with code 1.
    Useful for strict CI pipelines.

.EXAMPLE
    .\CheckMarkdownPSBlocks.ps1 -Path README.md

.EXAMPLE
    .\CheckMarkdownPSBlocks.ps1 -Recurse -Detailed

.EXAMPLE
    .\CheckMarkdownPSBlocks.ps1 -Recurse -FailOnWarning
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Path = '.',

    [switch]$Recurse,

    [switch]$Detailed,

    [switch]$FailOnWarning
)

# Global counters
$Script:TotalFiles     = 0
$Script:TotalBlocks    = 0
$Script:ErrorBlocks    = 0
$Script:WarningBlocks  = 0

function Write-SectionHeader {
    param([string]$Message)

    Write-Host ""
    Write-Host "==========================================================" -ForegroundColor Cyan
    Write-Host $Message -ForegroundColor White
    Write-Host "==========================================================" -ForegroundColor Cyan
}

function Get-MarkdownFiles {
    param(
        [string]$Path,
        [switch]$Recurse
    )

    if (Test-Path $Path -PathType Leaf) {
        if ($Path.ToLower().EndsWith('.md')) {
            return ,(Get-Item $Path)
        } else {
            Write-Host "[WARN] Provided file is not a .md: $Path" -ForegroundColor Yellow
            return @()
        }
    }

    if (Test-Path $Path -PathType Container) {
        $searchPath = (Resolve-Path $Path).ProviderPath
        if ($Recurse) {
            return Get-ChildItem -Path $searchPath -Filter '*.md' -Recurse -File
        } else {
            return Get-ChildItem -Path $searchPath -Filter '*.md' -File
        }
    }

    Write-Host "[WARN] Path not found: $Path" -ForegroundColor Yellow
    return @()
}

function Get-PowerShellBlocksFromMarkdown {
    <#
    .SYNOPSIS
        Extracts PowerShell code blocks from Markdown text.

    .DESCRIPTION
        Finds fenced code blocks with language tags: powershell, ps, ps1.
        Returns objects with Code, StartLine, EndLine.
    #>
    param(
        [Parameter(Mandatory)][string]$Content
    )

    $lines = $Content -split "`r?`n"
    $blocks = @()

    $insideBlock  = $false
    $blockLines   = @()
    $blockStart   = 0

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]

        if (-not $insideBlock) {
            # Detect start fence: ```powershell / ```ps / ```ps1 (case-insensitive)
            if ($line -match '^\s*```(?<lang>[a-zA-Z0-9+-]*)\s*$') {
                $lang = $Matches['lang'].ToLower()
                if ($lang -in @('powershell','ps','ps1')) {
                    $insideBlock = $true
                    $blockLines  = @()
                    $blockStart  = $i + 2   # content starts on next line (1-based)
                }
            }
        }
        else {
            # End of block fence
            if ($line -match '^\s*```\s*$') {
                $blockEnd = $i       # line before fence is last content line (1-based)
                $code     = ($blockLines -join [Environment]::NewLine)
                $blocks  += [PSCustomObject]@{
                    Code      = $code
                    StartLine = $blockStart
                    EndLine   = $blockEnd
                }
                $insideBlock = $false
                $blockLines  = @()
            } else {
                $blockLines += $line
            }
        }
    }

    return $blocks
}

function Test-PowerShellCodeBlock {
    <#
    .SYNOPSIS
        Validates a single PowerShell code block and returns diagnostics.
    #>
    param(
        [Parameter(Mandatory)][string]$Code,
        [Parameter(Mandatory)][string]$File,
        [Parameter(Mandatory)][int]$BlockNumber
    )

    $result = [PSCustomObject]@{
        File     = $File
        Block    = $BlockNumber
        IsValid  = $true
        Error    = $null
        Warnings = @()
    }

    # 1) Syntax validation via parser (no execution)
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize($Code, [ref]$null)
    } catch {
        $result.IsValid = $false
        $result.Error   = $_.Exception.Message
        return $result
    }

    # 2) Heuristic warnings

    # Placeholder / template text
    if ($Code -match '<.*?>|\[.*?\]|YOUR-.*?|PLACEHOLDER') {
        $result.Warnings += "Contains placeholder text (YOUR-..., <...>, or [..]) that should be replaced with real values."
    }

    # Hardcoded DeepCleanPro paths without env vars
    if ($Code -match 'C:\\DeepCleanPro' -and $Code -notmatch '\$env:') {
        $result.Warnings += "Contains hardcoded C:\DeepCleanPro path. Consider using environment variables or documented default paths."
    }

    # Old Dr-Diodac repo references
    if ($Code -match 'Dr-Diodac/deep-clean-pro' -or
        $Code -match 'https://github\.com/Dr-Diodac/deep-clean-pro' -or
        $Code -match 'https://raw\.githubusercontent\.com/Dr-Diodac/deep-clean-pro') {
        $result.Warnings += "Contains old Dr-Diodac repository URL. Use iSystemDevelopment/deep-clean-pro instead."
    }

    return $result
}

function Test-MarkdownFile {
    param(
        [Parameter(Mandatory)][System.IO.FileInfo]$File
    )

    $Script:TotalFiles++

    Write-Host ""
    Write-Host "Checking file: $($File.FullName)" -ForegroundColor Cyan

    $content = Get-Content -Path $File.FullName -Raw -ErrorAction Stop
    $blocks  = Get-PowerShellBlocksFromMarkdown -Content $content

    if ($blocks.Count -eq 0) {
        Write-Host "  No PowerShell code blocks found" -ForegroundColor DarkGray
        return $true
    }

    Write-Host "  Found $($blocks.Count) PowerShell block(s)" -ForegroundColor Gray

    $fileValid   = $true
    $blockNumber = 0

    foreach ($block in $blocks) {
        $blockNumber++
        $Script:TotalBlocks++

        $testResult = Test-PowerShellCodeBlock -Code $block.Code -File $File.FullName -BlockNumber $blockNumber

        if (-not $testResult.IsValid) {
            $Script:ErrorBlocks++
            $fileValid = $false
            Write-Host "  ❌ Block #$blockNumber (Lines $($block.StartLine)-$($block.EndLine)) has SYNTAX ERROR:" -ForegroundColor Red
            Write-Host "     $($testResult.Error)" -ForegroundColor Red
            continue
        }

        if ($testResult.Warnings.Count -gt 0) {
            $Script:WarningBlocks += $testResult.Warnings.Count
            $fileValid = $fileValid -and (-not $FailOnWarning)
            if ($Detailed) {
                Write-Host "  ⚠ Block #$blockNumber (Lines $($block.StartLine)-$($block.EndLine)) WARNINGS:" -ForegroundColor Yellow
                foreach ($w in $testResult.Warnings) {
                    Write-Host "     - $w" -ForegroundColor Yellow
                }
            }
        } elseif ($Detailed) {
            Write-Host "  ✅ Block #$blockNumber (Lines $($block.StartLine)-$($block.EndLine)) is valid" -ForegroundColor Green
        }
    }

    return $fileValid
}

# ── Main Execution ────────────────────────────────────────────────────────────

Write-SectionHeader "Deep Clean Pro - Markdown PowerShell Block Validation"

$files = Get-MarkdownFiles -Path $Path -Recurse:$Recurse

if (-not $files -or $files.Count -eq 0) {
    Write-Host "No Markdown files found for path '$Path'." -ForegroundColor Yellow
    exit 0
}

$allValid = $true

foreach ($file in $files) {
    $fileResult = Test-MarkdownFile -File $file
    if (-not $fileResult) {
        $allValid = $false
    }
}

Write-Host ""
Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host "Files Checked:        $Script:TotalFiles"    -ForegroundColor White
Write-Host "PowerShell Blocks:    $Script:TotalBlocks"   -ForegroundColor White

$errColor = if ($Script:ErrorBlocks   -gt 0) { 'Red'    } else { 'Green' }
$warColor = if ($Script:WarningBlocks -gt 0) { 'Yellow' } else { 'Green' }

Write-Host "Blocks with Errors:   $Script:ErrorBlocks"   -ForegroundColor $errColor
Write-Host "Blocks with Warnings: $Script:WarningBlocks" -ForegroundColor $warColor
Write-Host "==========================================================" -ForegroundColor Cyan

if ($Script:ErrorBlocks -gt 0) {
    Write-Host "`n❌ Found invalid PowerShell code blocks in documentation." -ForegroundColor Red
    Write-Host "Please fix the syntax errors before committing." -ForegroundColor Yellow
    exit 1
}

if ($FailOnWarning -and $Script:WarningBlocks -gt 0) {
    Write-Host "`n⚠ Validation failed due to warnings (FailOnWarning enabled)." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n✅ All PowerShell code blocks are syntactically valid." -ForegroundColor Green

if ($Script:WarningBlocks -gt 0) {
    Write-Host "There are warnings you may want to address." -ForegroundColor Yellow
}

exit 0
