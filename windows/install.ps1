# Windows Development Environment Setup Script
# This script is idempotent - running it multiple times is safe
# Dotfiles are copied directly to their target locations (no stow on Windows)
# Keep the script readable for future maintenance and review.

# $ErrorActionPreference = 'Stop' (Disabled to ensure script continues even if some packages fail)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SharedDotfilesDir = Join-Path $RepoRoot "dotfiles"
$WindowsDotfilesDir = Join-Path $ScriptDir "dotfiles"

# Colors
# Centralize output colors so log messages stay consistent.
$Colors = @{
  Info    = 'Cyan'
  Success = 'Green'
  Warning = 'Yellow'
  Error   = 'Red'
}

function Write-Log
{
  param(
    [string]$Message,
    [ValidateSet('INFO', 'OK', 'WARNING', 'ERROR')][string]$Level = 'INFO'
  )
  switch ($Level)
  {
    'OK'
    { Write-Host "[OK] $Message" -ForegroundColor $Colors.Success 
    }
    'WARNING'
    { Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Warning 
    }
    'ERROR'
    { Write-Host "[ERROR] $Message" -ForegroundColor $Colors.Error 
    }
    default
    { Write-Host "[INFO] $Message" -ForegroundColor $Colors.Info 
    }
  }
}

# ============================================================================
# Helper Functions
# ============================================================================

function Test-CommandExists
{
  param([string]$Command)
  return [bool](Get-Command $Command -ErrorAction SilentlyContinue)
}

function Copy-DotfileSafe
{
  # Copy a file or directory after ensuring the destination tree exists.
  param(
    [string]$Source,
    [string]$Destination,
    [switch]$Recurse
  )

  if (-not (Test-Path $Source))
  {
    Write-Log "Source not found: $Source" -Level 'WARNING'
    return
  }

  $destDir = if ($Recurse)
  { $Destination
  } else
  { Split-Path -Parent $Destination
  }

  if ([string]::IsNullOrWhiteSpace($destDir))
  {
    Write-Log "Destination directory could not be determined for $Destination" -Level 'ERROR'
    return
  }

  try
  {
    New-Item -ItemType Directory -Path $destDir -Force -ErrorAction Stop | Out-Null
  } catch
  {
    Write-Log "Failed to create destination directory ${destDir}: $($_.Exception.Message)" -Level 'ERROR'
    return
  }

  try
  {
    if ($Recurse)
    {
      Copy-Item -Path "$Source\*" -Destination $Destination -Recurse -Force -ErrorAction Stop
    } else
    {
      Copy-Item -Path $Source -Destination $Destination -Force -ErrorAction Stop
    }
    Write-Log "Copied $Source -> $Destination" -Level 'OK'
  } catch
  {
    Write-Log "Failed to copy $Source -> ${Destination}: $($_.Exception.Message)" -Level 'ERROR'
  }
}

# ============================================================================
# Winget Packages Installation
# ============================================================================

function Install-WingetPackages
{
  if (-not (Test-CommandExists "winget"))
  {
    Write-Log "winget not found. Please install App Installer from the Microsoft Store." -Level 'ERROR'
    return
  }

  $packagesJson = Join-Path $WindowsDotfilesDir "winget\packages.json"
  if (-not (Test-Path $packagesJson))
  {
    Write-Log "Winget packages file not found: $packagesJson" -Level 'ERROR'
    return
  }

  Write-Log "Installing winget packages from $packagesJson..."
  winget import -i $packagesJson --accept-source-agreements --accept-package-agreements --ignore-unavailable
  Write-Log "Winget packages installed" -Level 'OK'
}

# ============================================================================
# PowerShell Profile
# ============================================================================

function Install-PowerShellProfile
{
  # Install the profile early so the next shell session picks up prompt changes.
  $source = Join-Path $WindowsDotfilesDir "PowerShell\Microsoft.PowerShell_profile.ps1"
  $destination = $PROFILE

  if (-not (Test-Path $source))
  {
    Write-Log "PowerShell profile source not found: $source" -Level 'ERROR'
    return
  }

  # Backup existing profile if it exists and does not look like one we created.
  if ((Test-Path $destination) -and -not (Select-String -Path $destination -Pattern "Oh My Posh" -Quiet -ErrorAction SilentlyContinue))
  {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = "$destination.backup.$timestamp"
    Copy-Item -Path $destination -Destination $backup -Force
    Write-Log "Backed up existing profile to $backup"
  }

  Copy-DotfileSafe -Source $source -Destination $destination
  # Remove the downloaded-file marker from the installed profile.
  Unblock-File -Path $destination
  Write-Log "PowerShell profile installed" -Level 'OK'
}

# ============================================================================
# Neovim Configuration
# ============================================================================

function Install-NeovimConfig
{
  $source = Join-Path $SharedDotfilesDir "nvim\.config\nvim"
  $destination = Join-Path $env:LOCALAPPDATA "nvim"

  if (-not (Test-Path $source))
  {
    Write-Log "Neovim config source not found: $source" -Level 'ERROR'
    return
  }

  if ((Test-Path $destination) -and (Test-Path (Join-Path $destination "lua\config\lazy.lua")))
  {
    Write-Log "Neovim configuration is already installed" -Level 'OK'
  } else
  {
    Write-Log "Installing Neovim configuration..."
  }

  Copy-DotfileSafe -Source $source -Destination $destination -Recurse
  [Environment]::SetEnvironmentVariable("EDITOR", "nvim", "User")
  Write-Log "Neovim configuration installed" -Level 'OK'
}

# ============================================================================
# Yazi Configuration
# ============================================================================

function Install-YaziConfig
{
  $source = Join-Path $SharedDotfilesDir "yazi\.config\yazi"
  $destination = Join-Path $env:APPDATA "yazi"

  if (-not (Test-Path $source))
  {
    Write-Log "Yazi config source not found: $source" -Level 'ERROR'
    return
  }

  Copy-DotfileSafe -Source $source -Destination $destination -Recurse
  [Environment]::SetEnvironmentVariable(
    "YAZI_FILE_ONE",
    "C:\Program Files\Git\usr\bin\file.exe",
    "User"
  )
  Write-Log "Yazi configuration installed" -Level 'OK'
}

# ============================================================================
# Lazygit Configuration
# ============================================================================

function Install-LazygitConfig
{
  $source = Join-Path $SharedDotfilesDir "lazygit\.config\lazygit\config.yml"
  $destination = Join-Path $env:LOCALAPPDATA "lazygit\config.yml"

  if (-not (Test-Path $source))
  {
    Write-Log "Lazygit config source not found: $source" -Level 'ERROR'
    return
  }

  if (Test-Path $destination)
  {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = "$destination.backup.$timestamp"
    Copy-Item -Path $destination -Destination $backup -Force
    Write-Log "Backed up existing Lazygit config to $backup"
  }

  Copy-DotfileSafe -Source $source -Destination $destination
  Write-Log "Lazygit configuration installed" -Level 'OK'
}

# ============================================================================
# Oh My Posh Configuration
# ============================================================================

function Install-OhMyPoshConfig
{
  $source = Join-Path $WindowsDotfilesDir ".OhMyPosh"
  $destination = Join-Path $env:USERPROFILE ".OhMyPosh"

  if (-not (Test-Path $source))
  {
    Write-Log "Oh My Posh config source not found: $source" -Level 'ERROR'
    return
  }

  Copy-DotfileSafe -Source $source -Destination $destination -Recurse
  Write-Log "Oh My Posh configuration installed" -Level 'OK'
}

# ============================================================================
# Iosevka Mono Font
# ============================================================================

function Install-IosevkaMonoFont
{
  if (-not (Test-CommandExists "oh-my-posh"))
  {
    Write-Log "oh-my-posh not found, skipping font installation" -Level 'WARNING'
    return
  }

  Write-Log "Installing Iosevka Mono font..."
  oh-my-posh font install Iosevka
  Write-Log "Iosevka Mono font installed" -Level 'OK'
}

# ============================================================================
# WezTerm Configuration
# ============================================================================

function Install-WezTermConfig
{
  $source = Join-Path $SharedDotfilesDir "wezterm\.wezterm.lua"
  $destination = Join-Path $env:USERPROFILE ".wezterm.lua"

  if (-not (Test-Path $source))
  {
    Write-Log "WezTerm config source not found: $source" -Level 'ERROR'
    return
  }

  # Backup existing config
  if (Test-Path $destination)
  {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backup = "$destination.backup.$timestamp"
    Copy-Item -Path $destination -Destination $backup -Force
    Write-Log "Backed up existing WezTerm config to $backup"
  }

  Copy-DotfileSafe -Source $source -Destination $destination
  Write-Log "WezTerm configuration installed" -Level 'OK'
}

# ============================================================================
# Komorebi and YASB Configuration
# ============================================================================

function Install-KomorebiConfig
{
  # Komorebi config lives under the user profile config tree on Windows.
  $komorebiSource = Join-Path $WindowsDotfilesDir ".config\komorebi"
  $komorebiDest = Join-Path $env:USERPROFILE ".config\komorebi"

  if (-not (Test-Path $komorebiSource))
  {
    Write-Log "Komorebi config source not found: $komorebiSource" -Level 'ERROR'
  } else
  {
    Copy-DotfileSafe -Source $komorebiSource -Destination $komorebiDest -Recurse
    Write-Log "Komorebi configuration installed" -Level 'OK'
  }

  # YASB config follows the same user-scoped config layout.
  $yasbSource = Join-Path $WindowsDotfilesDir ".config\yasb"
  $yasbDest = Join-Path $env:USERPROFILE ".config\yasb"

  if (-not (Test-Path $yasbSource))
  {
    Write-Log "YASB config source not found: $yasbSource" -Level 'ERROR'
  } else
  {
    Copy-DotfileSafe -Source $yasbSource -Destination $yasbDest -Recurse
    Write-Log "YASB configuration installed" -Level 'OK'
  }

  [Environment]::SetEnvironmentVariable("KOMOREBI_CONFIG_HOME", "$Env:USERPROFILE\.config\komorebi", "User")
  komorebic enable-autostart
  yasbc enable-autostart
}

# ============================================================================
# AutoHotkey Scripts
# ============================================================================

function Install-AHKScripts
{
  $source = Join-Path $WindowsDotfilesDir "AutoHotkey"
  $destination = Join-Path $env:USERPROFILE "AutoHotkey"

  if (-not (Test-Path $source))
  {
    Write-Log "AHK scripts source not found: $source" -Level 'ERROR'
    return
  }

  Copy-DotfileSafe -Source $source -Destination $destination -Recurse
  Write-Log "AutoHotkey scripts installed" -Level 'OK'
}

# ============================================================================
# PSReadLine Module
# ============================================================================

function Install-PSReadLineModule
{
  if (Get-Module -ListAvailable -Name PSReadLine)
  {
    Write-Log "PSReadLine module is already installed" -Level 'OK'
  } else
  {
    Write-Log "Installing PSReadLine module..."
    Install-Module -Name PSReadLine -AllowPrerelease -Force -Scope CurrentUser
    Write-Log "PSReadLine module installed" -Level 'OK'
  }
}

# ============================================================================
# GnuWin32 PATH
# ============================================================================

function Install-GnuWin32Path
{
  $gnuWin32Bin = "C:\Program Files (x86)\GnuWin32\bin"

  if (-not (Test-Path $gnuWin32Bin))
  {
    Write-Log "GnuWin32 bin directory not found, skipping PATH setup" -Level 'WARNING'
    return
  }

  $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($currentPath -like "*GnuWin32*")
  {
    Write-Log "GnuWin32 is already in PATH" -Level 'OK'
  } else
  {
    Write-Log "Adding GnuWin32 to user PATH..."
    [Environment]::SetEnvironmentVariable("Path", "$currentPath;$gnuWin32Bin", "User")
    $env:Path = "$env:Path;$gnuWin32Bin"
    Write-Log "GnuWin32 added to PATH" -Level 'OK'
  }
}

# ============================================================================
# LLVM Path 
# ===========================================================================

function Install-LLVMPath
{
  $llvmBin = "C:\Program Files\LLVM\bin"

  if (-not (Test-Path $llvmBin))
  {
    Write-Log "LLVM bin directory not found, skipping PATH setup" -Level 'WARNING'
    return
  }

  $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
  if ($currentPath -like "*LLVM*")
  {
    Write-Log "LLVM is already in PATH" -Level 'OK'
  } else
  {
    Write-Log "Adding LLVM to user PATH..."
    [Environment]::SetEnvironmentVariable(
      "Path",
      [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\Program Files\LLVM\bin",
      "Machine"
    )
    Write-Log "LLVM added to PATH" -Level 'OK'
  }
}

# ============================================================================
# Python Setup
# ============================================================================

function Install-PythonSetup
{
  if (-not (Test-CommandExists "py"))
  {
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

function Install-NodeViaNVM
{
  if (-not (Test-CommandExists "nvm"))
  {
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

function Install-RegistryTweaks
{
  # Apply the Start menu policy tweak from a checked-in .reg file when present.
  $regFile = Join-Path $ScriptDir "DisableRecoStartMenu.reg"

  if (-not (Test-Path $regFile))
  {
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

function Main
{
  Write-Host ""
  Write-Host "+================================================================+" -ForegroundColor Cyan
  Write-Host "|       Windows Development Environment Setup                     |" -ForegroundColor Cyan
  Write-Host "|                (Direct copy dotfiles)                            |" -ForegroundColor Cyan
  Write-Host "+================================================================+" -ForegroundColor Cyan
  Write-Host ""

  # Check if running on Windows
  if ($env:OS -ne "Windows_NT")
  {
    Write-Log "This script is intended for Windows only." -Level 'ERROR'
    exit 1
  }

  # Install winget packages first because later steps depend on them.
  Install-WingetPackages

  # Copy the core configuration files and directories.
  Install-PowerShellProfile
  Install-NeovimConfig
  Install-YaziConfig
  Install-LazygitConfig
  Install-OhMyPoshConfig
  Install-WezTermConfig
  Install-KomorebiConfig
  Install-AHKScripts

  # Install the supporting tools and modules that the dotfiles expect.
  Install-PSReadLineModule
  Install-IosevkaMonoFont
  Install-GnuWin32Path
  Install-LLVMPath
  Install-PythonSetup
  Install-NodeViaNVM

  # Apply the Windows shell and Start menu tweaks last.
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
