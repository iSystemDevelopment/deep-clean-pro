# 📝 GitHub Gist Setup Instructions

This directory contains the launcher script that should be uploaded to GitHub Gist for creating "online" shortcuts that always run the latest version of Deep Clean Pro from your repository.

## 🎯 Why Use a Gist Launcher?

The Gist launcher provides several benefits:
- **Always Current**: Shortcuts always run the latest version from your repository
- **No Local Updates**: Users don't need to update local files
- **Easy Distribution**: Share a single Gist URL instead of files
- **Central Control**: Update the script once, affects all users
- **Security**: Only pulls from your verified GitHub repository

## 📋 Setup Steps

### Step 1: Prepare the Launcher Script

1. Open `gist-launcher.ps1` in this directory
2. **IMPORTANT**: Update line 22 with your repository URL:
   ```powershell
   RepoUrl = "https://raw.githubusercontent.com/YOUR-USERNAME/YOUR-REPO/main/DeepCleanPro.ps1"
   ```
3. Save the file

### Step 2: Create a GitHub Gist

1. **Sign in to GitHub**
   - Go to [https://github.com](https://github.com)
   - Sign in to your account

2. **Navigate to Gist**
   - Go to [https://gist.github.com](https://gist.github.com)
   - Click the "+" or "New gist" button (top right)

3. **Create the Gist**
   - **Gist description**: `Deep Clean Pro - GitHub Launcher v1.0`
   - **Filename**: `DeepCleanPro-Launcher.ps1`
   - **Content**: Copy and paste the entire content of `gist-launcher.ps1`

4. **Choose Visibility**
   - **Secret Gist** (Recommended): Only accessible via direct link
   - **Public Gist**: Visible to everyone, searchable

5. **Create the Gist**
   - Click "Create secret gist" or "Create public gist"

### Step 3: Get the Raw URL

1. After creating the Gist, you'll see your new Gist page
2. Click the **"Raw"** button (top right of the code area)
3. Copy the URL from your browser's address bar

The Raw URL will look like:
```
https://gist.githubusercontent.com/YOUR-USERNAME/GIST-ID/raw/HASH/DeepCleanPro-Launcher.ps1
```

### Step 4: Create Desktop Shortcuts

Now use this Raw URL to create shortcuts that pull from GitHub:

```powershell
# Navigate to your Deep Clean Pro installation
cd C:\DeepCleanPro\Scripts

# Run the shortcut creator with your Gist URL
.\CreateDesktopShortcuts.ps1 -GistLauncherURL "YOUR-RAW-GIST-URL"
```

This will create three online shortcuts:
- **Deep Clean Pro (Online)** - Full mode from GitHub
- **Deep Clean Pro Quick (Online)** - Quick mode from GitHub  
- **Deep Clean Pro Test (Online)** - Test mode from GitHub

## 🔧 Customization Options

### Repository URL
If you've forked the repository, update the `RepoUrl` in the launcher:
```powershell
$Script:Config = @{
    RepoUrl = "https://raw.githubusercontent.com/YOUR-FORK/deep-clean-pro/main/DeepCleanPro.ps1"
    # ...
}
```

### Timeout Settings
Adjust for slow connections:
```powershell
$Script:Config = @{
    # ...
    Timeout = 60        # Increase timeout to 60 seconds
    RetryCount = 5      # Increase retry attempts
    RetryDelay = 3      # Wait longer between retries
}
```

### Custom Branch
To pull from a different branch:
```powershell
RepoUrl = "https://raw.githubusercontent.com/USER/REPO/development/DeepCleanPro.ps1"
#                                                      ^^^^^^^^^^^ 
#                                                      Your branch name
```

## 🔒 Security Considerations

### For Secret Gists
- Only share the URL with trusted users
- URLs are long and hard to guess but not encrypted
- Can be deleted anytime from your Gist page

### For Public Gists
- Anyone can view and fork
- Good for open-source distributions
- Can track stars and forks

### Best Practices
1. **Never include sensitive data** in the launcher
2. **Always verify** the repository URL is correct
3. **Use HTTPS** URLs only (not HTTP)
4. **Regularly review** Gist access logs if public
5. **Update cautiously** - changes affect all users immediately

## 🚀 Testing Your Launcher

### Manual Test
```powershell
# Test the launcher directly
irm 'YOUR-RAW-GIST-URL' | iex
```

### Test with Parameters
```powershell
# Test Quick Mode
$env:DCP_QUICK_MODE='true'; irm 'YOUR-RAW-GIST-URL' | iex

# Test WhatIf Mode
$WhatIfPreference=$true; irm 'YOUR-RAW-GIST-URL' | iex
```

## 📝 Updating the Launcher

To update the launcher after creation:

1. Go to your Gist page: [https://gist.github.com/YOUR-USERNAME](https://gist.github.com/YOUR-USERNAME)
2. Click on your Deep Clean Pro launcher Gist
3. Click "Edit" button
4. Make your changes
5. Click "Update secret gist" or "Update public gist"

**Note**: Updates are immediate - all users will get the new version on next run

## ❓ Troubleshooting

### Common Issues

**"Cannot download from GitHub"**
- Check internet connection
- Verify GitHub isn't blocked by firewall
- Try accessing the Raw URL directly in a browser

**"Script appears invalid"**
- Ensure the Gist contains the complete script
- Check for copy/paste errors
- Verify the Raw URL is correct

**"Administrator privileges required"**
- Right-click shortcut → Run as administrator
- Or run PowerShell as admin first

**"Repository not found"**
- Check the repository URL in the launcher
- Ensure repository is public or accessible
- Verify branch name is correct

## 📊 Example Gist Structure

Your Gist page should show:
```
DeepCleanPro-Launcher.ps1
Deep Clean Pro - GitHub Launcher v1.0
Created X minutes ago • 0 stars • 0 forks

[Raw] [Blame] [History]

1  | <#
2  | .SYNOPSIS
3  |     Deep Clean Pro - GitHub Launcher Script
...
```

## 🔗 Useful Links

- [GitHub Gists Documentation](https://docs.github.com/en/github/writing-on-github/creating-gists)
- [PowerShell Execution Policies](https://docs.microsoft.com/powershell/module/microsoft.powershell.core/about/about_execution_policies)
- [Deep Clean Pro Repository](https://github.com/iSystemDevelopment/deep-clean-pro)

---

**Need Help?** Create an issue in the main repository or contact support@isystem.app