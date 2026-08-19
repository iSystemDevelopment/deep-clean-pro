# Deep Clean Pro — Documentation Index

All guides live in [`docs/`](docs/). Root keeps the runnable scripts only.

---

## Getting started

| Guide | Path |
|-------|------|
| Beginner's guide | [docs/BEGINNERS-GUIDE.md](docs/BEGINNERS-GUIDE.md) |
| Installation | [docs/INSTALLATION-GUIDE.md](docs/INSTALLATION-GUIDE.md) |
| Deployment | [docs/DEPLOYMENT-GUIDE.md](docs/DEPLOYMENT-GUIDE.md) |

### One-click run (elevated PowerShell)

Preferred (supports parameters):

```powershell
$path = "$env:TEMP\DeepCleanPro.ps1"
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' -OutFile $path
& $path
```

Default full run without parameters also works:

```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

**Do not** use `irm ... | iex; DeepCleanPro.ps1 -Profile ...` — after `iex` there is no `DeepCleanPro.ps1` command on PATH.

### Local menu / shortcuts

| Entry | Path |
|-------|------|
| Control Center menu | [`Control-center.bat`](Control-center.bat) |
| Profile BATs | [`Shortcuts/`](Shortcuts/) |
| Elevated launcher | [`Scripts/Invoke-DcpElevated.ps1`](Scripts/Invoke-DcpElevated.ps1) |
| Desktop `.lnk` helper | [`Scripts/CreateDesktopShortcuts.ps1`](Scripts/CreateDesktopShortcuts.ps1) |

---

## Reference

| Topic | Path |
|-------|------|
| Architecture | [docs/ARCHITECTURE-GUIDE.md](docs/ARCHITECTURE-GUIDE.md) |
| API reference | [docs/API-REFERENCE.md](docs/API-REFERENCE.md) |
| Full developer reference | [docs/FULL-DEVELOPER-REFERENCE.md](docs/FULL-DEVELOPER-REFERENCE.md) |
| CLI masters | [docs/CLI-MASTERS.md](docs/CLI-MASTERS.md) |
| Advanced | [docs/ADVANCED-GUIDE.md](docs/ADVANCED-GUIDE.md) |
| Examples | [docs/EXAMPLES.md](docs/EXAMPLES.md) |
| Extensions | [docs/EXTENSIONS.md](docs/EXTENSIONS.md) |

---

## Tools

| Tool | Path |
|------|------|
| OneDrive Liberator | [docs/OneDRIVE-LIBERATOR.md](docs/OneDRIVE-LIBERATOR.md) + `OneDriveNuke.ps1` |
| Fix Windows Policies | [docs/FIX-WINDOWS-POLICIES.md](docs/FIX-WINDOWS-POLICIES.md) + `Fix-WindowsPolicies.ps1` |
| Security hardening | [docs/SECURITY-HARDENING.md](docs/SECURITY-HARDENING.md) (`-Harden` / `-HardenStrict`) |
| Validation | `Scripts/VALIDATION-GUIDE.md` + `Scripts/VALIDATE.ps1` |
| Shortcuts | `Scripts/SHORTCUTS-README.md` |
| Gist launcher | `Gist-Setup/README.md` + `Gist-Setup/gist-launcher.ps1` |

---

## Root scripts

| File | Role |
|------|------|
| `DeepCleanPro.ps1` | Main engine |
| `DEPLOY.ps1` | Local install + shortcuts |
| `Fix-WindowsPolicies.ps1` | Policy repair |
| `OneDriveNuke.ps1` | OneDrive Liberator |
| `Control-center.bat` | Launcher menu |
| `Shortcuts/` | Profile batch files (call `Invoke-DcpElevated.ps1`) |
| `Scripts/Invoke-DcpElevated.ps1` | Shared elevate + run helper |

---

## Contributing & security

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [SECURITY.md](SECURITY.md)
- [LICENSE](LICENSE) (MIT)
