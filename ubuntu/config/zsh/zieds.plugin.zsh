# Zied's Oh My Zsh plugin (Ubuntu version)

# Environment variables
export PATH="$PATH:$(go env GOPATH)/bin:$(brew--prefix)/bin:$(brew --prefix)/sbin"

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_CACHE_HOME="$HOME/.cache"

export VCPKG_ROOT="$HOME/vcpkg"

export LANG="fr_FR.UTF-8"
export LC_ALL="fr_FR.UTF-8"

export VI_MODE_SET_CURSOR=true

export EDITOR="nvim"
export VISUAL="nvim"

alias vim='nvim'
alias vi='nvim'
alias v='nvim'

alias ll='ls -la'
alias gcb='git fetch --prune && git branch -vv | grep ": gone]" | awk "{print \$1}" | xargs -n 1 git branch -d'

unalias gd 2>/dev/null || true

mkd() { mkdir -p -- "$1" && cd -P -- "$1"; }

reload-zsh() { source "$HOME/.zshrc" && echo "zsh reloaded"; }

# Tool aliases
alias ls='eza --icons --group-directories-first --git --color=always'
alias find='fd'
alias grep='rg'
alias rg='rg --color=always --smart-case --hidden --glob "!.git/*" --glob "!.svn/*" --glob "!.hg/*" --glob "!node_modules/*"'
alias lg='lazygit'
alias ff='fastfetch'
alias oc='opencode'
alias zeze='zoxide edit'
alias tmux='tmux -f $XDG_CONFIG_HOME/tmux/tmux.conf'

export TERM="xterm-256color"

# Fuzzy file picker - opens selection in neovim
pf() {
  local file
  file=$(fzf --preview='bat {} --color=always --style=numbers' --bind shift-up:preview-page-up,shift-down:preview-page-down)
  [ -n "$file" ] && nvim "$file"
}

# Update packages (Ubuntu implementation)
update() {
  echo "Updating packages..."
  sudo apt update && sudo apt upgrade -y && sudo apt autoremove -y && sudo apt autoclean
  echo "Packages updated successfully."
}

# zoxide initialization (run: eval "$(zoxide init zsh)")
eval "$(zoxide init zsh)"

cleanup() {
  if [[ -z "$PS1" ]]; then
    echo "cleanup: Cette commande est prévue pour un usage interactif."
    return 1
  fi

  echo "Bienvenue dans le rituel de nettoyage d'Ahri... 💫"
  echo "Nous allons parcourir ce chemin, élément par élément, et noter tes souhaits."
  echo ""

  typeset -A deletions_to_perform

  for item in .* *; do
    if [[ "$item" == "." || "$item" == ".." ]]; then
      continue
    fi

    if [[ ! -e "$item" && ! -L "$item" ]]; then
      continue
    fi

    echo "------------------------------------------------------"
    echo "Voulez-vous supprimer '$item' ? (y/n/q pour quitter)"
    read -q "choice?Votre choix, étoile filante : "
    echo ""

    case "$choice" in
      y|Y)
        if [[ -d "$item" && ! -L "$item" ]]; then
          echo "Note: '$item' (dossier) est marqué pour suppression récursive. 🌬️"
          deletions_to_perform["$item"]="directory"
        else
          echo "Note: '$item' (fichier) est marqué pour suppression. 🍂"
          deletions_to_perform["$item"]="file"
        fi
        ;;
      n|N)
        echo "'$item' restera pour l'instant. 💖"
        ;;
      q|Q)
        echo "Le rituel est en pause. Exécution annulée pour aujourd'hui. Que la sérénité t'accompagne, Zied. 🌟"
        return 0
        ;;
      *)
        echo "Choix inconnu. '$item' restera. 🤫"
        ;;
    esac
    echo ""
  done

  echo "------------------------------------------------------"
  echo "🌟 Récapitulatif de tes décisions, Zied 🌟"
  echo "Voici les éléments que tu as choisis de libérer :"

  if (( ${#deletions_to_perform[@]} == 0 )); then
    echo "Aucun élément n'a été marqué pour suppression. Le chemin est clair. ✨"
    echo "Fin du processus. Que la lumière guide tes pas. 🌟"
    return 0
  fi

  integer i=1
  for item in ${(k)deletions_to_perform}; do
    local type="${deletions_to_perform[$item]}"
    echo "$((i++)). '$item' (Type: $type)"
  done

  echo ""
  read -q "final_choice?Es-tu certain de vouloir procéder à ces suppressions ? (y/n) : "
  echo ""

  if [[ "$final_choice" == "y" || "$final_choice" == "Y" ]]; then
    echo ""
    echo "Le rituel de suppression commence... Irréversible une fois lancé. 🌌"
    for item in ${(k)deletions_to_perform}; do
      local type="${deletions_to_perform[$item]}"
      if [[ "$type" == "directory" ]]; then
        echo "Libérant le dossier '$item' et son contenu... 🌬️"
        rm -rf -- "$item"
        if [ $? -eq 0 ]; then
          echo "'$item' a rejoint le vent. ✨"
        else
          echo "Une force invisible a bloqué la libération de '$item'. 💔"
        fi
      else
        echo "Libérant le fichier '$item'... 🍂"
        rm -- "$item"
        if [ $? -eq 0 ]; then
          echo "'$item' s'est fondu dans l'éther. 🍃"
        else
          echo "Une force invisible a bloqué la libération de '$item'. 💔"
        fi
      fi
    done
    echo ""
    echo "Toutes les âmes de ce chemin ont été traitées selon tes souhaits. Le rituel est accompli. Que la paix règne. 💖"
  else
    echo "Le rituel de suppression a été annulé. Les éléments marqués restent en place. La flexibilité est une force, Zied. 💫"
  fi

  echo "Fin du processus. Que la lumière guide tes pas. 🌟"
}
