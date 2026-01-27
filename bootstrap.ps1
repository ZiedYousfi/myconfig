<#
.SYNOPSIS
    Bootstrap Script for Setup Configuration (Windows)
.DESCRIPTION
    Downloads and installs the complete development environment for Windows.
    Usage:
        irm https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.ps1 | iex
#>

$ErrorActionPreference = 'Stop'

# Repository configuration
$RepoOwner = "ZiedYousfi"
$RepoName = "myconfig"
$GithubRepo = "$RepoOwner/$RepoName"

# Installation directory
$InstallDir = Join-Path $HOME ".setup-config"
$TempDir = Join-Path $env:TEMP "setup-config-$pid"

# Colors
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
    switch ($Level) {
        'SUCCESS' { Write-Host "[OK] $Message" -ForegroundColor $Colors.Success }
        'WARNING' { Write-Host "[WARNING] $Message" -ForegroundColor $Colors.Warning }
        'ERROR'   { Write-Host "[FAIL] $Message" -ForegroundColor $Colors.Error }
        default    { Write-Host "[INFO] $Message" -ForegroundColor $Colors.Info }
    }
}

function Print-Banner {
    Write-Host @"
+-----------------------------------------------------------+
|                                                           |
|        Setup Configuration Bootstrap Script               |
|                                                           |
|        Automated Development Environment Setup            |
|                                                           |
+-----------------------------------------------------------+
"@ -ForegroundColor Cyan
}

function Get-LatestReleaseTag {
    Write-Log "Fetching latest release information..."
    $url = "https://api.github.com/repos/$GithubRepo/releases/latest"
    try {
        $release = Invoke-RestMethod -Uri $url -ErrorAction Stop
        return $release.tag_name
    } catch {
        Write-Log "No releases found or network error, will download from main branch." -Level 'WARNING'
        return "main"
    }
}

function Download-And-Extract {
    param([string]$Tag)

    if (!(Test-Path $TempDir)) {
        New-Item -ItemType Directory -Path $TempDir | Out-Null
    }

    $zipPath = Join-Path $TempDir "setup-config.zip"

    if ($Tag -eq "main") {
        Write-Log "Downloading repository from main branch..."
        $url = "https://github.com/$GithubRepo/archive/refs/heads/main.zip"
    } else {
        Write-Log "Downloading release $Tag..."
        $url = "https://github.com/$GithubRepo/releases/download/$Tag/setup-config.zip"
        # Fallback to source code zip if asset not found
        try {
            $response = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing -ErrorAction Stop
        } catch {
            Write-Log "Release asset not found, downloading from source archive..." -Level 'WARNING'
            $url = "https://github.com/$GithubRepo/archive/refs/tags/$Tag.zip"
        }
    }

    try {
        Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing
        Write-Log "Downloaded successfully" -Level 'SUCCESS'
    } catch {
        Write-Log "Failed to download from $url" -Level 'ERROR'
        exit 1
    }

    Write-Log "Extracting archive..."
    try {
        Expand-Archive -Path $zipPath -DestinationPath $TempDir -Force
        Remove-Item $zipPath
    } catch {
        Write-Log "Failed to extract archive" -Level 'ERROR'
        exit 1
    }

    # Find the source directory (GitHub zips usually have a root folder)
    $extractedDirs = Get-ChildItem -Path $TempDir -Directory
    if ($extractedDirs.Count -eq 1) {
        return $extractedDirs[0].FullName
    }

    return $TempDir
}

function Run-Installation {
    param(
        [string]$SourceDir
    )

    Write-Log "Preparing installation directory..."
    Write-Log "Source directory: $SourceDir"

    # Backup existing installation
    if (Test-Path $InstallDir) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDir = "${InstallDir}.backup.$timestamp"
        Write-Log "Backing up existing installation to $backupDir" -Level 'WARNING'
        Rename-Item -Path $InstallDir -NewName (Split-Path $backupDir -Leaf)
    }

    # Create installation directory and copy files
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Copy-Item -Path "$SourceDir\*" -Destination $InstallDir -Recurse -Force

    # Verify copy
    if (!(Test-Path (Join-Path $InstallDir "windows\install.ps1"))) {
        Write-Log "File copy failed or source directory was incomplete. Check $InstallDir" -Level 'ERROR'
        exit 1
    }

    Write-Log "Files copied to $InstallDir" -Level 'SUCCESS'

    # Run the Windows installation script
    Write-Log "Starting Windows installation..."
    Write-Host ""

    $installScript = Join-Path $InstallDir "windows\install.ps1"
    Set-Location (Join-Path $InstallDir "windows")
    & $installScript
}

function Cleanup {
    Write-Log "Cleaning up temporary files..."
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
    Write-Log "Cleanup complete" -Level 'SUCCESS'
}

function Main {
    Print-Banner

    $tag = Get-LatestReleaseTag
    $extractedDir = Download-And-Extract -Tag $tag

    try {
        Run-Installation -SourceDir $extractedDir
    } finally {
        Cleanup
    }

    Write-Host ""
    Write-Log "Installation complete!" -Level 'SUCCESS'
    Write-Log "Configuration installed to: $InstallDir"
    Write-Host ""
    Write-Log "Windows setup complete!"
    Write-Log "GlazeWM and Zebar will start on your next login."
    Write-Log "WSL Ubuntu setup will run automatically if installed."
    Write-Log "Please restart your computer for all changes to take effect."
    Write-Host ""
}

# Run main function
Main
