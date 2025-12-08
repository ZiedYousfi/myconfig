#!/bin/bash
# Install fastfetch on macOS
if ! command -v fastfetch &> /dev/null; then
  brew install fastfetch
fi

if ! grep -q 'alias ff="fastfetch"' "$HOME/.zieds-perfect-setup"; then
  echo 'alias ff="fastfetch"' >> "$HOME/.zieds-perfect-setup"
fi
