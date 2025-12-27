{ config, pkgs, lib, ... }:

/*
  macos.nix

  Purpose:
    - Provide a darwin / macOS-specific home-manager module that complements
      the top-level flake's home configuration and (optionally) integrates
      with nix-darwin system configuration when used on macOS hosts.
    - Offer safe, opt-in activations for:
        * populating ~/.dotfiles from the flake
        * installing Homebrew (if requested)
        * installing brew formulae and casks (opt-in)
        * enabling small macOS-specific fixes (key repeat, bootout-gui hint)
    - Keep the module conservative and side-effect-aware: system-changing
      operations are opt-in and guarded.

  Usage:
    - Import this via the top-level flake's home-manager configuration
      or include it into a nix-darwin module set when configuring darwin systems.
    - Configure options under `setupConfig.macos` (see options below).
*/

let
  types = lib.types;

  # Helper: safe import of repository helper if present (repo-path.nix lives next to other modules)
  safeImport = path: if builtins.pathExists path then import path else null;
  repoPath = safeImport ../../repo-path.nix;

  # helper to join lists safely as shell words
  joinShell = xs: lib.concatStringsSep " " xs;
in

{
  options = {
    setupConfig.macos = {

      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable macOS-specific helpers for the setup-config flake.";
      };

      # When true, attempt to install Homebrew if it's not already present.
      installHomebrew = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          When true, activations will attempt to bootstrap Homebrew (the official
          installer script). This is opt-in because bootstrapping modifies the system.
        '';
      };

      # List of Homebrew formulae (non-cask) to install via `brew install` when requested.
      brewFormulae = lib.mkOption {
        type = types.listOf types.str;
        default = [ "tmux" "neovim" "lazygit" ];
        description = "List of Homebrew formula names to install when brew install is executed.";
      };

      # List of Homebrew casks to install via `brew install --cask` (e.g. zed, ghostty)
      brewCasks = lib.mkOption {
        type = types.listOf types.str;
        default = [ "zed" ];
        description = "List of Homebrew cask names to install when brew cask install is executed.";
      };

      # Whether to attempt automatic stow after copying dotfiles
      autoStow = lib.mkOption {
        type = types.bool;
        default = false;
        description = "If true, run GNU Stow (if installed) after the flake's dotfiles are copied into the target directory.";
      };

      # Dotfiles target directory (override default ~/.dotfiles)
      dotfilesTarget = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional override for the user's dotfiles target directory (e.g. /Users/me/.dotfiles).";
      };

      # Small UX toggles
      enableKeyRepeatFix = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When true, prints a hint during activation about disabling macOS key repeat behavior (opt-in to apply manual fix).";
      };

      enableBootoutGuiHint = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When true, prints an informational message about `bootout-gui` and related macOS GUI helpers described in the SPECS.";
      };
    };
  };

  config = lib.mkIf config.setupConfig.macos.enable {

    # Expose platform identity to the user's environment
    home.sessionVariables = {
      SETUP_CONFIG_PLATFORM = "macos";
      # Prefer updating Nix-managed packages; fall back to Homebrew if Nix is not available.
      SETUP_CONFIG_UPDATE_CMD = "nix profile upgrade || (brew update && brew upgrade)";
    };

    # Conservative set of packages to install via Nix (preferred over Homebrew).
    # These are user-level tools provided by nixpkgs and do not conflict with Homebrew-managed binaries.
    home.packages = with pkgs; lib.mkForce ([
      git
      zsh
      tmux
      neovim
      fd
      ripgrep
      fzf
      bat
      lazygit
      zoxide
      btop
      fastfetch
      stow
    ] ++ (lib.optional (pkgs ? ghostty) ghostty)
      ++ (lib.optional (pkgs ? zed) zed)
      ++ (lib.optional (pkgs ? yabai) yabai)
      ++ (lib.optional (pkgs ? sketchybar) sketchybar)
    );

    # Zsh defaults: keep parity with other OS modules
    programs.zsh = {
      enable = true;
      enableZshenv = true;

      shellAliases = {
        v = "nvim";
        vim = "nvim";
        vi = "nvim";
        ll = "ls -la";
        lg = "lazygit";
        ff = "fastfetch";
      };

      interactiveShellInit = ''
        # macOS-specific helper: expose DOTFILES if repo helper available or default to ~/.dotfiles
        if [ -n "${SETUP_CONFIG_DOTFILES:-}" ]; then
          export DOTFILES="${SETUP_CONFIG_DOTFILES}"
        elif [ -d "${HOME}/.dotfiles" ]; then
          export DOTFILES="${HOME}/.dotfiles"
        elif [ -n "${repoPathdot:-}" ]; then
          :
        fi

        # If the flake-provided zieds plugin exists in the dotfiles, make sure fpath includes it.
        if [ -d "${DOTFILES}/zsh/.oh-my-zsh/custom/plugins/zieds" ]; then
          fpath+=("${DOTFILES}/zsh/.oh-my-zsh/custom/plugins/zieds")
        fi
      '';
    };

    programs.neovim.enable = true;
    programs.tmux.enable = true;

    # Activation: copy dotfiles from the checked-out flake to the user's dotfiles directory (if present)
    home.activation.copyDotfiles = lib.mkIf (repoPath != null) {
      text = ''
        mkdir -p "${if config.setupConfig.macos.dotfilesTarget != null then config.setupConfig.macos.dotfilesTarget else repoPath.dotfilesDir}"
        target="${if config.setupConfig.macos.dotfilesTarget != null then config.setupConfig.macos.dotfilesTarget else repoPath.dotfilesDir}"
        # Only populate target if it's empty
        if [ -z "$(ls -A "${target}" 2>/dev/null)" ]; then
          cp -r ${repoPath.flakeDotfilesPath}/* "${target}/" || true
        fi
      '';
    };

    # Optional: run GNU Stow after copying dotfiles when autoStow is requested
    home.activation.stowDotfiles = lib.mkIf (repoPath != null && config.setupConfig.macos.autoStow) {
      text = ''
        if command -v stow >/dev/null 2>&1; then
          echo "Running GNU Stow to create symlinks from ${if config.setupConfig.macos.dotfilesTarget != null then config.setupConfig.macos.dotfilesTarget else repoPath.dotfilesDir}..."
          cd "${if config.setupConfig.macos.dotfilesTarget != null then config.setupConfig.macos.dotfilesTarget else repoPath.dotfilesDir}" && stow -v *
        else
          echo "GNU Stow not found; skipping automatic stow. Install it via Nix or Homebrew to enable automatic symlinking."
        fi
      '';
    };

    # Optional: attempt to bootstrap Homebrew (opt-in)
    home.activation.bootstrapHomebrew = lib.mkIf config.setupConfig.macos.installHomebrew {
      text = ''
        # This script is intentionally conservative:
        # - It only runs the official non-interactive installer when user set installHomebrew=true
        # - It does not attempt to sudo or change /usr/local permissions
        if command -v brew >/dev/null 2>&1; then
          echo "Homebrew already present; skipping bootstrap."
          exit 0
        fi

        echo "Homebrew not found. Attempting to bootstrap Homebrew (this will run the official installer script)."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true

        echo "After bootstrapping Homebrew you may need to follow the on-screen instructions to add Homebrew to your PATH."
      '';
    };

    # Optional: install brew formulae/casks (only if brew exists); actions are opt-in and non-failing
    home.activation.installBrewPackages = lib.mkIf (config.setupConfig.macos.installHomebrew || (lib.length config.setupConfig.macos.brewFormulae > 0 || lib.length config.setupConfig.macos.brewCasks > 0)) {
      text = ''
        # Only attempt brew installs if brew is available
        if command -v brew >/dev/null 2>&1; then
          BREW_FORMULAE="${joinShell (config.setupConfig.macos.brewFormulae or [])}"
          BREW_CASKS="${joinShell (config.setupConfig.macos.brewCasks or [])}"

          if [ -n "${BREW_FORMULAE}" ]; then
            echo "Installing Homebrew formulae: ${BREW_FORMULAE}"
            brew install ${BREW_FORMULAE} || true
          fi

          if [ -n "${BREW_CASKS}" ]; then
            echo "Installing Homebrew casks: ${BREW_CASKS}"
            brew install --cask ${BREW_CASKS} || true
          fi
        else
          echo "brew not found; skipping Homebrew package installation. Enable installHomebrew or install Homebrew manually."
        fi
      '';
    };

    # macOS-specific hints/activation messages
    home.activation.postMessage = {
      text = ''
        echo "setup-config: macOS home-manager module applied."
        if [ "${toString config.setupConfig.macos.installHomebrew}" = "true" ]; then
          echo " - installHomebrew=true: attempted to bootstrap or verify Homebrew."
        else
          echo " - Homebrew installation is disabled by default. Set setupConfig.macos.installHomebrew = true to enable bootstrap activation."
        fi
        echo " - Dotfiles target: ${if config.setupConfig.macos.dotfilesTarget != null then config.setupConfig.macos.dotfilesTarget else (if repoPath != null then repoPath.dotfilesDir else '~/.dotfiles') }"
        if [ "${toString config.setupConfig.macos.autoStow}" = "true" ]; then
          echo " - autoStow=true: attempted to run GNU Stow after copying dotfiles (if stow installed)."
        fi
        if [ "${toString config.setupConfig.macos.enableKeyRepeatFix}" = "true" ]; then
          echo " - Key repeat hint: To adapt macOS key repeat for a more vi-like experience, see the README or run the suggested defaults write commands manually."
        fi
        if [ "${toString config.setupConfig.macos.enableBootoutGuiHint}" = "true" ]; then
          echo " - bootout-gui: A minimal macOS GUI helper is referenced in the main SPECS. Use it per the README if desired."
        fi
      '';
    };

    # Provide a small, lightweight environment hint so the zieds plugin's `update` function has a reasonable default.
    home.sessionVariables = lib.mkMerge [
      (config.home.sessionVariables or {})
      {
        # Prefer brew for macOS updates
        SETUP_CONFIG_UPDATE_CMD = "brew update && brew upgrade";
      }
    ];
  };
}
