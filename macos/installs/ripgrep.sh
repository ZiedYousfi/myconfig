# ripgrep
if [[ -x "$(command -v rg)" ]]; then
  echo "ripgrep est déjà là, prêt à chercher ~✨"
else
  echo "ripgrep manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install ripgrep
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer ripgrep automatiquement…"
  fi
fi

echo "alias rg='rg --color=always --smart-case --hidden --glob \"!.git/*\" --glob \"!.svn/*\" --glob \"!.hg/*\" --glob \"!node_modules/*\"'" >>"$HOME/.zieds-perfect-setup"
echo "alias grep='rg'" >>"$HOME/.zieds-perfect-setup"
