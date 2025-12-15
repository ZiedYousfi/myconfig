# Development Environment Specification

This document describes the desired development environment in a declarative, platform-agnostic way. For platform-specific details, see:

- [macOS Specification](macos/SPECS.md)
- [Ubuntu Specification](ubuntu/SPECS.md)

---

## Philosophy

### Single Command Installation

The entire setup should be installable by running **a single script**. The goal is to minimize the number of steps required to go from a fresh system to a fully configured development environment.

### Idempotency

Running the setup multiple times must be safe and produce the same result. Tools already installed should be skipped.

### Dotfiles Management with GNU Stow

All configuration files are managed using [GNU Stow](https://www.gnu.org/software/stow/), which creates symlinks from your home directory to the actual config files in this repository. This enables:

- **Easy modification:** Edit files directly in the repository
- **Version control:** All configs stay in git
- **Clean separation:** Each application is a separate stow package
- **Portability:** Clone the repo and stow on any machine

---

## Stow Package Structure

Each platform has a `dotfiles/` directory containing stow packages:

| Package   | Target                               | Contents                        |
| --------- | ------------------------------------ | ------------------------------- |
| `ghostty` | `~/.config/ghostty/`                 | Terminal emulator configuration |
| `nvim`    | `~/.config/nvim/lua/plugins/`        | Custom Neovim plugins           |
| `tmux`    | `~/.config/tmux/`                    | Custom tmux configuration       |
| `zsh`     | `~/.oh-my-zsh/custom/plugins/zieds/` | Custom Zsh plugin               |

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

### Multiplexer: tmux + Oh My Tmux

- **Framework:** Oh My Tmux (`https://github.com/gpakosz/.tmux.git`)
- **Setup:** Clone to `~/.oh-my-tmux/`, symlink main config, stow custom config
- **Custom Config:** Sets Zsh as default shell

### Editor: Neovim + LazyVim

- **Distribution:** LazyVim (`https://github.com/LazyVim/starter`)
- **Custom Plugins (stowed):**
  - `auto-save.lua` - Automatic file saving
  - `colorscheme.lua` - Monokai color scheme

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

| Aspect          | macOS                                  | Ubuntu                      |
| --------------- | -------------------------------------- | --------------------------- |
| Package Manager | Homebrew                               | apt + Homebrew (Linuxbrew)  |
| Ghostty Install | Homebrew cask                          | Community script            |
| tmux Path       | `/opt/homebrew/bin/tmux`               | `/usr/bin/tmux`             |
| Update Command  | `brew update && brew upgrade`          | `apt update && apt upgrade` |
| Extra Features  | `bootout-gui` function, key repeat fix | French locale generation    |

See the platform-specific SPECS for complete details.

---

## Directory Structure

```
setup-config/
├── README.md           # Usage documentation
├── SPECS.md            # This file (high-level spec)
├── macos/
│   ├── SPECS.md        # macOS-specific specification
│   ├── install.sh      # macOS installation script
│   ├── uninstall.sh    # macOS uninstall script
│   └── dotfiles/       # Stow packages for macOS
│       ├── ghostty/
│       ├── nvim/
│       ├── tmux/
│       └── zsh/
└── ubuntu/
    ├── SPECS.md        # Ubuntu-specific specification
    ├── install.sh      # Ubuntu installation script
    ├── uninstall.sh    # Ubuntu uninstall script
    └── dotfiles/       # Stow packages for Ubuntu
        ├── ghostty/
        ├── nvim/
        ├── tmux/
        └── zsh/
```

---

## Uninstallation

Each platform includes an uninstall script to remove everything installed by the setup:

```bash
# macOS
bash macos/uninstall.sh

# Ubuntu
bash ubuntu/uninstall.sh
```

The uninstall scripts will:

1. Unstow all dotfiles (remove symlinks)
2. Remove Oh My Zsh and all plugins
3. Remove Oh My Tmux and tmux configuration
4. Remove LazyVim/Neovim configuration, data, and cache
5. Remove Ghostty configuration
6. Remove Homebrew packages installed by setup
7. Optionally remove Homebrew itself
8. Clean up empty directories

The scripts are interactive and will ask for confirmation before proceeding.
