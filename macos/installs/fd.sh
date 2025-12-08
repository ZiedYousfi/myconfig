# fd
if [[ -x "$(command -v fd)" ]]; then
  echo "fd est déjà là, prêt à chercher ~✨"
else
  echo "fd manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install fd
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer fd automatiquement…"
  fi
fi

echo "alias find='fd'" >> "$HOME/.zieds-perfect-setup"
