# Ubuntu Development Environment Specification

This document describes the Ubuntu-specific development environment configuration. For the general philosophy and shared specifications, see the root [SPECS.md](../SPECS.md).

---

## Package Managers

### apt (System Dependencies)

Used for essential system packages required before Homebrew:

| Package         | Description              |
| --------------- | ------------------------ |
| build-essential | C/C++ build tools        |
| procps          | Process utilities        |
| curl            | URL transfer tool        |
| file            | File type detection      |
| git             | Version control          |
| zsh             | Shell                    |
| stow            | Dotfiles symlink manager |

### Homebrew (Linuxbrew)

**Primary package manager** for up-to-date developer tools.

- Installation: `NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Location: `/home/linuxbrew/.linuxbrew` (system-wide) or `$HOME/.linuxbrew` (user)
- Shell environment: `eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"`

**Why Homebrew on Linux?**

- `apt` package versions are often outdated
- Homebrew provides up-to-date packages
- Handles architecture (amd64/arm64) automatically
- Consistent experience across macOS and Linux

### Packages Installed via Homebrew

| Package          | Description             |
| ---------------- | ----------------------- |
| git              | Version control         |
| zsh              | Shell                   |
| tmux             | Terminal multiplexer    |
| neovim           | Text editor             |
| go               | Go programming language |
| llvm             | C/C++ toolchain (clang) |
| zoxide           | Smart directory jumping |
| eza              | Modern ls replacement   |
| fd               | Modern find replacement |
| fzf              | Fuzzy finder            |
| ripgrep          | Modern grep replacement |
| bat              | Modern cat replacement  |
| lazygit          | Git TUI                 |
| btop             | Resource monitor        |
| fastfetch        | System info display     |
| sst/tap/opencode | AI coding assistant     |

### Cask Applications (via Community Scripts)

| Application | Installation Method    | Description        |
| ----------- | ---------------------- | ------------------ |
| Ghostty     | Community script       | Terminal emulator  |
| Zed         | Official Linux install | Modern code editor |

---

## Dotfiles Structure (Stow Packages)

During installation, dotfiles are copied from `ubuntu/dotfiles/` to `~/.dotfiles` and stowed from there. This allows you to delete the repository after installation.

**Source (in repo):** `ubuntu/dotfiles/`
**Destination (on system):** `~/.dotfiles/`

After installation, your `~/.dotfiles` contains:

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

## Ghostty Configuration

**Installation:** Via community script (not available in Homebrew for Linux)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
```

**Location:** `~/.config/ghostty/config` (symlinked from `~/.dotfiles/ghostty/`)

### Settings

| Setting              | Value             | Description                           |
| -------------------- | ----------------- | ------------------------------------- |
| `fullscreen`         | `true`            | Start in fullscreen mode              |
| `background`         | `#000000`         | Black background                      |
| `background-opacity` | `0.75`            | 75% window opacity                    |
| `background-blur`    | `true`            | Enable background blur (Linux)        |
| `command`            | (tmux attach/new) | Auto-attach to or create tmux session |

### Config File

```
fullscreen=true
background = #000000
background-opacity = 0.75
background-blur = true
command = /bin/bash --noprofile --norc -c "/usr/bin/tmux has-session 2>/dev/null && /usr/bin/tmux attach-session -d || /usr/bin/tmux new-session"
```

Note: Uses `/usr/bin/tmux` path for system tmux or adjust to Homebrew path if needed. The `background-blur = true` setting enables background blur on Linux (compositor support required).

---

## Zed Configuration

**Installation:** Via official Zed Linux installer

```bash
curl -fsSL https://zed.dev/install.sh | sh
```

**Location:** `~/.config/zed/settings.json` (symlinked from `~/.dotfiles/zed/`)

Zed is a modern, high-performance code editor. Key settings include:

- **Theme:** Zedokai Darker Classic (dark mode)
- **Autosave:** Enabled with 2-second delay
- **Font sizes:** UI 18, Buffer 16
- **Agent:** Configured with Claude Opus 4.5 as default model
- **Edit Predictions:** Enabled with Zed provider
- **Git Panel:** Icon-based status, docked left
- **Project Panel:** Docked right
- **Minimap:** Disabled
- **Inline Diagnostics:** Enabled

---

## Zsh Configuration

### Oh My Zsh

- **Installation:** `~/.oh-my-zsh/`
- **Theme:** `refined`
- **Plugins:** `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `vi-mode`, `zieds`

### Custom Plugin (`zieds.plugin.zsh`)

**Location:** `~/.oh-my-zsh/custom/plugins/zieds/zieds.plugin.zsh` (symlinked from `~/.dotfiles/zsh/`)

Ubuntu-specific features:

- `use-tmux()` uses `/usr/bin/tmux`
- `update()` runs `sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean`
- PATH includes Homebrew: `$(brew --prefix)/bin:$(brew --prefix)/sbin`

### .zshrc

Generated by the install script:

```zsh
# Managed by setup-config
export ZSH="$HOME/.oh-my-zsh"

# Homebrew setup for Linux
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew" ]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi

ZSH_THEME="refined"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting vi-mode zieds)
source $ZSH/oh-my-zsh.sh
```

---

## tmux Configuration

### Oh My Tmux

- **Repository:** `https://github.com/gpakosz/.tmux.git`
- **Installation Location:** `~/.oh-my-tmux/`
- **Main Config:** `~/.config/tmux/tmux.conf` → symlink to `~/.oh-my-tmux/.tmux.conf`
- **Local Config:** `~/.config/tmux/tmux.conf.local` (stowed)

### Custom tmux.conf.local

**Location:** `~/.config/tmux/tmux.conf.local` (symlinked from `~/.dotfiles/tmux/`)

```tmux
# tmux.conf.local - Custom configuration for Oh My Tmux
# Managed by setup-config (stowed)

# -- Custom settings from setup-config ----------------------------------------

# Set ZSH as the default shell
set-option -g default-shell /bin/zsh
```

---

## Neovim Configuration

### LazyVim

- **Repository:** `https://github.com/LazyVim/starter`
- **Installation Location:** `~/.config/nvim/`
- **Custom Plugins:** Stowed into `~/.config/nvim/lua/plugins/`

### Custom Plugins (Stowed)

**auto-save.lua:**

```lua
return {
  "Pocco81/auto-save.nvim",
  lazy = false,
  opts = {
    debounce_delay = 500,
    execution_message = {
      message = function()
        return ""
      end,
    },
  },
  keys = {
    { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
  },
}
```

**colorscheme.lua:**

```lua
return {
    { "tanvirtin/monokai.nvim" },
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "monokai",
        },
    },
}
```

---

## Locale Configuration

French locale is configured:

```bash
sudo locale-gen fr_FR.UTF-8
```

Environment variables set in zieds plugin:

```bash
export LANG="fr_FR.UTF-8"
export LC_ALL="fr_FR.UTF-8"
```

---

## Path Configuration

The following paths are configured:

- Homebrew: `/home/linuxbrew/.linuxbrew/bin` or `$HOME/.linuxbrew/bin`
- Go binaries: `$(go env GOPATH)/bin`
- Homebrew sbin: `$(brew --prefix)/sbin`

---

## Installation

```bash
bash ubuntu/install.sh
```

The script is idempotent - running it multiple times is safe.

---

## Post-Installation

1. Log out and back in for shell changes to take effect
2. Run `source ~/.zshrc` to apply Zsh configuration
3. Open Neovim and run `:Lazy sync` to install plugins
4. You can now safely delete the `setup-config` repository — dotfiles are in `~/.dotfiles`

---

## Uninstallation

To remove everything installed by the setup script:

```bash
bash ubuntu/uninstall.sh
```

The uninstall script will:

1. **Unstow all dotfiles** - Remove symlinks for ghostty, nvim, tmux, zed, and zsh
2. **Remove Oh My Zsh** - Including all plugins and managed `.zshrc`
3. **Remove Oh My Tmux** - And tmux configuration directory
4. **Remove LazyVim** - Including Neovim data, state, and cache
5. **Remove Ghostty configuration** - Note: Ghostty binary may need manual removal
6. **Remove Homebrew packages** - All packages installed by the setup (except git/zsh/stow)
7. **Optionally remove Homebrew** - Including Linuxbrew directories
8. **Optionally remove apt packages** - stow and rsync packages
9. **Optionally remove ~/.dotfiles** - Remove the dotfiles directory

**Note:** The script will ask for confirmation before proceeding.
