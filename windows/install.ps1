<#
.SYNOPSIS
    Windows Development Environment Setup Script
.DESCRIPTION
    Installs GlazeWM, Zebar, and configures Windows development environment.
    Part 1: Setup GlazeWM and Zebar
    Part 2: Check for WSL Ubuntu and run setup if installed
.PARAMETER SkipWM
    Skip window manager (GlazeWM/Zybar) installation
.PARAMETER SkipWSL
    Skip WSL Ubuntu setup check
#>

[CmdletBinding()]
param(
    [switch]$SkipWM,
    [switch]$SkipWSL
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = Split-Path -Parent $ScriptDir
$SharedDotfilesDir = "$RepoRoot\dotfiles"
$WindowsDotfilesDir = "$ScriptDir\dotfiles"

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
        default    { Write-Host $logEntry -ForegroundColor $Colors.Info }
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

function Test-GlazeWMInstalled {
    try {
        $result = winget list --id GlazeWM --exact 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Test-ZebarInstalled {
    try {
        $result = winget list --id glzr-io.zebar --exact 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

function Install-WingetPackageSafe {
    param(
        [string]$Package,
        [string]$PackageId
    )

    $installed = winget list --exact --id $PackageId 2>$null
    if (-not [string]::IsNullOrEmpty($installed) -and -not ($installed -match 'No installed package found')) {
        Write-Log "$Package is already installed" -Level 'INFO'
        return
    }

    Write-Log "Installing $Package..." -Level 'INFO'
    winget install --id $PackageId --accept-source-agreements --accept-package-agreements -e

    if ($LASTEXITCODE -eq 0) {
        Write-Log "$Package installed successfully" -Level 'SUCCESS'
    } else {
        Write-Log "Failed to install $Package (exit code: $LASTEXITCODE)" -Level 'ERROR'
        exit 1
    }
}

function Set-StartupShortcut {
    param(
        [string]$Name,
        [string]$TargetPath,
        [string]$Arguments = ""
    )

    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupFolder "$Name.lnk"

    # Always recreate shortcut to ensure it points to the correct path
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

    Write-Log "Created startup shortcut: $shortcutPath" -Level 'SUCCESS'
}

function Copy-DotfileConfig {
    param(
        [string]$SourceDir,
        [string]$TargetDir,
        [string]$ConfigName
    )

    $sourceConfig = Join-Path $SourceDir $ConfigName
    $targetDir = Split-Path $TargetDir

    if (-not (Test-Path $sourceConfig)) {
        Write-Log "Source config not found: $sourceConfig" -Level 'WARNING'
        return
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Log "Created directory: $targetDir" -Level 'INFO'
    }

    $targetConfig = Join-Path $targetDir $ConfigName

    Copy-Item -Path $sourceConfig -Destination $targetConfig -Force
    Write-Log "Copied $ConfigName to: $targetConfig" -Level 'SUCCESS'
}

function Test-WSLUbuntuInstalled {
    $env:WSL_UTF8 = 1
    $distros = wsl --list --verbose 2>$null

    if ($distros -match [regex]::Escape('Ubuntu')) {
        return $true
    }

    return $false
}

function Install-WindowsWM {
    Write-Log "=== Part 1: Windows Window Manager Setup ===" -Level 'INFO'
    Write-Log ""

    $isAdmin = Test-Administrator
    if (-not $isAdmin) {
        Write-Log "This script requires administrator privileges for some operations." -Level 'WARNING'
        Write-Log "Running without admin - some features may not work correctly." -Level 'WARNING'
    }

    Write-Log "[1/2] Installing GlazeWM..." -Level 'INFO'
    Install-WingetPackageSafe -Package "GlazeWM" -PackageId "GlazeWM"

    Write-Log "[2/2] Installing Zebar..." -Level 'INFO'
    Install-WingetPackageSafe -Package "Zebar" -PackageId "glzr-io.zebar"

    Write-Log ""
    Write-Log "Configuring GlazeWM and Zebar..." -Level 'INFO'

    $glazewmConfigDir = "$env:USERPROFILE\.glzr\glazewm"
    $zebarConfigDir = "$env:USERPROFILE\.glzr\zebar"

    if (-not (Test-Path $glazewmConfigDir)) {
        New-Item -ItemType Directory -Path $glazewmConfigDir -Force | Out-Null
        Write-Log "Created GlazeWM config directory: $glazewmConfigDir" -Level 'INFO'
    }

    if (-not (Test-Path $zebarConfigDir)) {
        New-Item -ItemType Directory -Path $zebarConfigDir -Force | Out-Null
        Write-Log "Created Zebar config directory: $zebarConfigDir" -Level 'INFO'
    }

    Copy-DotfileConfig -SourceDir $WindowsDotfilesDir\glazewm -TargetDir $glazewmConfigDir -ConfigName "config.yaml"

    Copy-Item -Path "$WindowsDotfilesDir\zebar\*" -Destination $zebarConfigDir -Recurse -Force
    Write-Log "Copied Zebar widgets to: $zebarConfigDir" -Level 'SUCCESS'

    Write-Log ""
    Write-Log "Setting up startup shortcuts..." -Level 'INFO'

    # 1. GlazeWM
    $glazewmExePath = ""
    if (Test-Command "glazewm") {
        $glazewmExePath = (Get-Command glazewm).Source
    }

    if (-not $glazewmExePath -or -not (Test-Path $glazewmExePath)) {
        $paths = @(
            "$env:LOCALAPPDATA\Programs\glazewm\glazewm.exe",
            "$env:ProgramFiles\glazewm\glazewm.exe"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) { $glazewmExePath = $p; break }
        }
    }

    if ($glazewmExePath -and (Test-Path $glazewmExePath)) {
        Set-StartupShortcut -Name "GlazeWM" -TargetPath $glazewmExePath
    } else {
        Write-Log "GlazeWM executable not found. Please ensure it is installed." -Level 'WARNING'
    }

    # 2. Zebar
    $zebarExePath = ""
    if (Test-Command "zebar") {
        $zebarExePath = (Get-Command zebar).Source
    }

    if (-not $zebarExePath -or -not (Test-Path $zebarExePath)) {
        $paths = @(
            "$env:LOCALAPPDATA\Programs\zebar\zebar.exe",
            "$env:ProgramFiles\zebar\zebar.exe"
        )
        foreach ($p in $paths) {
            if (Test-Path $p) { $zebarExePath = $p; break }
        }
    }

    if ($zebarExePath -and (Test-Path $zebarExePath)) {
        Set-StartupShortcut -Name "Zebar" -TargetPath $zebarExePath
    } else {
        Write-Log "Zebar executable not found. Please ensure it is installed." -Level 'WARNING'
    }

    Write-Log ""
    Write-Log "Windows Window Manager setup complete!" -Level 'SUCCESS'
    Write-Log ""
}

function Install-WSLUbuntu {
    Write-Log "=== Part 2: WSL Ubuntu Setup ===" -Level 'INFO'
    Write-Log ""

    Write-Log "Checking for WSL Ubuntu..." -Level 'INFO'

    $ubuntuInstalled = Test-WSLUbuntuInstalled

    if (-not $ubuntuInstalled) {
        Write-Log "" -Level 'ERROR'
        Write-Log "WSL Ubuntu is not installed." -Level 'ERROR'
        Write-Log "" -Level 'ERROR'
        Write-Log "Please install WSL Ubuntu first:" -Level 'WARNING'
        Write-Log "  1. Open PowerShell as Administrator" -Level 'INFO'
        Write-Log "  2. Run: wsl --install -d Ubuntu" -Level 'INFO'
        Write-Log "  3. Restart your computer" -Level 'INFO'
        Write-Log "  4. Run this script again after installation" -Level 'INFO'
        Write-Log "" -Level 'ERROR'
        exit 1
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
    Write-Host "|          (GlazeWM + Zebar + WSL)                             |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    if (-not (Test-Command 'winget')) {
        Write-Log "winget is not installed or not in PATH" -Level 'ERROR'
        Write-Log "Please install winget or ensure it's in your PATH" -Level 'ERROR'
        exit 1
    }

    if (-not $SkipWM) {
        Install-WindowsWM
    }

    if (-not $SkipWSL) {
        Install-WSLUbuntu
    }

    Write-Host ""
    Write-Host "+---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host "|                  Installation Complete!                       |" -ForegroundColor Green
    Write-Host "+---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
    Write-Log "Next steps:" -Level 'INFO'
    Write-Log "  1. Log out and log back in to start GlazeWM" -Level 'INFO'
    Write-Log "  2. Open WSL Ubuntu for Linux development tools" -Level 'INFO'
    Write-Log "  3. Use VS Code with WSL extension for development" -Level 'INFO'
    Write-Host ""
}

Main
