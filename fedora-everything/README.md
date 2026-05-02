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
- Installs the base Wayland stack for `niri`, `waybar`, `greetd`, `gtkgreet`, `fuzzel`, `mako`, `swww`, `yad`, screenshots, audio, portals including `xdg-desktop-portal-wlr`, and the Fedora packages Axidev OSK now needs when installed from source (`python3-pip`, `python3-setuptools`, `python3-wheel`, `python3-pyside6`, `qt6-qtwayland`, `layer-shell-qt`, `libinput-devel`, `systemd-devel`, `systemd-libs`, `libxkbcommon-devel`, `python3-devel`)
- Installs `glibc-langpack-en` and `glibc-locale-source`, generates `en_US.UTF-8` when needed, persists `LANG=en_US.UTF-8` with `localectl`, and sets the system keymap/XKB layout to `us`
- Installs the shared CLI base used by the repo profile such as `stow`, `zsh`, `fd-find`, `ripgrep`, `fzf`, `zoxide`, and `jq`
- Installs optional user tools like `neovim`, `tmux`, `lazygit`, `eza`, `bat`, `fastfetch`, `btop`, `tokei`, `tree-sitter-cli`, `yazi`, and `wezterm` in a separate non-critical step
- Installs development tools and runtimes from Fedora packages where available, including Python, Go, Rustup, OpenJDK, Maven, GCC, LLVM, CMake, Make, Meson, Conan, and Zig
- Installs media, file, and creative tools such as FFmpeg, 7-Zip, Poppler, resvg, ImageMagick, Thunar, Blender, Krita, Kdenlive, and Audacity
- Installs Wi-Fi support packages for NetworkManager, Intel Wi-Fi firmware splits, `nm-applet`, and NetworkManager connection editing tools
- Installs KDE Connect, enables `firewalld`, and opens the KDE Connect firewall service
- Installs RPM Fusion NVIDIA packages and writes `~/enroll-secure-boot-nvidia.sh` so one shared MOK key signs both NVIDIA kernel modules and rEFInd
- Installs `Iosevka Nerd Font` for the shared WezTerm profile and Yazi icons
- Enables the `lihaohong/yazi` COPR before the optional `yazi` install
- Enables the `dejan/lazygit` COPR before the optional `lazygit` install
- Enables the official `wezfurlong/wezterm-nightly` COPR recommended by the WezTerm docs before the optional `wezterm` install
- Configures the official 1Password yum repository and installs `1password`
- Installs `google-chrome-stable` from Google's official 64-bit RPM package on `x86_64`
- Installs Docker from Docker's official Fedora repository and adds the normal user to the `docker` group
- Installs Ollama from the official Linux installer
- Installs NVM, Node.js LTS, OpenAI Codex, and T3 Code
- Copies the shared repo packages into `~/dotfiles`
- Stows the shared repo packages for:
  - `fuzzel`
  - `kanata`
  - `niri`
  - `nvim`
  - `tmux`
  - `waybar`
  - `wezterm`
  - `mako`
  - `lazygit`
- Installs the repo `~/.zshrc`, syncs the shared `blacknpink` Oh My Zsh theme into `~/.oh-my-zsh/custom/themes`, and syncs the shared `inaya` plugin into `~/.oh-my-zsh/custom/plugins/inaya`
- Installs the repo Yazi config into `~/.config/yazi`, including `yazi.toml` with `nvim` as the editor
- Installs Oh My Zsh plus `zsh-autosuggestions` and `zsh-syntax-highlighting`
- Installs Oh My Tmux
- Installs `rEFInd`, runs `refind-install`, enables mouse input in `refind.conf`, and adds a minimal black-pink rEFInd theme under `/boot/efi/EFI/refind/themes/black-pink` (the source-of-truth files live in [`../dotfiles/refind/`](../dotfiles/refind/) and are copied onto the ESP by the installer; they are not stowed)
- Installs `gtkgreet`
- Downloads the latest `axidev-osk-source.zip` release archive into a temp directory, extracts it into `/opt/axidev-osk`, creates a system venv there with `--system-site-packages`, refreshes `pip`/`setuptools`/`wheel`, installs the bundled `vendor/axidev-io-python` dependency plus `axidev-osk` itself with `pip --no-deps`, and writes `/usr/local/bin/axidev-osk` as a small launcher that enables Qt Wayland layer-shell support
- Downloads the latest upstream Kanata `kanata-linux-x64.zip` release archive and installs the non-legacy Linux binary as `/usr/local/bin/kanata`
- Stows the shared Kanata profiles and tray script into `~/.config/kanata`
- Configures `/dev/uinput` access for the normal user and the greetd user during installation so group membership is active after the first reboot
- Configures Kanata access to `/dev/uinput` and `/dev/input/event*` through the `input` group
- Creates `/usr/local/bin/niri-session`
- Creates `/usr/local/bin/gtkgreet-session` for the dedicated greeter compositor
- Registers a `niri.desktop` wayland session and a `Niri` greetd command alias so `gtkgreet` shows `Niri` instead of the wrapper path
- Configures `greetd` to launch `gtkgreet` and `axidev-osk` inside a dedicated `niri` greeter session
- Writes dark-mode preferences for the user session (`environment.d`, GTK 3/4 settings, Qt 5/6 ct configs, portal/terminal variables, and GNOME/libadwaita color-scheme hints)
- Writes user PipeWire tuning files for 48 kHz audio, lower latency quantum, and disabled session suspend
- Forces the greeter and OSK wrappers to use dark `Adwaita`/Qt styling too
- Installs an `efi-boot-order-guard.service` that keeps the `rEFInd` EFI entry first, with Fedora shim as fallback
- Sets the default boot target to `graphical.target`
- Enables `NetworkManager`, turns Wi-Fi radio on when available, and enables `greetd`
- Removes duplicate terminal packages (`foot`, `alacritty`, and the common `alacrity` typo if present) at the end of installation so WezTerm is the only configured terminal

## Dotfiles Model

Fedora does not install repo files directly into place anymore.

- Shared packages are copied to `~/dotfiles`
- GNU Stow links them into `$HOME`
- Repo-managed files such as `~/.wezterm.lua` and `~/.config/nvim` come from the stowed packages
- Fedora desktop files such as `~/.config/fuzzel`, `~/.config/mako`, `~/.config/niri`, and `~/.config/waybar` also come from the shared stowed packages
- Kanata files such as `~/.config/kanata/homerow.kbd`, `~/.config/kanata/disabled.kbd`, `~/.config/kanata/valo.kbd`, and `~/.config/kanata/kanata-tray` come from the shared stowed `kanata` package
- `~/.zshrc` is installed directly from the repo, the shared `blacknpink` theme is synced into `~/.oh-my-zsh/custom/themes`, and the shared `inaya` plugin is synced into `~/.oh-my-zsh/custom/plugins/inaya`
- `~/.config/yazi` is installed directly from the repo because Yazi expects its config files at the top level of that directory on Linux
- `~/.config/niri` is also stowed unless `~/.config/niri/config.kdl` already exists as a regular file, in which case the installer leaves the existing session config untouched
- `~/.config/waybar` is stowed from the shared repo package and the shared `niri` config starts `waybar` at session startup
- The shared `niri` config also starts `swww-daemon`, applies `~/wallpapers/fond.jpg` with a fade transition, and starts `axidev-osk` plus `~/.config/kanata/kanata-tray` at session startup so the wallpaper, on-screen keyboard, and mouse-accessible Kanata profile switcher are available after login
- `dotfiles/refind/` is **not** stowed because rEFInd lives on the EFI System Partition (FAT32, mounted at `/boot/efi`). The installer copies its contents onto `/boot/efi/EFI/refind/` instead. See [`../dotfiles/refind/README.md`](../dotfiles/refind/README.md) for what each file controls and how to update it.

## Kanata Profiles

Kanata is used only for home-row mods, profile-specific keyboard modes, and F17/F18 mouse-wheel output. Profile switching is handled by a `yad` tray icon, so it does not depend on a keyboard shortcut.

- Left-click the Kanata tray icon in Waybar to open the profile menu.
- `Home Row` enables `a/s/d/f` and `j/k/l/;` home-row modifiers plus F17/F18 scroll.
- `Disabled` keeps a small accessibility mapping on `z/a/s/w`, maps `c/v` to scroll, and maps F17/F18 to scroll.
- `Valo` enables the requested Valorant-oriented key mode and maps F17/F18 to scroll.
- `Off` stops Kanata.
- `Quit` stops Kanata and closes the tray process.

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
- `Alt+t` launches `wezterm`
- `Alt+Shift+Space` toggles floating
- `Alt+i` shows the `niri` hotkey overlay

`niri` does not expose a compositor-level minimize action like the Windows setup, so the `Alt+m` AHK bind is intentionally not ported.

## Notes

- Fedora does not install or depend on Homebrew.
- `rEFInd` is installed from Fedora packages and the installer runs `refind-install` to copy it onto the EFI System Partition.
- The installer enables `rEFInd` mouse input by ensuring `enable_mouse true` is present in `/boot/efi/EFI/refind/refind.conf`. The snippet that gets appended is read from [`../dotfiles/refind/mouse.conf`](../dotfiles/refind/mouse.conf), and the black-pink theme is sourced from [`../dotfiles/refind/themes/black-pink/`](../dotfiles/refind/themes/black-pink/). To change rEFInd settings or theme, edit the files there and re-run `install.sh`; see [`../dotfiles/refind/README.md`](../dotfiles/refind/README.md) for details.
- When Secure Boot is enabled, the installer tries to reuse Fedora's shim for the `rEFInd` install.
- `gtkgreet` is installed from Fedora packages.
- `axidev-osk` does not have a Fedora package yet, so the installer follows the upstream Fedora source-install path using the published `axidev-osk-source.zip` release archive and installs it under `/opt/axidev-osk`.
- Linux keyboard injection uses `/dev/uinput`; the installer writes `/etc/udev/rules.d/70-axidev-io-uinput.rules`, loads `uinput`, persists it in `/etc/modules-load.d/uinput.conf`, and adds both the normal user and greetd user to the `input` group before reboot.
- Kanata uses `/dev/uinput` for output and `/dev/input/event*` for input; the installer writes `/etc/udev/rules.d/71-kanata-input.rules`, loads `uinput`, persists it in `/etc/modules-load.d/uinput.conf`, and adds the normal user to the `input` group before reboot.
- The greeter launches Axidev through `/usr/local/bin/greetd-axidev-osk`, which now waits for the Wayland socket and retries startup a few times so the keyboard is less likely to miss the login screen due to compositor startup timing.
- `yazi` is installed from the `lihaohong/yazi` COPR, per the Yazi installation docs for Fedora.
- `lazygit` is installed from the `dejan/lazygit` COPR because it is not available in Fedora's base repositories on all target installs.
- `wezterm` is installed from the `wezfurlong/wezterm-nightly` COPR, which the WezTerm Linux docs recommend for staying current on Fedora and other rpm-based systems.
- `codex` is installed from the `sureclaw/codex` COPR.
- `t3code` is installed from the `burningpho3nix/T3-Code` COPR.
- `1password` is installed from 1Password's official yum repository, which also enables automatic updates.
- `google-chrome-stable` is installed from Google's official 64-bit Fedora/openSUSE RPM package, which also configures Chrome updates.
- Google Chrome is skipped automatically on non-`x86_64` Fedora installs.
- Existing files for stowed packages may still be adopted into `~/dotfiles` during `stow` if they already exist under `$HOME`, except the installer now skips the shared `niri` package when `~/.config/niri/config.kdl` already exists.
- Optional tool installation and configuration are allowed to fail without aborting the boot-critical Fedora setup path.
- After the script finishes, reboot and log in through `gtkgreet`.
- For dual-boot systems with Windows, [grub-protector.ps1](grub-protector.ps1) can be run as Administrator in Windows to make Windows Boot Manager chainload Fedora's `shimx64.efi`.
