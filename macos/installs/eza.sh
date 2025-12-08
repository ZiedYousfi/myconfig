# eza
echo "alias ls='eza --icons --group-directories-first --git --color=always'" >> "$HOME/.zieds-perfect-setup"
if [[ -x "$(command -v eza)" ]]; then
  echo "eza est déjà là, prêt à lister ~✨"
else
  echo "eza manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install eza
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer eza automatiquement…"
  fi
fi
