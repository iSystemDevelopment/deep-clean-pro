# Deep Clean Pro – Shortcuts Pack

Fast, safe Windows cleanup — without typing commands.

These BAT files live in the repo under `Shortcuts\` and elevate through
[`Scripts/Invoke-DcpElevated.ps1`](Invoke-DcpElevated.ps1) (local install preferred; otherwise downloads the latest engine).

---

## How to install

### Option A — Control Center (easiest)

From the repo root (or `C:\DeepCleanPro` after deploy):

1. Double-click **`Control-center.bat`**
2. Pick a mode from the menu

### Option B — Desktop `.lnk` shortcuts

After a local clone or `.\DEPLOY.ps1`:

```powershell
.\Scripts\CreateDesktopShortcuts.ps1
```

Or deploy with shortcuts:

```powershell
.\DEPLOY.ps1 -CreateShortcuts
```

### Option C — Use the BAT pack as-is

Copy the whole `Shortcuts\` folder (keep the repo structure so
`%~dp0..\Scripts\Invoke-DcpElevated.ps1` resolves). Double-click any BAT.

Administrator elevation is requested automatically.

---

## Included shortcuts

| Shortcut | What it runs |
|----------|----------------|
| Quick Fix | `-QuickMode -NoReboot` |
| Full Optimization | full run, `-NoReboot` |
| Gaming Mode | `-Profile Gaming` |
| Dev Mode | `-Profile Development` |
| Music Mode | `-Profile Music` |
| Video Mode | `-Profile Video` |
| Office Mode | `-Profile Office` |
| Updates + Optimize | `-RunWindowsUpdates` |
| Test Mode | `-WhatIf` (no changes) |
| OneDrive Liberator | elevates `OneDriveNuke.ps1` |

---

## Files

| File | Purpose |
|------|---------|
| `Control-center.bat` | Menu launcher |
| `Shortcuts\*.bat` | One-click modes |
| `Scripts\Invoke-DcpElevated.ps1` | Shared elevate/download/`-File` runner |
| `OneDriveNuke.ps1` | OneDrive Liberator (required for that shortcut) |
| `Scripts\CreateDesktopShortcuts.ps1` | Builds desktop `.lnk` entries |

There is **no** `Install-Shortcuts.bat` in this repo — use option B above.

---

## Testing safely

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

Or double-click **Test Mode**.

---

## Troubleshooting

### PowerShell window closes instantly

Right-click the BAT → **Run as administrator**, or approve the UAC prompt from `Invoke-DcpElevated.ps1`.

### “Cannot run scripts”

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### OneDrive Liberator says script not found

Keep `OneDriveNuke.ps1` at the repo root, or deploy with `.\DEPLOY.ps1` so it exists at `C:\DeepCleanPro\OneDriveNuke.ps1`.

---

## Advanced (CLI equivalent)

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -QuickMode -NoReboot
```

Online with parameters (do **not** append a second `DeepCleanPro.ps1` after `iex`):

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path -Profile Gaming
```

Env-var style (works with `irm | iex` **or** the gist launcher):

```powershell
$env:DCP_PROFILE = 'Gaming'
$env:DCP_QUICK_MODE = 'true'
$env:DCP_NO_REBOOT = 'true'
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

Gist / online shortcuts: see [`Gist-Setup/README.md`](../Gist-Setup/README.md).

---

## Support

- Issues: https://github.com/iSystemDevelopment/deep-clean-pro/issues
- Discussions: https://github.com/iSystemDevelopment/deep-clean-pro/discussions
