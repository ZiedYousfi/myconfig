# The step that I took to set up my config on Windows to know what to do in the scripts

1. Update PowerShell :
   - Open PowerShell as Administrator `Start-Process powershell -Verb RunAs`
   - Run the command: `Invoke-Expression "& { $(Invoke-RestMethod 'https://aka.ms/install-powershell.ps1') } -useMSI -Quiet -EnablePSRemoting"`
   - Restart PowerShell to apply the update.

2. Set up Windows Terminal :
   - Download and install Windows Terminal from the Microsoft Store.
   - Set the settings JSON to this :

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

4. Setup GlazeWM :
   - Install GlazeWM by typing the following command in PowerShell:

   ```powershell
   winget install GlazeWM
   ```

   - Create a configuration file for GlazeWM at `$HOME\.glzr\config.yaml` with the following content:

```yaml
general:
  startup_commands: ['shell-exec zebar']
  shutdown_commands: ['shell-exec taskkill /IM zebar.exe /F']
  focus_follows_cursor: false
  toggle_workspace_on_refocus: false
  cursor_jump:
    enabled: true
    trigger: 'monitor_focus'
  hide_method: 'cloak'
  show_all_in_taskbar: false

gaps:
  scale_with_dpi: true
  inner_gap: '20px'
  outer_gap:
    top: '20px'
    right: '20px'
    bottom: '20px'
    left: '20px'

window_effects:
  focused_window:
    border:
      enabled: true
      color: '#A6E22E'
  other_windows:
    border:
      enabled: true
      color: '#2B2B2B'

window_behavior:
  initial_state: 'tiling'
  state_defaults:
    floating:
      centered: true
      shown_on_top: false

workspaces:
  - name: '1'
  - name: '2'
  - name: '3'
  - name: '4'
  - name: '5'
  - name: '6'
  - name: '7'
  - name: '8'
  - name: '9'
  - name: '10'

window_rules:
  - commands: ['ignore']
    match:
      - window_process: { equals: 'zebar' }
      - window_title: { regex: '[Pp]icture.in.[Pp]icture' }
        window_class: { regex: 'Chrome_WidgetWin_1|MozillaDialogClass' }

mouse_bindings:
  - modifier: 'alt'
    button: 'left'
    command: 'set-move-mode'
  - modifier: 'alt'
    button: 'right'
    command: 'set-resize-mode'

keybindings:
  # Focus
  - commands: ['focus --direction left']
    bindings: ['alt+h', 'alt+left']
  - commands: ['focus --direction right']
    bindings: ['alt+l', 'alt+right']
  - commands: ['focus --direction up']
    bindings: ['alt+k', 'alt+up']
  - commands: ['focus --direction down']
    bindings: ['alt+j', 'alt+down']

  # Move
  - commands: ['move --direction left']
    bindings: ['alt+shift+h', 'alt+shift+left']
  - commands: ['move --direction right']
    bindings: ['alt+shift+l', 'alt+shift+right']

  # Workspaces (1 à 10, avec 0 pour le workspace 10)
  - commands: ['focus --workspace 1']
    bindings: ['alt+1']
  - commands: ['focus --workspace 2']
    bindings: ['alt+2']
  - commands: ['focus --workspace 3']
    bindings: ['alt+3']
  - commands: ['focus --workspace 4']
    bindings: ['alt+4']
  - commands: ['focus --workspace 5']
    bindings: ['alt+5']
  - commands: ['focus --workspace 6']
    bindings: ['alt+6']
  - commands: ['focus --workspace 7']
    bindings: ['alt+7']
  - commands: ['focus --workspace 8']
    bindings: ['alt+8']
  - commands: ['focus --workspace 9']
    bindings: ['alt+9']
  - commands: ['focus --workspace 10']
    bindings: ['alt+0']

  # Move to Workspace
  - commands: ['move --workspace 1']
    bindings: ['alt+shift+1']
  - commands: ['move --workspace 2']
    bindings: ['alt+shift+2']
  - commands: ['move --workspace 10']
    bindings: ['alt+shift+0']

  # Autres raccourcis essentiels
  - commands: ['close']
    bindings: ['alt+shift+q']
  - commands: ['wm-reload-config']
    bindings: ['alt+shift+r']
  - commands: ['toggle-floating --centered']
    bindings: ['alt+shift+space']
```

4. Setup Zebar :
   - Move the dotfiles folder (windows/dotfiles/zebar/monokai-statusbar/) to `~\.glzr\zebar`
   - Set `~\.glzr\zebar\settings.json` to this :

   ```json
   {
      "$schema": "https://github.com/glzr-io/zebar/raw/v3.1.1/resources/settings-schema.json",
      "startupConfigs": [
        {
          "pack": "monokai-statusbar",
          "widget": "monokai-topbar",
          "preset": "default"
        }
      ]
    }
   ```

5. Set GlazeWM to start on login :
    - Run the following command in PowerShell :

    ```powershell
    Start-Process pwsh -Verb RunAs -ArgumentList @(
      '-NoProfile',
      '-Command',
      "`$ErrorActionPreference='Stop'; `$exe='C:\Program Files\glzr.io\GlazeWM\cli\glazewm.exe'; if(!(Test-Path `$exe)){throw 'Introuvable: ' + `$exe}; `$name='GlazeWM (Start on logon)'; `$a=New-ScheduledTaskAction -Execute `$exe -Argument 'start'; `$t=New-ScheduledTaskTrigger -AtLogOn; Register-ScheduledTask -TaskName `$name -Action `$a -Trigger `$t -Description 'Start GlazeWM on user logon' -Force | Out-Null; 'OK: tâche créée: ' + `$name"
    )
    ```
