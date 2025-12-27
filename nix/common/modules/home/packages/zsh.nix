{ config, pkgs, lib, ... }:

/*
  zsh.nix

  Home Manager module to declaratively manage Zsh configuration and Oh My Zsh
  from the flake's dotfiles. This module follows the pattern used for tmux/nvim/zed:
  - It treats the flake-provided `nix/dotfiles/zsh` directory as the canonical source.
  - It manages `.zshrc`, `.zprofile` (if present), and the `.oh-my-zsh` tree via `home.file.<...>.source`.
  - It enables `programs.zsh` and adds a small interactive shell init to include custom plugin paths
    (such as the `zieds` plugin located in `.oh-my-zsh/custom/plugins/zieds`).
  - It is conservative: it only manages files/dirs that actually exist in the flake at evaluation time.

  Default source path (relative to this file):
    ../../../dotfiles/zsh

  Options:
    setupConfig.zsh.enable : bool        - enable this module (default: true)
    setupConfig.zsh.source : null | path - optional override path to the zsh package in the flake
    setupConfig.zsh.manageOhMyZsh : bool - manage ~/.oh-my-zsh from the flake (default: true)
    setupConfig.zsh.manageZshrc  : bool  - manage ~/.zshrc from the flake (default: true)
    setupConfig.zsh.manageZprofile: bool - manage ~/.zprofile from the flake (default: true)
*/

let
  types = lib.types;

  # Default path inside the flake to the zsh package (relative to this file)
  defaultSource = ../../../dotfiles/zsh;

in
{
  options = {
    setupConfig.zsh = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable the zsh home-manager module (manage zsh + oh-my-zsh from the flake)";
      };

      source = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional override path in the flake for the zsh package (e.g. ./nix/dotfiles/zsh).";
      };

      manageOhMyZsh = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When true, manage ~/.oh-my-zsh from the flake-provided content if present.";
      };

      manageZshrc = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When true, manage ~/.zshrc from the flake-provided content if present.";
      };

      manageZprofile = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When true, manage ~/.zprofile from the flake-provided content if present.";
      };
    };
  };

  config = lib.mkIf config.setupConfig.zsh.enable (let
    src = if config.setupConfig.zsh.source != null then config.setupConfig.zsh.source else defaultSource;

    # candidate paths inside the package
    zshrcAtRoot     = "${src}/.zshrc";
    zprofileAtRoot  = "${src}/.zprofile";
    ohmyAtRoot      = "${src}/.oh-my-zsh";
    zshrcInDotfiles = "${src}/dotfiles/.zshrc";   # account for alternate layouts
    zprofileInDotfiles = "${src}/dotfiles/.zprofile";
    ohmyInDotfiles   = "${src}/dotfiles/.oh-my-zsh";

    # existence checks (at evaluation time)
    hasZshrcRoot     = builtins.pathExists zshrcAtRoot;
    hasZprofileRoot  = builtins.pathExists zprofileAtRoot;
    hasOhmyRoot      = builtins.pathExists ohmyAtRoot;
    hasZshrcDot      = builtins.pathExists zshrcInDotfiles;
    hasZprofileDot   = builtins.pathExists zprofileInDotfiles;
    hasOhmyDot       = builtins.pathExists ohmyInDotfiles;

    # choose preferred candidates (root preferred, then dotfiles/ subpath)
    zshrcSrc = if hasZshrcRoot then zshrcAtRoot else (if hasZshrcDot then zshrcInDotfiles else null);
    zprofileSrc = if hasZprofileRoot then zprofileAtRoot else (if hasZprofileDot then zprofileInDotfiles else null);
    ohmySrc = if hasOhmyRoot then ohmyAtRoot else (if hasOhmyDot then ohmyInDotfiles else null);

    # build the home.file attribute set conditionally
    zshAttrs = lib.mkMerge [
      (if config.setupConfig.zsh.manageZshrc && zshrcSrc != null then {
        ".zshrc" = {
          source = zshrcSrc;
        };
      } else {});

      (if config.setupConfig.zsh.manageZprofile && zprofileSrc != null then {
        ".zprofile" = {
          source = zprofileSrc;
        };
      } else {});

      (if config.setupConfig.zsh.manageOhMyZsh && ohmySrc != null then {
        ".oh-my-zsh" = {
          source = ohmySrc;
          recursive = true;
        };
      } else {})
    ];

    # interactive shell init that appends the zieds plugin path to fpath if present
    interactiveInit = ''
      # If the zieds plugin is installed under ~/.oh-my-zsh/custom/plugins/zieds add it to fpath
      if [ -d "${config.home.homeDirectory}/.oh-my-zsh/custom/plugins/zieds" ]; then
        fpath+=("${config.home.homeDirectory}/.oh-my-zsh/custom/plugins/zieds")
      fi

      # Ensure DOTFILES env var is available (prefer existing SETUP_CONFIG_DOTFILES if set)
      if [ -z "${SETUP_CONFIG_DOTFILES:-}" ]; then
        export DOTFILES="${config.home.homeDirectory}/.dotfiles"
      fi
    '';

  in
  {
    # Merge with any existing home.file entries to avoid clobbering other modules.
    home.file = lib.mkMerge [ (config.home.file or {}) zshAttrs ];

    # Enable programs.zsh and set a few conservative options
    programs.zsh = {
      enable = true;
      enableZshenv = true;
      oh-my-zsh = {
        enable = false; # keep home-manager's built-in oh-my-zsh support off; we manage .oh-my-zsh via home.file
      };
      shellAliases = lib.mkMerge [
        (config.programs.zsh.shellAliases or {})
        {
          v = "nvim";
          vim = "nvim";
          vi = "nvim";
          ll = "ls -la";
          lg = "lazygit";
          ff = "fastfetch";
        }
      ];
      interactiveShellInit = lib.mkIf true interactiveInit;
    };

    # Provide a short activation message describing what was applied
    home.activation.zshInfo = {
      text = ''
        echo "setup-config: Zsh module applied."
        echo -n " - .zshrc managed: "
        if [ "${if ${toString hasZshrcRoot} == \"1\" then \"1\" else \"0\"}" = "1" ]; then
          echo "yes (from ${zshrcAtRoot})"
        elif [ "${if ${toString hasZshrcDot} == \"1\" then \"1\" else \"0\"}" = "1" ]; then
          echo "yes (from ${zshrcInDotfiles})"
        else
          echo "no"
        fi
        echo -n " - .zprofile managed: "
        if [ "${if ${toString hasZprofileRoot} == \"1\" then \"1\" else \"0\"}" = "1" ]; then
          echo "yes (from ${zprofileAtRoot})"
        elif [ "${if ${toString hasZprofileDot} == \"1\" then \"1\" else \"0\"}" = "1" ]; then
          echo "yes (from ${zprofileInDotfiles})"
        else
          echo "no"
        fi
        echo -n " - .oh-my-zsh managed: "
        if [ "${if ${toString hasOhmyRoot} == \"1\" then \"1\" else \"0\"}" = "1" ]; then
          echo "yes (from ${ohmyAtRoot})"
        elif [ "${if ${toString hasOhmyDot} == \"1\" then \"1\" else \"0\"}" = "1" ]; then
          echo "yes (from ${ohmyInDotfiles})"
        else
          echo "no"
        fi

        echo " - To experiment: edit files in the flake's nix/dotfiles/zsh and re-activate home-manager."
        echo " - If you prefer the stow workflow, ensure the shared dotfiles module exposes ~/.dotfiles/zsh and run: cd ~/.dotfiles && stow zsh"
      '';
    };
  })
}
