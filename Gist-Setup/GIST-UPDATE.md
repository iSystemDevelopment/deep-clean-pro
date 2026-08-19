# Update the GitHub Gist launcher

After editing `gist-launcher.ps1` in this repo, publish to:

**Gist:** https://gist.github.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7  
**Filename on gist:** `DeepCleanPro-Launcher.ps1`

## One-liner (users)

```powershell
irm 'https://gist.githubusercontent.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7/raw/DeepCleanPro-Launcher.ps1' | iex
```

## Publish steps

1. Copy contents of `Gist-Setup/gist-launcher.ps1` (or `DeepCleanPro-Launcher.ps1` — same file).
2. Open the gist → Edit → replace **DeepCleanPro-Launcher.ps1** body → Save.
3. Optional local edit copy: `.private/deep-clean-pro-gist.txt` (not in git).

## Verify

```powershell
$WhatIfPreference = $true
$env:DCP_NO_PAUSE = 'true'
irm 'https://gist.githubusercontent.com/Dr-Diodac/25787f26b3506573bd4df4c42d1ffce7/raw/DeepCleanPro-Launcher.ps1' | iex
```

Expect launcher **v1.0.3** header and Deep Clean Pro **v2.5.0** engine banner.

## Launcher ↔ engine parity (2.5.0)

| Env var | Switch |
|---------|--------|
| `DCP_PROFILE` | `-Profile` |
| `DCP_QUICK_MODE=true` | `-QuickMode` |
| `DCP_NO_REBOOT=true` | `-NoReboot` |
| `DCP_RUN_UPDATES=true` | `-RunWindowsUpdates` |
| `DCP_SKIP_EXTENSIONS=true` | `-SkipExtensions` |
| `DCP_HARDEN=true` | `-Harden` |
| `DCP_HARDEN_STRICT=true` | `-HardenStrict` |
