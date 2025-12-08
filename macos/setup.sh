#!/usr/bin/env bash

# Ensure Homebrew
if [[ -x "$(command -v brew)" ]]; then
  echo "Homebrew est déjà installé ~✨"
else
  echo "Homebrew n'est pas installé, petit renard…"
  echo "Installation de Homebrew… 🦊"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Ensure Git
if [[ -x "$(command -v git)" ]]; then
  echo "Git est déjà installé ~✨"
else
  echo "Git n'est pas installé, petit renard…"
  echo "Installation de Git… 🦊"
  brew install git
fi

# Install Oh My Zsh non-interactively
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  echo "Oh My Zsh est déjà installé ~✨"
else
  echo "Installation d'Oh My Zsh (non-interactive)…"
  export RUNZSH=no
  export CHSH=no
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# Set ZSH theme to refined (macOS sed)
if [[ -f "$HOME/.zshrc" ]]; then
  if grep -q '^ZSH_THEME=' "$HOME/.zshrc"; then
    sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="refined"/' "$HOME/.zshrc"
  else
    echo 'ZSH_THEME="refined"' >> "$HOME/.zshrc"
  fi

  # Ensure recommended plugins are enabled (we will also add 'zieds' plugin)
  if grep -q '^plugins=' "$HOME/.zshrc"; then
    sed -i '' 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting vi-mode zieds)/' "$HOME/.zshrc"
  else
    echo 'plugins=(git zsh-autosuggestions zsh-syntax-highlighting vi-mode zieds)' >> "$HOME/.zshrc"
  fi
fi

# Install our custom Oh My Zsh plugin into the user's custom plugins dir
if [[ -d "$HOME/.oh-my-zsh" ]]; then
  mkdir -p "$HOME/.oh-my-zsh/custom/plugins/zieds"
  cp -a "$(pwd)/oh-my-zsh/zieds.plugin.zsh" "$HOME/.oh-my-zsh/custom/plugins/zieds/zieds.plugin.zsh"
  echo "Installed zieds plugin to ~/.oh-my-zsh/custom/plugins/zieds"
  git clone https://github.com/zsh-users/zsh-autosuggestions $HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
else
  echo "Oh My Zsh not found; skipping plugin installation"
fi

# ensure config file used by installers is reset
rm -f "$HOME/.zieds-perfect-setup"

defaults write ApplePressAndHoldEnabled -bool false

# Guarantee .zshrc sources our aggregated config
if ! grep -q 'source ~/.zieds-perfect-setup' "$HOME/.zshrc"; then
  echo 'source ~/.zieds-perfect-setup' >>"$HOME/.zshrc"
  echo "source ~/.zieds-perfect-setup ajouté à votre .zshrc"
else
  echo "source ~/.zieds-perfect-setup est déjà dans votre .zshrc"
fi

# Run installs
source ./install.sh

# Update helper
source ./update.sh
