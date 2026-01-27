<#
.SYNOPSIS
    Windows Development Environment Setup Script
.DESCRIPTION
    Installs and configures Windows development environment:
    - PowerShell Core (pwsh)
    - Windows Terminal with Monokai theme
    - Oh My Posh with Pure theme
    - PSReadLine with Vi mode
    - Terminal-Icons
    - GlazeWM (tiling window manager)
    - Zebar (status bar)
    - WSL Ubuntu setup (optional)
.PARAMETER SkipPowerShell
    Skip PowerShell Core installation
.PARAMETER SkipTerminal
    Skip Windows Terminal configuration
.PARAMETER SkipOhMyPosh
    Skip Oh My Posh and shell configuration
.PARAMETER SkipWM
    Skip window manager (GlazeWM/Zebar) installation
.PARAMETER SkipWSL
    Skip WSL Ubuntu setup check
#>

[CmdletBinding()]
param(
    [switch]$SkipPowerShell,
    [switch]$SkipTerminal,
    [switch]$SkipOhMyPosh,
    [switch]$SkipWM,
    [switch]$SkipWSL
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SharedDotfilesDir = Join-Path $RepoRoot "dotfiles"
$WindowsDotfilesDir = Join-Path $ScriptDir "dotfiles"

$ErrorActionPreference = 'Stop'
$Colors = @{
    Info = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error = 'Red'
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'SUCCESS', 'WARNING', 'ERROR')][string]$Level = 'INFO'
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        'SUCCESS' { Write-Host $logEntry -ForegroundColor $Colors.Success }
        'WARNING' { Write-Host $logEntry -ForegroundColor $Colors.Warning }
        'ERROR'   { Write-Host $logEntry -ForegroundColor $Colors.Error }
        default   { Write-Host $logEntry -ForegroundColor $Colors.Info }
    }
}

function Test-Command {
    param([string]$Command)
    try {
        Get-Command $Command -ErrorAction Stop | Out-Null
        return $true
    } catch {
        return $false
    }
}

function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Install-WingetPackage {
    param(
        [string]$PackageId,
        [string]$PackageName
    )

    $installed = winget list --exact --id $PackageId 2>$null
    if ($installed -and -not ($installed -match 'No installed package found')) {
        Write-Log "$PackageName is already installed" -Level 'INFO'
        return $true
    }

    Write-Log "Installing $PackageName..." -Level 'INFO'
    winget install --id $PackageId --accept-source-agreements --accept-package-agreements -e

    if ($LASTEXITCODE -eq 0) {
        Write-Log "$PackageName installed successfully" -Level 'SUCCESS'
        return $true
    } else {
        Write-Log "Failed to install $PackageName (exit code: $LASTEXITCODE)" -Level 'ERROR'
        return $false
    }
}

function Ensure-Directory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
        Write-Log "Created directory: $Path" -Level 'INFO'
    }
}

function Set-StartupShortcut {
    param(
        [string]$Name,
        [string]$TargetPath,
        [string]$Arguments = ""
    )

    $startupFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupFolder "$Name.lnk"

    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
    }

    $wshell = New-Object -ComObject WScript.Shell
    $shortcut = $wshell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $TargetPath
    $shortcut.Arguments = $Arguments
    $shortcut.WorkingDirectory = Split-Path $TargetPath
    $shortcut.Description = "$Name startup shortcut"
    $shortcut.Save()

    Write-Log "Created startup shortcut: $Name" -Level 'SUCCESS'
}

function Test-WSLUbuntuInstalled {
    try {
        if (-not (Test-Command 'wsl')) {
            return $false
        }

        $env:WSL_UTF8 = 1
        $distros = wsl --list --verbose 2>$null

        if ($distros -match [regex]::Escape('Ubuntu')) {
            return $true
        }
    } catch {
        return $false
    }

    return $false
}

# =============================================================================
# STEP 1: PowerShell Core Installation
# =============================================================================
function Install-PowerShellCore {
    Write-Log "=== Step 1: PowerShell Core Setup ===" -Level 'INFO'

    # Check if pwsh is already installed
    if (Test-Command 'pwsh') {
        $version = (pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()') 2>$null
        Write-Log "PowerShell Core is already installed (version: $version)" -Level 'INFO'
        return
    }

    Write-Log "Installing PowerShell Core..." -Level 'INFO'

    # Use winget for installation (cleaner than MSI)
    $installed = Install-WingetPackage -PackageId "Microsoft.PowerShell" -PackageName "PowerShell Core"

    if ($installed) {
        Write-Log "PowerShell Core installed. Please restart your terminal to use 'pwsh'." -Level 'SUCCESS'
    } else {
        Write-Log "Failed to install PowerShell Core via winget. Trying MSI installer..." -Level 'WARNING'

        try {
            Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -UseMSI -Quiet"
            Write-Log "PowerShell Core installed via MSI" -Level 'SUCCESS'
        } catch {
            Write-Log "Failed to install PowerShell Core: $_" -Level 'ERROR'
        }
    }
}

# =============================================================================
# STEP 2: Windows Terminal Configuration
# =============================================================================
function Install-WindowsTerminal {
    Write-Log "=== Step 2: Windows Terminal Setup ===" -Level 'INFO'

    # Install Windows Terminal if not present
    Install-WingetPackage -PackageId "Microsoft.WindowsTerminal" -PackageName "Windows Terminal"

    # Configure Windows Terminal settings
    $terminalSettingsDir = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"

    # Also check for Windows Terminal Preview and regular install locations
    $possiblePaths = @(
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"),
        (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState"),
        (Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal")
    )

    $terminalSettingsDir = $null
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $terminalSettingsDir = $path
            break
        }
    }

    if (-not $terminalSettingsDir) {
        # Create default path
        $terminalSettingsDir = $possiblePaths[0]
        Ensure-Directory $terminalSettingsDir
    }

    $settingsPath = Join-Path $terminalSettingsDir "settings.json"

    $terminalSettings = @'
{
  "$help": "https://aka.ms/terminal-documentation",
  "$schema": "https://aka.ms/terminal-profiles-schema",
  "actions": [
    {
      "command": {
        "action": "copy",
        "singleLine": false
      },
      "id": "User.copy.644BA8F2"
    },
    {
      "command": "paste",
      "id": "User.paste"
    },
    {
      "command": {
        "action": "splitPane",
        "split": "auto",
        "splitMode": "duplicate"
      },
      "id": "User.splitPane.A6751878"
    },
    {
      "command": "find",
      "id": "User.find"
    }
  ],
  "copyFormatting": "none",
  "copyOnSelect": true,
  "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
  "firstWindowPreference": "persistedWindowLayout",
  "focusFollowMouse": true,
  "keybindings": [
    {
      "id": "User.copy.644BA8F2",
      "keys": "ctrl+c"
    },
    {
      "id": "User.paste",
      "keys": "ctrl+v"
    },
    {
      "id": "User.find",
      "keys": "ctrl+shift+f"
    },
    {
      "id": "User.splitPane.A6751878",
      "keys": "alt+shift+d"
    }
  ],
  "newTabMenu": [
    {
      "type": "remainingProfiles"
    }
  ],
  "profiles": {
    "defaults": {
      "colorScheme": "Monokai Classic",
      "font": {
        "face": "JetBrainsMono Nerd Font"
      }
    },
    "list": [
      {
        "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
        "hidden": false,
        "name": "PowerShell",
        "source": "Windows.Terminal.PowershellCore"
      }
    ]
  },
  "schemes": [
    {
      "background": "#272822",
      "black": "#272822",
      "blue": "#66D9EF",
      "brightBlack": "#75715E",
      "brightBlue": "#66D9EF",
      "brightCyan": "#A1EFE4",
      "brightGreen": "#A6E22E",
      "brightPurple": "#AE81FF",
      "brightRed": "#FD971F",
      "brightWhite": "#F9F8F5",
      "brightYellow": "#E6DB74",
      "cursorColor": "#F8F8F2",
      "cyan": "#A1EFE4",
      "foreground": "#F8F8F2",
      "green": "#A6E22E",
      "name": "Monokai Classic",
      "purple": "#AE81FF",
      "red": "#F92672",
      "selectionBackground": "#49483E",
      "white": "#F8F8F2",
      "yellow": "#E6DB74"
    }
  ],
  "showTabsFullscreen": true,
  "themes": [],
  "useAcrylicInTabRow": true,
  "warning.confirmCloseAllTabs": false,
  "warning.inputService": false,
  "warning.largePaste": false,
  "warning.multiLinePaste": false,
  "windowingBehavior": "useExisting"
}
'@

    $terminalSettings | Set-Content -Path $settingsPath -Encoding utf8
    Write-Log "Windows Terminal settings configured: $settingsPath" -Level 'SUCCESS'
}

# =============================================================================
# STEP 3: Oh My Posh Setup
# =============================================================================
function Install-OhMyPosh {
    Write-Log "=== Step 3: Oh My Posh Setup ===" -Level 'INFO'

    # Install Oh My Posh
    Install-WingetPackage -PackageId "JanDeDobbeleer.OhMyPosh" -PackageName "Oh My Posh"

    # Install PSReadLine module
    Write-Log "Installing PSReadLine module..." -Level 'INFO'
    if (-not (Get-Module -ListAvailable -Name PSReadLine | Where-Object { $_.Version -ge [version]"2.2.0" })) {
        Install-Module PSReadLine -Force -SkipPublisherCheck -Scope CurrentUser
        Write-Log "PSReadLine installed" -Level 'SUCCESS'
    } else {
        Write-Log "PSReadLine is already installed" -Level 'INFO'
    }

    # Install Terminal-Icons module
    Write-Log "Installing Terminal-Icons module..." -Level 'INFO'
    if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
        Install-Module Terminal-Icons -Force -Scope CurrentUser
        Write-Log "Terminal-Icons installed" -Level 'SUCCESS'
    } else {
        Write-Log "Terminal-Icons is already installed" -Level 'INFO'
    }

    # Install JetBrainsMono Nerd Font
    Write-Log "Installing JetBrainsMono Nerd Font..." -Level 'INFO'
    $fontDir = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
    $fontInstalled = Get-ChildItem -Path $fontDir -Filter "*JetBrainsMono*" -ErrorAction SilentlyContinue

    if (-not $fontInstalled) {
        try {
            # Refresh PATH to include oh-my-posh
            $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

            if (Test-Command 'oh-my-posh') {
                oh-my-posh font install JetBrainsMono
                Write-Log "JetBrainsMono Nerd Font installed" -Level 'SUCCESS'
            } else {
                Write-Log "oh-my-posh not in PATH yet. Font will be installed on next run." -Level 'WARNING'
            }
        } catch {
            Write-Log "Failed to install font: $_" -Level 'WARNING'
        }
    } else {
        Write-Log "JetBrainsMono Nerd Font is already installed" -Level 'INFO'
    }

    # Download Pure theme
    $ohMyPoshDir = Join-Path $env:USERPROFILE ".OhMyPosh"
    Ensure-Directory $ohMyPoshDir

    $themeFile = Join-Path $ohMyPoshDir "pure.omp.json"
    if (-not (Test-Path $themeFile)) {
        Write-Log "Downloading Pure theme..." -Level 'INFO'
        try {
            Invoke-WebRequest `
                -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/pure.omp.json" `
                -OutFile $themeFile `
                -UseBasicParsing
            Write-Log "Pure theme downloaded" -Level 'SUCCESS'
        } catch {
            Write-Log "Failed to download Pure theme: $_" -Level 'ERROR'
        }
    } else {
        Write-Log "Pure theme already exists" -Level 'INFO'
    }

    # Create PowerShell profile
    Write-Log "Configuring PowerShell profile..." -Level 'INFO'

    # Get the profile path for PowerShell Core (pwsh)
    $profileDir = Split-Path $PROFILE
    Ensure-Directory $profileDir

    $profileContent = @'
# PROFILE LOADED
Write-Host "PROFILE LOADED: $PROFILE"

# --- Oh My Posh (prompt theme) ---
$ohMyPoshConfig = Join-Path $env:USERPROFILE ".OhMyPosh\pure.omp.json"
if (Test-Path $ohMyPoshConfig) {
    oh-my-posh init pwsh --config $ohMyPoshConfig | Invoke-Expression
}

# --- Terminal-Icons ---
if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# --- PSReadLine (Vi mode + inline autosuggest) ---
if (Get-Module -ListAvailable -Name PSReadLine) {
    Import-Module PSReadLine

    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Cursor shape change (Windows Terminal supports this)
    $esc = [char]0x1b

    try {
        Set-PSReadLineOption -ViModeIndicator Script
        Set-PSReadLineOption -ViModeChangeHandler {
            param($mode)
            switch ($mode) {
                "Insert"  { Write-Host -NoNewline "$([char]0x1b)[5 q" }  # beam
                "Command" { Write-Host -NoNewline "$([char]0x1b)[1 q" }  # block
                default   { Write-Host -NoNewline "$([char]0x1b)[5 q" }
            }
        }
    } catch {
        # PSReadLine version doesn't support ViModeChangeHandler
    }
}
'@

    $profileContent | Set-Content -Path $PROFILE -Encoding utf8
    Write-Log "PowerShell profile configured: $PROFILE" -Level 'SUCCESS'
}

# =============================================================================
# STEP 4: GlazeWM and Zebar Setup
# =============================================================================
function Install-WindowManager {
    Write-Log "=== Step 4: Window Manager Setup (GlazeWM + Zebar) ===" -Level 'INFO'

    # Install GlazeWM
    Install-WingetPackage -PackageId "glzr-io.glazewm" -PackageName "GlazeWM"

    # Install Zebar
    Install-WingetPackage -PackageId "glzr-io.zebar" -PackageName "Zebar"

    # Configure GlazeWM
    $glzrDir = Join-Path $env:USERPROFILE ".glzr"
    $glazewmConfigDir = Join-Path $glzrDir "glazewm"
    $zebarConfigDir = Join-Path $glzrDir "zebar"

    Ensure-Directory $glazewmConfigDir
    Ensure-Directory $zebarConfigDir

    # Copy GlazeWM config
    $glazewmSource = Join-Path $WindowsDotfilesDir "glazewm\config.yaml"
    $glazewmDest = Join-Path $glazewmConfigDir "config.yaml"

    if (Test-Path $glazewmSource) {
        Copy-Item -Path $glazewmSource -Destination $glazewmDest -Force
        Write-Log "GlazeWM config installed: $glazewmDest" -Level 'SUCCESS'
    } else {
        Write-Log "GlazeWM config not found: $glazewmSource" -Level 'WARNING'
    }

    # Copy Zebar widgets (monokai-statusbar folder)
    $zebarWidgetsSource = Join-Path $WindowsDotfilesDir "zebar\monokai-statusbar"
    $zebarWidgetsDest = Join-Path $zebarConfigDir "monokai-statusbar"

    if (Test-Path $zebarWidgetsSource) {
        if (Test-Path $zebarWidgetsDest) {
            Remove-Item -Path $zebarWidgetsDest -Recurse -Force
        }
        Copy-Item -Path $zebarWidgetsSource -Destination $zebarWidgetsDest -Recurse -Force
        Write-Log "Zebar widgets installed: $zebarWidgetsDest" -Level 'SUCCESS'
    } else {
        Write-Log "Zebar widgets not found: $zebarWidgetsSource" -Level 'WARNING'
    }

    # Create Zebar settings.json
    $zebarSettingsPath = Join-Path $zebarConfigDir "settings.json"
    $zebarSettings = @'
{
  "$schema": "https://github.com/glzr-io/zebar/raw/v3.1.1/resources/settings-schema.json",
  "startupConfigs": [
    {
      "pack": "monokai-statusbar",
      "widget": "monokai-topbar",
      "preset": "default"
    }
  ]
}
'@

    $zebarSettings | Set-Content -Path $zebarSettingsPath -Encoding utf8
    Write-Log "Zebar settings configured: $zebarSettingsPath" -Level 'SUCCESS'

    # Setup GlazeWM and Zebar to start on login using startup shortcut
    Write-Log "Configuring startup shortcuts..." -Level 'INFO'

    # Find GlazeWM executable
    $glazewmExe = $null
    $glazewmPaths = @(
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\glzr-io.glazewm_Microsoft.Winget.Source_8wekyb3d8bbwe\glazewm.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\glazewm\glazewm.exe"),
        (Join-Path $env:ProgramFiles "glzr.io\GlazeWM\glazewm.exe"),
        (Join-Path $env:ProgramFiles "glzr.io\GlazeWM\cli\glazewm.exe")
    )

    # Find Zebar executable
    $zebarExe = $null
    $zebarPaths = @(
        (Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages\glzr-io.zebar_Microsoft.Winget.Source_8wekyb3d8bbwe\zebar.exe"),
        (Join-Path $env:LOCALAPPDATA "Programs\zebar\zebar.exe"),
        (Join-Path $env:ProgramFiles "glzr.io\Zebar\zebar.exe")
    )

    # Also try to find via winget package location
    $wingetPackagesDir = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Packages"
    if (Test-Path $wingetPackagesDir) {
        # Check GlazeWM packages
        $glazewmPackages = Get-ChildItem -Path $wingetPackagesDir -Filter "glzr-io.glazewm*" -Directory -ErrorAction SilentlyContinue
        foreach ($pkg in $glazewmPackages) {
            $exePath = Get-ChildItem -Path $pkg.FullName -Filter "glazewm.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($exePath) { $glazewmPaths = @($exePath.FullName) + $glazewmPaths }
        }

        # Check Zebar packages
        $zebarPackages = Get-ChildItem -Path $wingetPackagesDir -Filter "glzr-io.zebar*" -Directory -ErrorAction SilentlyContinue
        foreach ($pkg in $zebarPackages) {
            $exePath = Get-ChildItem -Path $pkg.FullName -Filter "zebar.exe" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1
            if ($exePath) { $zebarPaths = @($exePath.FullName) + $zebarPaths }
        }
    }

    foreach ($path in $glazewmPaths) {
        if (Test-Path $path) { $glazewmExe = $path; break }
    }
    foreach ($path in $zebarPaths) {
        if (Test-Path $path) { $zebarExe = $path; break }
    }

    # Try command path
    if (-not $glazewmExe -and (Test-Command "glazewm")) {
        $glazewmExe = (Get-Command glazewm -ErrorAction SilentlyContinue).Source
    }
    if (-not $zebarExe -and (Test-Command "zebar")) {
        $zebarExe = (Get-Command zebar -ErrorAction SilentlyContinue).Source
    }

    # Create GlazeWM startup shortcut
    if ($glazewmExe -and (Test-Path $glazewmExe)) {
        Set-StartupShortcut -Name "GlazeWM" -TargetPath $glazewmExe
    } else {
        Write-Log "GlazeWM executable not found. Startup shortcut not created." -Level 'WARNING'
    }

    # Create Zebar startup shortcut
    if ($zebarExe -and (Test-Path $zebarExe)) {
        Set-StartupShortcut -Name "Zebar" -TargetPath $zebarExe
    } else {
        Write-Log "Zebar executable not found. Startup shortcut not created." -Level 'WARNING'
    }

    Write-Log "Window Manager setup complete!" -Level 'SUCCESS'
}

# =============================================================================
# STEP 5: WSL Ubuntu Setup
# =============================================================================
function Install-WSLUbuntu {
    Write-Log "=== Step 5: WSL Ubuntu Setup ===" -Level 'INFO'

    Write-Log "Checking for WSL Ubuntu..." -Level 'INFO'

    $ubuntuInstalled = Test-WSLUbuntuInstalled

    if (-not $ubuntuInstalled) {
        Write-Log "WSL Ubuntu is not installed. Skipping WSL setup." -Level 'WARNING'
        Write-Log "If you want to use WSL, please install it first:" -Level 'INFO'
        Write-Log "  1. Open PowerShell as Administrator" -Level 'INFO'
        Write-Log "  2. Run: wsl --install -d Ubuntu" -Level 'INFO'
        Write-Log "  3. Restart your computer and run this script again." -Level 'INFO'
        return
    }

    Write-Log "Found WSL Ubuntu installation" -Level 'SUCCESS'

    Write-Log "Setting up Ubuntu development environment inside WSL..." -Level 'INFO'

    $ubuntuScriptPath = Join-Path $RepoRoot "ubuntu-server\install.sh"

    if (-not (Test-Path $ubuntuScriptPath)) {
        Write-Log "Ubuntu install script not found at: $ubuntuScriptPath" -Level 'ERROR'
        exit 1
    }

    Write-Log "Running Ubuntu setup inside WSL..." -Level 'INFO'
    Write-Log ""

    $wslScriptPath = wsl wslpath -a -u $ubuntuScriptPath.Replace('\', '\\')

    $command = "cd ~ && bash `"$wslScriptPath`""

    wsl -d Ubuntu -e bash -c $command

    if ($LASTEXITCODE -eq 0) {
        Write-Log ""
        Write-Log "WSL Ubuntu setup completed successfully!" -Level 'SUCCESS'
    } else {
        Write-Log ""
        Write-Log "WSL Ubuntu setup failed with exit code: $LASTEXITCODE" -Level 'ERROR'
        exit 1
    }
}

function Main {
    Write-Host ""
    Write-Host "+--------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|       Windows Development Environment Setup                  |" -ForegroundColor Cyan
    Write-Host "|   (PowerShell + Terminal + OhMyPosh + GlazeWM + Zebar)       |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    # Check for winget
    if (-not (Test-Command 'winget')) {
        Write-Log "winget is not installed or not in PATH" -Level 'ERROR'
        Write-Log "Please install winget from the Microsoft Store (App Installer)" -Level 'ERROR'
        exit 1
    }

    # Step 1: PowerShell Core
    if (-not $SkipPowerShell) {
        Install-PowerShellCore
        Write-Host ""
    }

    # Step 2: Windows Terminal
    if (-not $SkipTerminal) {
        Install-WindowsTerminal
        Write-Host ""
    }

    # Step 3: Oh My Posh
    if (-not $SkipOhMyPosh) {
        Install-OhMyPosh
        Write-Host ""
    }

    # Step 4: Window Manager (GlazeWM + Zebar)
    if (-not $SkipWM) {
        Install-WindowManager
        Write-Host ""
    }

    # Step 5: WSL Ubuntu
    if (-not $SkipWSL) {
        Install-WSLUbuntu
        Write-Host ""
    }

    Write-Host ""
    Write-Host "+---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host "|                  Installation Complete!                       |" -ForegroundColor Green
    Write-Host "+---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
    Write-Log "What was installed:" -Level 'INFO'
    if (-not $SkipPowerShell) { Write-Log "  - PowerShell Core (pwsh)" -Level 'INFO' }
    if (-not $SkipTerminal)   { Write-Log "  - Windows Terminal with Monokai theme" -Level 'INFO' }
    if (-not $SkipOhMyPosh)   { Write-Log "  - Oh My Posh with Pure theme" -Level 'INFO' }
    if (-not $SkipOhMyPosh)   { Write-Log "  - PSReadLine with Vi mode" -Level 'INFO' }
    if (-not $SkipOhMyPosh)   { Write-Log "  - Terminal-Icons" -Level 'INFO' }
    if (-not $SkipWM)         { Write-Log "  - GlazeWM (tiling window manager)" -Level 'INFO' }
    if (-not $SkipWM)         { Write-Log "  - Zebar (status bar)" -Level 'INFO' }
    Write-Host ""
    Write-Log "Next steps:" -Level 'INFO'
    Write-Log "  1. Restart your terminal or log out/in to apply changes" -Level 'INFO'
    Write-Log "  2. GlazeWM and Zebar will start automatically on next login" -Level 'INFO'
    if (-not $SkipWSL) {
        Write-Log "  3. Open WSL Ubuntu for Linux development tools" -Level 'INFO'
    }
    Write-Host ""
}

Main
