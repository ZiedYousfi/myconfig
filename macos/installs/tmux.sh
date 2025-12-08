rm -rf "$HOME/.oh-my-tmux"
rm -rf "$XDG_CONFIG_HOME/tmux"

# Tmux
if [[ -x "$(command -v tmux)" ]]; then
  echo "tmux est déjà là, prêt à ouvrir ses fenêtres sur tes rêves ~✨"
else
  echo "tmux manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install tmux
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer tmux automatiquement…"
  fi
fi

# Oh My Tmux
git clone --single-branch https://github.com/gpakosz/.tmux.git "$HOME/.oh-my-tmux"
mkdir -p "$XDG_CONFIG_HOME/tmux"
ln -s "$HOME/.oh-my-tmux/.tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"
cp "$HOME/.oh-my-tmux/.tmux.conf.local" "$XDG_CONFIG_HOME/tmux/tmux.conf.local"

echo "alias tmux='tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf'" >> "$HOME/.zieds-perfect-setup"
