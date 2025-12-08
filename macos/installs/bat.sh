# bat
if [[ -x "$(command -v bat)" ]]; then
  echo "bat est déjà là, prêt à voler ~✨"
else
  echo "bat manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install bat
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer bat automatiquement…"
  fi
fi
