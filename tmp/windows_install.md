# Unordered steps to setup the development environment on Windows

- Install the winget packages : winget import packages.json --accept-source-agreements --accept-package-agreements
- Copy the powershell profile : copy <repo>\windows\dotfiles\PowerShell\Microsoft.PowerShell_profile.ps1 $profile
- Copy the nvim configuration : copy <repo>\dotfiles\nvim\.config\nvim\* $env:APPDATA\nvim\
- Install the treesitter cli : cargo install tree-sitter-cli
- Install the powershell module PSReadLine : Install-Module -Name PSReadLine -AllowPrerelease -Force
- Copy the .OhMyPosh folder to the user profile : copy .\.OhMyPosh $env:USERPROFILE\.OhMyPosh -Recurse
- Install JetBrains Mono font : oh-my-posh font install JetBrainsMono
