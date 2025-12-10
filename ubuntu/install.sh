#!/bin/bash

# Ubuntu Development Environment Setup Script
# This script is idempotent - running it multiple times is safe

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLATFORM_CONFIG_DIR="$SCRIPT_DIR/config"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Ensure XDG directories exist
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

mkdir -p "$XDG_CONFIG_HOME"
mkdir -p "$XDG_CACHE_HOME"

# ============================================================================
# System Update
# ============================================================================

update_system() {
    log_info "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    log_success "System packages updated"
}

# ============================================================================
# APT Package Installation
# ============================================================================

install_apt_package() {
    local package="$1"
    if dpkg -l "$package" 2>/dev/null | grep -q "^ii"; then
        log_success "$package is already installed"
    else
        log_info "Installing $package..."
        sudo apt install -y "$package"
        log_success "$package installed"
    fi
}

install_base_packages() {
    log_info "Installing base packages via APT..."

    # Essential build tools and dependencies
    install_apt_package "build-essential"
    install_apt_package "curl"
    install_apt_package "wget"
    install_apt_package "git"
    install_apt_package "zsh"
    install_apt_package "tmux"
    install_apt_package "unzip"
    install_apt_package "fontconfig"
    install_apt_package "software-properties-common"

    # btop
    install_apt_package "btop"

    log_success "Base packages installed"
}

# ============================================================================
# Go Installation
# ============================================================================

install_go() {
    if command -v go &>/dev/null; then
        log_success "Go is already installed ($(go version))"
    else
        log_info "Installing Go..."
        local GO_VERSION="1.22.5"
        local GO_TARBALL="go${GO_VERSION}.linux-amd64.tar.gz"

        wget -q "https://go.dev/dl/${GO_TARBALL}" -O "/tmp/${GO_TARBALL}"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "/tmp/${GO_TARBALL}"
        rm "/tmp/${GO_TARBALL}"

        # Add to current session
        export PATH="$PATH:/usr/local/go/bin"

        log_success "Go ${GO_VERSION} installed"
    fi

    # Ensure Go is in PATH for this session
    export PATH="$PATH:/usr/local/go/bin"
    export PATH="$PATH:$(go env GOPATH)/bin"
}

# ============================================================================
# LLVM/Clang Installation
# ============================================================================

install_clang() {
    if command -v clang &>/dev/null; then
        log_success "Clang is already installed ($(clang --version | head -n1))"
    else
        log_info "Installing LLVM/Clang..."
        install_apt_package "clang"
        install_apt_package "llvm"
        log_success "LLVM/Clang installed"
    fi
}

# ============================================================================
# Neovim Installation (latest stable from GitHub releases)
# ============================================================================

install_neovim() {
    if command -v nvim &>/dev/null; then
        log_success "Neovim is already installed ($(nvim --version | head -n1))"
    else
        log_info "Installing Neovim..."

        # Install latest stable from GitHub releases
        local NVIM_VERSION="v0.10.1"
        wget -q "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux64.tar.gz" -O /tmp/nvim-linux64.tar.gz
        sudo rm -rf /opt/nvim
        sudo tar -C /opt -xzf /tmp/nvim-linux64.tar.gz
        sudo mv /opt/nvim-linux64 /opt/nvim
        sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
        rm /tmp/nvim-linux64.tar.gz

        log_success "Neovim ${NVIM_VERSION} installed"
    fi
}

# ============================================================================
# Modern CLI Tools Installation
# ============================================================================

install_zoxide() {
    if command -v zoxide &>/dev/null; then
        log_success "zoxide is already installed"
    else
        log_info "Installing zoxide..."
        curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
        # Move to /usr/local/bin if installed to ~/.local/bin
        if [ -f "$HOME/.local/bin/zoxide" ]; then
            sudo mv "$HOME/.local/bin/zoxide" /usr/local/bin/
        fi
        log_success "zoxide installed"
    fi
}

install_eza() {
    if command -v eza &>/dev/null; then
        log_success "eza is already installed"
    else
        log_info "Installing eza..."
        # Add eza repository
        sudo mkdir -p /etc/apt/keyrings
        wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
        echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
        sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
        sudo apt update
        sudo apt install -y eza
        log_success "eza installed"
    fi
}

install_fd() {
    if command -v fd &>/dev/null || command -v fdfind &>/dev/null; then
        log_success "fd is already installed"
    else
        log_info "Installing fd..."
        sudo apt install -y fd-find
        # Create symlink from fdfind to fd
        if [ ! -f /usr/local/bin/fd ] && command -v fdfind &>/dev/null; then
            sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
        fi
        log_success "fd installed"
    fi
}

install_fzf() {
    if command -v fzf &>/dev/null; then
        log_success "fzf is already installed"
    else
        log_info "Installing fzf..."
        sudo apt install -y fzf
        log_success "fzf installed"
    fi
}

install_ripgrep() {
    if command -v rg &>/dev/null; then
        log_success "ripgrep is already installed"
    else
        log_info "Installing ripgrep..."
        sudo apt install -y ripgrep
        log_success "ripgrep installed"
    fi
}

install_bat() {
    if command -v bat &>/dev/null || command -v batcat &>/dev/null; then
        log_success "bat is already installed"
    else
        log_info "Installing bat..."
        sudo apt install -y bat
        # Create symlink from batcat to bat on Ubuntu
        if [ ! -f /usr/local/bin/bat ] && command -v batcat &>/dev/null; then
            sudo ln -sf "$(which batcat)" /usr/local/bin/bat
        fi
        log_success "bat installed"
    fi
}

install_lazygit() {
    if command -v lazygit &>/dev/null; then
        log_success "lazygit is already installed"
    else
        log_info "Installing lazygit..."
        LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
        curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
        sudo tar -xzf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
        rm /tmp/lazygit.tar.gz
        log_success "lazygit installed"
    fi
}

install_fastfetch() {
    if command -v fastfetch &>/dev/null; then
        log_success "fastfetch is already installed"
    else
        log_info "Installing fastfetch..."
        # Try to install from apt first (available in newer Ubuntu versions)
        if apt-cache show fastfetch &>/dev/null; then
            sudo apt install -y fastfetch
        else
            # Install from GitHub releases
            FASTFETCH_VERSION=$(curl -s "https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest" | grep -Po '"tag_name": "\K[^"]*')
            curl -Lo /tmp/fastfetch.deb "https://github.com/fastfetch-cli/fastfetch/releases/download/${FASTFETCH_VERSION}/fastfetch-linux-amd64.deb"
            sudo dpkg -i /tmp/fastfetch.deb || sudo apt install -f -y
            rm /tmp/fastfetch.deb
        fi
        log_success "fastfetch installed"
    fi
}

install_modern_cli_tools() {
    log_info "Installing modern CLI tools..."

    install_zoxide
    install_eza
    install_fd
    install_fzf
    install_ripgrep
    install_bat
    install_lazygit
    install_fastfetch

    log_success "Modern CLI tools installed"
}

# ============================================================================
# Ghostty Installation
# ============================================================================

install_ghostty() {
    if command -v ghostty &>/dev/null; then
        log_success "Ghostty is already installed"
    else
        log_info "Installing Ghostty..."

        # Ghostty requires building from source on Linux
        # Dependencies
        sudo apt install -y libgtk-4-dev libadwaita-1-dev git

        # Check if zig is installed (needed to build Ghostty)
        if ! command -v zig &>/dev/null; then
            log_info "Installing Zig (required for Ghostty build)..."
            local ZIG_VERSION="0.13.0"
            wget -q "https://ziglang.org/download/${ZIG_VERSION}/zig-linux-x86_64-${ZIG_VERSION}.tar.xz" -O /tmp/zig.tar.xz
            sudo tar -xf /tmp/zig.tar.xz -C /opt
            sudo ln -sf "/opt/zig-linux-x86_64-${ZIG_VERSION}/zig" /usr/local/bin/zig
            rm /tmp/zig.tar.xz
            log_success "Zig installed"
        fi

        # Clone and build Ghostty
        if [ ! -d "/tmp/ghostty" ]; then
            git clone https://github.com/ghostty-org/ghostty.git /tmp/ghostty
        fi

        cd /tmp/ghostty
        zig build -Doptimize=ReleaseFast

        # Install binary
        sudo cp zig-out/bin/ghostty /usr/local/bin/

        # Install desktop file and icons if available
        if [ -f "dist/linux/ghostty.desktop" ]; then
            sudo cp dist/linux/ghostty.desktop /usr/share/applications/
        fi

        cd - > /dev/null
        rm -rf /tmp/ghostty

        log_success "Ghostty installed"
    fi
}

# ============================================================================
# OpenCode (SST) Installation
# ============================================================================

install_opencode() {
    if command -v opencode &>/dev/null; then
        log_success "opencode is already installed"
    else
        log_info "Installing opencode..."
        # Install via Go
        go install github.com/sst/opencode@latest
        log_success "opencode installed"
    fi
}

# ============================================================================
# Font Installation
# ============================================================================

install_fonts() {
    log_info "Installing Departure Mono Nerd Font..."

    local FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"

    if fc-list | grep -qi "Departure"; then
        log_success "Departure Mono Nerd Font is already installed"
    else
        # Download Departure Mono Nerd Font
        local NERD_FONTS_VERSION="v3.2.1"
        wget -q "https://github.com/ryanoasis/nerd-fonts/releases/download/${NERD_FONTS_VERSION}/DepartureMono.zip" -O /tmp/DepartureMono.zip

        unzip -q -o /tmp/DepartureMono.zip -d "$FONT_DIR"
        rm /tmp/DepartureMono.zip

        # Refresh font cache
        fc-cache -fv

        log_success "Departure Mono Nerd Font installed"
    fi
}

# ============================================================================
# Oh My Zsh Installation
# ============================================================================

install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_success "Oh My Zsh is already installed"
    else
        log_info "Installing Oh My Zsh..."
        RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
        log_success "Oh My Zsh installed"
    fi
}

install_zsh_plugins() {
    local ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

    # zsh-autosuggestions
    if [ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        log_success "zsh-autosuggestions is already installed"
    else
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
        log_success "zsh-autosuggestions installed"
    fi

    # zsh-syntax-highlighting
    if [ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        log_success "zsh-syntax-highlighting is already installed"
    else
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
        log_success "zsh-syntax-highlighting installed"
    fi

    # Custom zieds plugin (use Ubuntu-specific version)
    local ZIEDS_PLUGIN_DIR="$ZSH_CUSTOM/plugins/zieds"
    mkdir -p "$ZIEDS_PLUGIN_DIR"
    log_info "Installing zieds custom plugin..."
    cp "$PLATFORM_CONFIG_DIR/zsh/zieds.plugin.zsh" "$ZIEDS_PLUGIN_DIR/zieds.plugin.zsh"
    log_success "zieds plugin installed"
}

configure_zshrc() {
    local ZSHRC="$HOME/.zshrc"

    log_info "Configuring .zshrc..."

    # Backup existing .zshrc if it exists and wasn't created by us
    if [ -f "$ZSHRC" ] && ! grep -q "# Managed by setup-config" "$ZSHRC"; then
        cp "$ZSHRC" "$ZSHRC.backup.$(date +%Y%m%d%H%M%S)"
        log_info "Backed up existing .zshrc"
    fi

    cat > "$ZSHRC" << 'EOF'
# Managed by setup-config
# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Add Go to PATH
export PATH="$PATH:/usr/local/go/bin"

# Theme
ZSH_THEME="refined"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting vi-mode zieds)

source $ZSH/oh-my-zsh.sh
EOF

    log_success ".zshrc configured"
}

set_default_shell() {
    if [ "$SHELL" = "$(which zsh)" ]; then
        log_success "Zsh is already the default shell"
    else
        log_info "Setting Zsh as default shell..."
        chsh -s "$(which zsh)"
        log_success "Zsh set as default shell (requires logout to take effect)"
    fi
}

# ============================================================================
# Oh My Tmux Installation
# ============================================================================

install_oh_my_tmux() {
    local OH_MY_TMUX_DIR="$HOME/.oh-my-tmux"
    local TMUX_CONFIG_DIR="$XDG_CONFIG_HOME/tmux"

    # Clone Oh My Tmux
    if [ -d "$OH_MY_TMUX_DIR" ]; then
        log_success "Oh My Tmux is already installed"
    else
        log_info "Installing Oh My Tmux..."
        git clone https://github.com/gpakosz/.tmux.git "$OH_MY_TMUX_DIR"
        log_success "Oh My Tmux installed"
    fi

    # Create tmux config directory
    mkdir -p "$TMUX_CONFIG_DIR"

    # Symlink tmux.conf
    if [ -L "$TMUX_CONFIG_DIR/tmux.conf" ]; then
        log_success "tmux.conf symlink already exists"
    else
        log_info "Creating tmux.conf symlink..."
        ln -sf "$OH_MY_TMUX_DIR/.tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
        log_success "tmux.conf symlink created"
    fi

    # Copy tmux.conf.local if it doesn't exist
    if [ -f "$TMUX_CONFIG_DIR/tmux.conf.local" ]; then
        log_success "tmux.conf.local already exists"
    else
        log_info "Copying tmux.conf.local..."
        cp "$OH_MY_TMUX_DIR/.tmux.conf.local" "$TMUX_CONFIG_DIR/tmux.conf.local"
        log_success "tmux.conf.local copied"
    fi
}

# ============================================================================
# Neovim Configuration (LazyVim)
# ============================================================================

install_lazyvim() {
    local NVIM_CONFIG_DIR="$XDG_CONFIG_HOME/nvim"

    if [ -d "$NVIM_CONFIG_DIR" ] && [ -f "$NVIM_CONFIG_DIR/lua/config/lazy.lua" ]; then
        log_success "LazyVim is already installed"
    else
        log_info "Installing LazyVim..."

        # Backup existing config if present
        if [ -d "$NVIM_CONFIG_DIR" ]; then
            mv "$NVIM_CONFIG_DIR" "$NVIM_CONFIG_DIR.backup.$(date +%Y%m%d%H%M%S)"
            log_info "Backed up existing nvim config"
        fi

        # Clone LazyVim starter
        git clone https://github.com/LazyVim/starter "$NVIM_CONFIG_DIR"

        # Remove .git directory
        rm -rf "$NVIM_CONFIG_DIR/.git"

        log_success "LazyVim installed"
    fi

    # Install custom plugins
    log_info "Installing custom Neovim plugins..."
    mkdir -p "$NVIM_CONFIG_DIR/lua/plugins"

    cp "$PLATFORM_CONFIG_DIR/nvim/lua/plugins/avante.lua" "$NVIM_CONFIG_DIR/lua/plugins/avante.lua"
    cp "$PLATFORM_CONFIG_DIR/nvim/lua/plugins/auto-save.lua" "$NVIM_CONFIG_DIR/lua/plugins/auto-save.lua"
    cp "$PLATFORM_CONFIG_DIR/nvim/lua/plugins/colorscheme.lua" "$NVIM_CONFIG_DIR/lua/plugins/colorscheme.lua"

    log_success "Custom Neovim plugins installed"
}

# ============================================================================
# Ghostty Configuration
# ============================================================================

configure_ghostty() {
    local GHOSTTY_CONFIG_DIR="$XDG_CONFIG_HOME/ghostty"

    log_info "Configuring Ghostty..."

    mkdir -p "$GHOSTTY_CONFIG_DIR"
    cp "$PLATFORM_CONFIG_DIR/ghostty/config" "$GHOSTTY_CONFIG_DIR/config"

    log_success "Ghostty configured"
}

# ============================================================================
# Locale Configuration
# ============================================================================

configure_locale() {
    log_info "Configuring French locale..."

    # Generate French locale if not already present
    if ! locale -a | grep -q "fr_FR.utf8"; then
        sudo locale-gen fr_FR.UTF-8
        log_success "French locale generated"
    else
        log_success "French locale is already available"
    fi
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Ubuntu Development Environment Setup                   ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Check if running on Linux
    if [[ "$(uname)" != "Linux" ]]; then
        log_error "This script is intended for Linux only."
        exit 1
    fi

    # Check if running on Ubuntu/Debian-based system
    if ! command -v apt &>/dev/null; then
        log_error "This script requires apt package manager (Ubuntu/Debian)."
        exit 1
    fi

    # Update system first
    update_system

    # Install base packages (git first, then others)
    install_base_packages

    # Install Go (needed for some tools like opencode)
    install_go

    # Install Clang/LLVM
    install_clang

    # Install Neovim
    install_neovim

    # Install modern CLI tools
    install_modern_cli_tools

    # Install Ghostty (this can take a while as it builds from source)
    install_ghostty

    # Install opencode
    install_opencode

    # Install fonts
    install_fonts

    # Configure locale
    configure_locale

    # Setup Oh My Zsh and plugins
    install_oh_my_zsh
    install_zsh_plugins
    configure_zshrc
    set_default_shell

    # Setup tmux with Oh My Tmux
    install_oh_my_tmux

    # Setup Neovim with LazyVim
    install_lazyvim

    # Configure Ghostty
    configure_ghostty

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Installation Complete! 🎉                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Please log out and back in for shell changes to take effect."
    log_info "Then run 'source ~/.zshrc' to apply Zsh configuration."
    echo ""
}

main "$@"
