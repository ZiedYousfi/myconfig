# The step that I took to set up my config on Windows to know what to do in the scripts

1. Update PowerShell :
    - Open PowerShell as Administrator `Start-Process powershell -Verb RunAs`
    - Run the command: `Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"`
    - Restart PowerShell to apply the update.

2. Set up Windows Terminal :
    - Download and install Windows Terminal from the Microsoft Store.
    - Set the JSON to this :

    ```json
    {
        "$help": "https://aka.ms/terminal-documentation",
        "$schema": "https://aka.ms/terminal-profiles-schema",
        "actions": [
            {
                    "command": {
                        "action": "copy",
                        "singleLine": false
                    },
                    "id": "User.copy.644BA8F2"
            },
            {
                    "command": "paste",
                    "id": "User.paste"
            },
            {
                    "command": {
                        "action": "splitPane",
                        "split": "auto",
                        "splitMode": "duplicate"
                    },
                    "id": "User.splitPane.A6751878"
            },
            {
                    "command": "find",
                    "id": "User.find"
            }
        ],
        "copyFormatting": "none",
        "copyOnSelect": true,
        "defaultProfile": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
        "firstWindowPreference": "persistedWindowLayout",
        "focusFollowMouse": true,
        "keybindings": [
            {
                    "id": "User.copy.644BA8F2",
                    "keys": "ctrl+c"
            },
            {
                    "id": "User.paste",
                    "keys": "ctrl+v"
            },
            {
                    "id": "User.find",
                    "keys": "ctrl+shift+f"
            },
            {
                    "id": "User.splitPane.A6751878",
                    "keys": "alt+shift+d"
            }
        ],
        "newTabMenu": [
            {
                    "type": "remainingProfiles"
            }
        ],
        "profiles": {
            "defaults": {
                    "colorScheme": "Monokai Classic"
            },
            "list": [
                    {
                        "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
                        "hidden": false,
                        "name": "PowerShell",
                        "source": "Windows.Terminal.PowershellCore"
                    }
            ]
        },
        "schemes": [
            {
                    "background": "#272822",
                    "black": "#272822",
                    "blue": "#66D9EF",
                    "brightBlack": "#75715E",
                    "brightBlue": "#66D9EF",
                    "brightCyan": "#A1EFE4",
                    "brightGreen": "#A6E22E",
                    "brightPurple": "#AE81FF",
                    "brightRed": "#FD971F",
                    "brightWhite": "#F9F8F5",
                    "brightYellow": "#E6DB74",
                    "cursorColor": "#F8F8F2",
                    "cyan": "#A1EFE4",
                    "foreground": "#F8F8F2",
                    "green": "#A6E22E",
                    "name": "Monokai Classic",
                    "purple": "#AE81FF",
                    "red": "#F92672",
                    "selectionBackground": "#49483E",
                    "white": "#F8F8F2",
                    "yellow": "#E6DB74"
            }
        ],
        "showTabsFullscreen": true,
        "themes": [],
        "useAcrylicInTabRow": true,
        "warning.confirmCloseAllTabs": false,
        "warning.inputService": false,
        "warning.largePaste": false,
        "warning.multiLinePaste": false,
        "windowingBehavior": "useExisting"
    }
    ```

3. Setup OhMyPosh :
    - Open PowerShell and run the following commands:

    ```powershell
    winget install JanDeDobbeleer.OhMyPosh -e
    Install-Module PSReadLine -Force -SkipPublisherCheck
    Install-Module Terminal-Icons -Force
    oh-my-posh font install JetBrainsMono
    ```

    - Fetch this [file](https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/pure.omp.json) and save it to `C:\Users\<username>\.OhMyPosh\pure.omp.json` by running the following commands:

    ```powershell
    $dir = Join-Path $HOME ".OhMyPosh"
    New-Item -ItemType Directory -Path $dir -Force | Out-Null

    Invoke-WebRequest `
    -Uri "https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/pure.omp.json" `
    -OutFile (Join-Path $dir "pure.omp.json")
    ```

    - Create the profile folder if needed and overwrite the PowerShell profile with the config below by running this command:

    ```powershell
    New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null

    @'
    "PROFILE LOADED: $PROFILE" | Write-Host

    # --- Oh My Posh (prompt theme) ---
    oh-my-posh init pwsh --config "$HOME\.OhMyPosh\pure.omp.json" | Invoke-Expression

    Import-Module Terminal-Icons

    # --- PSReadLine (Vi mode + inline autosuggest) ---
    if (-not (Get-Module -Name PSReadLine)) {
    Import-Module PSReadLine
    }

    Set-PSReadLineOption -EditMode Vi
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle InlineView
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Cursor shape change (Windows Terminal supports this)
    # Beam (insertion) / Block (normal)
    $esc = [char]0x1b

    # Try to use ViModeChangeHandler if available
    if (Get-Command Set-PSReadLineOption -ErrorAction SilentlyContinue) {
    try {
        Set-PSReadLineOption -ViModeIndicator Script
        Set-PSReadLineOption -ViModeChangeHandler {
            param($mode)

            switch ($mode) {
            "Insert" { Write-Host -NoNewline "$esc[5 q" } # beam
            "Command" { Write-Host -NoNewline "$esc[1 q" } # block
            default { Write-Host -NoNewline "$esc[5 q" }
            }
        }
    } catch {
        # If your PSReadLine doesn't support this handler, ignore
    }
    }
    '@ | Set-Content -Path $PROFILE -Encoding utf8
    ```
