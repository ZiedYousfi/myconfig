# go
if [[ -x "$(command -v go)" ]]; then
  echo "go est déjà là, prêt à coder ~✨"
else
  echo "go manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install go
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer go automatiquement…"
  fi
fi

echo "alias find='fd'" >> "$HOME/.zieds-perfect-setup"

