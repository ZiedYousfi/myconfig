# Development Environment Specification

This document describes the desired development environment in a declarative, platform-agnostic way. For platform-specific details, see:

- [macOS Specification](macos/SPECS.md)
- [Ubuntu Specification](ubuntu/SPECS.md)
- [Arch Linux Specification](archlinux/SPECS.md)

---

## Philosophy

### Single Command Installation

The entire setup should be installable by running **a single script**. The goal is to minimize the number of steps required to go from a fresh system to a fully configured development environment.

### Idempotency

Running the setup multiple times must be safe and produce the same result. Tools already installed should be skipped.

### Tiling Window Manager & Status Bar

The environment uses a **tiling window manager** for efficient window organization and a **status bar** at the top of the screen for system information and workspace indicators. Platform-specific implementations:

- **macOS:** Yabai (tiling WM) + Sketchybar (status bar)
- **Arch Linux:** Niri (scrollable tiling Wayland compositor) + Waybar (status bar)
- **Ubuntu:** (not yet configured)

### Monokai Classic Color Theme

All visual components use the **Monokai Classic** color palette for a consistent aesthetic:

| Color      | Hex       | RGB             | Usage                          |
| ---------- | --------- | --------------- | ------------------------------ |
| Background | `#272822` | (39, 40, 34)    | Primary background             |
| Foreground | `#f8f8f2` | (248, 248, 242) | Primary text                   |
| Pink       | `#f92672` | (249, 38, 114)  | Keywords, highlights, active   |
| Orange     | `#fd971f` | (253, 151, 31)  | Warnings, secondary highlights |
| Yellow     | `#e6db74` | (230, 219, 116) | Strings                        |
| Green      | `#a6e22e` | (166, 226, 46)  | Success, strings, functions    |
| Cyan       | `#66d9ef` | (102, 217, 239) | Types, info, accents           |
| Purple     | `#ae81ff` | (174, 129, 255) | Numbers, constants             |

This theme is applied to:

- Neovim (via `monokai.nvim`)
- Zed (via Zedokai Darker Classic)
- Status bar (Sketchybar on macOS, Waybar on Arch Linux)
- Window manager borders (Niri on Arch Linux)
- Terminal applications

### Dotfiles Management with GNU Stow

All configuration files are managed using [GNU Stow](https://www.gnu.org/software/stow/). During installation:

1. Dotfiles are **copied** from the repository to `~/.dotfiles`
2. Stow creates **symlinks** from your home directory to `~/.dotfiles`

This enables:

- **Repository independence:** Delete the cloned repo after installation
- **Easy modification:** Edit files in `~/.dotfiles` and changes apply immediately
- **Version control:** Back up `~/.dotfiles` to your own git repo
- **Clean separation:** Each application is a separate stow package
- **Portability:** Copy `~/.dotfiles` to any machine and stow

---

## Stow Package Structure

After installation, `~/.dotfiles` contains:

| Package   | Target                               | Contents                        |
| --------- | ------------------------------------ | ------------------------------- |
| `ghostty` | `~/.config/ghostty/`                 | Terminal emulator configuration |
| `nvim`    | `~/.config/nvim/lua/plugins/`        | Custom Neovim plugins           |
| `tmux`    | `~/.config/tmux/`                    | Custom tmux configuration       |
| `zed`     | `~/.config/zed/`                     | Zed editor configuration        |
| `zsh`     | `~/.oh-my-zsh/custom/plugins/zieds/` | Custom Zsh plugin               |

```
~/.dotfiles/
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
├── nvim/
│   └── .config/
│       └── nvim/
│           └── lua/
│               └── plugins/
│                   ├── auto-save.lua
│                   └── colorscheme.lua
├── tmux/
│   └── .config/
│       └── tmux/
│           └── tmux.conf.local
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

---

## Core Applications

### Shell: Zsh + Oh My Zsh

- **Framework:** Oh My Zsh
- **Theme:** `refined`
- **Plugins:** `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `vi-mode`, `zieds`
- **Custom Plugin:** `zieds` provides environment variables, aliases, and helper functions

### Terminal: Ghostty

- Starts in fullscreen mode
- Black background
- Automatically attaches to or creates a tmux session
- **Opacity:** 75% (`background-opacity = 0.75`)
- **Background Blur:**
  - macOS: `background-blur = macos-glass-regular` (native glass effect)
  - Other platforms (Linux): `background-blur = true`

### Multiplexer: tmux + Oh My Tmux

- **Framework:** Oh My Tmux (`https://github.com/gpakosz/.tmux.git`)
- **Setup:** Clone to `~/.oh-my-tmux/`, symlink main config, stow custom config from `~/.dotfiles`
- **Custom Config:** Sets Zsh as default shell

### Editor: Neovim + LazyVim

- **Distribution:** LazyVim (`https://github.com/LazyVim/starter`)
- **Custom Plugins (stowed from ~/.dotfiles):**
  - `auto-save.lua` - Automatic file saving
  - `colorscheme.lua` - Monokai color scheme

### Editor: Zed

- **Installation:** macOS App (Homebrew cask)
- **Configuration:** Stowed from `~/.dotfiles/zed/`
- **Features:**
  - Dark theme (Zedokai Darker Classic)
  - Autosave after 2 seconds
  - Agent integration with Copilot Claude Opus 4.5
  - Edit predictions via Zed
  - Git panel on left, project panel on right
  - Minimap disabled

---

## CLI Tools

| Tool      | Replaces | Alias        | Description                         |
| --------- | -------- | ------------ | ----------------------------------- |
| zoxide    | cd       | `z`, `zi`    | Smart directory jumping             |
| eza       | ls       | `ls`         | Modern ls with icons and git status |
| fd        | find     | `find`       | Fast and user-friendly find         |
| fzf       | -        | -            | Fuzzy finder                        |
| ripgrep   | grep     | `grep`, `rg` | Fast recursive grep                 |
| bat       | cat      | -            | Syntax-highlighted cat              |
| lazygit   | -        | `lg`         | Git terminal UI                     |
| btop      | top      | -            | Resource monitor                    |
| fastfetch | neofetch | `ff`         | System information display          |

---

## Development Tools

| Tool           | Description                                                |
| -------------- | ---------------------------------------------------------- |
| Git            | Version control (installed first, required by other tools) |
| Go             | Go programming language, binaries in PATH                  |
| LLVM/Clang     | C/C++ compiler toolchain                                   |
| OpenCode (SST) | AI coding assistant CLI (`oc` alias)                       |

---

## Custom Zsh Functions

| Function     | Description                                |
| ------------ | ------------------------------------------ |
| `mkd`        | Create directory and cd into it            |
| `use-tmux`   | Attach to or create tmux session           |
| `reload-zsh` | Reload Zsh configuration                   |
| `pf`         | Fuzzy file picker that opens in Neovim     |
| `update`     | Update system packages (platform-specific) |
| `cleanup`    | Interactive directory cleanup wizard       |
| `zeze`       | Edit zoxide database                       |

---

## Custom Zsh Aliases

| Alias            | Command                 |
| ---------------- | ----------------------- |
| `vim`, `vi`, `v` | `nvim`                  |
| `ll`             | `ls -la`                |
| `gcb`            | Clean gone git branches |
| `lg`             | `lazygit`               |
| `ff`             | `fastfetch`             |
| `oc`             | `opencode`              |

---

## Environment Variables

| Variable             | Value            |
| -------------------- | ---------------- |
| `XDG_CONFIG_HOME`    | `$HOME/.config`  |
| `XDG_CACHE_HOME`     | `$HOME/.cache`   |
| `EDITOR`             | `nvim`           |
| `VISUAL`             | `nvim`           |
| `TERM`               | `xterm-256color` |
| `LANG`               | `fr_FR.UTF-8`    |
| `LC_ALL`             | `fr_FR.UTF-8`    |
| `VI_MODE_SET_CURSOR` | `true`           |

---

## Platform Differences

| Aspect          | macOS                                  | Ubuntu                      | Arch Linux              |
| --------------- | -------------------------------------- | --------------------------- | ----------------------- |
| Package Manager | Homebrew                               | apt + Homebrew (Linuxbrew)  | pacman + paru/yay (AUR) |
| Ghostty Install | Homebrew cask                          | Community script            | AUR (`yay -S ghostty`)  |
| Tiling WM       | Yabai                                  | —                           | Niri                    |
| Status Bar      | Sketchybar                             | —                           | Waybar                  |
| tmux Path       | `/opt/homebrew/bin/tmux`               | `/usr/bin/tmux`             | `/usr/bin/tmux`         |
| Update Command  | `brew update && brew upgrade`          | `apt update && apt upgrade` | `paru -Syu`             |
| Extra Features  | `bootout-gui` function, key repeat fix | French locale generation    | `reload-niri` function  |

See the platform-specific SPECS for complete details.

---

## Directory Structure

### Repository (before installation)

```
setup-config/
├── README.md           # Usage documentation
├── SPECS.md            # This file (high-level spec)
├── macos/
│   ├── SPECS.md        # macOS-specific specification
│   ├── install.sh      # macOS installation script
│   ├── uninstall.sh    # macOS uninstall script
│   └── dotfiles/       # Source dotfiles (copied to ~/.dotfiles)
│       ├── ghostty/
│       ├── nvim/
│       ├── sketchybar/
│       ├── tmux/
│       ├── yabai/
│       ├── zed/
│       └── zsh/
├── ubuntu/
│   ├── SPECS.md        # Ubuntu-specific specification
│   ├── install.sh      # Ubuntu installation script
│   ├── uninstall.sh    # Ubuntu uninstall script
│   └── dotfiles/       # Source dotfiles (copied to ~/.dotfiles)
│       ├── ghostty/
│       ├── nvim/
│       ├── tmux/
│       ├── zed/
│       └── zsh/
└── archlinux/
    ├── SPECS.md        # Arch Linux-specific specification
    ├── install.sh      # Arch Linux installation script
    ├── uninstall.sh    # Arch Linux uninstall script
    └── dotfiles/       # Source dotfiles (copied to ~/.dotfiles)
        ├── ghostty/
        ├── niri/
        ├── nvim/
        ├── tmux/
        ├── waybar/
        ├── zed/
        └── zsh/
```

### After Installation

The repository can be deleted. Your dotfiles live in:

```
~/.dotfiles/           # Your dotfiles (stow source)
├── ghostty/
├── niri/              # Arch Linux only
├── nvim/
├── sketchybar/        # macOS only
├── tmux/
├── waybar/            # Arch Linux only
├── yabai/             # macOS only
├── zed/
└── zsh/
```

Symlinks point from your home directory to `~/.dotfiles`.

---

## Uninstallation

Each platform includes an uninstall script to remove everything installed by the setup:

```bash
# macOS
bash macos/uninstall.sh

# Ubuntu
bash ubuntu/uninstall.sh

# Arch Linux
bash archlinux/uninstall.sh
```

The uninstall scripts will:

1. Unstow all dotfiles from `~/.dotfiles` (remove symlinks)
2. Remove Oh My Zsh and all plugins
3. Remove Oh My Tmux and tmux configuration
4. Remove LazyVim/Neovim configuration, data, and cache
5. Remove Ghostty configuration
6. Remove Homebrew packages installed by setup
7. Optionally remove Homebrew itself
8. Optionally remove `~/.dotfiles` directory
9. Clean up empty directories

The scripts are interactive and will ask for confirmation before proceeding.
