#!/bin/bash

# Arch Linux Development Environment Setup Script
# Idempotent installer using pacman + paru (AUR) only.
# Dotfiles are managed via GNU Stow and placed in ~/.dotfiles.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DOTFILES_DIR="$SCRIPT_DIR/dotfiles"
USER_DOTFILES_DIR="$HOME/.dotfiles"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info(){ echo -e "${BLUE}[INFO]${NC} $1"; }
log_success(){ echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning(){ echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error(){ echo -e "${RED}[ERROR]${NC} $1"; }

export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

mkdir -p "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"

install_paru() {
  if command -v paru &>/dev/null; then
    log_success "paru is already installed"
    return 0
  fi

  log_info "Installing paru (AUR helper)..."
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp
  tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/paru.git "$tmp/paru"
  cd "$tmp/paru"
  makepkg -si --noconfirm
  cd -
  rm -rf "$tmp"
  log_success "paru installed"
}

get_aur_helper() {
  echo "paru"
}

install_pacman_package() {
  local pkg="$1"
  if pacman -Qi "$pkg" &>/dev/null; then
    log_success "$pkg is already installed"
  else
    log_info "Installing $pkg..."
    sudo pacman -S --needed --noconfirm "$pkg"
    log_success "$pkg installed"
  fi
}

install_aur_package() {
  local pkg="$1"
  if paru -Qi "$pkg" &>/dev/null; then
    log_success "$pkg (AUR) already installed"
    return
  fi

  log_info "Installing $pkg (AUR via paru)..."
  paru -S --needed --noconfirm "$pkg"
  log_success "$pkg (AUR) installed"
}

install_packages() {
  log_info "Installing pacman packages..."
  install_pacman_package git
  install_pacman_package stow
  install_pacman_package zsh
  install_pacman_package tmux
  install_pacman_package neovim
  install_pacman_package go
  install_pacman_package clang
  install_pacman_package rsync
  install_pacman_package zoxide
  install_pacman_package eza
  install_pacman_package fd
  install_pacman_package fzf
  install_pacman_package ripgrep
  install_pacman_package bat
  install_pacman_package lazygit
  install_pacman_package btop
  install_pacman_package fastfetch
  install_pacman_package niri
  install_pacman_package waybar
  install_pacman_package ttf-hack-nerd
  install_pacman_package wireplumber
  install_pacman_package pipewire-pulse
  install_pacman_package fuzzel
  install_pacman_package swaylock
  install_pacman_package brightnessctl
  install_pacman_package grim
  install_pacman_package slurp

  log_info "Installing AUR packages via paru..."
  install_aur_package ghostty
  install_aur_package zed-editor
  install_aur_package opencode-bin || log_warning "opencode-bin not available in AUR"
  log_success "All packages installed"
}

copy_dotfiles() {
  log_info "Copying dotfiles to $USER_DOTFILES_DIR..."
  mkdir -p "$USER_DOTFILES_DIR"
  for pkg in ghostty nvim tmux zed zsh niri waybar; do
    if [ -d "$REPO_DOTFILES_DIR/$pkg" ]; then
      rsync -a --update "$REPO_DOTFILES_DIR/$pkg/" "$USER_DOTFILES_DIR/$pkg/"
    fi
  done
  log_success "Dotfiles copied"
}

stow_package() {
  local pkg="$1"
  local target="${2:-$HOME}"
  log_info "Stowing $pkg to $target..."
  if stow --dir="$USER_DOTFILES_DIR" --target="$target" --restow --no-folding "$pkg" &>/dev/null; then
    log_success "$pkg stowed successfully"
  else
    log_warning "Conflict detected while stowing $pkg. Manual resolution may be required."
  fi
}

install_oh_my_zsh() {
  if [ -d "$HOME/.oh-my-zsh" ]; then
    log_success "Oh My Zsh already installed"
    return
  fi
  log_info "Installing Oh My Zsh..."
  RUNZSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
}

install_zsh_plugins() {
  local custom="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
  [ -d "$custom/plugins/zsh-autosuggestions" ] || git clone https://github.com/zsh-users/zsh-autosuggestions "$custom/plugins/zsh-autosuggestions"
  [ -d "$custom/plugins/zsh-syntax-highlighting" ] || git clone https://github.com/zsh-users/zsh-syntax-highlighting "$custom/plugins/zsh-syntax-highlighting"
  stow_package zsh
}

configure_zshrc() {
  log_info "Writing ~/.zshrc"
  cat > "$HOME/.zshrc" <<'EOF'
# Managed by setup-config
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="refined"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting vi-mode zieds)
source $ZSH/oh-my-zsh.sh
EOF
  log_success ".zshrc configured"
}

install_oh_my_tmux() {
  local oh="$HOME/.oh-my-tmux"
  local conf="$XDG_CONFIG_HOME/tmux"
  if [ ! -d "$oh" ]; then
    git clone https://github.com/gpakosz/.tmux.git "$oh"
  fi
  mkdir -p "$conf"
  ln -sf "$oh/.tmux.conf" "$conf/tmux.conf"
  stow_package tmux
}

install_lazyvim() {
  local conf="$XDG_CONFIG_HOME/nvim"
  if [ -d "$conf" ] && [ -f "$conf/lua/config/lazy.lua" ]; then
    log_success "LazyVim already present"
    return
  fi
  [ -d "$conf" ] && mv "$conf" "$conf.backup.$(date +%s)"
  git clone https://github.com/LazyVim/starter "$conf"
  rm -rf "$conf/.git"
  stow_package nvim
}

configure_ghostty() { stow_package ghostty; }
configure_zed() { stow_package zed; }
configure_niri() { stow_package niri; }
configure_waybar() { stow_package waybar; }

configure_locale() {
  log_info "Configuring fr_FR locale..."
  if ! locale -a | grep -q "fr_FR.utf8"; then
    sudo sed -i 's/^#fr_FR.UTF-8/fr_FR.UTF-8/' /etc/locale.gen
    sudo locale-gen
  fi
}

set_default_shell() {
  if [ "$SHELL" != "/bin/zsh" ]; then
    chsh -s /bin/zsh
  fi
}

setup_screenshots_dir() {
  mkdir -p "$HOME/Pictures/Screenshots"
}

main() {
  [[ -f /etc/arch-release ]] || { log_error "Arch Linux required."; exit 1; }
  install_paru
  AUR_HELPER=$(get_aur_helper)
  log_info "Using AUR helper: $AUR_HELPER"
  install_packages
  copy_dotfiles
  configure_locale
  install_oh_my_zsh
  install_zsh_plugins
  configure_zshrc
  install_oh_my_tmux
  install_lazyvim
  configure_ghostty
  configure_zed
  configure_niri
  configure_waybar
  setup_screenshots_dir
  set_default_shell
  log_success "Installation complete! Log out/in and run 'source ~/.zshrc'."
}

main "$@"
