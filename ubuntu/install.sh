#!/bin/bash

# Ubuntu Development Environment Setup Script
# This script is idempotent - running it multiple times is safe
# Uses Homebrew as the primary package manager for better package availability

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
# System Update & Essential Dependencies
# ============================================================================

install_system_dependencies() {
    log_info "Installing essential system dependencies via apt..."
    sudo apt update
    sudo apt install -y build-essential procps curl file git zsh
    log_success "System dependencies installed"
}

# ============================================================================
# Homebrew Installation
# ============================================================================

install_homebrew() {
    if command -v brew &>/dev/null; then
        log_success "Homebrew is already installed"
    else
        log_info "Installing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        log_success "Homebrew installed"
    fi

    # Add Homebrew to PATH for this session
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -d "$HOME/.linuxbrew" ]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi
}

# ============================================================================
# Brew Package Installation
# ============================================================================

install_brew_package() {
    local package="$1"

    if brew list "$package" &>/dev/null; then
        log_success "$package is already installed"
    else
        log_info "Installing $package..."
        brew install "$package"
        log_success "$package installed"
    fi
}

install_packages() {
    log_info "Installing packages via Homebrew..."

    # Core tools
    install_brew_package "git"
    install_brew_package "zsh"
    install_brew_package "tmux"
    install_brew_package "neovim"
    install_brew_package "go"
    install_brew_package "llvm"

    # Modern CLI tools
    install_brew_package "zoxide"
    install_brew_package "eza"
    install_brew_package "fd"
    install_brew_package "fzf"
    install_brew_package "ripgrep"
    install_brew_package "bat"
    install_brew_package "lazygit"
    install_brew_package "btop"
    install_brew_package "fastfetch"

    # opencode (install SST version from sst/tap)
    if brew list "sst/tap/opencode" &>/dev/null; then
        log_success "SST opencode is already installed"
    else
        log_info "Installing SST opencode..."
        brew install sst/tap/opencode
        log_success "SST opencode installed"
    fi

    log_success "All packages installed"
}

# ============================================================================
# Ghostty Installation
# ============================================================================

install_ghostty() {
    if command -v ghostty &>/dev/null; then
        log_success "Ghostty is already installed"
    else
        log_info "Installing Ghostty via community script..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
        log_success "Ghostty installed"
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

# Homebrew setup for Linux
if [ -d "/home/linuxbrew/.linuxbrew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -d "$HOME/.linuxbrew" ]; then
    eval "$($HOME/.linuxbrew/bin/brew shellenv)"
fi

# Theme
ZSH_THEME="refined"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting vi-mode zieds)

source $ZSH/oh-my-zsh.sh
EOF

    log_success ".zshrc configured"
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
    echo "║                   (Powered by Homebrew)                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Check if running on Linux
    if [[ "$(uname)" != "Linux" ]]; then
        log_error "This script is intended for Linux only."
        exit 1
    fi

    # Install essential system dependencies via apt first
    install_system_dependencies

    # Install Homebrew
    install_homebrew

    # Ensure brew is in PATH for this session
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -d "$HOME/.linuxbrew" ]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi

    # Install all packages via Homebrew
    install_packages

    # Install Ghostty (via community script, not available in brew for Linux)
    install_ghostty

    # Configure locale
    configure_locale

    # Setup Oh My Zsh and plugins
    install_oh_my_zsh
    install_zsh_plugins
    configure_zshrc

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
