#!/bin/bash

# Arch Linux Development Environment Uninstall Script
# This script removes everything installed by install.sh
# Interactive - will ask for confirmation before proceeding

set -e

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

# XDG directories
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# ============================================================================
# Unstow Dotfiles
# ============================================================================

unstow_packages() {
    log_info "Unstowing dotfiles..."

    if [ ! -d "$USER_DOTFILES_DIR" ]; then
        log_warning "~/.dotfiles directory not found, skipping unstow"
        return
    fi

    cd "$USER_DOTFILES_DIR"

    for package in ghostty nvim tmux zed zsh niri waybar; do
        if [ -d "$USER_DOTFILES_DIR/$package" ]; then
            log_info "Unstowing $package..."
            stow --dir="$USER_DOTFILES_DIR" --target="$HOME" --delete "$package" 2>/dev/null || true
        fi
    done

    log_success "Dotfiles unstowed"
}

# ============================================================================
# Remove Oh My Zsh
# ============================================================================

remove_oh_my_zsh() {
    log_info "Removing Oh My Zsh..."

    if [ -d "$HOME/.oh-my-zsh" ]; then
        rm -rf "$HOME/.oh-my-zsh"
        log_success "Oh My Zsh removed"
    else
        log_info "Oh My Zsh not found, skipping"
    fi

    # Remove managed .zshrc
    if [ -f "$HOME/.zshrc" ] && grep -q "# Managed by setup-config" "$HOME/.zshrc"; then
        rm -f "$HOME/.zshrc"
        log_success "Managed .zshrc removed"
    fi

    # Restore backup if exists
    local latest_backup=$(ls -t "$HOME"/.zshrc.backup.* 2>/dev/null | head -1)
    if [ -n "$latest_backup" ]; then
        log_info "Restoring .zshrc from backup: $latest_backup"
        cp "$latest_backup" "$HOME/.zshrc"
    fi
}

# ============================================================================
# Remove Oh My Tmux
# ============================================================================

remove_oh_my_tmux() {
    log_info "Removing Oh My Tmux..."

    if [ -d "$HOME/.oh-my-tmux" ]; then
        rm -rf "$HOME/.oh-my-tmux"
        log_success "Oh My Tmux removed"
    else
        log_info "Oh My Tmux not found, skipping"
    fi

    # Remove tmux config directory
    if [ -d "$XDG_CONFIG_HOME/tmux" ]; then
        rm -rf "$XDG_CONFIG_HOME/tmux"
        log_success "tmux config directory removed"
    fi
}

# ============================================================================
# Remove LazyVim/Neovim Configuration
# ============================================================================

remove_lazyvim() {
    log_info "Removing LazyVim/Neovim configuration..."

    # Remove config
    if [ -d "$XDG_CONFIG_HOME/nvim" ]; then
        rm -rf "$XDG_CONFIG_HOME/nvim"
        log_success "Neovim config removed"
    fi

    # Remove data
    if [ -d "$XDG_DATA_HOME/nvim" ]; then
        rm -rf "$XDG_DATA_HOME/nvim"
        log_success "Neovim data removed"
    fi

    # Remove state
    if [ -d "$XDG_STATE_HOME/nvim" ]; then
        rm -rf "$XDG_STATE_HOME/nvim"
        log_success "Neovim state removed"
    fi

    # Remove cache
    if [ -d "$XDG_CACHE_HOME/nvim" ]; then
        rm -rf "$XDG_CACHE_HOME/nvim"
        log_success "Neovim cache removed"
    fi
}

# ============================================================================
# Remove Ghostty Configuration
# ============================================================================

remove_ghostty_config() {
    log_info "Removing Ghostty configuration..."

    if [ -d "$XDG_CONFIG_HOME/ghostty" ]; then
        rm -rf "$XDG_CONFIG_HOME/ghostty"
        log_success "Ghostty config removed"
    else
        log_info "Ghostty config not found, skipping"
    fi
}

# ============================================================================
# Remove Zed Configuration
# ============================================================================

remove_zed_config() {
    log_info "Removing Zed configuration..."

    if [ -d "$XDG_CONFIG_HOME/zed" ]; then
        rm -rf "$XDG_CONFIG_HOME/zed"
        log_success "Zed config removed"
    else
        log_info "Zed config not found, skipping"
    fi
}

# ============================================================================
# Remove Niri Configuration
# ============================================================================

remove_niri_config() {
    log_info "Removing Niri configuration..."

    if [ -d "$XDG_CONFIG_HOME/niri" ]; then
        rm -rf "$XDG_CONFIG_HOME/niri"
        log_success "Niri config removed"
    else
        log_info "Niri config not found, skipping"
    fi
}

# ============================================================================
# Remove Waybar Configuration
# ============================================================================

remove_waybar_config() {
    log_info "Removing Waybar configuration..."

    if [ -d "$XDG_CONFIG_HOME/waybar" ]; then
        rm -rf "$XDG_CONFIG_HOME/waybar"
        log_success "Waybar config removed"
    else
        log_info "Waybar config not found, skipping"
    fi
}

# ============================================================================
# Remove AUR Packages
# ============================================================================

remove_aur_packages() {
    log_info "Removing AUR packages installed by setup..."

    local AUR_PACKAGES=(
        "ghostty"
        "zed-editor"
        "opencode-bin"
    )

    for pkg in "${AUR_PACKAGES[@]}"; do
        if yay -Qi "$pkg" &>/dev/null; then
            log_info "Removing $pkg..."
            yay -Rns --noconfirm "$pkg" 2>/dev/null || true
        fi
    done

    log_success "AUR packages removed"
}

# ============================================================================
# Remove Dotfiles Directory
# ============================================================================

remove_dotfiles_dir() {
    if [ -d "$USER_DOTFILES_DIR" ]; then
        rm -rf "$USER_DOTFILES_DIR"
        log_success "~/.dotfiles directory removed"
    fi
}

# ============================================================================
# Clean Up Empty Directories
# ============================================================================

cleanup_empty_dirs() {
    log_info "Cleaning up empty directories..."

    # Remove empty config directories
    rmdir "$XDG_CONFIG_HOME" 2>/dev/null || true

    log_success "Cleanup complete"
}

# ============================================================================
# Main Uninstall Flow
# ============================================================================

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║       Arch Linux Development Environment Uninstaller           ║"
    echo "║                                                                ║"
    echo "║  This will remove all components installed by install.sh      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    log_warning "This will remove:"
    echo "  • Oh My Zsh and all plugins"
    echo "  • Oh My Tmux and tmux configuration"
    echo "  • LazyVim/Neovim configuration, data, and cache"
    echo "  • Ghostty configuration"
    echo "  • Zed configuration"
    echo "  • Niri configuration"
    echo "  • Waybar configuration"
    echo "  • All symlinks from ~/.dotfiles"
    echo ""

    read -r -p "Are you sure you want to continue? [y/N] " response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        log_info "Uninstallation cancelled"
        exit 0
    fi

    echo ""

    # Unstow dotfiles first (removes symlinks)
    unstow_packages

    # Remove configurations
    remove_oh_my_zsh
    remove_oh_my_tmux
    remove_lazyvim
    remove_ghostty_config
    remove_zed_config
    remove_niri_config
    remove_waybar_config

    # Ask about AUR packages
    echo ""
    read -r -p "Remove AUR packages (ghostty, zed-editor, opencode-bin)? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        remove_aur_packages
    fi

    # Ask about ~/.dotfiles directory
    echo ""
    read -r -p "Remove ~/.dotfiles directory? [y/N] " response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        remove_dotfiles_dir
    fi

    # Cleanup
    cleanup_empty_dirs

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                  Uninstallation Complete!                      ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_success "All components have been removed"
    echo ""
    log_info "Note: System packages installed via pacman were not removed."
    log_info "To remove them, run: sudo pacman -Rns <package-name>"
    echo ""
}

main "$@"
