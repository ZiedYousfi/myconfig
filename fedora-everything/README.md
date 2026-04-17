# Fedora Everything Minimal Niri Setup

This target installs a small Fedora desktop based on `niri`, `greetd`, `gtkgreet`, and shared repo `dotfiles` with GNU Stow.

## Intended Install Flow

1. Install Fedora using the Everything (netinstall) ISO.
2. Choose a minimal install without GNOME or KDE.
3. Create your normal user during installation.
4. Boot into the new system.
5. Run the installer as root:

```bash
sudo bash install.sh
```

You can also run it through the repo bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash -s -- fedora
```

## What It Configures

- Installs `grub2-efi-x64`, `shim-x64`, `efibootmgr`, and `rEFInd`
- Installs the base Wayland stack for `niri`, `waybar`, `greetd`, `gtkgreet`, `foot`, `fuzzel`, `mako`, screenshots, audio, portals, and the build dependencies needed for `wvkbd` when Fedora does not package it
- Installs the shared CLI base used by the repo profile such as `stow`, `zsh`, `fd-find`, `ripgrep`, `fzf`, `zoxide`, and `jq`
- Installs optional user tools like `neovim`, `tmux`, `lazygit`, `eza`, `bat`, `fastfetch`, `yazi`, and `wezterm` in a separate non-critical step
- Installs `Iosevka Nerd Font` for the shared WezTerm profile and Yazi icons
- Enables the `lihaohong/yazi` COPR before the optional `yazi` install
- Enables the official `wezfurlong/wezterm-nightly` COPR recommended by the WezTerm docs before the optional `wezterm` install
- Configures the official 1Password yum repository and installs `1password`
- Installs `google-chrome-stable` from Google's official 64-bit RPM package on `x86_64`
- Copies the shared repo packages into `~/dotfiles`
- Stows the shared repo packages for:
  - `niri`
  - `nvim`
  - `tmux`
  - `waybar`
  - `wezterm`
  - `lazygit`
  - `zed`
- Installs the repo `~/.zshrc` and syncs the shared `zieds` Oh My Zsh plugin into `~/.oh-my-zsh/custom/plugins/zieds`
- Installs the repo Yazi config into `~/.config/yazi`, including `yazi.toml` with `nvim` as the editor
- Installs Oh My Zsh plus `zsh-autosuggestions` and `zsh-syntax-highlighting`
- Installs Oh My Tmux
- Installs `rEFInd`, runs `refind-install`, and enables mouse input in `refind.conf`
- Installs `gtkgreet`
- Installs `wvkbd` from Fedora packages when available, otherwise builds `wvkbd-mobintl` from upstream into `/usr/local/bin/wvkbd-mobintl`
- Creates `/usr/local/bin/niri-session`
- Creates `/usr/local/bin/gtkgreet-session` for the dedicated greeter compositor
- Registers a `niri.desktop` wayland session
- Configures `greetd` to launch `gtkgreet` and `wvkbd` inside a dedicated `niri` greeter session
- Forces the greeter itself to use the dark `Adwaita` GTK theme without changing the user session theme
- Installs an `efi-boot-order-guard.service` that keeps the `rEFInd` EFI entry first, with Fedora shim as fallback
- Sets the default boot target to `graphical.target`
- Enables `NetworkManager` and `greetd`

## Dotfiles Model

Fedora does not install repo files directly into place anymore.

- Shared packages are copied to `~/dotfiles`
- GNU Stow links them into `$HOME`
- Repo-managed files such as `~/.wezterm.lua` and `~/.config/nvim` come from the stowed packages
- `~/.zshrc` is installed directly from the repo and the shared `zieds` plugin is synced into `~/.oh-my-zsh/custom/plugins/zieds`
- `~/.config/yazi` is installed directly from the repo because Yazi expects its config files at the top level of that directory on Linux
- `~/.config/niri` is also stowed unless `~/.config/niri/config.kdl` already exists as a regular file, in which case the installer leaves the existing session config untouched
- `~/.config/waybar` is stowed from the shared repo package and the shared `niri` config starts `waybar` at session startup
- The shared `niri` config also starts `wvkbd-mobintl` at session startup so the on-screen keyboard is already open after login

The only non-stowed pieces are third-party upstream checkouts:

- `~/.oh-my-zsh`
- `~/.oh-my-tmux`

## Shortcut Model

The Fedora `niri` config follows the Windows `komorebi` + AHK workflow in this repo:

- `Alt+h/j/k/l` and `Alt+Arrow` focus left/down/up/right
- `Alt+Shift+h/j/k/l` and `Alt+Shift+Arrow` move windows
- `Alt+1..0` focuses workspaces `1..10`
- `Alt+Shift+1..0` sends the focused column to workspaces `1..10`
- `Alt+q` closes the focused window
- `Alt+Shift+t` launches `foot`
- `Alt+Shift+Space` toggles floating
- `Alt+i` shows the `niri` hotkey overlay

`niri` does not expose a compositor-level minimize action like the Windows setup, so the `Alt+m` AHK bind is intentionally not ported.

## Notes

- Fedora does not install or depend on Homebrew.
- `rEFInd` is installed from Fedora packages and the installer runs `refind-install` to copy it onto the EFI System Partition.
- The installer enables `rEFInd` mouse input by ensuring `enable_mouse true` is present in `/boot/efi/EFI/refind/refind.conf`.
- When Secure Boot is enabled, the installer tries to reuse Fedora's shim for the `rEFInd` install.
- `gtkgreet` is installed from Fedora packages.
- The installer tries to install `wvkbd` from Fedora packages first, and falls back to building `wvkbd-mobintl` from the upstream Git repository when it is unavailable.
- `yazi` is installed from the `lihaohong/yazi` COPR, per the Yazi installation docs for Fedora.
- `wezterm` is installed from the `wezfurlong/wezterm-nightly` COPR, which the WezTerm Linux docs recommend for staying current on Fedora and other rpm-based systems.
- `1password` is installed from 1Password's official yum repository, which also enables automatic updates.
- `google-chrome-stable` is installed from Google's official 64-bit Fedora/openSUSE RPM package, which also configures Chrome updates.
- Google Chrome is skipped automatically on non-`x86_64` Fedora installs.
- Existing files for stowed packages may still be adopted into `~/dotfiles` during `stow` if they already exist under `$HOME`, except the installer now skips the shared `niri` package when `~/.config/niri/config.kdl` already exists.
- Optional tool installation and configuration are allowed to fail without aborting the boot-critical Fedora setup path.
- After the script finishes, reboot and log in through `gtkgreet`.
- For dual-boot systems with Windows, [grub-protector.ps1](grub-protector.ps1) can be run as Administrator in Windows to make Windows Boot Manager chainload Fedora's `shimx64.efi`.
