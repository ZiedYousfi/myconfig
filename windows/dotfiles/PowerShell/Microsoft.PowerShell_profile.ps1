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
Set-Alias -Name grep -Value ripgrep
Set-Alias -Name rg -Value ripgrep

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

# --- zoxide (smart cd) ---
# NEED TO STAY AT THE END OF THE FILE !

Invoke-Expression (& { (zoxide init powershell | Out-String) })
