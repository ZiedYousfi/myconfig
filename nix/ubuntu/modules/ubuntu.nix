{ config, pkgs, lib, ... }:

/*
  Ubuntu per-distro home-manager module for setup-config flake.

  Purpose:
    - Provide Ubuntu-friendly user-level defaults (home.packages, zsh/tmux/neovim settings)
    - Provide optional activations to:
        * copy stowed dotfiles from the flake into the user's ~/.dotfiles
        * run GNU Stow to create symlinks
        * optionally attempt to install system packages via apt (requires sudo)
        * optionally add Linuxbrew paths to environment

  Notes & Safety:
    - Running apt via a home.activation requires sudo and will be attempted only when
      `installSystemPackages = true`. The activation will call `sudo apt update && sudo apt install -y ...`
      — this may prompt for a password interactively when activating as your user.
    - Copying the flake-provided dotfiles into the user's target directory is guarded:
      it only performs a copy if the target directory is empty.
    - This module prefers to use Nixpkgs packages for user tools where available.
*/

let
  types = lib.types;
  safeImport = path: if builtins.pathExists path then import path else null;

  # Path to the repo helper (provides dotfilesDir, activationScript, stowCommand when imported).
  repoPath = safeImport ../../repo-path.nix;
in

{
  options = {
    setupConfig.ubuntu = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable Ubuntu-specific home-manager helpers for the setup-config flake.";
      };

      # A boolean that when true will attempt to install the requested system packages.
      # Prefer installing user-level and developer packages via Nix (add them to `home.packages`).
      # This option remains opt-in for cases where a system package is required; when enabled
      # the activation will try to use Nix (`nix profile install`) if available and fall back to apt.
      installSystemPackages = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          When true, the activation will attempt to install the listed packages.
          Preferred flow: add packages to `home.packages` so they are installed from nixpkgs declaratively.
          If this option is enabled, the activation will first try to use `nix` (nix profile install).
          Only if `nix` is not available will it fall back to using apt as a last resort.
          Use with caution: fallbacks that use apt run as the local user (sudo required) and can modify the system.
        '';
      };

      # List of apt package names to install when installSystemPackages = true.
      systemPackages = lib.mkOption {
        type = types.listOf types.str;
        default = [ "build-essential" "curl" "stow" ];
        description = "List of apt packages that will be installed if installSystemPackages = true.";
      };

      # If true, add typical Linuxbrew paths to PATH and provide instructions to install Homebrew on Linux.
      installLinuxbrew = lib.mkOption {
        type = types.bool;
        default = false;
        description = "When true, add typical Linuxbrew paths to the user environment and provide install hints.";
      };

      # A small opt-in to run GNU Stow automatically after dotfiles are copied.
      autoStow = lib.mkOption {
        type = types.bool;
        default = false;
        description = "If true, run GNU Stow (if installed) after the flake's dotfiles are copied into the target directory.";
      };
    };
  };

  config = lib.mkIf config.setupConfig.ubuntu.enable {
    # Make it easy to see which distro helper is active in the user's environment.
    home.sessionVariables = {
      SETUP_CONFIG_PLATFORM = "ubuntu";
      # Prefer updating Nix-managed packages by default; fall back to an explanatory message if `nix` is not present.
      SETUP_CONFIG_UPDATE_CMD = "nix profile upgrade || echo 'Run nix profile upgrade to update Nix-managed packages'";
    };

    # Provide a curated set of user-level packages (from nixpkgs) aligned with SPECS.md.
    home.packages = with pkgs; [
      git
      zsh
      tmux
      neovim
      fd
      ripgrep
      fzf
      bat
      eza
      lazygit
      zoxide
      btop
      fastfetch
      stow
    ];

    # Zsh: small init that prefers stowed dotfiles (keeps behavior consistent with SPECS).
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

      interactiveShellInit = lib.mkIf true ''
        # If dotfiles are present, expose DOTFILES and add custom plugin path for zieds.
        if [ -d "${repoPath.dotfilesDir}" ]; then
          export DOTFILES="${repoPath.dotfilesDir}"
          if [ -d "${repoPath.dotfilesDir}/zsh/.oh-my-zsh/custom/plugins/zieds" ]; then
            fpath+=("${repoPath.dotfilesDir}/zsh/.oh-my-zsh/custom/plugins/zieds")
          fi
        fi
      '';
    };

    # Neovim & tmux are enabled conservatively; detailed config should be stowed from ~/.dotfiles.
    programs.neovim.enable = true;
    programs.tmux.enable = true;

    # If the repo helper is available, create activations that copy the flake dotfiles and optionally stow them.
    home.activation.copyDotfiles = lib.mkIf (repoPath != null) {
      text = repoPath.activationScript;
    };

    # Auto-run stow if requested by option `setupConfig.ubuntu.autoStow`.
    home.activation.stowDotfiles = lib.mkIf (repoPath != null && config.setupConfig.ubuntu.autoStow) {
      text = ''
        # Run the stow command provided by the repo helper (this checks for stow and prints a message if missing).
        ${repoPath.stowCommand}
      '';
    };

    # Optionally expose Linuxbrew typical paths and hint about installation: non-invasive.
    home.sessionVariables = lib.mkMerge [
      (if config.setupConfig.ubuntu.installLinuxbrew then {
        # These are common Linuxbrew locations; if user installs Linuxbrew they will be added to PATH.
        PATH = lib.mkForce (let
          user = config.home.username or "unknown";
          brew1 = "/home/${user}/.linuxbrew/bin";
          brew2 = "/home/${user}/.linuxbrew/sbin";
          brew3 = "/home/linuxbrew/.linuxbrew/bin";
          brew4 = "/home/linuxbrew/.linuxbrew/sbin";
        in builtins.concatStringsSep ":" (filter (p: p != null && p != "") [ brew1 brew2 brew3 brew4 "${pkgs.runCommand}/bin" ]) + ":${lib.getEnv \"PATH\"}";
      } else {}) ,
      (if config.setupConfig.ubuntu.installLinuxbrew then {
        HOMEBREW = lib.mkForce "1";
      } else {})
    ];

    # Optional activation that attempts to install system packages (prefers Nix, falls back to apt).
    home.activation.installSystemPackages = lib.mkIf config.setupConfig.ubuntu.installSystemPackages {
      text = ''
        set -euo pipefail

        # Build a whitespace-separated list of requested package names.
        PACKAGES="${lib.escapeShellArg (lib.concatStringsSep " " config.setupConfig.ubuntu.systemPackages)}"

        if [ -z "${PACKAGES}" ]; then
          echo "No packages requested; skipping system package installation."
          exit 0
        fi

        echo "Requested system packages: ${PACKAGES}"

        # Prefer Nix if available. Try installing each package from nixpkgs via `nix profile install`.
        if command -v nix >/dev/null 2>&1; then
          echo "Nix detected: attempting to install requested packages via nix profile (nixpkgs)."
          for p in ${lib.concatStringsSep " " config.setupConfig.ubuntu.systemPackages}; do
            echo " - Attempting: nix profile install nixpkgs#${p} (best-effort mapping to nixpkgs name)"
            # Attempt to install by nomeclature nixpkgs#<name>. If it fails, continue and warn.
            nix profile install "nixpkgs#${p}" || echo "Warning: failed to install ${p} via nix; package may have a different name in nixpkgs."
          done
        else
          echo "Nix not found: falling back to apt (requires sudo)."
          if [ -z "${PACKAGES}" ]; then
            echo "No packages requested; nothing to do."
            exit 0
          fi
          if command -v sudo >/dev/null 2>&1; then
            echo "Using apt to install packages: ${PACKAGES}"
            sudo apt update
            sudo apt install -y ${lib.concatStringsSep " " config.setupConfig.ubuntu.systemPackages}
          else
            echo "sudo not found: cannot install apt packages automatically. Install packages manually:"
            echo "  sudo apt update && sudo apt install -y ${lib.concatStringsSep " " config.setupConfig.ubuntu.systemPackages}"
          fi
        fi

        echo "Finished attempt to install requested packages. Prefer `home.packages` for declarative Nix-managed installation."
      '';
    };

    # Helpful activation that prints guidance about Linuxbrew (if opted-in).
    home.activation.linuxbrewHint = lib.mkIf config.setupConfig.ubuntu.installLinuxbrew {
      text = ''
        echo "setup-config: Linuxbrew hint"
        echo "If you want Linuxbrew (Homebrew on Linux), you can install it by running:"
        echo '  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
        echo "After installation, consider adding the Linuxbrew bin/sbin to your PATH or re-run this activation."
      '';
    };

    # Activation message summarizing what this Ubuntu module configured.
    home.activation.postMessage.text = ''
      echo "setup-config: Ubuntu home-manager module applied."
      echo " - Dotfiles target: ${if repoPath != null then repoPath.dotfilesDir else '~/.dotfiles'}"
      echo " - To populate dotfiles from the flake: run home-manager activation, then run stow (or enable autoStow)."
      if [ "${toString config.setupConfig.ubuntu.installSystemPackages}" = "true" ]; then
        echo " - Note: installSystemPackages=true, activation attempted apt package installation."
      fi
    '';
  };
}
