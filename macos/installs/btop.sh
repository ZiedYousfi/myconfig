# btop
if [[ -x "$(command -v btop)" ]]; then
  echo "btop est déjà là, prêt à monitorer ~✨"
else
  echo "btop manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install btop
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer btop automatiquement…"
  fi
fi
