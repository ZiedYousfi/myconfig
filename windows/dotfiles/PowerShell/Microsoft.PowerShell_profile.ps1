# PROFILE LOADED
Write-Host "PROFILE LOADED: $PROFILE"

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

    # Cursor shape change (Windows Terminal supports this)
    $esc = [char]0x1b

    try {
        Set-PSReadLineOption -ViModeIndicator Script
        Set-PSReadLineOption -ViModeChangeHandler {
            param($mode)
            switch ($mode) {
                "Insert"  { Write-Host -NoNewline "$([char]0x1b)[5 q" }  # beam
                "Command" { Write-Host -NoNewline "$([char]0x1b)[1 q" }  # block
                default   { Write-Host -NoNewline "$([char]0x1b)[5 q" }
            }
        }
    } catch {
        # PSReadLine version doesn't support ViModeChangeHandler
    }
}
