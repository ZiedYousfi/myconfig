# ghostty
if [[ -x "$(command -v ghostty)" ]]; then
  echo "ghostty est déjà là, prêt à hanter ~✨"
else
  echo "ghostty manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install ghostty
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer ghostty automatiquement…"
  fi
fi

rm -rf "$XDG_CONFIG_HOME/ghostty"
mkdir -p "$XDG_CONFIG_HOME/ghostty"
touch "$XDG_CONFIG_HOME/ghostty/config"
cat > "$XDG_CONFIG_HOME/ghostty/config" <<EOF
fullscreen=true
background = #000000
font-size = 18
font-family = "Departure Mono"
command = /bin/bash --noprofile --norc -c "/opt/homebrew/bin/tmux has-session 2>/dev/null && /opt/homebrew/bin/tmux attach-session -d || /opt/homebrew/bin/tmux new-session"
EOF

echo "export TERM=\"xterm-256color\"" >>"$HOME/.zieds-perfect-setup"
