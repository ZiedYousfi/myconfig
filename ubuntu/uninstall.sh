#!/bin/bash

# Ubuntu Development Environment Uninstall Script
# This script removes everything installed by install.sh
# Use with caution - this will remove configurations and installed packages

set -e

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

# ============================================================================
# Confirmation
# ============================================================================

confirm_uninstall() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Ubuntu Development Environment Uninstaller             ║"
    echo "║                     ⚠️  WARNING ⚠️                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_warning "This script will remove:"
    echo "  - Oh My Zsh and all plugins"
    echo "  - Oh My Tmux"
    echo "  - LazyVim configuration"
    echo "  - Ghostty and its configuration"
    echo "  - Stowed dotfiles symlinks"
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
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local DOTFILES_DIR="$SCRIPT_DIR/dotfiles"

    if command -v stow &>/dev/null && [ -d "$DOTFILES_DIR" ]; then
        log_info "Unstowing dotfiles..."

        for package in ghostty nvim tmux zsh; do
            if [ -d "$DOTFILES_DIR/$package" ]; then
                log_info "Unstowing $package..."
                stow --dir="$DOTFILES_DIR" --target="$HOME" --delete "$package" 2>/dev/null || true
            fi
        done

        log_success "Dotfiles unstowed"
    else
        log_warning "Stow not found or dotfiles directory missing, skipping unstow"
    fi
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

remove_ghostty() {
    # Remove Ghostty configuration
    if [ -d "$XDG_CONFIG_HOME/ghostty" ]; then
        log_info "Removing Ghostty configuration..."
        rm -rf "$XDG_CONFIG_HOME/ghostty"
        log_success "Ghostty configuration removed"
    else
        log_info "Ghostty configuration not found, skipping"
    fi

    # Remove Ghostty binary if installed via community script
    if command -v ghostty &>/dev/null; then
        log_info "Ghostty binary found. It was installed via community script."
        log_warning "You may need to manually remove Ghostty depending on how it was installed."
        log_info "Check: which ghostty"
    fi
}

# ============================================================================
# Remove Homebrew Packages
# ============================================================================

remove_brew_packages() {
    # Source Homebrew environment if available
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -d "$HOME/.linuxbrew" ]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi

    if ! command -v brew &>/dev/null; then
        log_warning "Homebrew not found, skipping package removal"
        return
    fi

    log_info "Removing Homebrew packages installed by setup..."

    # List of packages installed by the setup script
    local packages=(
        "sst/tap/opencode"
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
    )

    # Remove formulae
    for package in "${packages[@]}"; do
        if brew list "$package" &>/dev/null; then
            log_info "Removing package: $package..."
            brew uninstall "$package" || true
        fi
    done

    # Note: We don't remove git and zsh as they might be needed by the system
    log_warning "git, zsh, and stow were NOT removed as they may be system dependencies"

    log_success "Homebrew packages removed"
}

remove_homebrew() {
    # Source Homebrew environment if available
    if [ -d "/home/linuxbrew/.linuxbrew" ]; then
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    elif [ -d "$HOME/.linuxbrew" ]; then
        eval "$($HOME/.linuxbrew/bin/brew shellenv)"
    fi

    if ! command -v brew &>/dev/null; then
        log_info "Homebrew not found, skipping"
        return
    fi

    read -p "Do you also want to remove Homebrew itself? (yes/no): " remove_brew
    if [[ "$remove_brew" == "yes" ]]; then
        log_info "Removing Homebrew..."
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)" || true

        # Remove Homebrew directories
        if [ -d "/home/linuxbrew/.linuxbrew" ]; then
            log_info "Removing /home/linuxbrew/.linuxbrew..."
            sudo rm -rf /home/linuxbrew/.linuxbrew
        fi

        if [ -d "$HOME/.linuxbrew" ]; then
            log_info "Removing $HOME/.linuxbrew..."
            rm -rf "$HOME/.linuxbrew"
        fi

        log_success "Homebrew removed"
    else
        log_info "Keeping Homebrew installed"
    fi
}

# ============================================================================
# Remove System Packages (Optional)
# ============================================================================

remove_apt_packages() {
    read -p "Do you want to remove apt packages (stow)? (yes/no): " remove_apt
    if [[ "$remove_apt" == "yes" ]]; then
        log_info "Removing apt packages..."
        sudo apt remove -y stow || true
        sudo apt autoremove -y
        log_success "apt packages removed"
    else
        log_info "Keeping apt packages installed"
    fi
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
    # Check if running on Linux
    if [[ "$(uname)" != "Linux" ]]; then
        log_error "This script is intended for Linux only."
        exit 1
    fi

    confirm_uninstall

    # Unstow dotfiles first (while stow is still installed)
    unstow_dotfiles

    # Remove configurations
    remove_ghostty
    remove_lazyvim
    remove_oh_my_tmux
    remove_oh_my_zsh

    # Remove Homebrew packages
    remove_brew_packages

    # Optionally remove Homebrew
    remove_homebrew

    # Optionally remove apt packages
    remove_apt_packages

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
