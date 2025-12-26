{ config, pkgs, lib, ... }:

/*
  Arch Linux per-distro home-manager module for the setup-config flake.

  Purpose:
    - Provide Arch-specific user-level defaults (home.packages, zsh/tmux/neovim settings)
    - Provide safe activations to copy stowed dotfiles into ~/.dotfiles
    - Optionally install system packages using pacman and AUR packages via an AUR helper (paru)
    - Offer an opt-in automatic GNU Stow step to symlink dotfiles

  Safety:
    - System package installation is opt-in (installSystemPackages=false by default).
      When enabled, the activation uses sudo and may prompt for a password.
    - Copying the flake-provided dotfiles into the user's target directory is guarded:
      it only performs a copy if the target directory is empty.
    - AUR operations are opt-in and use the AUR helper only if requested.
*/

let
  types = lib.types;
  safeImport = path: if builtins.pathExists path then import path else null;

  repoPath = safeImport ../../repo-path.nix;
in

{
  options = {
    setupConfig.archlinux = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable Arch Linux specific helpers for the setup-config flake.";
      };

      # When true, attempt to install the requested system packages.
      # Prefer installing user-level and developer packages via Nix (add them to `home.packages`).
      # This option remains opt-in for cases where a system package is required; when enabled
      # the activation will first try to use `nix` (nix profile install) and fall back to pacman.
      installSystemPackages = lib.mkOption {
        type = types.bool;
        default = false;
        description = ''
          When true, the activation will attempt to install the listed packages.
          Preferred flow: add packages to `home.packages` so they are installed from nixpkgs declaratively.
          If this option is enabled, the activation will first try to use `nix` (nix profile install).
          Only if `nix` is not available will it fall back to using pacman as a last resort.
          Use with caution: fallbacks that use pacman run as the local user (sudo required) and can modify the system.
        '';
      };

      # List of pacman package names to install when installSystemPackages = true.
      systemPackages = lib.mkOption {
        type = types.listOf types.str;
        default = [ "base-devel" "git" "stow" "tmux" "neovim" ];
        description = "List of pacman packages that will be installed if installSystemPackages = true.";
      };

      # When true, attempt to install AUR packages using the AUR helper specified below.
      installAUR = lib.mkOption {
        type = types.bool;
        default = false;
        description = "When true, attempt installation of packages from the AUR using the AUR helper (e.g. paru).";
      };

      # AUR helper to use (string): e.g. 'paru' or 'yay'. The activation will try to install it via pacman or build from AUR if necessary.
      aurHelper = lib.mkOption {
        type = types.str;
        default = "paru";
        description = "AUR helper to use when installAUR = true (default: \"paru\").";
      };

      # List of AUR package names to install when installAUR = true.
      aurPackages = lib.mkOption {
        type = types.listOf types.str;
        default = [ "ghostty" ]; # ghostty is typically in AUR
        description = "List of AUR packages to attempt to install when installAUR = true.";
      };

      # Automatically run GNU Stow after copying dotfiles.
      autoStow = lib.mkOption {
        type = types.bool;
        default = false;
        description = "If true, run GNU Stow (if installed) after the flake's dotfiles are copied into the target directory.";
      };
    };
  };

  config = lib.mkIf config.setupConfig.archlinux.enable {
    # Make the chosen platform visible in environment
    home.sessionVariables = {
      SETUP_CONFIG_PLATFORM = "archlinux";
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

    # Zsh: lightweight init that prefers stowed dotfiles (keeps behavior consistent with SPECS).
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
        if [ -d "${if repoPath != null then repoPath.dotfilesDir else "${config.home.homeDirectory}/.dotfiles"}" ]; then
          export DOTFILES="${if repoPath != null then repoPath.dotfilesDir else "${config.home.homeDirectory}/.dotfiles"}"
          if [ -d "${if repoPath != null then repoPath.dotfilesDir else "${config.home.homeDirectory}/.dotfiles"}/zsh/.oh-my-zsh/custom/plugins/zieds" ]; then
            fpath+=("${if repoPath != null then repoPath.dotfilesDir else "${config.home.homeDirectory}/.dotfiles"}/zsh/.oh-my-zsh/custom/plugins/zieds")
          fi
        fi
      '';
    };

    programs.neovim.enable = true;
    programs.tmux.enable = true;

    # Activation: copy the flake dotfiles into the user's dotfiles directory (if repo helper present).
    home.activation.copyDotfiles = lib.mkIf (repoPath != null) {
      text = repoPath.activationScript;
    };

    # Optional: run GNU Stow after copying dotfiles when user opts-in.
    home.activation.stowDotfiles = lib.mkIf (repoPath != null && config.setupConfig.archlinux.autoStow) {
      text = ''
        ${repoPath.stowCommand}
      '';
    };

    # Optional: attempt to install system packages (prefers Nix, falls back to pacman).
    home.activation.installSystemPackages = lib.mkIf config.setupConfig.archlinux.installSystemPackages {
      text = ''
        set -euo pipefail

        PACKAGES=${lib.escapeShellArg (lib.concatStringsSep " " config.setupConfig.archlinux.systemPackages)}

        if [ -z "${PACKAGES}" ]; then
          echo "No packages requested; skipping system package installation."
          exit 0
        fi

        echo "Requested system packages: ${PACKAGES}"

        # Prefer Nix when available: try to install each requested package from nixpkgs via `nix profile install`.
        if command -v nix >/dev/null 2>&1; then
          echo "Nix detected: attempting to install requested packages via nix profile (nixpkgs)."
          for p in ${lib.concatStringsSep " " config.setupConfig.archlinux.systemPackages}; do
            echo " - Attempting: nix profile install nixpkgs#${p} (best-effort mapping to nixpkgs name)"
            nix profile install "nixpkgs#${p}" || echo "Warning: failed to install ${p} via nix; package may have a different name in nixpkgs."
          done
        else
          echo "Nix not found: falling back to pacman (requires sudo)."
          if [ -z "${PACKAGES}" ]; then
            echo "No packages requested; nothing to do."
            exit 0
          fi
          if command -v sudo >/dev/null 2>&1; then
            echo "Using pacman to install packages: ${PACKAGES}"
            sudo pacman -Syu --noconfirm ${lib.concatStringsSep " " config.setupConfig.archlinux.systemPackages}
          else
            echo "sudo not found: cannot install pacman packages automatically. Install packages manually:"
            echo "  sudo pacman -Syu --noconfirm ${lib.concatStringsSep " " config.setupConfig.archlinux.systemPackages}"
          fi
        fi

        echo "Finished attempt to install requested packages. Prefer `home.packages` for declarative Nix-managed installation."
      '';
    };

    # Optional: attempt to install AUR packages via the chosen helper. This activation is opt-in.
    home.activation.installAURPackages = lib.mkIf config.setupConfig.archlinux.installAUR {
      text = ''
        set -euo pipefail

        # Helper and packages requested by configuration
        AUR_HELPER="${lib.escapeShellArg config.setupConfig.archlinux.aurHelper}"
        AUR_PACKAGES="${lib.escapeShellArg (lib.concatStringsSep " " config.setupConfig.archlinux.aurPackages)}"

        if [ -z "${AUR_PACKAGES}" ]; then
          echo "No AUR packages requested; skipping AUR installation."
          exit 0
        fi

        echo "Attempting to ensure AUR helper '${AUR_HELPER}' is present and install AUR packages: ${AUR_PACKAGES}"
        echo "This will use sudo and may prompt for your password."

        # Install AUR helper using pacman if available, otherwise attempt manual build (conservative).
        if command -v ${config.setupConfig.archlinux.aurHelper} >/dev/null 2>&1; then
          echo "AUR helper ${AUR_HELPER} already available; using it to install packages."
          ${config.setupConfig.archlinux.aurHelper} -S --noconfirm ${lib.concatStringsSep " " config.setupConfig.archlinux.aurPackages} || true
        else
          echo "AUR helper ${AUR_HELPER} not found. Attempting to install it via pacman (if available) or inform the user."

          if command -v sudo >/dev/null 2>&1 && command -v pacman >/dev/null 2>&1; then
            # Try pacman first (some helpers are available in community)
            sudo pacman -Sy --noconfirm ${AUR_HELPER} || true
          fi

          if command -v ${config.setupConfig.archlinux.aurHelper} >/dev/null 2>&1; then
            echo "Installed AUR helper ${AUR_HELPER}; installing requested AUR packages."
            ${config.setupConfig.archlinux.aurHelper} -S --noconfirm ${lib.concatStringsSep " " config.setupConfig.archlinux.aurPackages} || true
          else
            echo "Could not install AUR helper automatically. Please install one of: paru, yay, etc. Then run:"
            echo "  <aur-helper> -S ${lib.concatStringsSep " " config.setupConfig.archlinux.aurPackages}"
          fi
        fi

        echo "Finished AUR installation attempt."
      '';
    };

    # Activation message summarizing what this Arch module configured.
    home.activation.postMessage.text = ''
      echo "setup-config: Arch Linux home-manager module applied."
      echo " - Dotfiles target: ${if repoPath != null then repoPath.dotfilesDir else '~/.dotfiles'}"
      if [ "${toString config.setupConfig.archlinux.installSystemPackages}" = "true" ]; then
        echo " - installSystemPackages=true: attempted pacman package installation."
      fi
      if [ "${toString config.setupConfig.archlinux.installAUR}" = "true" ]; then
        echo " - installAUR=true: attempted AUR package installation (aurHelper=${config.setupConfig.archlinux.aurHelper})."
      fi
      if [ "${toString config.setupConfig.archlinux.autoStow}" = "true" ]; then
        echo " - autoStow=true: attempted to run GNU Stow after copying dotfiles (if stow installed)."
      fi
    '';
  };
}
