# Setup Config — Development Environment

This repository provides a single-script, idempotent setup for a development environment on macOS, Ubuntu, and Arch Linux. Each platform has a dedicated installer and its own configuration subtree so you can run the installer for the platform you need. The goal is to get from a clean or newly installed OS to a fully functional developer environment with one command.

**Key Feature:** Dotfiles are copied to `~/.dotfiles` and managed using [GNU Stow](https://www.gnu.org/software/stow/). After installation, you can safely delete this repository — your dotfiles live in your home directory.

Table of contents

- Quick start
- What it installs (overview)
- Installation details (macOS and Ubuntu)
- Dotfiles management with GNU Stow
- Post-install checks & steps
- Customization & editing configs
- Troubleshooting
- Uninstalling
- File and config reference

## Quick start

Clone the repository:

```
git clone https://github.com/ZiedYousfi/myconfig.git
cd setup-config
```

Choose the platform and run the installer script:

- macOS

```
bash macos/install.sh
```

- Ubuntu

```
bash ubuntu/install.sh
```

- Arch Linux (with Niri + Waybar already installed via archinstall)

```
bash archlinux/install.sh
```

After installation completes, you can delete this repository:

```
cd ..
rm -rf setup-config
```

Your dotfiles are now in `~/.dotfiles` and symlinked to the appropriate locations.

Notes:

- The installers are idempotent — running them multiple times is safe.
- Some steps require `sudo` for installing system packages and changing shells. You will be prompted for your password as needed.
- Make sure you have a working network connection (the scripts fetch packages and remote repositories).

## What it installs (overview)

The installers add and configure the following tools (platform differences noted in the scripts):

- Shell and shell framework:
  - Zsh + Oh My Zsh, custom plugin `zieds`
- Terminal: Ghostty
- Multiplexer: tmux with Oh My Tmux
- Editor: Neovim (LazyVim configuration + custom plugins)
- CLI tools: zoxide, eza, fd, fzf, ripgrep, bat, lazygit, btop, fastfetch
- Development toolchain: Git, Go, LLVM/Clang
- Optional: OpenCode / SST (opencode CLI)
- GNU Stow for dotfiles management
- Tiling window manager & status bar:
  - macOS: Yabai + Sketchybar
  - Arch Linux: Niri + Waybar (Monokai theme)

Important: The installers try to be minimally intrusive but they install software system-wide; read the script before running if you want to know the specifics.

## Installation details

### macOS

- Path to macOS installer:

```
bash macos/install.sh
```

- What this macOS script does (high level):
  - Installs Homebrew (if missing)
  - Uses `brew` to install packages and casks (including `stow`)
  - **Copies dotfiles to `~/.dotfiles`**
  - Installs Oh My Zsh, zsh plugins and sets up `.zshrc` (managed by the script)
  - **Uses GNU Stow** to symlink custom Zsh plugin, Neovim plugins, Ghostty config, and tmux config from `~/.dotfiles`
  - Configures tmux using Oh My Tmux and XDG config paths
  - Installs LazyVim and stows the platform-specific Neovim plugins
  - Applies macOS-specific settings (ex: disable press-and-hold for key repeats)

### Ubuntu

- Path to Ubuntu installer:

```
bash ubuntu/install.sh
```

- What this Ubuntu script does (high level):
  - Updates and upgrades system packages via `apt`
  - Installs default build tools and dependencies (`build-essential`, `zsh`, `stow`, `rsync`, etc.)
  - Installs Homebrew for Linux for additional package management
  - **Copies dotfiles to `~/.dotfiles`**
  - Installs modern CLI tools (zoxide, eza, fd, fzf, ripgrep, bat, lazygit, fastfetch)
  - Installs Ghostty via community script
  - Installs Oh My Zsh and **uses stow** for the custom zsh plugin from `~/.dotfiles`
  - Sets up Oh My Tmux and LazyVim, **using stow** for custom configs
  - Configures French locale if not present

### Arch Linux

- Path to Arch Linux installer:

```
bash archlinux/install.sh
```

- What this Arch Linux script does (high level):
  - Installs `yay` (AUR helper) if not present
  - Uses `pacman` and `yay` to install packages
  - **Copies dotfiles to `~/.dotfiles`**
  - Installs modern CLI tools via pacman
  - Installs Ghostty and Zed via AUR
  - Configures **Niri** (scrollable tiling Wayland compositor) with Monokai-themed borders
  - Configures **Waybar** status bar with Monokai theme matching Sketchybar on macOS
  - Installs Oh My Zsh and **uses stow** for the custom zsh plugin from `~/.dotfiles`
  - Sets up Oh My Tmux and LazyVim, **using stow** for custom configs
  - Configures French locale if not present

## Dotfiles management with GNU Stow

### How it works

During installation, dotfiles are:

1. **Copied** from `<repo>/macos/dotfiles/` (or `ubuntu/dotfiles/`) to `~/.dotfiles`
2. **Stowed** from `~/.dotfiles` to create symlinks in your home directory

This means:

- ✅ You can delete the cloned repository after installation
- ✅ Your dotfiles live permanently in `~/.dotfiles`
- ✅ Symlinks point to `~/.dotfiles`, not the repo
- ✅ Easy to modify — edit files in `~/.dotfiles` and changes apply immediately

### Dotfiles structure in ~/.dotfiles

After installation, your `~/.dotfiles` directory contains:

```
~/.dotfiles/
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
├── niri/                    # Arch Linux only
│   └── .config/
│       └── niri/
│           └── config.kdl
├── nvim/
│   └── .config/
│       └── nvim/
│           └── lua/
│               └── plugins/
│                   ├── auto-save.lua
│                   └── colorscheme.lua
├── sketchybar/              # macOS only
│   └── .config/
│       └── sketchybar/
│           └── ...
├── tmux/
│   └── .config/
│       └── tmux/
│           └── tmux.conf.local
├── waybar/                  # Arch Linux only
│   └── .config/
│       └── waybar/
│           ├── config
│           └── style.css
├── yabai/                   # macOS only
│   └── .config/
│       └── yabai/
│           └── yabairc
├── zed/
│   └── .config/
│       └── zed/
│           └── settings.json
└── zsh/
    └── .oh-my-zsh/
        └── custom/
            └── plugins/
                └── zieds/
                    └── zieds.plugin.zsh
```

### Manual stow commands

After installation, you can manually manage dotfiles from `~/.dotfiles`:

```bash
cd ~/.dotfiles

# Re-stow a package after editing
stow --target="$HOME" --restow ghostty

# Unstow a package (remove symlinks)
stow --target="$HOME" --delete nvim

# Stow all packages
for pkg in ghostty nvim tmux zsh; do
  stow --target="$HOME" --restow "$pkg"
done
```

### How tmux works with stow

Tmux configuration uses Oh My Tmux as a base framework:

1. Oh My Tmux is cloned to `~/.oh-my-tmux/`
2. The main `tmux.conf` is symlinked from Oh My Tmux to `~/.config/tmux/tmux.conf`
3. Our custom `tmux.conf.local` is stowed from `~/.dotfiles/tmux/` to `~/.config/tmux/tmux.conf.local`

This is similar to how LazyVim works — the framework is installed first, then our custom config is stowed on top.

## Post-install checks & steps

- After installation, logout/login or run:

```
source ~/.zshrc
```

- Verify key tools:

```
git --version
zsh --version
nvim --version
go version
clang --version
zoxide --version
rg --version
bat --version
lazygit --version
stow --version
```

- LazyVim plugin management:
  - Open Neovim and run `:Lazy sync` (or `:Lazy` follow prompts)
  - Alternatively, open `nvim` and the plugin manager should trigger Lazy to sync

## Customization

### Editing configs after installation

Since dotfiles are in `~/.dotfiles` and symlinked:

1. Edit files directly in `~/.dotfiles/`
2. Changes are immediately reflected (they're symlinked!)
3. No need to re-run stow unless you add new files

Example:

```bash
# Edit Ghostty config
nvim ~/.dotfiles/ghostty/.config/ghostty/config

# Changes apply immediately — Ghostty reads from the symlink
```

### Adding new config files

To add a new config file to an existing stow package:

1. Create the file with the correct path structure under `~/.dotfiles/<package>/`
2. Run stow to create the symlink:

```bash
cd ~/.dotfiles
stow --target="$HOME" --restow <package>
```

### Creating a new stow package

To add a new application's config:

1. Create a new directory under `~/.dotfiles/` named after the package
2. Mirror the home directory structure inside it
3. Run stow manually

Example for adding a hypothetical `starship` config:

```bash
mkdir -p ~/.dotfiles/starship/.config
echo 'format = "🚀 $all"' > ~/.dotfiles/starship/.config/starship.toml
cd ~/.dotfiles
stow --target="$HOME" --restow starship
```

### Environment variables

Set a custom `XDG_CONFIG_HOME` before running the installer if you want the config to go to a different directory:

```
export XDG_CONFIG_HOME="$HOME/.config"
bash ubuntu/install.sh
```

## Troubleshooting & debugging

### General issues

- The scripts are intended to be idempotent, but if you run into issues:
  - Inspect the script to find the failing step:

```
less ubuntu/install.sh
```

- Re-run the script with verbose debugging:

```
bash -x ubuntu/install.sh
```

### Stow conflicts

If stow reports conflicts, it usually means a file already exists that isn't a symlink:

```bash
cd ~/.dotfiles

# Option 1: Let stow adopt the existing file
stow --target="$HOME" --adopt <package>

# Option 2: Manually remove the conflicting file first
rm ~/.config/ghostty/config
stow --target="$HOME" --restow ghostty
```

### Resetting configurations

If parts of the environment are out of sync, remove old configuration and re-run:

```
rm -rf "$XDG_CONFIG_HOME/nvim"
rm -rf "$XDG_CONFIG_HOME/tmux"
rm -rf "$XDG_CONFIG_HOME/ghostty"
bash macos/install.sh
```

### Shell not set to zsh

If the default shell is not set to zsh after install:

```
chsh -s "$(which zsh)"
```

Log out and log back in for the change to take effect.

## Uninstalling

To remove everything installed by the setup scripts, run the uninstall script for your platform:

**macOS:**

```
bash macos/uninstall.sh
```

**Ubuntu:**

```
bash ubuntu/uninstall.sh
```

**Arch Linux:**

```
bash archlinux/uninstall.sh
```

The uninstall scripts will:

1. Unstow all dotfiles from `~/.dotfiles` (remove symlinks)
2. Remove Oh My Zsh and plugins
3. Remove Oh My Tmux
4. Remove LazyVim/Neovim configuration and data
5. Remove Ghostty configuration
6. Remove Niri/Waybar configuration (Arch Linux)
7. Remove Sketchybar/Yabai configuration (macOS)
8. Remove Homebrew packages installed by the setup (macOS/Ubuntu)
9. Optionally remove AUR packages (Arch Linux)
10. Optionally remove Homebrew itself (macOS/Ubuntu)
11. Optionally remove `~/.dotfiles` directory
12. Restore default system settings (macOS)

**Note:** The scripts will ask for confirmation before proceeding and offer choices for optional removals.

## Known limitations & notes

- The scripts assume `amd64` architecture; if you use an ARM Linux system, adjust the downloads accordingly.
- The scripts will install system-wide software — if you are running on machines where you cannot use `sudo`, you may need to adapt the scripts for local installation.
- Neovim will be installed via Homebrew (both platforms).
- The Zsh plugin `zieds` is platform-specific (uses `brew` vs `apt` vs `yay` for updates).

## File reference

- Platform installers:
  - macOS: `macos/install.sh`
  - Ubuntu: `ubuntu/install.sh`
  - Arch Linux: `archlinux/install.sh`

- Platform-specific dotfiles (source, copied to ~/.dotfiles):
  - macOS: `macos/dotfiles/*` (includes sketchybar, yabai)
  - Ubuntu: `ubuntu/dotfiles/*`
  - Arch Linux: `archlinux/dotfiles/*` (includes niri, waybar)

- Platform-specific specifications:
  - macOS: `macos/SPECS.md`
  - Ubuntu: `ubuntu/SPECS.md`
  - Arch Linux: `archlinux/SPECS.md`

- Uninstall scripts:
  - macOS: `macos/uninstall.sh`
  - Ubuntu: `ubuntu/uninstall.sh`
  - Arch Linux: `archlinux/uninstall.sh`

- Specification: `SPECS.md` — contains the desired environment specification (high-level overview).

## Contributing

If you want to improve, add, or remove packages or change configuration, please:

1. Edit the appropriate `install.sh` or `dotfiles/*` files
2. Test your changes on a fresh VM or a disposable machine
3. Raise a PR or commit changes into your forked repo

Enjoy the setup!
