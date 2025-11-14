# 📚 **Deep Clean Pro – Example Library**

### *Real-world examples, quick recipes, and practical command-line usage.*

This Example Library provides **copy-and-paste commands** for every major scenario:

* Running Deep Clean Pro normally
* Using profiles
* Technician operations
* Enterprise deployment
* Developer usage
* Extension and module integration
* OneDrive removal
* Windows Update maintenance
* Silent automation
* Launcher tricks
* Safe testing

Choose the scenario that fits your needs!

---

# 🚀 1. **Basic Usage**

### Run Deep Clean Pro (default Balanced profile)

```powershell
irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex
```

### Run from local install

```powershell
C:\DeepCleanPro\DeepCleanPro.ps1
```

---

# 🎮 2. **Profile Examples**

### Gaming

```powershell
.\DeepCleanPro.ps1 -Profile Gaming
```

### Development

```powershell
.\DeepCleanPro.ps1 -Profile Development
```

### Music / Audio Production

```powershell
.\DeepCleanPro.ps1 -Profile Music
```

### Video Editing

```powershell
.\DeepCleanPro.ps1 -Profile Video
```

### Office

```powershell
.\DeepCleanPro.ps1 -Profile Office
```

---

# ⚙️ 3. **Mode Examples**

### Quick Mode (fast 5-minute cleanup)

```powershell
.\DeepCleanPro.ps1 -QuickMode
```

### Full Optimization

```powershell
.\DeepCleanPro.ps1
```

### WhatIf (simulate without applying changes)

```powershell
.\DeepCleanPro.ps1 -WhatIf
```

### Skip health check

```powershell
.\DeepCleanPro.ps1 -SkipHealth
```

### Skip defrag

```powershell
.\DeepCleanPro.ps1 -SkipDefrag
```

### No reboot prompt

```powershell
.\DeepCleanPro.ps1 -NoReboot
```

### Force reboot when finished

```powershell
.\DeepCleanPro.ps1 -AutoReboot
```

---

# 🧩 4. **Combining Flags**

### Gaming + Quick Mode + No Reboot

```powershell
.\DeepCleanPro.ps1 -Profile Gaming -QuickMode -NoReboot
```

### Development Mode with simulation only

```powershell
.\DeepCleanPro.ps1 -Profile Development -WhatIf
```

### Full Optimization, skip Windows Update prompt

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates
```

### Balanced profile but Quick Mode and WhatIf:

```powershell
.\DeepCleanPro.ps1 -QuickMode -WhatIf
```

---

# 💻 5. **Running From the Launcher (Gist)**

### Standard:

```powershell
irm 'GIST_URL' | iex
```

### With profile:

```powershell
$env:DCP_PROFILE = 'Gaming'
irm 'GIST_URL' | iex
```

### Quick Mode:

```powershell
$env:DCP_QUICK_MODE = 'true'
irm 'GIST_URL' | iex
```

### No reboot:

```powershell
$env:DCP_NO_REBOOT = 'true'
irm 'GIST_URL' | iex
```

### Simulation mode:

```powershell
irm 'GIST_URL' | iex -WhatIf
```

---

# ☁️ 6. **OneDrive Liberator Examples**

### Run normally (recommended)

```powershell
.\OneDriveNuke.ps1
```

### Automatic mode (skip YES prompt)

```powershell
.\OneDriveNuke.ps1 -Force
```

### Skip backup (NOT recommended)

```powershell
.\OneDriveNuke.ps1 -KeepFiles:$false -Force
```

### Common enterprise use:

```powershell
Invoke-Command -ComputerName PC01 {
    & "C:\DeepCleanPro\OneDriveNuke.ps1" -Force
}
```

---

# 🔧 7. **Fix Windows Policies Tool**

### Run policy fixer standalone:

```powershell
.\Fix-WindowsPolicies.ps1
```

### Trigger via Deep Clean Pro:

```powershell
.\DeepCleanPro.ps1 -FixPolicies
```

### Specify alternate backup path:

```powershell
.\Fix-WindowsPolicies.ps1 -BackupPath "D:\PolicyBackup.json"
```

---

# 🔄 8. **Windows Update Maintenance Examples**

### Run Windows Update maintenance manually

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates
```

### Force update cycle without optimizations

```powershell
.\Optimize-WindowsUpdates.ps1
```

### Combine with Full Clean

```powershell
.\DeepCleanPro.ps1 -RunWindowsUpdates -AutoReboot
```

### Skip update step during Full Clean

```powershell
.\DeepCleanPro.ps1
# When prompted: type "N"
```

---

# 🧩 9. **Extensions & Modules Examples**

### Add a custom profile

```powershell
# Extensions\MyProfile.ps1
$Script:CustomProfiles['MyStudio'] = {
    # Example: Audio environment tuning
    Write-ColorOutput "Applying MyStudio optimizations..." -Type Info
}
```

Run it:

```powershell
.\DeepCleanPro.ps1 -Profile MyStudio
```

### Add a GPU optimization extension

```powershell
# Extensions\Optimize-IntelGPU.ps1
function Optimize-IntelGPU {
    Write-ColorOutput "Applying Intel GPU tuning" -Type Info
}
Register-ExtensionHook -Stage "AfterOptimize" -ScriptBlock { Optimize-IntelGPU }
```

---

# 🏢 10. **Enterprise / Technician Examples**

### GPO Startup Script (Lightweight)

```powershell
if (Test-NetConnection github.com -Port 443 -Quiet) {
    irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1' | iex -QuickMode
}
```

### SCCM / Intune Package

```xml
powershell.exe -ExecutionPolicy Bypass -File DeepCleanPro.ps1 -Profile Office -QuickMode
```

### Bulk remote run

```powershell
$pcs = Get-ADComputer -Filter * | Select -Expand Name
Invoke-Command -ComputerName $pcs -ScriptBlock {
    & "C:\DeepCleanPro\DeepCleanPro.ps1" -Profile Office -QuickMode
}
```

---

# 🧪 11. **Testing Examples**

### Run full validation suite

```powershell
.\Scripts\VALIDATE.ps1
```

### Run all Pester tests

```powershell
Invoke-Pester -Path .\Tests\
```

### Run only security tests

```powershell
Invoke-Pester -Tag 'Security'
```

### Run ScriptAnalyzer

```powershell
Invoke-ScriptAnalyzer -Path . -Recurse
```

---

# 🔍 12. **Developer Examples**

### Run raw script with parameters

```powershell
$params = @{
    Profile   = 'Gaming'
    QuickMode = $true
}
& ([ScriptBlock]::Create((irm 'https://raw.githubusercontent.com/iSystemDevelopment/deep-clean-pro/main/DeepCleanPro.ps1'))) @params
```

### Debug mode

```powershell
$DebugPreference = 'Continue'
.\DeepCleanPro.ps1
```

### Measure performance of core engine

```powershell
Measure-Script -Path .\DeepCleanPro.ps1 -Expression { .\DeepCleanPro.ps1 -QuickMode }
```

---

# 🔄 13. **Maintenance Examples**

### Update to latest version

```powershell
Remove-Item C:\DeepCleanPro -Recurse -Force
git clone https://github.com/iSystemDevelopment/deep-clean-pro.git C:\DeepCleanPro
```

### Remove all logs over 30 days

```powershell
Get-ChildItem "C:\DeepCleanPro\Logs" | 
    Where-Object LastWriteTime -lt (Get-Date).AddDays(-30) |
    Remove-Item -Force
```

---

# 🎉 **Example Library Complete**

