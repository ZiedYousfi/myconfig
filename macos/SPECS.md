# macOS Development Environment Specification

This document describes the macOS-specific development environment configuration. For the general philosophy and shared specifications, see the root [SPECS.md](../SPECS.md).

---

## Package Manager

**Homebrew** is the primary package manager for macOS.

- Installation: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`
- Shell environment: `eval "$(/opt/homebrew/bin/brew shellenv)"` (Apple Silicon) or `eval "$(/usr/local/bin/brew shellenv)"` (Intel)

### Packages Installed via Homebrew

| Package          | Type    | Description              |
| ---------------- | ------- | ------------------------ |
| git              | formula | Version control          |
| stow             | formula | Dotfiles symlink manager |
| zsh              | formula | Shell                    |
| tmux             | formula | Terminal multiplexer     |
| neovim           | formula | Text editor              |
| go               | formula | Go programming language  |
| llvm             | formula | C/C++ toolchain (clang)  |
| zoxide           | formula | Smart directory jumping  |
| eza              | formula | Modern ls replacement    |
| fd               | formula | Modern find replacement  |
| fzf              | formula | Fuzzy finder             |
| ripgrep          | formula | Modern grep replacement  |
| bat              | formula | Modern cat replacement   |
| lazygit          | formula | Git TUI                  |
| btop             | formula | Resource monitor         |
| fastfetch        | formula | System info display      |
| ghostty          | cask    | Terminal emulator        |
| zed              | cask    | Modern code editor       |
| sst/tap/opencode | formula | AI coding assistant      |
| yabai            | formula | Tiling window manager    |
| sketchybar       | formula | Custom macOS menu bar    |

---

## Dotfiles Structure (Stow Packages)

During installation, dotfiles are copied from `macos/dotfiles/` to `~/.dotfiles` and stowed from there. This allows you to delete the repository after installation.

| Package      | Target                  | Contents                    |
| ------------ | ----------------------- | --------------------------- |
| `sketchybar` | `~/.config/sketchybar/` | Bar configuration & plugins |
| `yabai`      | `~/.config/yabai/`      | Window manager config       |

**Source (in repo):** `macos/dotfiles/`
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
├── sketchybar/
│   └── .config/
│       └── sketchybar/
│           ├── sketchybarrc
│           └── plugins/
│               ├── battery.sh
│               ├── clock.sh
│               ├── front_app.sh
│               ├── space.sh
│               ├── switch_space.sh
│               └── volume.sh
├── tmux/
│   └── .config/
│       └── tmux/
│           └── tmux.conf.local
├── yabai/
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

---

## Yabai Configuration (Tiling Window Manager)

**Location:** `~/.config/yabai/yabairc` (symlinked from `~/.dotfiles/yabai/`)

Yabai is a tiling window manager for macOS that provides automatic window arrangement using binary space partitioning (BSP).

### Layout Settings

| Setting            | Value          | Description                        |
| ------------------ | -------------- | ---------------------------------- |
| `layout`           | `bsp`          | Binary space partitioning layout   |
| `window_gap`       | `12`           | Gap between windows in pixels      |
| `top_padding`      | `12`           | Padding from top edge              |
| `bottom_padding`   | `12`           | Padding from bottom edge           |
| `left_padding`     | `12`           | Padding from left edge             |
| `right_padding`    | `12`           | Padding from right edge            |
| `external_bar`     | `all:25:0`     | Reserve 25px at top for Sketchybar |
| `window_placement` | `second_child` | New windows spawn as second child  |

### Window Appearance

| Setting                 | Value   | Description                      |
| ----------------------- | ------- | -------------------------------- |
| `window_shadow`         | `float` | Shadows only on floating windows |
| `window_opacity`        | `on`    | Enable window transparency       |
| `active_window_opacity` | `1.0`   | Focused window fully opaque      |
| `normal_window_opacity` | `0.9`   | Unfocused windows at 90% opacity |

### Mouse Settings

| Setting          | Value | Description                       |
| ---------------- | ----- | --------------------------------- |
| `mouse_modifier` | `alt` | Hold Alt to interact with windows |

---

## Sketchybar Configuration (Menu Bar)

**Location:** `~/.config/sketchybar/` (symlinked from `~/.dotfiles/sketchybar/`)

Sketchybar is a highly customizable macOS menu bar replacement. Our configuration uses the Monokai Classic color theme.

### Bar Settings

| Setting       | Value        | Description                   |
| ------------- | ------------ | ----------------------------- |
| `position`    | `top`        | Bar at top of screen          |
| `height`      | `28`         | Bar height in pixels          |
| `blur_radius` | `30`         | Background blur effect        |
| `color`       | `0xf0272822` | Monokai background with alpha |

### Font Configuration

| Element | Font                | Size |
| ------- | ------------------- | ---- |
| Icons   | Hack Nerd Font Bold | 14.0 |
| Labels  | Hack Nerd Font Bold | 12.0 |

### Color Scheme (Monokai Classic)

| Color      | Hex       | ARGB         | Usage                        |
| ---------- | --------- | ------------ | ---------------------------- |
| Background | `#272822` | `0xf0272822` | Bar background               |
| Foreground | `#ffffff` | `0xffffffff` | Default text                 |
| Pink       | `#f92672` | `0xfff92672` | Active space, highlights     |
| Orange     | `#fd971f` | `0xfffd971f` | Battery icon                 |
| Green      | `#a6e22e` | `0xffa6e22e` | Front app label, volume icon |
| Cyan       | `#66d9ef` | `0xff66d9ef` | Chevron, clock icon          |

### Bar Items

| Position | Item        | Description                           |
| -------- | ----------- | ------------------------------------- |
| Left     | Spaces 1-10 | Mission Control space indicators      |
| Left     | Chevron     | Separator icon (cyan)                 |
| Left     | Front App   | Currently focused application (green) |
| Center   | Clock       | Time display with icon (cyan)         |
| Right    | Volume      | System volume (green icon)            |
| Right    | Battery     | Battery status (orange icon)          |

### Plugin Scripts

| Script            | Purpose                        |
| ----------------- | ------------------------------ |
| `space.sh`        | Handle space indicator updates |
| `switch_space.sh` | Switch to clicked space        |
| `front_app.sh`    | Update front app display       |
| `clock.sh`        | Update time display            |
| `volume.sh`       | Handle volume changes          |
| `battery.sh`      | Update battery status          |

---

## Ghostty Configuration

**Location:** `~/.config/ghostty/config` (symlinked from `~/.dotfiles/ghostty/`)

```
fullscreen=true
background = #000000
command = /bin/bash --noprofile --norc -c "/opt/homebrew/bin/tmux has-session 2>/dev/null && /opt/homebrew/bin/tmux attach-session -d || /opt/homebrew/bin/tmux new-session"
```

Note: Uses `/opt/homebrew/bin/tmux` path for Apple Silicon Macs.

---

## Zed Configuration

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

macOS-specific features:

- `use-tmux()` uses `/opt/homebrew/bin/tmux`
- `update()` runs `brew update && brew upgrade && brew cleanup`
- `bootout-gui()` function: `launchctl bootout gui/$UID`

### .zshrc

Generated by the install script:

```zsh
# Managed by setup-config
export ZSH="$HOME/.oh-my-zsh"
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

## macOS-Specific System Settings

Applied by the install script:

```bash
# Disable press-and-hold for key repeat (enables key repeat in all apps)
defaults write -g ApplePressAndHoldEnabled -bool false
```

---

## Path Configuration

The following paths are configured:

- Homebrew: `/opt/homebrew/bin` (Apple Silicon) or `/usr/local/bin` (Intel)
- Go binaries: `$(go env GOPATH)/bin`

---

## Installation

```bash
bash macos/install.sh
```

The script is idempotent - running it multiple times is safe.

---

## Post-Installation

1. Restart terminal or run `source ~/.zshrc`
2. Open Neovim and run `:Lazy sync` to install plugins
3. Log out and back in for macOS settings to take effect
4. You can now safely delete the `setup-config` repository — dotfiles are in `~/.dotfiles`

---

## Uninstallation

To remove everything installed by the setup script:

```bash
bash macos/uninstall.sh
```

The uninstall script will:

1. **Unstow all dotfiles** - Remove symlinks for ghostty, nvim, tmux, and zsh
2. **Remove Oh My Zsh** - Including all plugins and managed `.zshrc`
3. **Remove Oh My Tmux** - And tmux configuration directory
4. **Remove LazyVim** - Including Neovim data, state, and cache
5. **Remove Ghostty configuration**
6. **Remove Homebrew packages** - All packages installed by the setup (except git/zsh)
7. **Restore macOS settings** - Re-enable press-and-hold for key repeat
8. **Optionally remove Homebrew** - If you want a complete cleanup
9. **Optionally remove ~/.dotfiles** - Remove the dotfiles directory

**Note:** The script will ask for confirmation before proceeding.
