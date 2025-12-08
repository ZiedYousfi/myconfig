# Nerd Fonts

if [[ -x "$(command -v font-departure-mono)" ]]; then
  echo "font-departure-mono est déjà là, prêt à styler ~✨"
else
  echo "font-departure-mono manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install font-departure-mono
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer font-departure-mono automatiquement…"
  fi
fi


