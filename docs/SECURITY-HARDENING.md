# Security hardening (attack-surface reduction)

**Status:** Implemented in Deep Clean Pro **v2.5.0**

Deep Clean Pro can tighten common Windows exposures.  
This is **not** a claim that the PC cannot be compromised. Good habits, updates, MFA, and skepticism of unexpected files still matter.

## Modes

| Flag | What it does |
|------|----------------|
| `-Harden` | Safe set (no interactive RDP/WinRM kill) |
| `-HardenStrict` | Safe set + **YES** prompts (or switches) for risky options |
| `-HardenOnly` | Skip cleanup/perf; harden only |

### Safe set (always with `-Harden`)

- Microsoft Defender realtime check + PUA / cloud prefs (best-effort)
- Windows Firewall enabled (Domain / Private / Public)
- SMBv1 disabled
- AutoPlay / AutoRun restricted
- Guest account disabled
- UAC secure defaults (`EnableLUA`, consent on secure desktop)
- Remote Assistance invitations disabled
- Anonymous / null-session share restrictions
- Discovery helper services → Manual (best-effort)
- PowerShell Script Block Logging enabled

### Strict choices (need `YES` or an explicit switch)

| Switch | Effect |
|--------|--------|
| `-DisableRdp` | Turns off Remote Desktop |
| `-DisableWinRm` | Disables WinRM service |
| `-DisableLlmnr` | Disables LLMNR via policy |
| `-DisablePowershellV2` | Removes PowerShell v2 optional feature |
| `-EnableAsrRules` | Enables a small Defender ASR rule set |

## Examples

```powershell
# Preview safe harden
.\DeepCleanPro.ps1 -HardenOnly -WhatIf -NoReboot

# Apply safe harden only
.\DeepCleanPro.ps1 -HardenOnly -NoReboot

# Strict with prompts
.\DeepCleanPro.ps1 -HardenOnly -HardenStrict -NoReboot

# Strict, non-interactive (you already decided)
.\DeepCleanPro.ps1 -HardenOnly -DisableRdp -DisableWinRm -DisableLlmnr -DisablePowershellV2 -NoReboot

# Clean + safe harden together
.\DeepCleanPro.ps1 -QuickMode -Harden -NoReboot
```

Control Center → options **9 / 10 / 11**, or  
`Shortcuts\Deep-Clean-Security-Harden.bat` / `…-Strict.bat`.

## Safety

- Creates a restore point when possible (`-SkipRestorePoint` to skip)
- Honors `-WhatIf`
- Strict remote-access changes are never silent without a switch/`YES`
- Pair with Windows Update (`-RunWindowsUpdates`) for patch currency

## Limits (be honest)

Hardening reduces **chance and blast radius**. It cannot replace:

- Patching
- Strong unique passwords / MFA
- Not running untrusted software
- Network perimeter controls on servers/VPS
