# vcpkg
if [[ -x "$(command -v vcpkg)" ]]; then
  echo "vcpkg est déjà là, prêt à gérer les paquets ~✨"
else
  echo "vcpkg manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install vcpkg
    git clone https://github.com/microsoft/vcpkg "$HOME/vcpkg"
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer vcpkg automatiquement…"
  fi
fi
