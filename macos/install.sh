#!/bin/bash

# macOS Development Environment Setup Script
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
# Homebrew Installation
# ============================================================================

install_homebrew() {
    if command -v brew &>/dev/null; then
        log_success "Homebrew is already installed"
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for this session
        eval "$(/opt/homebrew/bin/brew shellenv)"
        log_success "Homebrew installed"
    fi
}

# ============================================================================
# Brew Packages Installation
# ============================================================================

install_brew_package() {
    local package="$1"
    local cask="${2:-false}"

    if [ "$cask" = "true" ]; then
        if brew list --cask "$package" &>/dev/null; then
            log_success "$package (cask) is already installed"
        else
            log_info "Installing $package (cask)..."
            brew install --cask "$package"
            log_success "$package (cask) installed"
        fi
    else
        if brew list "$package" &>/dev/null; then
            log_success "$package is already installed"
        else
            log_info "Installing $package..."
            brew install "$package"
            log_success "$package installed"
        fi
    fi
}

install_packages() {
    log_info "Installing packages via Homebrew..."

    # Core tools (order matters - git first)
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

    # Cask applications
    install_brew_package "ghostty" "true"

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

    # Custom zieds plugin
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
# macOS System Settings
# ============================================================================

configure_macos_settings() {
    log_info "Configuring macOS settings..."

    # Disable press-and-hold for key repeat
    defaults write -g ApplePressAndHoldEnabled -bool false
    log_success "Disabled press-and-hold for key repeat"

    log_success "macOS settings configured"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         macOS Development Environment Setup                    ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is intended for macOS only."
        exit 1
    fi

    # Install Homebrew first (needed for all other packages)
    install_homebrew

    # Ensure brew is in PATH
    eval "$(/opt/homebrew/bin/brew shellenv)" 2>/dev/null || eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null || true

    # Install all packages
    install_packages

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

    # Configure macOS-specific settings
    configure_macos_settings

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Installation Complete! 🎉                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
    log_info "You may also need to log out and back in for some macOS settings to take effect."
    echo ""
}

main "$@"
