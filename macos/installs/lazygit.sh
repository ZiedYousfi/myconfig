#!/bin/bash

# lazygit
if [[ -x "$(command -v lazygit)" ]]; then
  echo "lazygit est déjà là, prêt à gérer tes commits ~✨"
else
  echo "lazygit manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install lazygit
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer lazygit automatiquement…"
  fi
fi

echo "alias lg='lazygit'" >>"$HOME/.zieds-perfect-setup"

