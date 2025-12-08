# Development Environment Specification

This document describes the desired development environment in a declarative, platform-agnostic way. Each section is one application with its complete configuration.

## Installation Philosophy

The entire setup should be installable by running **a single script**. The goal is to minimize the number of steps required to go from a fresh system to a fully configured development environment. One command, one execution, everything configured.

---

## Zsh

The shell is Zsh with Oh My Zsh framework.

### Oh My Zsh Configuration

- Theme: `refined`
- Plugins: `git`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `vi-mode`, `zieds`

### Custom Plugin (`zieds.plugin.zsh`)

This plugin is platform-agnostic and should be installed as-is:

```zsh
# Zied's Oh My Zsh plugin

# Environment variables
export PATH="$PATH:$(go env GOPATH)/bin"

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

# Update packages (platform-specific implementation needed)
update() {
  echo "Updating packages..."
  # On macOS: brew update && brew upgrade && brew cleanup
  # On Linux: apt update && apt upgrade (or equivalent)
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
```

---

## Ghostty

Terminal emulator.

### Configuration (`$XDG_CONFIG_HOME/ghostty/config`)

```
fullscreen=true
background = #000000
font-size = 18
font-family = "Departure Mono"
command = <platform-specific command to attach or create tmux session>
```

On macOS, the command is:

```
command = /bin/bash --noprofile --norc -c "/opt/homebrew/bin/tmux has-session 2>/dev/null && /opt/homebrew/bin/tmux attach-session -d || /opt/homebrew/bin/tmux new-session"
```

---

## tmux

Terminal multiplexer with Oh My Tmux framework.

### Setup

- Clone Oh My Tmux from `https://github.com/gpakosz/.tmux.git` to `$HOME/.oh-my-tmux`
- Symlink `$HOME/.oh-my-tmux/.tmux.conf` to `$XDG_CONFIG_HOME/tmux/tmux.conf`
- Copy `$HOME/.oh-my-tmux/.tmux.conf.local` to `$XDG_CONFIG_HOME/tmux/tmux.conf.local`

---

## Neovim

Text editor with LazyVim distribution.

### Setup

- Clone LazyVim starter from `https://github.com/LazyVim/starter` to `$XDG_CONFIG_HOME/nvim`
- Remove the `.git` directory from the cloned config

### Plugin: avante.nvim (`$XDG_CONFIG_HOME/nvim/lua/plugins/avante.lua`)

```lua
return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,
    opts = {
      provider = "copilot",
      providers = {
        copilot = {
          model = "gpt-5-mini",
        },
      },
    },
    build = "make BUILD_FROM_SOURCE=true",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-mini/mini.pick",
      "nvim-telescope/telescope.nvim",
      "hrsh7th/nvim-cmp",
      "ibhagwan/fzf-lua",
      "nvim-tree/nvim-web-devicons",
      "zbirenbaum/copilot.lua",
      {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
          default = {
            embed_image_as_base64 = false,
            prompt_for_file_name = false,
            drag_and_drop = { insert_mode = true },
            use_absolute_path = true,
          },
        },
      },
      {
        "MeanderingProgrammer/render-markdown.nvim",
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
      },
    },
  },
}
```

### Plugin: auto-save.nvim (`$XDG_CONFIG_HOME/nvim/lua/plugins/auto-save.lua`)

```lua
return {
  "Pocco81/auto-save.nvim",
  lazy = false,
  opts = {
    debounce_delay = 500,
    execution_message = {
      message = function()
        return ""
      end,
    },
  },
  keys = {
    { "<leader>uv", "<cmd>ASToggle<CR>", desc = "Toggle autosave" },
  },
}
```

### Plugin: colorscheme (`$XDG_CONFIG_HOME/nvim/lua/plugins/colorscheme.lua`)

```lua
return {
  { "thesimonho/kanagawa-paper.nvim" },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "kanagawa-paper",
    },
  },
}
```

---

## zoxide

Smart directory jumping.

### Behavior

- Typing `z <partial-path>` jumps to the best matching directory
- Typing `zi` opens an interactive directory picker
- Typing `zeze` opens the zoxide database editor
- The full zoxide shell integration must be sourced (hooks for tracking directories)

---

## eza

Modern replacement for `ls`.

### Behavior

- Typing `ls` shows files with icons, directories first, git status, colors always on

---

## fd

Modern replacement for `find`.

### Behavior

- Typing `find` uses fd instead

---

## fzf

Fuzzy finder.

### Behavior

- Available for interactive file/directory selection
- Integrated with bat for file previews via the `pf` function

---

## ripgrep

Modern replacement for `grep`.

### Behavior

- Typing `grep` uses ripgrep
- Typing `rg` uses ripgrep with smart defaults (color, smart-case, hidden files, common excludes)

---

## bat

Modern replacement for `cat` with syntax highlighting.

---

## lazygit

Terminal UI for git.

### Behavior

- Typing `lg` opens lazygit

---

## Git

Version control. Must be installed before other tools that clone repositories.

---

## Go

Go programming language.

### Behavior

- Go binaries (`$(go env GOPATH)/bin`) must be in PATH

---

## Clang

C/C++ compiler (installed via LLVM package).

---

## btop

Resource monitor for CPU, memory, disk, and network.

---

## fastfetch

System information display.

### Behavior

- Typing `ff` shows system information

---

## opencode

AI coding assistant CLI.

### Behavior

- Typing `oc` opens opencode

---

## Departure Mono

Nerd Font used by terminal and editor. Must be installed system-wide.

---

## Platform-Specific Notes

### macOS

- Disable press-and-hold for key repeat: `defaults write ApplePressAndHoldEnabled -bool false`
- `bootout-gui` function available: `bootout-gui() { launchctl bootout gui/$UID }`

---

## Idempotency

Running the setup multiple times must be safe and produce the same result. Tools already installed should be skipped.
