# clang
if [[ -x "$(command -v clang)" ]]; then
  echo "clang est déjà là, prêt à compiler ~✨"
else
  if [[ -x "$(command -v brew)" ]]; then
    brew install llvm
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer clang automatiquement…"
  fi
fi
