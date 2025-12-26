# zieds.plugin.zsh
# Lightweight placeholder plugin implementing helpers, aliases and environment
# bits referenced by the repository SPECS.md.
#
# Drop-in plugin for Oh My Zsh:
#   ~/.oh-my-zsh/custom/plugins/zieds/zieds.plugin.zsh
#
# Features:
#   - environment variables (DOTFILES, ZIEDS_LOADED)
#   - aliases (v, vim, vi, ll, lg, ff, oc)
#   - helper functions:
#       mkd        - mkdir -p and cd into it
#       use-tmux   - attach/create named tmux session
#       reload-zsh - reload the active zsh configuration
#       pf         - fuzzy file picker that opens selection in $EDITOR (nvim)
#       update     - run platform-appropriate update command (uses UPDATE_CMD if set)
#       cleanup    - interactive file/directory removal via fzf
#       zeze       - open zoxide database in editor
#       zieds-help - print a short usage summary
#
# Safe: multiple-sourcing is harmless (guarded with ZIEDS_LOADED).
# Intended as a portable starting point; adapt and extend in your dotfiles.

if [[ -n "${ZIEDS_LOADED:-}" ]]; then
  return 0
fi
typeset -gx ZIEDS_LOADED=1

# Default dotfiles directory (can be overridden by SETUP_CONFIG_DOTFILES env var)
if [[ -n "${SETUP_CONFIG_DOTFILES:-}" ]]; then
  typeset -gx DOTFILES="${SETUP_CONFIG_DOTFILES}"
else
  typeset -gx DOTFILES="${HOME}/.dotfiles"
fi

# Useful defaults
typeset -gx ZIEDS_PLUGIN_DIR="${${(%):-%x}:a:h}" 2>/dev/null || true  # path to this plugin file's dir (best-effort)
typeset -gx EDITOR="${EDITOR:-nvim}"
typeset -gx VISUAL="${VISUAL:-$EDITOR}"

# Aliases aligned with SPECS.md
alias v='nvim'
alias vim='nvim'
alias vi='nvim'
alias ll='ls -la'
alias lg='lazygit'
alias ff='fastfetch'
alias oc='opencode 2>/dev/null || echo "opencode (oc) not found"'

# Helpers --------------------------------------------------------------------

# mkd: make directory and cd into it
mkd() {
  if [[ $# -eq 0 ]]; then
    echo "mkd: missing directory name"
    return 1
  fi
  mkdir -p -- "$1" && cd -- "$1"
}

# use-tmux: attach to or create a tmux session
use-tmux() {
  local session="${1:-main}"

  if ! command -v tmux >/dev/null 2>&1; then
    echo "use-tmux: tmux not found"
    return 1
  fi

  # If session exists, attach; otherwise create a new session
  if tmux has-session -t "${session}" 2>/dev/null; then
    tmux attach -t "${session}"
  else
    tmux new -s "${session}"
  fi
}

# reload-zsh: reload zsh configuration (safely)
reload-zsh() {
  local rcfile="${ZDOTDIR:-$HOME}/.zshrc"
  if [[ -f "${rcfile}" ]]; then
    echo "Reloading ${rcfile}..."
    # Prefer exec to replace current shell only when asked; default to sourcing for safety
    source "${rcfile}"
  else
    echo "reload-zsh: ${rcfile} not found"
    return 1
  fi
}

# pf: fuzzy file picker that opens result in $EDITOR (uses fzf + fd or git)
pf() {
  local start_dir
  local file

  # Determine a reasonable search root: git repo root, DOTFILES, or current dir
  if git rev-parse --show-toplevel >/dev/null 2>&1; then
    start_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
  elif [[ -d "${DOTFILES}" ]]; then
    start_dir="${DOTFILES}"
  else
    start_dir="${PWD}"
  fi

  # Prefer fd for fast search, fallback to find
  if command -v fd >/dev/null 2>&1; then
    file="$(fd --type f --hidden --follow --exclude .git '' "${start_dir}" 2>/dev/null | fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null' )"
  elif command -v fzf >/dev/null 2>&1; then
    # generate file list with git if available for speed
    if git -C "${start_dir}" ls-files --others --cached --exclude-standard >/dev/null 2>&1; then
      file="$(git -C "${start_dir}" ls-files --others --cached --exclude-standard | fzf --preview 'bat --style=numbers --color=always ${start_dir}/{+} 2>/dev/null')"
    else
      file="$(find "${start_dir}" -type f 2>/dev/null | fzf --preview 'bat --style=numbers --color=always {} 2>/dev/null')"
    fi
  else
    echo "pf: requires fzf (and optionally fd or git)."
    return 1
  fi

  if [[ -n "${file}" ]]; then
    "${EDITOR}" "${file}" &
  else
    echo "pf: no file selected"
    return 1
  fi
}

# update: run platform-appropriate update command; respects UPDATE_CMD env var if present
update() {
  if [[ -n "${UPDATE_CMD:-}" ]]; then
    echo "Running UPDATE_CMD: ${UPDATE_CMD}"
    eval "${UPDATE_CMD}"
    return $?
  fi

  # Try to infer platform
  if command -v brew >/dev/null 2>&1 && [[ "$(uname -s)" == "Darwin" ]]; then
    echo "macOS detected: running brew update && brew upgrade"
    brew update && brew upgrade
    return $?
  fi

  # Linux: try to detect distro
  if [[ -f /etc/os-release ]]; then
    local id
    id="$(. /etc/os-release; echo "${ID:-}" )"
    case "${id}" in
      ubuntu|debian)
        echo "Debian/Ubuntu detected: sudo apt update && sudo apt upgrade -y"
        sudo apt update && sudo apt upgrade -y
        return $?
        ;;
      arch)
        if command -v paru >/dev/null 2>&1; then
          echo "Arch detected: paru -Syu"
          paru -Syu
          return $?
        elif command -v pacman >/dev/null 2>&1; then
          echo "Arch detected: pacman -Syu (requires sudo)"
          sudo pacman -Syu
          return $?
        fi
        ;;
    esac
  fi

  # Fallback: try nix package manager update semantics if present
  if command -v nix >/dev/null 2>&1; then
    echo "nix detected: running nix-channel --update (if applicable)"
    nix-channel --update 2>/dev/null || true
    return 0
  fi

  echo "update: no known update command for this system. Set UPDATE_CMD to override."
  return 1
}

# cleanup: interactive deletion helper using fzf
cleanup() {
  local target="${1:-.}"
  if ! command -v fzf >/dev/null 2>&1; then
    echo "cleanup: fzf is required for interactive selection"
    return 1
  fi

  # Let user select multiple files/dirs to delete
  local selection
  selection="$(find "${target}" -maxdepth 3 -mindepth 1 -type d -o -type f 2>/dev/null | sed "s|^\./||" | fzf -m --prompt='Select files/dirs to delete> ' --preview 'ls -la {} 2>/dev/null' )"

  if [[ -z "${selection}" ]]; then
    echo "cleanup: nothing selected"
    return 0
  fi

  echo "The following entries will be removed:"
  echo "${selection}" | sed 's/^/  /'
  read -q "?Confirm deletion? (y/N) " answer
  echo
  if [[ "${answer}" =~ ^[Yy]$ ]]; then
    echo "${selection}" | while IFS= read -r f; do
      rm -rf -- "$f"
    done
    echo "cleanup: selected items removed."
  else
    echo "cleanup: aborted."
  fi
}

# zeze: open zoxide db in editor (if present)
zeze() {
  # zoxide usually stores DB at ~/.local/share/zoxide/db
  local db="${ZOXIDE_DATABASE:-${HOME}/.local/share/zoxide/db}"
  if [[ -f "${db}" ]]; then
    "${EDITOR}" "${db}"
    return 0
  else
    echo "zeze: zoxide DB not found at ${db}"
    return 1
  fi
}

# zieds-help: short usage summary
zieds-help() {
  cat <<'EOF'
zieds plugin helpers:
  mkd <dir>         - mkdir -p <dir> && cd <dir>
  use-tmux [name]   - attach or create tmux session (default: main)
  reload-zsh        - source your ~/.zshrc
  pf                - fuzzy file picker (requires fzf; uses fd/git if available)
  update            - run platform update (uses UPDATE_CMD if set)
  cleanup [path]    - interactively remove files/dirs using fzf
  zeze              - edit zoxide database (if present)
  zieds-help        - this help message

Environment:
  DOTFILES          - path to your dotfiles (defaults to ~/.dotfiles)
  UPDATE_CMD        - custom update command used by update()
EOF
}

# Convenience: add simple completion for mkd and use-tmux (zsh only)
if [[ -n "${ZSH_VERSION:-}" ]]; then
  _zieds_mkd() { compadd -- ${(f)$(compgen -d)} } 2>/dev/null || true
  compdef _zieds_mkd mkd 2>/dev/null || true

  _zieds_tmux_sessions() {
    if command -v tmux >/dev/null 2>&1; then
      tmux list-sessions -F '#S' 2>/dev/null
    fi
  }
  compctl -K _zieds_tmux_sessions use-tmux 2>/dev/null || true
fi

# End of plugin
