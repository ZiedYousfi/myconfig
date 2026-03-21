# --- Oh My Posh (prompt theme) ---
$ohMyPoshConfig = Join-Path $env:USERPROFILE ".OhMyPosh\black-pink.omp.json"
if (Test-Path $ohMyPoshConfig)
{
  oh-my-posh init pwsh --config $ohMyPoshConfig | Invoke-Expression
}

# --- Terminal-Icons ---
if (Get-Module -ListAvailable -Name Terminal-Icons)
{
  Import-Module Terminal-Icons
}

# --- PSReadLine (Vi mode + inline autosuggest) ---
if (Get-Module -ListAvailable -Name PSReadLine)
{
  Import-Module PSReadLine

  Set-PSReadLineOption -EditMode Vi
  Set-PSReadLineOption -PredictionSource History
  Set-PSReadLineOption -PredictionViewStyle InlineView
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

  try
  {
    Set-PSReadLineOption -ViModeIndicator Script
    Set-PSReadLineOption -ViModeChangeHandler {
      param($mode)
      switch ($mode)
      {
        "Insert"
        { Write-Host -NoNewline "$([char]0x1b)[5 q" 
        }  # beam
        "Command"
        { Write-Host -NoNewline "$([char]0x1b)[1 q" 
        }  # block
        default
        { Write-Host -NoNewline "$([char]0x1b)[5 q" 
        }
      }
    }
  } catch
  {
    # PSReadLine version doesn't support ViModeChangeHandler
  }
}

Set-Alias -Name lg -Value lazygit
Set-Alias -Name oc -Value opencode
Set-Alias -Name vim -Value nvim
Set-Alias -Name vi -Value nvim
Set-Alias -Name v -Value nvim
Set-Alias -Name grep -Value rg
Set-Alias -Name which -Value gcm

function y
{
  $tmp = (New-TemporaryFile).FullName
  yazi.exe $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8
  if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container))
  {
    Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
  }
  Remove-Item -Path $tmp
}

function msvcenv
{
  $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

  if (Test-Path $vsWhere)
  {
    $installPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null

    if ($installPath)
    {
      $launchScript = Join-Path $installPath "Common7\Tools\Launch-VsDevShell.ps1"
      if (Test-Path $launchScript)
      {
        & $launchScript
        Write-Host "✅ MSVC environment loaded" -ForegroundColor Green
        return
      }
    }
  }

  $fallbackPaths = @(
    "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1"
    "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\Launch-VsDevShell.ps1"
    "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\Launch-VsDevShell.ps1"
    "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\Launch-VsDevShell.ps1"
  )

  foreach ($path in $fallbackPaths)
  {
    if (Test-Path $path)
    {
      & $path
      Write-Host "✅ MSVC environment loaded from fallback path" -ForegroundColor Green
      return
    }
  }

  Write-Host "❌ MSVC environment not found. Please ensure Visual Studio with C++ tools is installed." -ForegroundColor Red
}

function aic
{
  param(
    [string]$Model = "github-copilot/gpt-4.1"
  )

  $gitLog = git log --oneline -10
  $diffStat = git diff --cached --stat
  $diff = git diff --cached

  $hasStagedChanges = $null -ne $diffStat -and $diffStat -ne ""

  $stagedNote = if ($hasStagedChanges)
  {
    "There ARE staged changes. Commit ONLY the staged changes."
  } else
  {
    "There are NO staged changes. You must stage everything with 'git add -A' first, then commit."
  }

  $context = @"
Here is the context you need to write the commit message:

CONSIDER \n AS GIT MALFORMED COMMIT MESSAGES. DO NOT REPEAT THEIR MISTAKES. DO PROPER NEWLINES.

## Last 10 commits (for style/convention reference):
$gitLog

## Staged diff stat:
$(if ($diffStat) { $diffStat } else { "(none)" })

## Full staged diff:
$(if ($diff) { $diff } else { "(none)" })

---

Based on this context:
- $stagedNote
- Write a comprehensive and descriptive commit message following the style observed above.
- YOU HAVE TO commit using 'git commit -m "<message>"'.
- Do NOT push to remote under any circumstances.

And remember child: Why use a lot of words when few words do trick... Keep that in mind when writing the commit message. Be concise.
"@

  opencode run $context -m $Model
}

function update
{
  winget upgrade -r --include-unknown --accept-package-agreements --accept-source-agreements
}

function su
{
  $currentDir = (Get-Location).Path

  $wtArgs = @(
    "new-tab",
    "-p", "PowerShell",
    "-d", $currentDir,
    "pwsh",
    "-NoExit"
  )

  Start-Process -FilePath "wt.exe" -Verb RunAs -ArgumentList $wtArgs
}

function ..
{
  param (
    [int]$levels = 1
  )
  
  if ($levels -lt 1)
  {
    Write-Host "Please provide a positive integer for the number of levels to go up." -ForegroundColor Red
    return
  }

  $targetPath = (Get-Location).Path
  for ($i = 0; $i -lt $levels; $i++)
  {
    $targetPath = Split-Path -Path $targetPath -Parent
  }
  
  Set-Location -Path $targetPath
}

function repair-winget
{
  Install-Module microsoft.winget.client -Force -AllowClobber
  Import-Module microsoft.winget.client
  Repair-WinGetPackageManager -Force -Latest

  # Uninstalls and reinstalls selected winget-sourced packages to recreate symlinks in WinGet\Links

  # Auto-elevate to administrator if not already running as admin
  if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
  {
    Write-Host "Not running as administrator. Relaunching elevated..." -ForegroundColor Yellow
    Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
  }

  Write-Host "`nFetching installed packages..." -ForegroundColor Cyan

  $rawOutput = winget list | Out-String -Width 5000
  $lines = $rawOutput -split "`n" | Where-Object { $_.Trim() -ne "" }

  # Find header line to determine column offsets
  $headerLine = $lines | Where-Object {
    $_ -match "\bNom\b|\bName\b" -and $_ -match "\bID\b|\bId\b" -and $_ -match "\bSource\b"
  } | Select-Object -First 1

  if (-not $headerLine)
  {
    Write-Host "Could not find winget list header. Aborting." -ForegroundColor Red
    exit 1
  }

  $sourceIndex = $headerLine.IndexOf("Source")

  # Filter lines where the Source column contains "winget"
  $packages = $lines | Where-Object {
    $_ -notmatch "^[-\s]+$" -and
    $_.Length -gt $sourceIndex -and
    $_.Substring($sourceIndex).Trim() -like "winget*"
  } | ForEach-Object {
    $parts = $_ -split "\s{2,}"
    if ($parts.Count -ge 2)
    { $parts[1].Trim() 
    }
  } | Where-Object { $_ -and $_ -notmatch "^ID$|^Id$" }

  if ($packages.Count -eq 0)
  {
    Write-Host "No winget-sourced packages found. Aborting." -ForegroundColor Red
    exit 1
  }

  Write-Host "`n$($packages.Count) winget-sourced packages found." -ForegroundColor Yellow
  Write-Host "A selection window will open — hold Ctrl or Shift to select multiple packages." -ForegroundColor DarkGray

  # Let user pick packages via Out-GridView
  $selected = $packages | ForEach-Object { [PSCustomObject]@{ ID = $_ } } |
    Out-GridView -Title "Select packages to reinstall (Ctrl+click for multiple)" -OutputMode Multiple

  if (-not $selected -or $selected.Count -eq 0)
  {
    Write-Host "No packages selected. Aborted." -ForegroundColor DarkGray
    exit 0
  }

  Write-Host "`n$($selected.Count) package(s) selected:" -ForegroundColor Yellow
  $selected | ForEach-Object { Write-Host "  - $($_.ID)" }

  $confirm = Read-Host "`nProceed with uninstall + reinstall? (y/N)"

  if ($confirm -notin @("y", "Y", "yes", "Yes"))
  {
    Write-Host "Aborted." -ForegroundColor DarkGray
    exit 0
  }

  foreach ($pkg in $selected)
  {
    Write-Host "`nUninstalling $($pkg.ID)..." -ForegroundColor Magenta
    winget uninstall --id $pkg.ID --silent --accept-source-agreements 2>&1

    Write-Host "Reinstalling $($pkg.ID)..." -ForegroundColor Blue
    winget install --id $pkg.ID --silent --force `
      --accept-package-agreements --accept-source-agreements 2>&1
  }

  Write-Host "`nDone! Open a new terminal for PATH changes to take effect." -ForegroundColor Green
}

function reload
{
  . $PROFILE
  $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")
  Clear-host
}

fastfetch.exe
# --- zoxide (smart cd) ---
# NEED TO STAY AT THE END OF THE FILE !

Invoke-Expression (& { (zoxide init powershell | Out-String) })
