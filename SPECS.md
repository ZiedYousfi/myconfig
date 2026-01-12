# Configuration Specifications

> A modular configuration bank for building reproducible development environments across platforms.

This document defines all components of the development environment, organized by category.
Platform-specific implementations are documented in their respective sections.

---

## Table of Contents

- [Shell](#shell)
- [Terminal Emulator](#terminal-emulator)
- [CLI Tools](#cli-tools)
- [File Manager](#file-manager)
- [Editors](#editors)
- [Desktop Environment](#desktop-environment)
- [Development Languages & Runtimes](#development-languages--runtimes)
- [Platform-Specific: macOS](#platform-specific-macos)
- [Platform-Specific: Ubuntu Server](#platform-specific-ubuntu-server)
- [Platform-Specific: Windows](#platform-specific-windows)

---

## Shell

### Zsh

The primary shell is **Zsh** with **Oh My Zsh** framework.

| Component | Value |
|-----------|-------|
| Shell | `zsh` |
| Framework | Oh My Zsh |
| Theme | `refined` |
| Config location | `~/.zshrc` |

#### Plugins

| Plugin | Source | Description |
|--------|--------|-------------|
| `git` | Built-in | Git aliases and completions |
| `vi-mode` | Built-in | Vi keybindings in shell |
| `zsh-autosuggestions` | [zsh-users/zsh-autosuggestions](https://github.com/zsh-users/zsh-autosuggestions) | Fish-like autosuggestions |
| `zsh-syntax-highlighting` | [zsh-users/zsh-syntax-highlighting](https://github.com/zsh-users/zsh-syntax-highlighting) | Syntax highlighting |
| `zieds` | Custom (stowed) | Personal aliases, functions, and environment |

#### Custom Plugin: `zieds`

Location: `~/.oh-my-zsh/custom/plugins/zieds/zieds.plugin.zsh`

**Environment Variables:**

```bash
XDG_CONFIG_HOME="$HOME/.config"
XDG_CACHE_HOME="$HOME/.cache"
EDITOR="nvim"
VISUAL="nvim"
TERM="xterm-256color"
VI_MODE_SET_CURSOR=true
LANG="en_US.UTF-8"
LC_ALL="en_US.UTF-8"
```

**Key Aliases:**

| Alias | Command | Description |
|-------|---------|-------------|
| `vim`, `vi`, `v` | `nvim` | Neovim as default editor |
| `ls` | `eza --icons --group-directories-first --git` | Modern ls replacement |
| `find` | `fd` | Fast find alternative |
| `grep` | `rg` | Ripgrep with smart defaults |
| `lg` | `lazygit` | Terminal UI for git |
| `ff` | `fastfetch` | System info display |
| `pip`, `pip3` | `uv pip` | Use uv for Python packages |
| `npm` | `bun` | Use Bun for npm |
| `npx` | `bunx` | Use Bun for npx |

**Key Functions:**

| Function | Description |
|----------|-------------|
| `y` | Yazi file manager wrapper (changes directory on exit) |
| `pf` | Fuzzy file picker with preview, opens in nvim |
| `mkd` | Create directory and cd into it |
| `use-tmux` | Attach or create tmux session |
| `reload-zsh` | Reload zsh configuration |
| `stowgo` | Create and stow a new dotfiles package |
| `update` | Update system packages |
| `cleanup` | Interactive cleanup utility |

#### Dotfiles Structure

```
zsh/
└── .oh-my-zsh/
    └── custom/
        └── plugins/
            └── zieds/
                └── zieds.plugin.zsh
```

---

## Terminal Emulator

### Ghostty

Modern, GPU-accelerated terminal emulator.

| Setting | Value |
|---------|-------|
| Background | `#000000` |
| Opacity | `0.75` (75%) |
| Background blur | `true` |
| Font size | `18` |
| Default command | Auto-attach to tmux session |

#### Dotfiles Structure

```
ghostty/
└── .config/
    └── ghostty/
        └── config
```

---

## CLI Tools

### Core Utilities

| Tool | Purpose | Replaces |
|------|---------|----------|
| `eza` | Modern ls with icons and git integration | `ls` |
| `fd` | Fast, user-friendly find | `find` |
| `ripgrep` (rg) | Fast recursive grep | `grep` |
| `bat` | Cat with syntax highlighting | `cat` |
| `fzf` | Fuzzy finder | - |
| `zoxide` | Smart cd with frecency | `cd` |
| `btop` | Resource monitor | `top`, `htop` |
| `fastfetch` | System information display | `neofetch` |
| `1password-cli` | 1Password command-line interface | - |
| `jq` | JSON processor | - |

### Git Tools

| Tool | Purpose |
|------|---------|
| `git` | Version control |
| `lazygit` | Terminal UI for git |

### Tmux

Terminal multiplexer with **Oh My Tmux** configuration.

| Component | Value |
|-----------|-------|
| Framework | [Oh My Tmux](https://github.com/gpakosz/.tmux) |
| Theme | Monokai (custom) |
| Default shell | `/bin/zsh` |
| Config location | `$XDG_CONFIG_HOME/tmux/` |

**Theme Colors (Monokai):**

| Element | Color |
|---------|-------|
| Background | `#272822` |
| Foreground | `#FFFFFF` |
| Accent (Pink) | `#F92672` |
| Green | `#A6E22E` |
| Orange | `#FD971F` |

#### Dotfiles Structure

```
tmux/
└── .config/
    └── tmux/
        └── tmux.conf.local
```

---

## File Manager

### Yazi

Terminal file manager with image preview support.

| Setting | Value |
|---------|-------|
| Theme | Monokai (via `ya pkg`) |
| Flavor source | `malick-tammal/monokai` |

**Dependencies:**

- `ffmpeg` - Video thumbnails
- `sevenzip` - Archive preview
- `poppler` - PDF preview
- `resvg` - SVG rendering
- `imagemagick` - Image processing
- `font-symbols-only-nerd-font` - Icons

#### Dotfiles Structure

```
yazi/
└── .config/
    └── yazi/
        ├── theme.toml
        └── flavors/
            └── .gitkeep
```

---

## Editors

### Neovim

Primary terminal-based editor.

| Component | Value |
|-----------|-------|
| Distribution | [LazyVim](https://www.lazyvim.org/) |
| Theme | Monokai (`tanvirtin/monokai.nvim`) |
| Config location | `$XDG_CONFIG_HOME/nvim/` |

**Custom Plugins:**

| Plugin | Purpose |
|--------|---------|
| `auto-save.lua` | Automatic file saving |
| `colorscheme.lua` | Monokai theme configuration |

#### Dotfiles Structure

```
nvim/
└── .config/
    └── nvim/
        └── lua/
            └── plugins/
                ├── auto-save.lua
                └── colorscheme.lua
```

### Zed

Modern GUI editor with AI integration.

| Setting | Value |
|---------|-------|
| Theme (dark) | Zedokai Darker Classic |
| Theme (light) | One Light |
| UI Font Size | 18 |
| Buffer Font Size | 16 |
| Autosave | 2000ms delay |
| Format on save | Enabled |
| Icon theme | Catppuccin Latte |

**AI Configuration:**

| Feature | Provider | Model |
|---------|----------|-------|
| Default model | Copilot Chat | `claude-opus-4.5` |
| Inline assistant | OpenRouter | `openai/gpt-oss-120b` |
| Commit messages | OpenRouter | `openai/gpt-oss-120b` |
| Edit predictions | Zed | Built-in |

#### Dotfiles Structure

```
zed/
└── .config/
    └── zed/
        ├── settings.json
        └── themes/
```

### Visual Studio Code

GUI editor with extensive extension ecosystem. Visual Studio Code is used **natively** on Windows.

**Key Extensions:**

| Category | Extensions |
|----------|------------|
| AI | `github.copilot`, `github.copilot-chat` |
| Git | `github.vscode-pull-request-github`, `donjayamanne.githistory` |
| Languages | `golang.go`, `ms-python.python`, `llvm-vs-code-extensions.vscode-clangd` |
| Containers | `ms-azuretools.vscode-docker`, `ms-azuretools.vscode-containers` |
| .NET | `ms-dotnettools.csdevkit`, `ms-dotnettools.csharp` |
| Formatting | `esbenp.prettier-vscode`, `cheshirekow.cmake-format` |
| Linting | `dbaeumer.vscode-eslint`, `davidanson.vscode-markdownlint` |

---

## Desktop Environment

Components that form the visual desktop experience.

### Window Management

Tiling window manager for efficient workspace organization.

**Expected Features:**

- Binary space partitioning (BSP) layout
- Window gaps and padding
- Keyboard-driven window control
- Mouse modifier support
- Window opacity (focused vs unfocused)
- Per-application rules

### Status Bar

System status bar displaying:

- Workspace/space indicators
- Active application
- System stats (CPU, RAM, Battery)
- Date and time
- Volume control
- Quick actions (restart WM, mission control/spaces overview)

**Theme:** Monokai

| Element | Color (Hex) |
|---------|-------------|
| Background | `#272822` |
| Pink (accent) | `#F92672` |
| Orange | `#FD971F` |
| Green | `#A6E22E` |
| Cyan | `#66D9EF` |

---

## Development Languages & Runtimes

| Language/Runtime | Tool | Purpose |
|------------------|------|---------|
| Python | `python`, `uv` | Python development, package management |
| Go | `go` | Go development |
| Rust | `rustup-init` | Rust toolchain |
| JavaScript/TypeScript | `bun` | Fast JS runtime & package manager |
| Java | `openjdk`, `maven` | Java development |
| C/C++ | `llvm` | Compiler toolchain |
| Build tools | `meson`, `conan` | C/C++ build systems |

---

## Platform-Specific: macOS

This section documents components specific to macOS.

### Window Management: Yabai

[Yabai](https://github.com/koekeishiya/yabai) - Tiling window manager for macOS.

| Setting | Value |
|---------|-------|
| Layout | BSP (Binary Space Partitioning) |
| Window gap | 20px |
| Padding (all sides) | 20px |
| External bar | Bottom, 30px height |
| Window placement | Second child |
| Mouse modifier | `alt` |
| Window shadows | Float only |
| Active window opacity | 1.0 |
| Inactive window opacity | 0.5 |

**Installation:** `brew install asmvik/formulae/yabai`

**Requirements:**

- Accessibility permissions
- SIP configuration for full functionality

#### Dotfiles Structure

```
yabai/
└── .config/
    └── yabai/
        └── yabairc
```

### Status Bar: Sketchybar

[Sketchybar](https://github.com/FelixKratz/SketchyBar) - Highly customizable macOS status bar.

| Setting | Value |
|---------|-------|
| Position | Bottom |
| Height | 34px |
| Blur radius | 30 |
| Theme | Monokai |
| Font | Hack Nerd Font |

**Components:**

| Item | Position | Description |
|------|----------|-------------|
| Restart WM | Left | Restart Yabai/Sketchybar |
| Mission Control | Left | Open Mission Control |
| Space indicators | Left | Workspace switcher (1-10) |
| Front app | Center | Currently focused application |
| CPU/RAM | Right | System statistics |
| Volume | Right | Audio control |
| Battery | Right | Battery status |
| Clock | Right | Date and time |

**Dependencies:**

- `sketchybar-system-stats` - CPU/RAM stats provider

**Plugin Scripts:**

- `battery.sh` - Battery status
- `clock.sh` - Time display
- `cpu.sh` - CPU usage
- `ram.sh` - Memory usage
- `front_app.sh` - Active application
- `volume.sh` - Audio control
- `space.sh` - Workspace indicator
- `switch_space.sh` - Workspace switching
- `hover.sh` - Hover effects
- `mission_control.sh` - Mission Control trigger
- `restart_window_management.sh` - Restart services

#### Dotfiles Structure

```
sketchybar/
└── .config/
    └── sketchybar/
        ├── sketchybarrc
        └── plugins/
            ├── battery.sh
            ├── clock.sh
            ├── cpu.sh
            ├── front_app.sh
            ├── hover.sh
            ├── mission_control.sh
            ├── ram.sh
            ├── restart_window_management.sh
            ├── space.sh
            ├── switch_space.sh
            └── volume.sh
```

### macOS-Specific Shell Functions

Located in `zieds.plugin.zsh`:

| Function | Description |
|----------|-------------|
| `update` | Runs `brew update && brew upgrade && brew cleanup` |
| `bootout-gui` | Bootout current GUI session via launchctl |

### macOS-Specific Environment Variables

```bash
JAVA_HOME="/opt/homebrew/opt/openjdk"
PATH="$HOME/.local/bin:$PATH:$(go env GOPATH)/bin:$JAVA_HOME/bin"
VCPKG_ROOT="$HOME/vcpkg"
```

### Package Manager: Homebrew

All packages installed via Homebrew. See [macos/install.sh](macos/install.sh) for the complete installation script.

### Dotfiles Management: GNU Stow

Dotfiles are managed using GNU Stow:

- Source: `~/dotfiles/` (copied from repository)
- Target: `$HOME` (symlinked via stow)
- Mode: `--restow --no-folding`

---

## Platform-Specific: Ubuntu Server

This section documents components specific to Ubuntu Server (headless, no desktop environment).

### Package Manager: Homebrew

All packages are installed via Homebrew (Linuxbrew), providing access to up-to-date packages and a larger repository compared to apt.

See [ubuntu-server/install.sh](ubuntu-server/install.sh) for the complete installation script.

### Ubuntu-Specific Shell Functions

Located in `zieds.plugin.zsh` (platform detection is automatic):

| Function | Description |
|----------|-------------|
| `update` | Updates both system (apt) and Homebrew packages |
| `use-tmux` | Attach or create tmux session |

### Ubuntu-Specific Environment Variables

```bash
HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
JAVA_HOME="$HOMEBREW_PREFIX/opt/openjdk@21"
GOPATH="$HOME/go"
BUN_INSTALL="$HOME/.bun"
PATH="$HOME/.local/bin:$HOME/.cargo/bin:$GOPATH/bin:$JAVA_HOME/bin:$BUN_INSTALL/bin:$HOMEBREW_PREFIX/bin:$PATH"
VCPKG_ROOT="$HOME/vcpkg"
```

### Installed Packages

All packages are installed via Homebrew:

| Category | Packages |
|----------|----------|
| Core | `git`, `stow`, `zsh`, `tmux`, `curl`, `wget`, `gcc`, `unzip` |
| Languages | `python@3.12`, `go`, `rustup` (via curl), `bun` (via curl), `openjdk@21`, `llvm` |
| Build Tools | `maven`, `meson` (via uv), `conan` (via uv) |
| CLI Tools | `eza`, `fd`, `fzf`, `ripgrep`, `bat`, `zoxide`, `lazygit`, `btop`, `fastfetch`, `uv` (via curl) |
| File Manager | `yazi`, `ffmpeg`, `p7zip`, `jq`, `poppler`, `imagemagick` |

### What's NOT Included (Server Edition)

The Ubuntu Server installation does **not** include:

- Desktop environment components
- Yabai (macOS-only window manager)
- Sketchybar (macOS-only status bar)
- GUI applications (Ghostty, Zed, VS Code)

The dotfiles for Ghostty and Zed are still stowed (for future use if GUI is needed), but the applications themselves are not installed.

---

## Platform-Specific: Windows

This section documents components specific to Windows.

### Window Management: Glaze WM

[Glaze WM](https://github.com/glazewm/glazewm) - A tiling window manager for Windows inspired by i3.

| Setting | Value |
|---------|-------|
| Layout | Tiling |
| Command | `glazewm` |

### Status Bar: zebar

[zebar](https://github.com/glazewm/zebar) - A customizable status bar for Windows (usually paired with Glaze WM).

| Setting | Value |
|---------|-------|
| Theme | Monokai |

### Windows Subsystem for Linux (WSL)

For all development tools, shell, and CLI utilities, Windows utilizes the **Ubuntu configuration** through WSL.

- **Distribution:** Ubuntu
- **Configuration:** Shared with [Ubuntu Server](#platform-specific-ubuntu-server)
- **Integration:** VS Code (native) connects to WSL for development.

---

## Dotfiles Summary

### Repository Structure

```
setup-config/
├── SPECS.md                    # This specification document
├── dotfiles/                   # Shared cross-platform dotfiles
│   ├── ghostty/
│   ├── nvim/
│   ├── tmux/
│   ├── yazi/
│   ├── zed/
│   └── zsh/
├── macos/                      # macOS-specific
│   ├── install.sh
│   ├── uninstall.sh
│   └── dotfiles/               # macOS-only dotfiles
│       ├── sketchybar/
│       └── yabai/
└── ubuntu-server/               # Ubuntu Server & Windows (WSL) specific
    ├── install.sh
    └── uninstall.sh
```

### Cross-Platform (Shareable)

These dotfiles are located in `/dotfiles/` at the project root and can be used across different Unix-like systems:

| Package | Description | Target |
|---------|-------------|--------|
| `ghostty` | Terminal emulator config | `~/.config/ghostty/` |
| `nvim` | Neovim/LazyVim plugins | `~/.config/nvim/` |
| `tmux` | Tmux customization | `~/.config/tmux/` |
| `yazi` | File manager theme | `~/.config/yazi/` |
| `zed` | Zed editor settings | `~/.config/zed/` |
| `zsh` | Custom Oh My Zsh plugin | `~/.oh-my-zsh/custom/` |

### macOS-Specific

These dotfiles are located in `/macos/dotfiles/`:

| Package | Description | Target |
|---------|-------------|--------|
| `yabai` | Window manager config | `~/.config/yabai/` |
| `sketchybar` | Status bar config | `~/.config/sketchybar/` |

---

## Theme: Monokai

A consistent Monokai theme is applied across all components:

| Color | Hex | Usage |
|-------|-----|-------|
| Background | `#272822` | Dark backgrounds |
| Foreground | `#FFFFFF` | Primary text |
| Pink | `#F92672` | Accents, highlights |
| Orange | `#FD971F` | Warnings, secondary accents |
| Green | `#A6E22E` | Success, active states |
| Cyan | `#66D9EF` | Links, info |
| Yellow | `#E6DB74` | Strings, emphasis |

**Applied to:**

- Neovim (colorscheme)
- Tmux (status bar)
- Sketchybar (UI elements)
- Yazi (file manager flavor)
- Zed (Zedokai Darker Classic variant)
