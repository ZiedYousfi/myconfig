# cmake
if [[ -x "$(command -v cmake)" ]]; then
  echo "cmake est déjà là, prêt à construire des projets ~✨"
else
  echo "cmake manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install cmake
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer cmake automatiquement…"
  fi
fi
