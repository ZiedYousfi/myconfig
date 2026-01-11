#!/bin/bash

# macOS Development Environment Uninstall Script
# This script removes everything installed by install.sh
# Use with caution - this will remove configurations and installed packages

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# User dotfiles directory (where dotfiles were copied during install)
USER_DOTFILES_DIR="$HOME/dotfiles"

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

# ============================================================================
# Confirmation
# ============================================================================

confirm_uninstall() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         macOS Development Environment Uninstaller              ║"
    echo "║                     ⚠️  WARNING ⚠️                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_warning "This script will remove:"
    echo "  - Oh My Zsh and all plugins"
    echo "  - Oh My Tmux"
    echo "  - LazyVim configuration"
    echo "  - Ghostty configuration"
    echo "  - Stowed dotfiles symlinks"
    echo "  - ~/.dotfiles directory (optionally)"
    echo "  - Homebrew packages installed by the setup"
    echo "  - (Optionally) Homebrew itself"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Uninstall cancelled."
        exit 0
    fi
    echo ""
}

# ============================================================================
# Unstow Dotfiles
# ============================================================================

unstow_dotfiles() {
    if command -v stow &>/dev/null && [ -d "$USER_DOTFILES_DIR" ]; then
        log_info "Unstowing dotfiles from $USER_DOTFILES_DIR..."

        for package in ghostty nvim tmux zed zsh yazi sketchybar yabai; do
            if [ -d "$USER_DOTFILES_DIR/$package" ]; then
                log_info "Unstowing $package..."
                stow --dir="$USER_DOTFILES_DIR" --target="$HOME" --delete "$package" 2>/dev/null || true
            fi
        done

        log_success "Dotfiles unstowed"
    else
        log_warning "Stow not found or ~/dotfiles directory missing, skipping unstow"
    fi
}

remove_user_dotfiles() {
    if [ -d "$USER_DOTFILES_DIR" ]; then
        read -p "Do you want to remove the ~/dotfiles directory? (yes/no): " remove_dotfiles
        if [[ "$remove_dotfiles" == "yes" ]]; then
            log_info "Removing $USER_DOTFILES_DIR..."
            rm -rf "$USER_DOTFILES_DIR"
            log_success "~/dotfiles directory removed"
        else
            log_info "Keeping ~/dotfiles directory"
        fi
    fi
# Remove Sketchybar config and service
remove_sketchybar_config() {
    if [ -d "$XDG_CONFIG_HOME/sketchybar" ]; then
        log_info "Removing Sketchybar configuration..."
        rm -rf "$XDG_CONFIG_HOME/sketchybar"
        log_success "Sketchybar configuration removed"
    else
        log_info "Sketchybar configuration not found, skipping"
    fi
    # Stop Sketchybar service if running
    if command -v brew &>/dev/null && brew services list | grep -q sketchybar; then
        log_info "Stopping Sketchybar service..."
        brew services stop sketchybar || true
    fi
}

# Remove Yabai config and service
remove_yabai_config() {
    if [ -d "$XDG_CONFIG_HOME/yabai" ]; then
        log_info "Removing Yabai configuration..."
        rm -rf "$XDG_CONFIG_HOME/yabai"
        log_success "Yabai configuration removed"
    else
        log_info "Yabai configuration not found, skipping"
    fi
    # Stop Yabai service if running
    if command -v yabai &>/dev/null && pgrep -x "yabai" > /dev/null; then
        log_info "Stopping Yabai service..."
        yabai --stop-service 2>/dev/null || true
    fi
}
}

# ============================================================================
# Remove Configurations
# ============================================================================

remove_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Removing Oh My Zsh..."
        rm -rf "$HOME/.oh-my-zsh"
        log_success "Oh My Zsh removed"
    else
        log_info "Oh My Zsh not found, skipping"
    fi

    # Remove .zshrc if managed by us
    if [ -f "$HOME/.zshrc" ] && grep -q "# Managed by setup-config" "$HOME/.zshrc"; then
        log_info "Removing managed .zshrc..."
        rm -f "$HOME/.zshrc"
        log_success ".zshrc removed"
    fi

    # Remove .zshrc backups
    for backup in "$HOME"/.zshrc.backup.*; do
        if [ -f "$backup" ]; then
            log_info "Removing backup: $backup"
            rm -f "$backup"
        fi
    done
}

remove_oh_my_tmux() {
    if [ -d "$HOME/.oh-my-tmux" ]; then
        log_info "Removing Oh My Tmux..."
        rm -rf "$HOME/.oh-my-tmux"
        log_success "Oh My Tmux removed"
    else
        log_info "Oh My Tmux not found, skipping"
    fi

    # Remove tmux config directory
    if [ -d "$XDG_CONFIG_HOME/tmux" ]; then
        log_info "Removing tmux configuration..."
        rm -rf "$XDG_CONFIG_HOME/tmux"
        log_success "tmux configuration removed"
    fi
}

remove_lazyvim() {
    if [ -d "$XDG_CONFIG_HOME/nvim" ]; then
        log_info "Removing Neovim/LazyVim configuration..."
        rm -rf "$XDG_CONFIG_HOME/nvim"
        log_success "Neovim configuration removed"
    else
        log_info "Neovim configuration not found, skipping"
    fi

    # Remove nvim backups
    for backup in "$XDG_CONFIG_HOME"/nvim.backup.*; do
        if [ -d "$backup" ]; then
            log_info "Removing backup: $backup"
            rm -rf "$backup"
        fi
    done

    # Remove Neovim data and cache
    if [ -d "$HOME/.local/share/nvim" ]; then
        log_info "Removing Neovim data..."
        rm -rf "$HOME/.local/share/nvim"
    fi

    if [ -d "$HOME/.local/state/nvim" ]; then
        log_info "Removing Neovim state..."
        rm -rf "$HOME/.local/state/nvim"
    fi

    if [ -d "$XDG_CACHE_HOME/nvim" ]; then
        log_info "Removing Neovim cache..."
        rm -rf "$XDG_CACHE_HOME/nvim"
    fi
}

remove_ghostty_config() {
    if [ -d "$XDG_CONFIG_HOME/ghostty" ]; then
        log_info "Removing Ghostty configuration..."
        rm -rf "$XDG_CONFIG_HOME/ghostty"
        log_success "Ghostty configuration removed"
    else
        log_info "Ghostty configuration not found, skipping"
    fi
}

remove_zed_config() {
    if [ -d "$XDG_CONFIG_HOME/zed" ]; then
        log_info "Removing Zed configuration..."
        rm -rf "$XDG_CONFIG_HOME/zed"
        log_success "Zed configuration removed"
    else
        log_info "Zed configuration not found, skipping"
    fi
}

remove_yazi_config() {
    if [ -d "$XDG_CONFIG_HOME/yazi" ]; then
        log_info "Removing Yazi configuration..."
        rm -rf "$XDG_CONFIG_HOME/yazi"
        log_success "Yazi configuration removed"
    else
        log_info "Yazi configuration not found, skipping"
    fi

    # Remove yazi data and state
    if [ -d "$HOME/.local/share/yazi" ]; then
        log_info "Removing Yazi data..."
        rm -rf "$HOME/.local/share/yazi"
    fi

    if [ -d "$HOME/.local/state/yazi" ]; then
        log_info "Removing Yazi state..."
        rm -rf "$HOME/.local/state/yazi"
    fi
}

# ============================================================================
# Remove Homebrew Packages
# ============================================================================

remove_brew_packages() {
    if ! command -v brew &>/dev/null; then
        log_warning "Homebrew not found, skipping package removal"
        return
    fi

    log_info "Removing Homebrew packages installed by setup..."


    # List of packages installed by the setup script (full symmetry with install.sh)
    local packages=(
        "sst/tap/opencode"
        "joncrangle/tap/sketchybar-system-stats"
        "1password-cli"
        "fastfetch"
        "btop"
        "lazygit"
        "bat"
        "ripgrep"
        "fzf"
        "fd"
        "eza"
        "zoxide"
        "llvm"
        "go"
        "neovim"
        "tmux"
        "stow"
        "yazi"
        "ffmpeg"
        "sevenzip"
        "jq"
        "poppler"
        "resvg"
        "imagemagick"
        "python"
        "openjdk"
        "maven"
        "rustup-init"
        "bun"
        "uv"
        "meson"
        "conan"
    )

    local casks=(
        "ghostty"
        "zed"
        "visual-studio-code"
        "font-symbols-only-nerd-font"
    )

    # Remove casks
    for cask in "${casks[@]}"; do
        if brew list --cask "$cask" &>/dev/null; then
            log_info "Removing cask: $cask..."
            brew uninstall --cask "$cask" || true
        fi
    done

    # Remove formulae
    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            log_info "Removing package: $package..."
            brew uninstall "$package" || true
        fi
    done

    # Note: We don't remove git and zsh as they might be needed by the system
    log_warning "git and zsh were NOT removed as they may be system dependencies"

    log_success "Homebrew packages removed"
}

remove_homebrew() {
    read -p "Do you also want to remove Homebrew itself? (yes/no): " remove_brew
    if [[ "$remove_brew" == "yes" ]]; then
        log_info "Removing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" || true
        log_success "Homebrew removed"
    else
        log_info "Keeping Homebrew installed"
    fi
}

# ============================================================================
# Restore macOS Settings
# ============================================================================

restore_macos_settings() {
    log_info "Restoring macOS settings..."

    # Re-enable press-and-hold for key repeat
    defaults write -g ApplePressAndHoldEnabled -bool true
    log_success "Re-enabled press-and-hold for key repeat"
}

# ============================================================================
# Clean Up
# ============================================================================

cleanup_empty_dirs() {
    log_info "Cleaning up empty directories..."

    # Remove XDG config home if empty
    if [ -d "$XDG_CONFIG_HOME" ] && [ -z "$(ls -A "$XDG_CONFIG_HOME")" ]; then
        rmdir "$XDG_CONFIG_HOME"
        log_info "Removed empty $XDG_CONFIG_HOME"
    fi

    # Remove XDG cache home if empty
    if [ -d "$XDG_CACHE_HOME" ] && [ -z "$(ls -A "$XDG_CACHE_HOME")" ]; then
        rmdir "$XDG_CACHE_HOME"
        log_info "Removed empty $XDG_CACHE_HOME"
    fi

    log_success "Cleanup complete"
}

# ============================================================================
# Main Uninstall Flow
# ============================================================================

main() {
    # Check if running on macOS
    if [[ "$(uname)" != "Darwin" ]]; then
        log_error "This script is intended for macOS only."
        exit 1
    fi

    confirm_uninstall

    # Unstow dotfiles first (while stow is still installed)
    unstow_dotfiles


    # Remove configurations
    remove_ghostty_config
    remove_zed_config
    remove_yazi_config
    remove_sketchybar_config
    remove_yabai_config
    remove_lazyvim
    remove_oh_my_tmux
    remove_oh_my_zsh

    # Remove Homebrew packages
    remove_brew_packages

    # Restore macOS settings
    restore_macos_settings

    # Optionally remove Homebrew
    remove_homebrew

    # Optionally remove ~/.dotfiles directory
    remove_user_dotfiles

    # Clean up empty directories
    cleanup_empty_dirs

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Uninstall Complete! 🧹                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "The development environment has been removed."
    log_info "You may want to restart your terminal or log out and back in."
    log_warning "If zsh was your default shell, you may need to change it:"
    echo "         chsh -s /bin/bash"
    echo ""
}

main "$@"
