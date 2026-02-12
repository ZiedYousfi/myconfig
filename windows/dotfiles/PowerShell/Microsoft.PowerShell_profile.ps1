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

    try {
        Set-PSReadLineOption -ViModeIndicator Script
        Set-PSReadLineOption -ViModeChangeHandler {
            param($mode)
            switch ($mode) {
                "Insert" { Write-Host -NoNewline "$([char]0x1b)[5 q" }  # beam
                "Command" { Write-Host -NoNewline "$([char]0x1b)[1 q" }  # block
                default { Write-Host -NoNewline "$([char]0x1b)[5 q" }
            }
        }
    }
    catch {
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

function y {
	$tmp = (New-TemporaryFile).FullName
	yazi.exe $args --cwd-file="$tmp"
	$cwd = Get-Content -Path $tmp -Encoding UTF8
	if ($cwd -ne $PWD.Path -and (Test-Path -LiteralPath $cwd -PathType Container)) {
		Set-Location -LiteralPath (Resolve-Path -LiteralPath $cwd).Path
	}
	Remove-Item -Path $tmp
}

function reload {
    . $PROFILE
}

function msvcenv {
    # Déjà chargé ?
    if (Get-Command cl -ErrorAction SilentlyContinue) {
        Write-Host "ℹ️ MSVC environment already loaded" -ForegroundColor Yellow
	return
    }

    # Cherche vswhere
    $vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"

    if (Test-Path $vsWhere) {
        $installPath = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2>$null

        if ($installPath) {
            $launchScript = Join-Path $installPath "Common7\Tools\Launch-VsDevShell.ps1"
            if (Test-Path $launchScript) {
                & $launchScript
                Write-Host "✅ MSVC environment loaded" -ForegroundColor Green
                return
            }
        }
    }

    # Fallback hardcode
    $fallbackPaths = @(
        "C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\Tools\Launch-VsDevShell.ps1"
        "C:\Program Files\Microsoft Visual Studio\2022\Professional\Common7\Tools\Launch-VsDevShell.ps1"
        "C:\Program Files\Microsoft Visual Studio\2022\Enterprise\Common7\Tools\Launch-VsDevShell.ps1"
        "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\Launch-VsDevShell.ps1"
    )

    foreach ($path in $fallbackPaths) {
        if (Test-Path $path) {
            & $path
            Write-Host "✅ MSVC environment loaded from fallback path" -ForegroundColor Green
            return
        }
    }

    Write-Host "❌ MSVC environment not found. Please ensure Visual Studio with C++ tools is installed." -ForegroundColor Red
}

function aic {
    opencode run @"
Follow these steps precisely:

1. Run 'git log --oneline -10' to analyze the style and conventions of previous commit messages.
2. Run 'git diff --cached --stat' to check if there are any staged changes.
3. Based on the result:
   - If there ARE staged changes: commit ONLY the staged changes using 'git commit -m \"<message>\"'.
   - If there are NO staged changes: stage everything with 'git add -A', then commit using 'git commit -m \"<message>\"'.
4. The commit message must:
   - Be comprehensive and descriptive of the actual changes being committed.
   - Follow the style and conventions observed in the previous commits from step 1.
   - Use 'git diff --cached' (after staging if applicable) to understand what is being committed.
5. Do NOT push to remote under any circumstances.
"@ -m github-copilot/gpt-4.1
}

function update {
    winget upgrade -r --include-unknown --accept-package-agreements --accept-source-agreements
}

# --- zoxide (smart cd) ---
# NEED TO STAY AT THE END OF THE FILE !

Invoke-Expression (& { (zoxide init powershell | Out-String) })
