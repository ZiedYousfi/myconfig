#!/bin/bash

# Ubuntu Server Development Environment Setup Script
# This script is idempotent - running it multiple times is safe
# Uses Homebrew for package management and GNU Stow for dotfiles
# Dotfiles are copied to ~/dotfiles and stowed from there

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DOTFILES_DIR="$REPO_ROOT/dotfiles"
USER_DOTFILES_DIR="$HOME/dotfiles"

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

# Ensure sudo access and keep it alive
check_sudo() {
    log_info "This script requires sudo privileges for some operations."
    log_info "You may be prompted for your password."

    # Ask for sudo upfront
    if sudo -v; then
        # Keep-alive: update existing sudo time stamp until the script has finished
        while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
        log_success "Sudo access granted"
    else
        log_error "Sudo access is required for this script to run correctly."
        exit 1
    fi
}

# Ensure XDG directories exist and have correct ownership
ensure_dir_owned() {
    local dir="$1"
    if [ -d "$dir" ]; then
        if [ ! -w "$dir" ]; then
            log_warning "Directory $dir is not writable. Attempting to fix with sudo..."
            sudo chown -R "$(id -u):$(id -g)" "$dir"
        fi
    else
        mkdir -p "$dir" || {
            log_warning "Failed to create $dir. Trying with sudo..."
            sudo mkdir -p "$dir"
            sudo chown -R "$(id -u):$(id -g)" "$dir"
        }
    fi
}

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

ensure_dir_owned "$XDG_CONFIG_HOME"
ensure_dir_owned "$XDG_CACHE_HOME"
ensure_dir_owned "$HOME/.local/bin"

# ============================================================================
# Homebrew Installation
# ============================================================================

install_homebrew() {
    if command -v brew &>/dev/null; then
        log_success "Homebrew is already installed"
    else
        log_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

        log_success "Homebrew installed"
    fi
}

# ============================================================================
# System Update
# ============================================================================

update_system() {
    log_info "Updating Homebrew and packages..."
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true
    brew update
    brew upgrade
    log_success "System updated"
}

# ============================================================================
# Homebrew Package Installation
# ============================================================================

install_brew_package() {
    local package="$1"

    # Ensure Homebrew is in PATH
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)" 2>/dev/null || true

    if brew list "$package" &>/dev/null; then
        log_success "$package is already installed"
    else
        log_info "Installing $package..."
        brew install "$package"
        log_success "$package installed"
    fi
}

# ============================================================================
# Individual Package Installation Functions
# ============================================================================

# Core tools
install_git() { install_brew_package "git"; }
install_stow() { install_brew_package "stow"; }
install_zsh() { install_brew_package "zsh"; }
install_tmux() { install_brew_package "tmux"; }
install_curl() { install_brew_package "curl"; }
install_wget() { install_brew_package "wget"; }
install_gcc() { install_brew_package "gcc"; }
install_unzip() { install_brew_package "unzip"; }

# Neovim
install_neovim() { install_brew_package "neovim"; }

# Python
install_python() { install_brew_package "python@3.12"; }

# Go
install_go() { install_brew_package "go"; }

# Rust
install_rustup() {
    if command -v rustup &>/dev/null; then
        log_success "Rustup is already installed"
    else
        log_info "Installing Rust via rustup..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
        source "$HOME/.cargo/env" 2>/dev/null || true
        log_success "Rust installed"
    fi
}

# Bun
install_bun() {
    if command -v bun &>/dev/null; then
        log_success "Bun is already installed"
    else
        log_info "Installing Bun..."
        curl -fsSL https://bun.sh/install | bash -s -- -y </dev/null
        export BUN_INSTALL="$HOME/.bun"
        export PATH="$BUN_INSTALL/bin:$PATH"
        log_success "Bun installed"
    fi
}

# Java and build tools
install_openjdk() { install_brew_package "openjdk@21"; }
install_maven() { install_brew_package "maven"; }

# LLVM
install_llvm() { install_brew_package "llvm"; }

# Modern CLI tools
install_zoxide() { install_brew_package "zoxide"; }

install_eza() { install_brew_package "eza"; }

install_fd() { install_brew_package "fd"; }

install_fzf() { install_brew_package "fzf"; }

install_ripgrep() { install_brew_package "ripgrep"; }

install_bat() { install_brew_package "bat"; }

install_lazygit() { install_brew_package "lazygit"; }

install_btop() { install_brew_package "btop"; }

install_fastfetch() { install_brew_package "fastfetch"; }

install_uv() {
    if command -v uv &>/dev/null; then
        log_success "uv is already installed"
    else
        log_info "Installing uv..."
        curl -LsSf https://astral.sh/uv/install.sh | sh -s -- --no-modify-path </dev/null
        export PATH="$HOME/.cargo/bin:$PATH"
        log_success "uv installed"
    fi
}

install_meson() {
    if command -v meson &>/dev/null; then
        log_success "meson is already installed"
    else
        log_info "Installing meson via uv..."
        # Ensure uv is in PATH
        export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
        if command -v uv &>/dev/null; then
            uv tool install meson 2>/dev/null || {
                log_warning "Failed to install meson via uv, skipping..."
                return 0
            }
            log_success "meson installed"
        else
            log_warning "uv not found, skipping meson installation"
        fi
    fi
}

install_conan() {
    if command -v conan &>/dev/null; then
        log_success "conan is already installed"
    else
        log_info "Installing conan via uv..."
        # Ensure uv is in PATH
        export PATH="$HOME/.cargo/bin:$HOME/.local/bin:$PATH"
        if command -v uv &>/dev/null; then
            uv tool install conan 2>/dev/null || {
                log_warning "Failed to install conan via uv, skipping..."
                return 0
            }
            log_success "conan installed"
        else
            log_warning "uv not found, skipping conan installation"
        fi
    fi
}

# Yazi file manager and dependencies
install_yazi() { install_brew_package "yazi"; }

install_ffmpeg() { install_brew_package "ffmpeg"; }
install_p7zip() { install_brew_package "p7zip"; }
install_jq() { install_brew_package "jq"; }
install_poppler() { install_brew_package "poppler"; }
install_imagemagick() { install_brew_package "imagemagick"; }

# ============================================================================
# Install All Packages
# ============================================================================

install_packages() {
    log_info "Installing packages..."

    # Core tools
    install_git
    install_stow
    install_curl
    install_wget
    install_gcc
    install_unzip

    log_info "Installing shell and terminal tools..."
    install_zsh
    install_tmux

    log_info "Installing editor and programming languages..."
    install_neovim
    install_python
    install_go
    install_llvm

    log_info "Installing Rust toolchain..."
    install_rustup

    log_info "Installing Bun runtime..."
    install_bun

    # Java and build tools
    log_info "Installing Java and build tools..."
    install_openjdk
    install_maven

    # Modern CLI tools
    log_info "Installing modern CLI tools..."
    install_zoxide
    install_eza
    install_fd
    install_fzf
    install_ripgrep
    install_bat
    install_lazygit
    install_btop
    install_fastfetch

    log_info "Installing Python tools..."
    install_uv
    install_meson
    install_conan

    # Yazi file manager and dependencies
    log_info "Installing Yazi file manager and dependencies..."
    install_yazi
    install_ffmpeg
    install_p7zip
    install_jq
    install_poppler
    install_imagemagick

    log_success "All packages installed"
}

# ============================================================================
# Dotfiles Setup - Copy to ~/dotfiles
# ============================================================================

setup_user_dotfiles() {
    log_info "Setting up dotfiles in $USER_DOTFILES_DIR..."

    # Create the user dotfiles directory if it doesn't exist
    mkdir -p "$USER_DOTFILES_DIR"

    # Copy shared dotfiles (platform-independent) from repo root
    for package in ghostty nvim tmux zed zsh yazi; do
        if [ -d "$SHARED_DOTFILES_DIR/$package" ]; then
            log_info "Copying $package to $USER_DOTFILES_DIR..."
            rsync -a --update "$SHARED_DOTFILES_DIR/$package/" "$USER_DOTFILES_DIR/$package/"
        fi
    done

    log_success "Dotfiles copied to $USER_DOTFILES_DIR"
}

# ============================================================================
# Stow Helper Functions
# ============================================================================

stow_package() {
    local package="$1"
    local target="${2:-$HOME}"

    log_info "Stowing $package to $target..."

    # Try to stow and capture any error output
    local stow_output
    if stow_output=$(stow --dir="$USER_DOTFILES_DIR" --target="$target" --restow --no-folding "$package" 2>&1); then
        log_success "$package stowed successfully"
        return 0
    fi

    # If we get here, there was a conflict
    log_warning "$package has conflicts with existing files:"
    echo ""

    # Extract and display conflicting files from stow output
    echo "$stow_output" | grep -E "(existing target|conflict)" | while read -r line; do
        echo -e "  ${YELLOW}→${NC} $line"
    done
    echo ""

    # Check if running in interactive mode
    if [ -t 0 ]; then
        # Interactive mode - ask user what to do
        echo -e "${BLUE}How would you like to resolve this conflict?${NC}"
        echo "  [a] Adopt   - Keep existing files and bring them into ~/dotfiles"
        echo "               (Use this if you've customized these configs)"
        echo "  [o] Override - Delete existing files and use ~/dotfiles versions"
        echo "               (Use this to get fresh configs from the repo)"
        echo "  [s] Skip    - Don't stow this package"
        echo ""

        while true; do
            read -r -p "Your choice [a/o/s]: " choice
            case "$choice" in
                [aA])
                    log_info "Adopting existing files for $package..."
                    stow --dir="$USER_DOTFILES_DIR" --target="$target" --adopt "$package"
                    stow --dir="$USER_DOTFILES_DIR" --target="$target" --restow --no-folding "$package"
                    log_success "$package adopted and restowed successfully"
                    return 0
                    ;;
                [oO])
                    log_info "Overriding existing files for $package..."
                    # Find and remove conflicting files
                    local stow_sim_output
                    stow_sim_output=$(stow --dir="$USER_DOTFILES_DIR" --target="$target" --simulate --restow --no-folding "$package" 2>&1 || true)

                    local conflicts
                    conflicts=$(echo "$stow_sim_output" | grep -oE "existing target is not owned by stow: [^ ]+" | sed 's/existing target is not owned by stow: //')
                    conflicts="$conflicts $(echo "$stow_sim_output" | grep -oE "over existing target [^ ]+ since" | sed 's/over existing target //' | sed 's/ since//')"

                    for conflict_file in $conflicts; do
                        [ -z "$conflict_file" ] && continue
                        local full_path="$target/$conflict_file"
                        if [ -e "$full_path" ] || [ -L "$full_path" ]; then
                            log_info "Removing $full_path..."
                            rm -rf "$full_path"
                        fi
                    done

                    stow --dir="$USER_DOTFILES_DIR" --target="$target" --restow --no-folding "$package"
                    log_success "$package stowed successfully (existing files overridden)"
                    return 0
                    ;;
                [sS])
                    log_warning "Skipping $package"
                    return 0
                    ;;
                *)
                    echo "Please enter 'a' for adopt, 'o' for override, or 's' for skip."
                    ;;
            esac
        done
    else
        # Non-interactive mode - use adopt strategy (safer default)
        log_info "Non-interactive mode: adopting existing files for $package..."
        stow --dir="$USER_DOTFILES_DIR" --target="$target" --adopt "$package" 2>&1 || {
            log_warning "Failed to adopt $package, trying to override..."
            # Find and remove conflicting files
            local stow_sim_output
            stow_sim_output=$(stow --dir="$USER_DOTFILES_DIR" --target="$target" --simulate --restow --no-folding "$package" 2>&1 || true)

            local conflicts
            conflicts=$(echo "$stow_sim_output" | grep -oE "existing target is not owned by stow: [^ ]+" | sed 's/existing target is not owned by stow: //')
            conflicts="$conflicts $(echo "$stow_sim_output" | grep -oE "over existing target [^ ]+ since" | sed 's/over existing target //' | sed 's/ since//')"

            for conflict_file in $conflicts; do
                [ -z "$conflict_file" ] && continue
                local full_path="$target/$conflict_file"
                if [ -e "$full_path" ] || [ -L "$full_path" ]; then
                    log_info "Removing $full_path..."
                    rm -rf "$full_path"
                fi
            done
        }
        stow --dir="$USER_DOTFILES_DIR" --target="$target" --restow --no-folding "$package" 2>&1 || {
            log_warning "Failed to stow $package, skipping..."
            return 0
        }
        log_success "$package stowed successfully"
        return 0
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

    # Stow custom zieds plugin
    stow_package "zsh"
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

# Enable command auto-correction
ENABLE_CORRECTION="true"

# Plugins
plugins=(git zsh-autosuggestions zsh-syntax-highlighting vi-mode zieds)

source $ZSH/oh-my-zsh.sh
EOF

    log_success ".zshrc configured"
}

set_default_shell() {
    local zsh_path
    zsh_path=$(which zsh)

    if [ -z "$zsh_path" ]; then
        log_error "Zsh not found in PATH"
        return 1
    fi

    # Check if zsh is already the default shell
    if [[ "$SHELL" == *"/zsh" ]]; then
        log_success "Zsh is already the default shell"
        return 0
    fi

    log_info "Setting zsh as default shell ($zsh_path)..."

    # Ensure zsh is in /etc/shells
    if ! grep -Fxq "$zsh_path" /etc/shells; then
        log_info "Adding $zsh_path to /etc/shells..."
        echo "$zsh_path" | sudo tee -a /etc/shells > /dev/null
    fi

    # Try to use sudo chsh to avoid interaction if we have sudo access
    if sudo -n true 2>/dev/null; then
        if sudo chsh -s "$zsh_path" "$USER"; then
            log_success "Zsh set as default shell via sudo"
            export SHELL="$zsh_path"
            return 0
        fi
    fi

    # Fallback to interactive chsh if sudo failed or not available
    if [ -t 0 ]; then
        if chsh -s "$zsh_path"; then
            log_success "Zsh set as default shell"
            export SHELL="$zsh_path"
        else
            log_warning "Failed to set zsh as default shell"
        fi
    else
        log_warning "Cannot change default shell in non-interactive mode without sudo"
        log_info "Run 'sudo chsh -s $zsh_path $USER' manually to set zsh as your default shell"
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
    ensure_dir_owned "$TMUX_CONFIG_DIR"

    # Symlink tmux.conf from Oh My Tmux
    if [ -L "$TMUX_CONFIG_DIR/tmux.conf" ]; then
        log_success "tmux.conf symlink already exists"
    else
        log_info "Creating tmux.conf symlink..."
        ln -sf "$OH_MY_TMUX_DIR/.tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
        log_success "tmux.conf symlink created"
    fi

    # Stow custom tmux.conf.local
    log_info "Stowing custom tmux configuration..."
    stow_package "tmux"
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

    # Stow custom Neovim plugins
    log_info "Stowing custom Neovim plugins..."
    stow_package "nvim"
}

# ============================================================================
# Ghostty Configuration (if present)
# ============================================================================

configure_ghostty() {
    if [ -d "$USER_DOTFILES_DIR/ghostty" ]; then
        log_info "Configuring Ghostty via stow..."
        stow_package "ghostty"
        log_success "Ghostty configured"
    else
        log_warning "Ghostty dotfiles not found, skipping"
    fi
}

# ============================================================================
# Zed Configuration (if present)
# ============================================================================

configure_zed() {
    if [ -d "$USER_DOTFILES_DIR/zed" ]; then
        log_info "Configuring Zed via stow..."
        stow_package "zed"
        log_success "Zed configured"
    else
        log_warning "Zed dotfiles not found, skipping"
    fi
}

# ============================================================================
# Yazi Configuration
# ============================================================================

configure_yazi() {
    log_info "Configuring Yazi via stow..."
    stow_package "yazi"

    # Ensure flavors directory exists (needed for ya pkg to work)
    ensure_dir_owned "$XDG_CONFIG_HOME/yazi/flavors"

    # Install monokai flavor for yazi
    if command -v ya &>/dev/null; then
        log_info "Installing yazi monokai flavor..."
        ya pkg add malick-tammal/monokai 2>/dev/null || true

        # Check if flavor was deployed, if not, manually copy it
        local FLAVOR_DIR="$XDG_CONFIG_HOME/yazi/flavors/monokai.yazi"
        if [ ! -f "$FLAVOR_DIR/flavor.toml" ]; then
            local PKG_DIR
            PKG_DIR=$(find "$HOME/.local/state/yazi/packages" -name "flavor.toml" -path "*monokai*" -exec dirname {} \; 2>/dev/null | head -n1)
            if [ -n "$PKG_DIR" ] && [ -d "$PKG_DIR" ]; then
                log_info "Manually deploying monokai flavor..."
                ensure_dir_owned "$FLAVOR_DIR"
                cp -r "$PKG_DIR"/* "$FLAVOR_DIR/"
            fi
        fi

        if [ -f "$FLAVOR_DIR/flavor.toml" ]; then
            log_success "Yazi monokai flavor installed"
        else
            log_warning "Could not install monokai flavor"
        fi
    else
        log_warning "ya command not found, skipping flavor installation"
    fi

    log_success "Yazi configured"
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       Ubuntu Server Development Environment Setup              ║"
    echo "║              (Powered by Homebrew & GNU Stow)                  ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Check for sudo access upfront
    check_sudo

    # Check if running on Linux
    if [[ "$(uname)" != "Linux" ]]; then
        log_error "This script is intended for Linux only."
        exit 1
    fi

    # Install Homebrew first
    install_homebrew

    # Update system
    update_system

    # Install all packages
    install_packages

    # Copy dotfiles to ~/dotfiles (before stowing)
    setup_user_dotfiles

    # Setup Oh My Zsh and plugins (uses stow for custom plugin)
    install_oh_my_zsh
    install_zsh_plugins
    configure_zshrc
    set_default_shell

    # Setup tmux with Oh My Tmux (uses stow for tmux.conf.local)
    install_oh_my_tmux

    # Setup Neovim with LazyVim (uses stow for custom plugins)
    install_lazyvim

    # Configure Ghostty (uses stow - only if installing locally)
    configure_ghostty

    # Configure Zed editor (uses stow - only if installing locally)
    configure_zed

    # Configure Yazi file manager
    configure_yazi

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Installation Complete! 🎉                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "Dotfiles are stored in: $USER_DOTFILES_DIR"
    log_info "Dotfiles are managed via GNU Stow from ~/dotfiles"
    log_info "You can now safely delete the setup-config repository."
    log_info "To modify configs, edit files in ~/dotfiles and re-run stow."
    echo ""
    log_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes."
    log_info "You may need to log out and back in for the default shell change to take effect."
    echo ""
}

main "$@"
