cat <<'EOF' >>"$HOME/.zieds-perfect-setup"

update() {
  echo "Updating packages..."
  brew update && brew upgrade && brew cleanup
  echo "Packages updated successfully."
}
alias update='update'

EOF

if ! grep -q 'update' "$HOME/.zshrc"; then
  echo "Update function and alias added to .zshrc"
else
  echo "Update function and alias already exist in .zshrc"
fi

update() {
  echo "Updating packages..."
  brew update && brew upgrade && brew cleanup
  echo "Packages updated successfully."
}

update # Call the update function to ensure packages are updated immediately
