#!/bin/bash

# Arch Linux Development Environment Setup Script
# This script is idempotent - running it multiple times is safe
# Uses pacman + yay (AUR) as package managers
# Uses GNU Stow for dotfiles management
# Dotfiles are copied to ~/.dotfiles and stowed from there

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
USER_DOTFILES_DIR="$HOME/.dotfiles"

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
# yay (AUR Helper) Installation
# ============================================================================

install_yay() {
    if command -v yay &>/dev/null; then
        log_success "yay is already installed"
    else
        log_info "Installing yay (AUR helper)..."

        # Install base-devel and git first if not present
        sudo pacman -S --needed --noconfirm base-devel git

        # Clone and build yay
        local YAY_TMP=$(mktemp -d)
        git clone https://aur.archlinux.org/yay.git "$YAY_TMP/yay"
        cd "$YAY_TMP/yay"
        makepkg -si --noconfirm
        cd -
        rm -rf "$YAY_TMP"

        log_success "yay installed"
    fi
}

# ============================================================================
# Package Installation
# ============================================================================

install_pacman_package() {
    local package="$1"

    if pacman -Qi "$package" &>/dev/null; then
        log_success "$package is already installed"
    else
        log_info "Installing $package..."
        sudo pacman -S --needed --noconfirm "$package"
        log_success "$package installed"
    fi
}

install_aur_package() {
    local package="$1"

    if yay -Qi "$package" &>/dev/null; then
        log_success "$package (AUR) is already installed"
    else
        log_info "Installing $package (AUR)..."
        yay -S --needed --noconfirm "$package"
        log_success "$package (AUR) installed"
    fi
}

install_packages() {
    log_info "Installing packages via pacman..."

    # Core tools (order matters - git first)
    install_pacman_package "git"
    install_pacman_package "stow"
    install_pacman_package "zsh"
    install_pacman_package "tmux"
    install_pacman_package "neovim"
    install_pacman_package "go"
    install_pacman_package "clang"
    install_pacman_package "rsync"

    # Modern CLI tools
    install_pacman_package "zoxide"
    install_pacman_package "eza"
    install_pacman_package "fd"
    install_pacman_package "fzf"
    install_pacman_package "ripgrep"
    install_pacman_package "bat"
    install_pacman_package "lazygit"
    install_pacman_package "btop"
    install_pacman_package "fastfetch"

    # Window manager and status bar (should be already installed via archinstall)
    install_pacman_package "niri"
    install_pacman_package "waybar"

    # Fonts
    install_pacman_package "ttf-hack-nerd"

    # Audio (for Waybar volume widget)
    install_pacman_package "wireplumber"
    install_pacman_package "pipewire-pulse"

    # Utilities for Niri
    install_pacman_package "fuzzel"
    install_pacman_package "swaylock"
    install_pacman_package "brightnessctl"
    install_pacman_package "grim"
    install_pacman_package "slurp"

    log_info "Installing AUR packages..."

    # Terminal emulator
    install_aur_package "ghostty"

    # Code editor
    install_aur_package "zed-editor"

    # AI coding assistant (if available)
    if yay -Ss opencode-bin &>/dev/null; then
        install_aur_package "opencode-bin"
    else
        log_warning "opencode-bin not found in AUR, skipping..."
    fi

    log_success "All packages installed"
}

# ============================================================================
# Dotfiles Setup - Copy to ~/.dotfiles
# ============================================================================

setup_user_dotfiles() {
    log_info "Setting up dotfiles in $USER_DOTFILES_DIR..."

    # Create the user dotfiles directory if it doesn't exist
    mkdir -p "$USER_DOTFILES_DIR"

    # Copy each stow package from repo to user dotfiles directory
    for package in ghostty nvim tmux zed zsh niri waybar; do
        if [ -d "$REPO_DOTFILES_DIR/$package" ]; then
            log_info "Copying $package to $USER_DOTFILES_DIR..."
            # Use rsync to copy, preserving structure and updating only if newer
            rsync -a --update "$REPO_DOTFILES_DIR/$package/" "$USER_DOTFILES_DIR/$package/"
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

    # Ask user what to do
    echo -e "${BLUE}How would you like to resolve this conflict?${NC}"
    echo "  [a] Adopt   - Keep existing files and bring them into ~/.dotfiles"
    echo "               (Use this if you've customized these configs)"
    echo "  [o] Override - Delete existing files and use ~/.dotfiles versions"
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
                # Use stow --simulate to find what would be stowed, then remove existing files
                local conflicts
                conflicts=$(stow --dir="$USER_DOTFILES_DIR" --target="$target" --simulate --restow --no-folding "$package" 2>&1 | grep -oE "existing target is not owned by stow: [^ ]+" | sed 's/existing target is not owned by stow: //')

                for conflict_file in $conflicts; do
                    local full_path="$target/$conflict_file"
                    if [ -e "$full_path" ] || [ -L "$full_path" ]; then
                        log_info "Removing $full_path..."
                        rm -rf "$full_path"
                    fi
                done

                # Now stow should work
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

    # Symlink tmux.conf from Oh My Tmux
    if [ -L "$TMUX_CONFIG_DIR/tmux.conf" ]; then
        log_success "tmux.conf symlink already exists"
    else
        log_info "Creating tmux.conf symlink..."
        ln -sf "$OH_MY_TMUX_DIR/.tmux.conf" "$TMUX_CONFIG_DIR/tmux.conf"
        log_success "tmux.conf symlink created"
    fi

    # Stow custom tmux.conf.local (like we do for LazyVim plugins)
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
# Ghostty Configuration
# ============================================================================

configure_ghostty() {
    log_info "Configuring Ghostty via stow..."
    stow_package "ghostty"
    log_success "Ghostty configured"
}

# ============================================================================
# Zed Configuration
# ============================================================================

configure_zed() {
    log_info "Configuring Zed via stow..."
    stow_package "zed"
    log_success "Zed configured"
}

# ============================================================================
# Niri Configuration (Tiling Window Manager)
# ============================================================================

configure_niri() {
    log_info "Configuring Niri via stow..."
    stow_package "niri"

    log_success "Niri configured"
    log_info "Niri configuration will take effect on next login or after running: niri msg action reload-config"
}

# ============================================================================
# Waybar Configuration (Status Bar)
# ============================================================================

configure_waybar() {
    log_info "Configuring Waybar via stow..."
    stow_package "waybar"

    log_success "Waybar configured"
    log_info "Waybar will restart automatically when Niri reloads"
}

# ============================================================================
# Locale Configuration
# ============================================================================

configure_locale() {
    log_info "Configuring French locale..."

    # Check if fr_FR.UTF-8 is already generated
    if locale -a 2>/dev/null | grep -q "fr_FR.utf8"; then
        log_success "French locale is already configured"
    else
        # Uncomment fr_FR.UTF-8 in /etc/locale.gen
        if grep -q "^#fr_FR.UTF-8" /etc/locale.gen; then
            sudo sed -i 's/^#fr_FR.UTF-8/fr_FR.UTF-8/' /etc/locale.gen
        fi
        sudo locale-gen
        log_success "French locale configured"
    fi
}

# ============================================================================
# Set Default Shell
# ============================================================================

set_default_shell() {
    local ZSH_PATH="/bin/zsh"

    if [ "$SHELL" = "$ZSH_PATH" ]; then
        log_success "Zsh is already the default shell"
    else
        log_info "Setting Zsh as default shell..."
        chsh -s "$ZSH_PATH"
        log_success "Zsh set as default shell (will take effect after re-login)"
    fi
}

# ============================================================================
# Create Screenshots Directory
# ============================================================================

setup_screenshots_dir() {
    local SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"

    if [ -d "$SCREENSHOTS_DIR" ]; then
        log_success "Screenshots directory already exists"
    else
        log_info "Creating screenshots directory..."
        mkdir -p "$SCREENSHOTS_DIR"
        log_success "Screenshots directory created at $SCREENSHOTS_DIR"
    fi
}

# ============================================================================
# Main Installation Flow
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       Arch Linux Development Environment Setup                 ║"
    echo "║              Niri + Waybar (Monokai Theme)                     ║"
    echo "║                  (Powered by GNU Stow)                         ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    # Check if running on Arch Linux
    if [ ! -f /etc/arch-release ]; then
        log_error "This script is intended for Arch Linux only."
        exit 1
    fi

    # Install yay (AUR helper)
    install_yay

    # Install all packages
    install_packages

    # Copy dotfiles to ~/.dotfiles (before stowing)
    setup_user_dotfiles

    # Configure locale
    configure_locale

    # Install and configure Oh My Zsh
    install_oh_my_zsh
    install_zsh_plugins
    configure_zshrc

    # Install and configure tmux
    install_oh_my_tmux

    # Install and configure Neovim
    install_lazyvim

    # Configure applications
    configure_ghostty
    configure_zed
    configure_niri
    configure_waybar

    # Setup directories
    setup_screenshots_dir

    # Set default shell
    set_default_shell

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "All components installed and configured!"
    echo ""
    echo "Next steps:"
    echo "  1. Log out and back in for shell changes and Niri/Waybar to take effect"
    echo "  2. Run 'source ~/.zshrc' to apply Zsh configuration immediately"
    echo "  3. Open Neovim and run ':Lazy sync' to install plugins"
    echo "  4. You can now safely delete the setup-config repository"
    echo "     Your dotfiles are in ~/.dotfiles"
    echo ""
    log_info "For Niri keybindings: Super+Return (terminal), Super+D (launcher)"
    log_info "To reload Niri config: niri msg action reload-config"
    echo ""
}

main "$@"
