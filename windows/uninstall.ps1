<#
.SYNOPSIS
    Windows Development Environment Uninstall Script
.DESCRIPTION
    Removes GlazeWM, Zebar configurations and startup shortcuts.
    Note: Does not uninstall packages - only removes configurations.
.PARAMETER RemoveWM
    Also remove GlazeWM and Zebar packages via winget
#>

[CmdletBinding()]
param(
    [switch]$RemoveWM
)

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
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
    param(
        [string]$Name
    )

    $startupFolder = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup"
    $shortcutPath = Join-Path $startupFolder "$Name.lnk"

    if (Test-Path $shortcutPath) {
        Remove-Item -Path $shortcutPath -Force
        Write-Log "Removed startup shortcut: $shortcutPath" -Level 'SUCCESS'
    } else {
        Write-Log "Startup shortcut not found: $shortcutPath" -Level 'WARNING'
    }
}

function Remove-Config {
    param(
        [string]$Path,
        [string]$Name
    )

    if (Test-Path $Path) {
        Remove-Item -Path $Path -Recurse -Force
        Write-Log "Removed $Name: $Path" -Level 'SUCCESS'
    } else {
        Write-Log "$Name not found: $Path" -Level 'WARNING'
    }
}

function Uninstall-Package {
    param(
        [string]$PackageId,
        [string]$PackageName
    )

    $installed = winget list --exact --id $PackageId 2>$null

    if (-not [string]::IsNullOrEmpty($installed) -and -not ($installed -match 'No installed package found')) {
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

function Main {
    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║         Windows Development Environment Uninstall              ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""

    $glazewmConfigDir = "$env:USERPROFILE\.glzr\glazewm"
    $zebarConfigDir = "$env:USERPROFILE\.glzr\zebar"
    $glazewmExePath = "$env:LOCALAPPDATA\Programs\glazewm\glazewm.exe"

    Write-Log "Removing GlazeWM configuration..." -Level 'INFO'
    Remove-Config -Path $glazewmConfigDir -Name "GlazeWM config"

    Write-Log "Removing Zebar configuration..." -Level 'INFO'
    Remove-Config -Path $zebarConfigDir -Name "Zebar config"

    Write-Log "Removing startup shortcuts..." -Level 'INFO'
    Remove-StartupShortcut -Name "GlazeWM"

    if ($RemoveWM) {
        Write-Log "" -Level 'WARNING'
        Write-Log "Removing GlazeWM package..." -Level 'WARNING'
        Uninstall-Package -PackageId "GlazeWM" -PackageName "GlazeWM"

        Write-Log "Removing Zebar package..." -Level 'WARNING'
        Uninstall-Package -PackageId "glzr-io.zebar" -PackageName "Zebar"
    }

    Write-Host ""
    Write-Host "╔════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                  Uninstall Complete! 🗑️                        ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Log "Notes:" -Level 'INFO'
    Write-Log "  - Configuration files have been removed" -Level 'INFO'
    Write-Log "  - Startup shortcuts have been removed" -Level 'INFO'
    if ($RemoveWM) {
        Write-Log "  - Packages have been uninstalled" -Level 'INFO'
    } else {
        Write-Log "  - Packages were NOT uninstalled (use -RemoveWM to remove)" -Level 'INFO'
    }
    Write-Log "  - You may need to log out and log back in for changes to take effect" -Level 'INFO'
    Write-Host ""
}

Main
