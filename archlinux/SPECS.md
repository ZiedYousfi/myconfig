# Arch Linux Development Environment Specification

This document describes the Arch Linux-specific development environment configuration. For the general philosophy and shared specifications, see the root [SPECS.md](../SPECS.md).

---

## Package Manager

**pacman** is the primary package manager for Arch Linux, with **yay** (AUR helper) for community packages.

### Packages Installed via pacman

| Package     | Description              |
| ----------- | ------------------------ |
| base-devel  | Build tools              |
| git         | Version control          |
| stow        | Dotfiles symlink manager |
| zsh         | Shell                    |
| tmux        | Terminal multiplexer     |
| neovim      | Text editor              |
| go          | Go programming language  |
| clang       | C/C++ toolchain          |
| zoxide      | Smart directory jumping  |
| eza         | Modern ls replacement    |
| fd          | Modern find replacement  |
| fzf         | Fuzzy finder             |
| ripgrep     | Modern grep replacement  |
| bat         | Modern cat replacement   |
| lazygit     | Git TUI                  |
| btop        | Resource monitor         |
| fastfetch   | System info display      |
| niri        | Scrollable tiling WM     |
| waybar      | Wayland status bar       |
| ttf-hack-nerd | Hack Nerd Font         |
| wireplumber | Audio session manager    |
| pipewire-pulse | PipeWire PulseAudio  |

### Packages Installed via yay (AUR)

| Package   | Description           |
| --------- | --------------------- |
| ghostty   | Terminal emulator     |
| zed-editor | Modern code editor   |
| opencode-bin | AI coding assistant |

---

## Tiling Window Manager: Niri

**Location:** `~/.config/niri/config.kdl` (symlinked from `~/.dotfiles/niri/`)

Niri is a scrollable-tiling Wayland compositor. Our configuration mirrors the Yabai setup on macOS.

### Layout Settings

| Setting              | Value     | Description                        |
| -------------------- | --------- | ---------------------------------- |
| `gaps`               | `12`      | Gap between windows in pixels      |
| `struts.top`         | `32`      | Reserve space for Waybar           |
| `focus-follows-mouse`| `true`    | Focus window under cursor          |
| `default-column-width` | `proportion 0.5` | Default window width      |

### Window Appearance

| Setting                    | Value   | Description                      |
| -------------------------- | ------- | -------------------------------- |
| `border.width`             | `2`     | Border width in pixels           |
| `border.active.color`      | `#f92672` | Monokai pink for focused       |
| `border.inactive.color`    | `#272822` | Monokai background for unfocused |
| `inactive-window-opacity`  | `0.9`   | Unfocused windows at 90% opacity |

### Key Bindings

| Binding          | Action                    |
| ---------------- | ------------------------- |
| `Super+Return`   | Spawn terminal (Ghostty)  |
| `Super+D`        | Spawn launcher (fuzzel)   |
| `Super+Q`        | Close focused window      |
| `Super+H/J/K/L`  | Focus left/down/up/right  |
| `Super+Shift+H/J/K/L` | Move window          |
| `Super+1-9`      | Switch to workspace       |
| `Super+Shift+1-9`| Move window to workspace  |
| `Super+F`        | Toggle fullscreen         |
| `Super+Space`    | Toggle floating           |
| `Super+Shift+E`  | Exit Niri                 |

---

## Status Bar: Waybar

**Location:** `~/.config/waybar/` (symlinked from `~/.dotfiles/waybar/`)

Waybar is a highly customizable Wayland bar. Our configuration uses the Monokai Classic color theme to match Sketchybar on macOS.

### Bar Settings

| Setting       | Value        | Description                   |
| ------------- | ------------ | ----------------------------- |
| `position`    | `top`        | Bar at top of screen          |
| `height`      | `28`         | Bar height in pixels          |
| `layer`       | `top`        | Render above windows          |

### Color Scheme (Monokai Classic)

| Color      | Hex       | Usage                        |
| ---------- | --------- | ---------------------------- |
| Background | `#272822` | Bar background               |
| Foreground | `#f8f8f2` | Default text                 |
| Pink       | `#f92672` | Active workspace, highlights |
| Orange     | `#fd971f` | Battery icon                 |
| Green      | `#a6e22e` | Window title, volume icon    |
| Cyan       | `#66d9ef` | Clock icon                   |

### Bar Modules

| Position | Module          | Description                           |
| -------- | --------------- | ------------------------------------- |
| Left     | `niri/workspaces` | Workspace indicators                |
| Left     | `niri/window`   | Currently focused window (green)      |
| Center   | `clock`         | Time display with icon (cyan)         |
| Right    | `pulseaudio`    | System volume (green icon)            |
| Right    | `battery`       | Battery status (orange icon)          |

---

## Dotfiles Structure (Stow Packages)

During installation, dotfiles are copied from `archlinux/dotfiles/` to `~/.dotfiles` and stowed from there. This allows you to delete the repository after installation.

| Package   | Target                  | Contents                    |
| --------- | ----------------------- | --------------------------- |
| `niri`    | `~/.config/niri/`       | Window manager config       |
| `waybar`  | `~/.config/waybar/`     | Status bar config & styles  |

**Source (in repo):** `archlinux/dotfiles/`
**Destination (on system):** `~/.dotfiles/`

After installation, your `~/.dotfiles` contains:

```
~/.dotfiles/
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
├── niri/
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
├── tmux/
│   └── .config/
│       └── tmux/
│           └── tmux.conf.local
├── waybar/
│   └── .config/
│       └── waybar/
│           ├── config
│           └── style.css
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

**Installation:** Via AUR (`yay -S ghostty`)

**Location:** `~/.config/ghostty/config` (symlinked from `~/.dotfiles/ghostty/`)

```
fullscreen=true
background = #000000
font-size = 18
command = /bin/bash --noprofile --norc -c "/usr/bin/tmux has-session 2>/dev/null && /usr/bin/tmux attach-session -d || /usr/bin/tmux new-session"
```

---

## Zed Configuration

**Installation:** Via AUR (`yay -S zed-editor`)

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

Arch Linux-specific features:

- `use-tmux()` uses `/usr/bin/tmux`
- `update()` runs `yay -Syu` for full system upgrade including AUR
- PATH includes Go binaries

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

## Locale Configuration

French locale is configured:

```bash
sudo locale-gen fr_FR.UTF-8
```

Ensure `/etc/locale.gen` contains:
```
fr_FR.UTF-8 UTF-8
```

Environment variables set in zieds plugin:

```bash
export LANG="fr_FR.UTF-8"
export LC_ALL="fr_FR.UTF-8"
```

---

## Path Configuration

The following paths are configured:

- Go binaries: `$(go env GOPATH)/bin`

---

## Installation

```bash
bash archlinux/install.sh
```

The script is idempotent - running it multiple times is safe.

---

## Post-Installation

1. Log out and back in for Niri/Waybar to start with new configuration
2. Run `source ~/.zshrc` to apply Zsh configuration
3. Open Neovim and run `:Lazy sync` to install plugins
4. You can now safely delete the `setup-config` repository — dotfiles are in `~/.dotfiles`

---

## Uninstallation

To remove everything installed by the setup script:

```bash
bash archlinux/uninstall.sh
```

The uninstall script will:

1. **Unstow all dotfiles** - Remove symlinks for all stow packages
2. **Remove Oh My Zsh** - Including all plugins and managed `.zshrc`
3. **Remove Oh My Tmux** - And tmux configuration directory
4. **Remove LazyVim** - Including Neovim data, state, and cache
5. **Remove Ghostty configuration**
6. **Remove Niri configuration**
7. **Remove Waybar configuration**
8. **Optionally remove AUR packages** - ghostty, zed-editor, opencode-bin
9. **Optionally remove ~/.dotfiles** - Remove the dotfiles directory

**Note:** The script will ask for confirmation before proceeding.
