#!/bin/bash

# Ubuntu Server Development Environment Uninstall Script
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
    echo "║       Ubuntu Server Environment Uninstaller                    ║"
    echo "║                     ⚠️  WARNING ⚠️                              ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_warning "This script will remove:"
    echo "  - Oh My Zsh and all plugins"
    echo "  - Oh My Tmux"
    echo "  - LazyVim configuration"
    echo "  - Stowed dotfiles symlinks"
    echo "  - ~/dotfiles directory (optionally)"
    echo "  - Installed packages (optionally)"
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

        for package in ghostty nvim tmux zed zsh yazi; do
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
}

# ============================================================================
# Remove Oh My Zsh
# ============================================================================

remove_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        log_info "Removing Oh My Zsh..."
        rm -rf "$HOME/.oh-my-zsh"
        log_success "Oh My Zsh removed"
    else
        log_warning "Oh My Zsh not found"
    fi

    # Restore default shell to bash
    local current_shell=$(getent passwd "$USER" | cut -d: -f7)
    if [[ "$current_shell" == */zsh ]]; then
        log_info "Restoring default shell to bash..."
        chsh -s /bin/bash || true
        log_success "Default shell restored to bash"
    fi
}

# ============================================================================
# Remove Oh My Tmux
# ============================================================================

remove_oh_my_tmux() {
    local OH_MY_TMUX_DIR="$HOME/.oh-my-tmux"
    local TMUX_CONFIG_DIR="$XDG_CONFIG_HOME/tmux"

    if [ -d "$OH_MY_TMUX_DIR" ]; then
        log_info "Removing Oh My Tmux..."
        rm -rf "$OH_MY_TMUX_DIR"
        log_success "Oh My Tmux removed"
    else
        log_warning "Oh My Tmux not found"
    fi

    if [ -L "$TMUX_CONFIG_DIR/tmux.conf" ]; then
        log_info "Removing tmux.conf symlink..."
        rm -f "$TMUX_CONFIG_DIR/tmux.conf"
        log_success "tmux.conf symlink removed"
    fi
}

# ============================================================================
# Remove LazyVim
# ============================================================================

remove_lazyvim() {
    local NVIM_CONFIG_DIR="$XDG_CONFIG_HOME/nvim"

    if [ -d "$NVIM_CONFIG_DIR" ]; then
        log_info "Removing Neovim configuration..."
        rm -rf "$NVIM_CONFIG_DIR"
        log_success "Neovim configuration removed"
    else
        log_warning "Neovim configuration not found"
    fi

    # Also remove Neovim cache and data
    rm -rf "$XDG_CACHE_HOME/nvim"
    rm -rf "$HOME/.local/share/nvim"
    rm -rf "$HOME/.local/state/nvim"
    log_success "Neovim cache and data removed"
}

# ============================================================================
# Remove Yazi Configuration
# ============================================================================

remove_yazi() {
    local YAZI_CONFIG_DIR="$XDG_CONFIG_HOME/yazi"

    if [ -d "$YAZI_CONFIG_DIR" ]; then
        log_info "Removing Yazi configuration..."
        rm -rf "$YAZI_CONFIG_DIR"
        log_success "Yazi configuration removed"
    else
        log_warning "Yazi configuration not found"
    fi

    rm -rf "$HOME/.local/state/yazi"
    log_success "Yazi state removed"
}

# ============================================================================
# Remove Zshrc
# ============================================================================

remove_zshrc() {
    if [ -f "$HOME/.zshrc" ] && grep -q "# Managed by setup-config" "$HOME/.zshrc"; then
        log_info "Removing managed .zshrc..."
        rm -f "$HOME/.zshrc"
        log_success ".zshrc removed"

        # Restore backup if exists
        local latest_backup=$(ls -t "$HOME"/.zshrc.backup.* 2>/dev/null | head -n1)
        if [ -n "$latest_backup" ]; then
            log_info "Restoring backup: $latest_backup"
            mv "$latest_backup" "$HOME/.zshrc"
            log_success "Backup restored"
        fi
    else
        log_warning ".zshrc not managed by setup-config or not found"
    fi
}

# ============================================================================
# Remove Installed Tools (Optional)
# ============================================================================

remove_installed_tools() {
    read -p "Do you want to remove installed tools (neovim, lazygit, yazi, etc.)? (yes/no): " remove_tools
    if [[ "$remove_tools" != "yes" ]]; then
        log_info "Keeping installed tools"
        return
    fi

    log_info "Removing installed tools..."

    # Remove Neovim
    if [ -d "/opt/nvim-linux64" ]; then
        sudo rm -rf /opt/nvim-linux64
        sudo rm -f /usr/local/bin/nvim
        log_success "Neovim removed"
    fi

    # Remove lazygit
    if [ -f "/usr/local/bin/lazygit" ]; then
        sudo rm -f /usr/local/bin/lazygit
        log_success "lazygit removed"
    fi

    # Remove yazi
    if [ -f "/usr/local/bin/yazi" ]; then
        sudo rm -f /usr/local/bin/yazi
        sudo rm -f /usr/local/bin/ya
        log_success "yazi removed"
    fi

    # Remove Go
    if [ -d "/usr/local/go" ]; then
        sudo rm -rf /usr/local/go
        rm -rf "$HOME/go"
        log_success "Go removed"
    fi

    # Remove Rust
    if [ -d "$HOME/.rustup" ]; then
        rm -rf "$HOME/.rustup"
        rm -rf "$HOME/.cargo"
        log_success "Rust removed"
    fi

    # Remove Bun
    if [ -d "$HOME/.bun" ]; then
        rm -rf "$HOME/.bun"
        log_success "Bun removed"
    fi

    # Remove zoxide
    rm -f "$HOME/.local/bin/zoxide"
    log_success "zoxide removed"

    # Remove fd symlink
    rm -f "$HOME/.local/bin/fd"

    # Remove bat symlink
    rm -f "$HOME/.local/bin/bat"

    log_success "Installed tools removed"
}

# ============================================================================
# Remove APT Packages (Optional)
# ============================================================================

remove_apt_packages() {
    read -p "Do you want to remove apt packages installed by setup? (yes/no): " remove_apt
    if [[ "$remove_apt" != "yes" ]]; then
        log_info "Keeping apt packages"
        return
    fi

    log_info "Removing apt packages..."

    local packages=(
        "btop"
        "fzf"
        "ripgrep"
        "bat"
        "fd-find"
        "eza"
        "jq"
        "ffmpeg"
        "p7zip-full"
        "poppler-utils"
        "imagemagick"
        "openjdk-21-jdk"
        "maven"
        "llvm"
        "clang"
        "clangd"
    )

    for pkg in "${packages[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            log_info "Removing $pkg..."
            sudo apt remove -y "$pkg" 2>/dev/null || true
        fi
    done

    sudo apt autoremove -y
    log_success "apt packages removed"
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

    # Unstow all dotfiles first
    unstow_dotfiles

    # Remove configurations
    remove_zshrc
    remove_oh_my_zsh
    remove_oh_my_tmux
    remove_lazyvim
    remove_yazi

    # Optionally remove ~/dotfiles
    remove_user_dotfiles

    # Optionally remove installed tools
    remove_installed_tools

    # Optionally remove apt packages
    remove_apt_packages

    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Uninstall Complete! 🧹                                 ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    log_info "The development environment has been removed."
    log_info "Please restart your terminal for all changes to take effect."
    echo ""
}

main "$@"
