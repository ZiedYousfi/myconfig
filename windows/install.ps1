# Windows Development Environment Setup Script
# This script is idempotent - running it multiple times is safe
# Dotfiles are copied directly to their target locations (no stow on Windows)

# $ErrorActionPreference = 'Stop' (Disabled to ensure script continues even if some packages fail)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SharedDotfilesDir = Join-Path $RepoRoot "dotfiles"
$WindowsDotfilesDir = Join-Path $ScriptDir "dotfiles"

# Colors
$Colors = @{
    Info    = 'Cyan'
    Success = 'Green'
    Warning = 'Yellow'
    Error   = 'Red'
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO', 'OK', 'WARNING', 'ERROR')][string]$Level = 'INFO'
    )
    switch ($Level) {
        'OK'      { Write-Host "[OK] $Message" -ForegroundColor $Colors.Success }
        'WARNING' { Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Warning }
        'ERROR'   { Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Error }
        default   { Write-Host "[INFO] $Message" -ForegroundColor $Colors.Info }
    }
}

# ============================================================================
# Helper Functions
# ============================================================================

function Test-CommandExists {
    param([string]$Command)
    return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Copy-DotfileSafe {
    param(
        [string]$Source,
        [string]$Destination,
        [switch]$Recurse
    )

    if (-not (Test-Path $Source)) {
        Write-Log "Source not found: $Source" -Level 'WARNING'
        return
    }

    $destDir = if ($Recurse) { $Destination } else { Split-Path -Parent $Destination }
    if (-not (Test-Path $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    if ($Recurse) {
        Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force
        Write-Log "Copied $Source -> $Destination" -Level 'OK'
    } else {
        Copy-Item -Path $Source -Destination $Destination -Force
        Write-Log "Copied $Source -> $Destination" -Level 'OK'
    }
}

# ============================================================================
# Winget Packages Installation
# ============================================================================

function Install-WingetPackages {
    if (-not (Test-CommandExists "winget")) {
        Write-Log "winget not found. Please install App Installer from the Microsoft Store." -Level 'ERROR'
        return
    }

    $packagesJson = Join-Path $WindowsDotfilesDir "winget\packages.json"
    if (-not (Test-Path $packagesJson)) {
        Write-Log "Winget packages file not found: $packagesJson" -Level 'ERROR'
        return
    }

    Write-Log "Installing winget packages from $packagesJson..."
    winget import $packagesJson --accept-source-agreements --accept-package-agreements --ignore-unavailable
    Write-Log "Winget packages installed" -Level 'OK'
}

# ============================================================================
# PowerShell Profile
# ============================================================================

function Install-PowerShellProfile {
    $source = Join-Path $WindowsDotfilesDir "PowerShell\Microsoft.PowerShell_profile.ps1"
    $destination = $PROFILE

    if (-not (Test-Path $source)) {
        Write-Log "PowerShell profile source not found: $source" -Level 'ERROR'
        return
    }

    # Backup existing profile if it exists and wasn't created by us
    if ((Test-Path $destination) -and -not (Select-String -Path $destination -Pattern "Oh My Posh" -Quiet -ErrorAction SilentlyContinue)) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backup = "$destination.backup.$timestamp"
        Copy-Item -Path $destination -Destination $backup -Force
        Write-Log "Backed up existing profile to $backup"
    }

    Copy-DotfileSafe -Source $source -Destination $destination
    Write-Log "PowerShell profile installed" -Level 'OK'
}

# ============================================================================
# Neovim Configuration
# ============================================================================

function Install-NeovimConfig {
    $source = Join-Path $SharedDotfilesDir "nvim\.config\nvim"
    $destination = Join-Path $env:LOCALAPPDATA "nvim"

    if (-not (Test-Path $source)) {
        Write-Log "Neovim config source not found: $source" -Level 'ERROR'
        return
    }

    if ((Test-Path $destination) -and (Test-Path (Join-Path $destination "lua\config\lazy.lua"))) {
        Write-Log "Neovim configuration is already installed" -Level 'OK'
    } else {
        Write-Log "Installing Neovim configuration..."
    }

    Copy-DotfileSafe -Source $source -Destination $destination -Recurse
    Write-Log "Neovim configuration installed" -Level 'OK'
}

# ============================================================================
# Yazi Configuration
# ============================================================================

function Install-YaziConfig {
    $source = Join-Path $SharedDotfilesDir "yazi\.config\yazi"
    $destination = Join-Path $env:APPDATA "yazi"

    if (-not (Test-Path $source)) {
        Write-Log "Yazi config source not found: $source" -Level 'ERROR'
        return
    }

    Copy-DotfileSafe -Source $source -Destination $destination -Recurse
    Write-Log "Yazi configuration installed" -Level 'OK'
}

# ============================================================================
# Oh My Posh Configuration
# ============================================================================

function Install-OhMyPoshConfig {
    $source = Join-Path $WindowsDotfilesDir ".OhMyPosh"
    $destination = Join-Path $env:USERPROFILE ".OhMyPosh"

    if (-not (Test-Path $source)) {
        Write-Log "Oh My Posh config source not found: $source" -Level 'ERROR'
        return
    }

    Copy-DotfileSafe -Source $source -Destination $destination -Recurse
    Write-Log "Oh My Posh configuration installed" -Level 'OK'
}

# ============================================================================
# JetBrains Mono Font
# ============================================================================

function Install-JetBrainsMonoFont {
    if (-not (Test-CommandExists "oh-my-posh")) {
        Write-Log "oh-my-posh not found, skipping font installation" -Level 'WARNING'
        return
    }

    Write-Log "Installing JetBrains Mono font..."
    oh-my-posh font install JetBrainsMono
    Write-Log "JetBrains Mono font installed" -Level 'OK'
}

# ============================================================================
# Windows Terminal Settings
# ============================================================================

function Install-WindowsTerminalSettings {
    $source = Join-Path $WindowsDotfilesDir "MicrosoftWindowsTerminal\settings.json"
    $destination = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $source)) {
        Write-Log "Windows Terminal settings source not found: $source" -Level 'ERROR'
        return
    }

    $destDir = Split-Path -Parent $destination
    if (-not (Test-Path $destDir)) {
        Write-Log "Windows Terminal is not installed (LocalState dir not found), skipping" -Level 'WARNING'
        return
    }

    # Backup existing settings
    if (Test-Path $destination) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backup = "$destination.backup.$timestamp"
        Copy-Item -Path $destination -Destination $backup -Force
        Write-Log "Backed up existing Windows Terminal settings to $backup"
    }

    Copy-DotfileSafe -Source $source -Destination $destination
    Write-Log "Windows Terminal settings installed" -Level 'OK'
}

# ============================================================================
# GlazeWM and Zebar Configuration
# ============================================================================

function Install-GlazeWMConfig {
    $source = Join-Path $WindowsDotfilesDir ".glzr"
    $destination = Join-Path $env:USERPROFILE ".glzr"

    if (-not (Test-Path $source)) {
        Write-Log "GlazeWM config source not found: $source" -Level 'ERROR'
        return
    }

    Copy-DotfileSafe -Source $source -Destination $destination -Recurse
    Write-Log "GlazeWM and Zebar configuration installed" -Level 'OK'
}

# ============================================================================
# AutoHotkey Scripts
# ============================================================================

function Install-AHKScripts {
    $source = Join-Path $WindowsDotfilesDir "AHK"
    $destination = Join-Path $env:USERPROFILE "AHK"

    if (-not (Test-Path $source)) {
        Write-Log "AHK scripts source not found: $source" -Level 'ERROR'
        return
    }

    Copy-DotfileSafe -Source $source -Destination $destination -Recurse
    Write-Log "AutoHotkey scripts installed" -Level 'OK'
}

# ============================================================================
# PSReadLine Module
# ============================================================================

function Install-PSReadLineModule {
    if (Get-Module -ListAvailable -Name PSReadLine) {
        Write-Log "PSReadLine module is already installed" -Level 'OK'
    } else {
        Write-Log "Installing PSReadLine module..."
        Install-Module -Name PSReadLine -AllowPrerelease -Force -Scope CurrentUser
        Write-Log "PSReadLine module installed" -Level 'OK'
    }
}

# ============================================================================
# Tree-sitter CLI
# ============================================================================

function Install-TreeSitterCLI {
    if (Test-CommandExists "tree-sitter") {
        Write-Log "tree-sitter-cli is already installed" -Level 'OK'
        return
    }

    if (-not (Test-CommandExists "cargo")) {
        Write-Log "cargo not found, skipping tree-sitter-cli installation" -Level 'WARNING'
        Write-Log "Install Rust via rustup first, then run: cargo install tree-sitter-cli"
        return
    }

    Write-Log "Installing tree-sitter-cli via cargo..."
    cargo install tree-sitter-cli
    Write-Log "tree-sitter-cli installed" -Level 'OK'
}

# ============================================================================
# GnuWin32 PATH
# ============================================================================

function Install-GnuWin32Path {
    $gnuWin32Bin = "C:\Program Files (x86)\GnuWin32\bin"

    if (-not (Test-Path $gnuWin32Bin)) {
        Write-Log "GnuWin32 bin directory not found, skipping PATH setup" -Level 'WARNING'
        return
    }

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -like "*GnuWin32*") {
        Write-Log "GnuWin32 is already in PATH" -Level 'OK'
    } else {
        Write-Log "Adding GnuWin32 to user PATH..."
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$gnuWin32Bin", "User")
        $env:Path = "$env:Path;$gnuWin32Bin"
        Write-Log "GnuWin32 added to PATH" -Level 'OK'
    }
}

# ============================================================================
# Python Setup
# ============================================================================

function Install-PythonSetup {
    if (-not (Test-CommandExists "py")) {
        Write-Log "Python launcher (py) not found, skipping Python setup" -Level 'WARNING'
        return
    }

    Write-Log "Configuring Python via py launcher..."
    py install --configure
    Write-Log "Python configured" -Level 'OK'
}

# ============================================================================
# Node.js via NVM
# ============================================================================

function Install-NodeViaNVM {
    if (-not (Test-CommandExists "nvm")) {
        Write-Log "nvm not found, skipping Node.js installation" -Level 'WARNING'
        return
    }

    Write-Log "Installing latest Node.js via nvm..."
    nvm install latest
    nvm use latest
    Write-Log "Node.js installed via nvm" -Level 'OK'
}

# ============================================================================
# Registry Tweaks
# ============================================================================

function Install-RegistryTweaks {
    $regFile = Join-Path $ScriptDir "DisableRecoStartMenu.reg"

    if (-not (Test-Path $regFile)) {
        Write-Log "Registry file not found: $regFile" -Level 'WARNING'
        return
    }

    Write-Log "Applying registry tweaks (disable Start Menu recommendations)..."
    reg import $regFile 2>$null
    Write-Log "Registry tweaks applied" -Level 'OK'
}

# ============================================================================
# Main Installation Flow
# ============================================================================

function Main {
    Write-Host ""
    Write-Host "+================================================================+" -ForegroundColor Cyan
    Write-Host "|       Windows Development Environment Setup                     |" -ForegroundColor Cyan
    Write-Host "|                (Direct copy dotfiles)                            |" -ForegroundColor Cyan
    Write-Host "+================================================================+" -ForegroundColor Cyan
    Write-Host ""

    # Check if running on Windows
    if ($env:OS -ne "Windows_NT") {
        Write-Log "This script is intended for Windows only." -Level 'ERROR'
        exit 1
    }

    # Install winget packages first (needed for most other steps)
    Install-WingetPackages

    # Copy dotfiles configurations
    Install-PowerShellProfile
    Install-NeovimConfig
    Install-YaziConfig
    Install-OhMyPoshConfig
    Install-WindowsTerminalSettings
    Install-GlazeWMConfig
    Install-AHKScripts

    # Install additional tools and modules
    Install-PSReadLineModule
    Install-JetBrainsMonoFont
    Install-TreeSitterCLI
    Install-GnuWin32Path
    Install-PythonSetup
    Install-NodeViaNVM

    # Apply registry tweaks
    Install-RegistryTweaks

    Write-Host ""
    Write-Host "+================================================================+" -ForegroundColor Green
    Write-Host "|       Installation Complete!                                     |" -ForegroundColor Green
    Write-Host "+================================================================+" -ForegroundColor Green
    Write-Host ""
    Write-Log "Dotfiles have been copied to their target locations."
    Write-Log "Please restart your terminal or run '. `$PROFILE' to apply changes."
    Write-Log "You may need to restart your computer for all changes to take effect."
    Write-Host ""
}

Main
