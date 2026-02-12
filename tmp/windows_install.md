# Unordered steps to setup the development environment on Windows

- Install the winget packages : winget import <repo>\windows\dotfiles\winget\packages.json --accept-source-agreements --accept-package-agreements
- Copy the powershell profile : copy <repo>\windows\dotfiles\PowerShell\Microsoft.PowerShell_profile.ps1 $profile
- Copy the nvim configuration : copy <repo>\dotfiles\nvim\.config\nvim\* $env:LocalAppData\nvim\ -Recurse
- Copy the yazi configuration : copy <repo>\dotfiles\yazi\.config\yazi\* $env:AppData\yazi\ -Recurse
- Install the treesitter cli : cargo install tree-sitter-cli (Don't forget to install cpp build tools with Visual Studio Installer)
- Install the powershell module PSReadLine : Install-Module -Name PSReadLine -AllowPrerelease -Force -Scope CurrentUser
- Copy the .OhMyPosh folder to the user profile : copy .\.OhMyPosh $env:USERPROFILE\.OhMyPosh -Recurse
- Install JetBrains Mono font : oh-my-posh font install JetBrainsMono
- Install the Windows Terminal settings : copy <repo>\windows\dotfiles\WindowsTerminal\settings.json $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
- Run [Environment]::SetEnvironmentVariable("Path", $env:Path + ";C:\Program Files (x86)\GnuWin32\bin", "User")
- Run py install --configure
