# Deep Clean Pro – Extension & Module System

**Status (v2.3.0):** Implemented in `DeepCleanPro.ps1` — lifecycle hooks, auto-load from `Extensions\`, and custom profiles via `$Script:CustomProfiles`.

Extend Deep Clean Pro without editing the core engine.

## Folders scanned

```
.\Extensions\                 # next to DeepCleanPro.ps1
C:\DeepCleanPro\Extensions\   # installed base path
```

Every `*.ps1` is dotted in at startup (unless `-SkipExtensions` or `DCP_SKIP_EXTENSIONS=true`).

Template: `Extensions/ExampleExtension.ps1.example` (rename to `.ps1` to activate).

## Lifecycle hooks

| Stage | When |
|-------|------|
| `BeforeStart` | After extensions load |
| `AfterHealthCheck` | After health scan |
| `BeforeOptimize` | Before core modules |
| `AfterOptimize` | After modules (+ Windows Update step) |
| `BeforeSummary` | Before final report |
| `AfterSummary` | After summary |

```powershell
Register-ExtensionHook -Stage 'AfterOptimize' -ScriptBlock {
    Write-ColorOutput 'Custom post-clean task' -Type Info
}
```

Failed hooks log a warning and do not abort the run.

## Custom profiles

```powershell
# Extensions\MyStudio.ps1
$Script:CustomProfiles['MyStudio'] = {
    Write-ColorOutput 'Applying MyStudio profile...' -Type Info
}

# Run:
.\DeepCleanPro.ps1 -Profile MyStudio
# or: $env:DCP_PROFILE = 'MyStudio'
```

## Security

- Review third-party scripts before dropping them into `Extensions\`
- Prefer WhatIf-aware code
- Use `-SkipExtensions` when debugging the core engine

## Tests

```powershell
Invoke-Pester -Path .\Tests\Extensions.Tests.ps1 -Tag Unit
```
