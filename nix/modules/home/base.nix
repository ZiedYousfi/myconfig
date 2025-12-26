{ config, pkgs, lib, ... }:

/*
  Base home-manager module for the setup-config flake.

  Purpose
  - Provide a minimal, safe baseline of user-level configuration shared across
    macOS, Ubuntu and Arch derivations.
  - Declare common packages, basic environment variables and small zsh/neovim/tmux
    settings that match the SPECS.md in the repository.

  Notes
  - This module is intentionally conservative: it avoids advanced or host-specific
    options so it can be imported by higher-level OS modules.
  - Override or extend these values from per-OS modules (e.g. ./modules/macos.nix,
    ./modules/ubuntu.nix, ./modules/archlinux.nix) that are imported from the flake.
*/

let
  # A small helper to refer to the user's home directory as configured by home-manager.
  homeDir = config.home.homeDirectory;
in
{
  description = "Base/home common settings for setup-config (packages, env, minimal programs)";

  # Expose a tiny option so other modules can enable/disable behaviors from this base module.
  options = {
    setupConfig.base.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the shared base home-manager settings provided by this module.";
    };
  };

  config = lib.mkIf config.setupConfig.base.enable {
    # Basic user-visible packages described in SPECS.md.
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
    ];

    # Session / environment variables recommended in SPECS.md.
    # These are conservative defaults; OS modules may refine or remove them.
    home.sessionVariables = {
      XDG_CONFIG_HOME = "${homeDir}/.config";
      XDG_CACHE_HOME = "${homeDir}/.cache";
      EDITOR = "nvim";
      VISUAL = "nvim";
      TERM = "xterm-256color";
      LANG = "fr_FR.UTF-8";
      LC_ALL = "fr_FR.UTF-8";
      VI_MODE_SET_CURSOR = "true";
    };

    # Zsh: enable and provide a few portable aliases and a small init snippet.
    programs.zsh = {
      enable = true;

      # Common aliases used across the repo (feel free to extend in per-OS modules or user dotfiles)
      shellAliases = {
        v = "nvim";
        vim = "nvim";
        vi = "nvim";
        ll = "ls -la";
        lg = "lazygit";
        ff = "fastfetch";
      };

      # lightweight init to detect ~/.dotfiles and expose DOTFILES variable
      interactiveShellInit = ''
        # If a dotfiles directory exists, expose it as $DOTFILES for convenience
        if [ -d "${homeDir}/.dotfiles" ]; then
          export DOTFILES="${homeDir}/.dotfiles"
        fi
      '';
    };

    # Neovim: enable basic support. Per-user or per-OS configs should be installed
    # via the dotfiles/stow workflow and/or by importing additional home-manager modules.
    programs.neovim = {
      enable = true;
      # Don't force a specific package override here; higher level modules may set `package`.
    };

    # Tmux: enable the tmux integration. Advanced tmux configuration is expected to
    # come from dotfiles (stowed) or from a more specific module.
    programs.tmux = {
      enable = true;
      # You can place a default tmux config stub in .dotfiles/tmux/tmux.conf.local
      # and let stow create the symlink into ${homeDir}/.config/tmux/.
    };

    # Small, safe home.file placeholders to illustrate the stow/dotfiles approach.
    # These are minimal and non-invasive: if users provide their own dotfiles those
    # will take precedence when stowed into ${homeDir}/.dotfiles.
    home.file.".zprofile".text = ''
      # Basic zsh profile that prefers stowed dotfiles if present.
      if [ -f "${homeDir}/.dotfiles/zsh/.zprofile" ]; then
        source "${homeDir}/.dotfiles/zsh/.zprofile"
      fi
    '';

    home.file.".config/nvim/lua/plugins/colorscheme.lua".text = ''
      -- Placeholder: Monokai Classic is configured from stowed dotfiles in the repo.
      -- Add your colorscheme.lua in ~/.dotfiles/nvim/.config/nvim/lua/plugins/
    '';

    # Helpful README file placed in ~/.dotfiles when users adopt a pure stow workflow.
    # Keep this tiny and informative; real dotfiles should live in the repository's ./dotfiles/.
    home.file.".dotfiles/README".text = ''
      This directory is intended to be managed by the setup-config flake.
      Put stow-style dotfiles under packages (e.g. nvim/, zsh/, tmux/) and use
      GNU Stow or the provided activation helpers to create symlinks in your home.
    '';

    # Informational activation: when home-manager activates, the user will see a
    # short message indicating this base module is active. This avoids side effects.
    home.activation.message = {
      text = ''
        echo "setup-config: base home-manager module applied. Extend with per-OS modules or your own dotfiles."
      '';
    };
  };
}
