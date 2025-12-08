# fzf
cat <<'EOF' >>"$HOME/.zieds-perfect-setup"
pf() {
  local file
  file=$(fzf --preview='bat {} --color=always --style=numbers' --bind shift-up:preview-page-up,shift-down:preview-page-down)
  [ -n "$file" ] && nvim "$file"
}
EOF
if [[ -x "$(command -v fzf)" ]]; then
  echo "fzf est déjà là, prêt à fuzzer ~✨"
else
  echo "fzf manque à l'appel… Invocation en cours via Homebrew !"
  if [[ -x "$(command -v brew)" ]]; then
    brew install fzf
  else
    echo "Homebrew n'est pas installé, impossible d'invoquer fzf automatiquement…"
  fi
fi
