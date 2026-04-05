# =========================
# Profile mode detection
# =========================

$ProfileMode = if ($env:PW_PROFILE_MODE) { $env:PW_PROFILE_MODE } else { "auto" }

$IsInteractiveConsole = (
  $Host.Name -eq "ConsoleHost" -and
  -not [Console]::IsInputRedirected -and
  -not [Console]::IsOutputRedirected
)

$UseInteractiveProfile = switch ($ProfileMode.ToLowerInvariant())
{
  "full"  { $true }
  "quiet" { $false }
  "auto"  { $IsInteractiveConsole }
  default { $IsInteractiveConsole }
}

$IsQuiet = -not $UseInteractiveProfile

# =========================
# Quiet-safe helpers
# =========================

function Write-Info($msg)
{
  if (-not $IsQuiet)
  {
    Write-Host $msg -ForegroundColor Cyan
  }
}

function Write-Success($msg)
{
  if (-not $IsQuiet)
  {
    Write-Host $msg -ForegroundColor Green
  }
}

function Write-Warn($msg)
{
  if (-not $IsQuiet)
  {
    Write-Host $msg -ForegroundColor Yellow
  }
}

function Write-Err($msg)
{
  Write-Host $msg -ForegroundColor Red
}

# =========================
# UI / Interactive only
# =========================

if ($UseInteractiveProfile)
{
  # --- Oh My Posh ---
  $ohMyPoshConfig = Join-Path $env:USERPROFILE ".OhMyPosh\black-pink.omp.json"
  if (Test-Path $ohMyPoshConfig)
  {
    oh-my-posh init pwsh --config $ohMyPoshConfig | Invoke-Expression
  }

  # --- Terminal Icons ---
  if (Get-Module -ListAvailable -Name Terminal-Icons)
  {
    Import-Module Terminal-Icons
  }

  # --- PSReadLine ---
  if (Get-Module -ListAvailable -Name PSReadLine)
  {
    Import-Module PSReadLine

    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    try
    {
      Set-PSReadLineOption -PredictionSource History
      Set-PSReadLineOption -PredictionViewStyle InlineView
    } catch {}

    try
    {
      Set-PSReadLineOption -ViModeIndicator Script
      Set-PSReadLineOption -ViModeChangeHandler {
        param($mode)
        switch ($mode)
        {
          "Insert"  { Write-Host -NoNewline "$([char]0x1b)[5 q" }
          "Command" { Write-Host -NoNewline "$([char]0x1b)[1 q" }
          default   { Write-Host -NoNewline "$([char]0x1b)[5 q" }
        }
      }
    } catch {}
  }
}

# =========================
# Aliases (always loaded)
# =========================

Set-Alias lg lazygit
Set-Alias oc opencode
Set-Alias co codex
Set-Alias vim nvim
Set-Alias vi nvim
Set-Alias v nvim
Set-Alias grep rg
Set-Alias which gcm

# =========================
# Core functions
# =========================

function y
{
  $tmp = (New-TemporaryFile).FullName
  yazi.exe $args --cwd-file="$tmp"
  $cwd = Get-Content -Path $tmp -Encoding UTF8

  if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container))
  {
    Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
  }

  Remove-Item $tmp
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
        Write-Success "✅ MSVC environment loaded"
        return
      }
    }
  }

  Write-Err "❌ MSVC environment not found."
}

# =========================
# AI Commit (Codex clean)
# =========================

function aic
{
  param(
    [string]$Model = "gpt-5.4-mini"
  )

  $branch = (git rev-parse --abbrev-ref HEAD) -join "`n"
  $gitLog = (git log -10 --pretty=format:"<commit>%n%h%n%B%n</commit>") -join "`n"
  $diffStat = (git diff --cached --stat) -join "`n"
  $diff = (git diff --cached) -join "`n"

  $branch = $branch.Replace("`r`n", "`n").Replace("`r", "`n").Trim()
  $gitLog = $gitLog.Replace("`r`n", "`n").Replace("`r", "`n").Trim()
  $diffStat = $diffStat.Replace("`r`n", "`n").Replace("`r", "`n").Trim()
  $diff = $diff.Replace("`r`n", "`n").Replace("`r", "`n").Trim()

  if ([string]::IsNullOrWhiteSpace($diffStat))
  {
    Write-Err "❌ No staged changes. Run git add first."
    return
  }

  while ($true)
  {
    $prompt = @"
You are writing a git commit message.

IMPORTANT:
- ALWAYS use real newlines when you want a multiline commit message
- DO NOT surround the answer with quotes
- Return ONLY the commit message text, nothing else

Branch:
$branch

Recent commits (subject + body raw):
$gitLog

Diff stat:
$diffStat

Full staged diff:
$diff

Rules:
- concise but descriptive
- infer the commit style from the recent commits
- if recent commits include a body, include a body if useful
- preserve the repository's usual formatting conventions
- include branch name when relevant for ticket/reference context
- no emojis
- no fluff
"@

    $rawMessage = $prompt | codex exec `
      -m $Model `
      -c model_reasoning_effort=low `
      -c temperature=0.2

    if (-not $rawMessage)
    {
      Write-Err "❌ Failed to generate commit message."
      return
    }

    $message = (($rawMessage | ForEach-Object { [string]$_ }) -join "`n")
    $message = $message.Replace("`r`n", "`n").Replace("`r", "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($message))
    {
      Write-Err "❌ Codex returned an empty commit message."
      return
    }

    Write-Host ""
    Write-Host "──────────────── commit preview ────────────────" -ForegroundColor DarkGray
    Write-Host $message -ForegroundColor Cyan
    Write-Host "───────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""

    $choice = Read-Host "[Y] yes  |  [R] retry  |  [C] cancel"

    switch ($choice.ToLowerInvariant())
    {
      "y"
      {
        $message | git commit -F -
        Write-Success "✨ Commit created. Tiny machine goblin satisfied."
        return
      }

      "r"
      {
        Write-Info "🔁 Retrying... maybe the robot was feeling silly."
        continue
      }

      "c"
      {
        Write-Warn "🚫 Commit cancelled. Nothing was committed."
        return
      }

      default
      {
        Write-Warn "🤨 Expected Y, R, or C. Let's try again."
        continue
      }
    }
  }
}

# =========================
# Misc
# =========================

function update
{
  winget upgrade -r --include-unknown --accept-package-agreements --accept-source-agreements
}

function ..
{
  param([int]$levels = 1)

  if ($levels -lt 1)
  {
    Write-Err "Please provide a positive number."
    return
  }

  $path = (Get-Location).Path
  for ($i = 0; $i -lt $levels; $i++)
  {
    $path = Split-Path $path -Parent
  }

  Set-Location $path
}

function reload
{
  . $PROFILE
  $env:PATH = [System.Environment]::GetEnvironmentVariable("PATH", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("PATH", "User")

  if (-not $IsQuiet)
  {
    Clear-Host
  }
}

# =========================
# Startup (interactive only)
# =========================

if ($UseInteractiveProfile)
{
  if (Get-Command fastfetch.exe -ErrorAction SilentlyContinue)
  {
    fastfetch.exe
  }

  if (Get-Command zoxide -ErrorAction SilentlyContinue)
  {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
  }
}
