# opencode
if [[ -x "$(command -v opencode)" ]]; then
  echo "opencode est déjà là, prêt à coder ~✨"
else
  echo "opencode manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install sst/tap/opencode
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer opencode automatiquement…"
  fi
fi

echo "alias oc=\"opencode\"" >> "$HOME/.zieds-perfect-setup"
