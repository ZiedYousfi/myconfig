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

3. Install OhMyPosh :
   - Open PowerShell and run the following commands:

```powershell
winget install JanDeDobbeleer.OhMyPosh -e
```
