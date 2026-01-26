<#
.SYNOPSIS
    Windows Development Environment Uninstall Script
.DESCRIPTION
    Removes configurations and optionally packages installed by install.ps1:
    - Oh My Posh configuration and PowerShell profile
    - Windows Terminal settings
    - GlazeWM and Zebar configurations
    - Startup shortcuts
.PARAMETER RemovePackages
    Also remove installed packages via winget (OhMyPosh, GlazeWM, Zebar)
.PARAMETER RemoveProfile
    Remove PowerShell profile
.PARAMETER RemoveTerminalSettings
    Remove Windows Terminal settings
#>

[CmdletBinding()]
param(
    [switch]$RemovePackages,
    [switch]$RemoveProfile,
    [switch]$RemoveTerminalSettings
)

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

function Remove-StartupShortcut {
    param([string]$Name)

    $startupFolder = Join-Path $env:APPDATA "Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupFolder "$Name.lnk"

    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
        Write-Log "Removed startup shortcut: $Name" -Level 'SUCCESS'
    } else {
        Write-Log "Startup shortcut not found: $Name" -Level 'INFO'
    }
}

function Uninstall-Package {
    param(
        [string]$PackageId,
        [string]$PackageName
    )

    $installed = winget list --exact --id $PackageId 2>$null

    if ($installed -and -not ($installed -match 'No installed package found')) {
        Write-Log "Uninstalling $PackageName..." -Level 'INFO'
        winget uninstall --id $PackageId --accept-source-agreements -e

        if ($LASTEXITCODE -eq 0) {
            Write-Log "$PackageName uninstalled successfully" -Level 'SUCCESS'
        } else {
            Write-Log "Failed to uninstall $PackageName (exit code: $LASTEXITCODE)" -Level 'ERROR'
        }
    } else {
        Write-Log "$PackageName is not installed" -Level 'INFO'
    }
}

function Remove-SafePath {
    param(
        [string]$Path,
        [string]$Description
    )

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Removed $Description" -Level 'SUCCESS'
    } else {
        Write-Log "$Description not found (already removed)" -Level 'INFO'
    }
}

function Main {
    Write-Host ""
    Write-Host "+--------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host "|       Windows Development Environment Uninstall              |" -ForegroundColor Cyan
    Write-Host "+--------------------------------------------------------------+" -ForegroundColor Cyan
    Write-Host ""

    # Remove startup shortcuts
    Write-Log "Removing startup shortcuts..." -Level 'INFO'
    Remove-StartupShortcut -Name "GlazeWM"
    Remove-StartupShortcut -Name "Zebar"

    # Remove Oh My Posh configuration
    Write-Log "Removing Oh My Posh configuration..." -Level 'INFO'
    $ohMyPoshDir = Join-Path $env:USERPROFILE ".OhMyPosh"
    Remove-SafePath -Path $ohMyPoshDir -Description "Oh My Posh config directory"

    # Remove GlazeWM and Zebar configuration
    Write-Log "Removing GlazeWM and Zebar configuration..." -Level 'INFO'
    $glzrDir = Join-Path $env:USERPROFILE ".glzr"
    Remove-SafePath -Path $glzrDir -Description "GlazeWM/Zebar config directory"

    # Remove PowerShell profile if requested
    if ($RemoveProfile) {
        Write-Log "Removing PowerShell profile..." -Level 'INFO'
        if (Test-Path $PROFILE) {
            Remove-Item -Path $PROFILE -Force
            Write-Log "PowerShell profile removed: $PROFILE" -Level 'SUCCESS'
        } else {
            Write-Log "PowerShell profile not found" -Level 'INFO'
        }
    }

    # Remove Windows Terminal settings if requested
    if ($RemoveTerminalSettings) {
        Write-Log "Removing Windows Terminal settings..." -Level 'INFO'
        $terminalPaths = @(
            (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"),
            (Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json")
        )
        foreach ($path in $terminalPaths) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Force
                Write-Log "Removed Windows Terminal settings: $path" -Level 'SUCCESS'
            }
        }
    }

    # Remove packages if requested
    if ($RemovePackages) {
        Write-Log "" -Level 'INFO'
        Write-Log "Removing packages..." -Level 'WARNING'

        Uninstall-Package -PackageId "JanDeDobbeleer.OhMyPosh" -PackageName "Oh My Posh"
        Uninstall-Package -PackageId "glzr-io.glazewm" -PackageName "GlazeWM"
        Uninstall-Package -PackageId "glzr-io.zebar" -PackageName "Zebar"
    }

    Write-Host ""
    Write-Host "+---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host "|                  Uninstall Complete!                          |" -ForegroundColor Green
    Write-Host "+---------------------------------------------------------------+" -ForegroundColor Green
    Write-Host ""
    Write-Log "What was removed:" -Level 'INFO'
    Write-Log "  - Startup shortcuts (GlazeWM, Zebar)" -Level 'INFO'
    Write-Log "  - Oh My Posh configuration (~/.OhMyPosh)" -Level 'INFO'
    Write-Log "  - GlazeWM/Zebar configuration (~/.glzr)" -Level 'INFO'
    if ($RemoveProfile) {
        Write-Log "  - PowerShell profile" -Level 'INFO'
    }
    if ($RemoveTerminalSettings) {
        Write-Log "  - Windows Terminal settings" -Level 'INFO'
    }
    if ($RemovePackages) {
        Write-Log "  - Packages (OhMyPosh, GlazeWM, Zebar)" -Level 'INFO'
    } else {
        Write-Log "" -Level 'INFO'
        Write-Log "Note: Packages were NOT uninstalled. Use -RemovePackages to remove them." -Level 'INFO'
    }
    if (-not $RemoveProfile) {
        Write-Log "Note: PowerShell profile was NOT removed. Use -RemoveProfile to remove it." -Level 'INFO'
    }
    Write-Host ""
}

Main
