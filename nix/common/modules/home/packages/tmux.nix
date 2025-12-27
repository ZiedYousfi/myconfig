{ config, pkgs, lib, ... }:

/*
  tmux.nix

  Home Manager module for declaratively managing tmux configuration.

  Features:
  - Exposes tmux configuration files from the flake's `nix/dotfiles/tmux` directory
    into the user's home via `home.file.<...>.source`. This is fully declarative.
  - Detects and manages either `./tmux.conf.local` or the `.config/tmux/` tree
    inside the package directory (whichever exists in the flake).
  - Enables `programs.tmux` in Home Manager (safe/lightweight).
  - Leaves the dotfiles package approach intact (if you also use the dotfiles module).
  - Options:
      - setupConfig.tmux.enable         : enable this module (default true)
      - setupConfig.tmux.source         : override source path for the tmux package
      - setupConfig.tmux.createAltLink  : create an additional ~/.tmux.conf.local
                                         symlink pointing to the primary file (default true)

  Notes:
  - The default source path points to `../../../dotfiles/tmux` relative to this file,
    which corresponds to `setup-config/nix/dotfiles/tmux` in the flake layout.
  - The module uses `builtins.pathExists` to conditionally manage only the files/dirs
    that actually exist in the flake, so it is tolerant of different package layouts.
*/

let
  types = lib.types;

  # Default path inside the flake to the tmux package (relative to this file)
  defaultSource = ../../../dotfiles/tmux;

in
{
  options = {
    setupConfig.tmux = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable the tmux home-manager module (manage tmux configuration files declaratively).";
      };

      # Optional override: allow the user to point to a custom source path for tmux package
      source = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional override for the tmux package source path (a path in the flake).";
      };

      # Whether to create a convenience ~/.tmux.conf.local pointing at the managed file (when appropriate)
      createAltLink = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Create an additional ~/.tmux.conf.local symlink to the managed tmux configuration when applicable.";
      };
    };
  };

  config = lib.mkIf config.setupConfig.tmux.enable (let
    # Effective source to use (path in the flake)
    src = if config.setupConfig.tmux.source != null then config.setupConfig.tmux.source else defaultSource;

    # Candidate paths inside the package we try to manage (as path values)
    tmuxConfigDir = "${src}/.config/tmux";      # e.g. ./nix/dotfiles/tmux/.config/tmux
    tmuxConfLocal  = "${src}/tmux.conf.local";  # e.g. ./nix/dotfiles/tmux/tmux.conf.local

    # Check which of these exist in the flake at evaluation time
    hasConfigDir = builtins.pathExists tmuxConfigDir;
    hasConfLocal = builtins.pathExists tmuxConfLocal;

    # Build the home.file attribute set conditionally
    tmuxAttrs =
      lib.mkMerge [
        (if hasConfigDir then {
          # Manage the entire config directory (recursive symlink to Nix store)
          ".config/tmux" = {
            source = tmuxConfigDir;
            recursive = true;
          };
        } else {});

        (if hasConfLocal then {
          # If a top-level tmux.conf.local exists inside the package, manage it.
          ".tmux.conf.local" = {
            source = tmuxConfLocal;
          };
        } else {});

        # If only the .config/tmux exists but user wants an alt link (~/.tmux.conf.local),
        # create it pointing to the canonical file inside .config/tmux if that file exists.
        (if (hasConfigDir && config.setupConfig.tmux.createAltLink) then
          let
            canonical = "${tmuxConfigDir}/tmux.conf.local";
          in
            (if builtins.pathExists canonical then {
              ".tmux.conf.local" = {
                source = canonical;
              };
            } else {} )
         else {})
      ];

  in
  {
    # Merge with any pre-existing home.file entries so we don't clobber other modules
    home.file = lib.mkMerge [ (config.home.file or {}) tmuxAttrs ];

    # Enable tmux program-level support (this is conservative and non-invasive)
    programs.tmux = {
      enable = true;
      # The user can still manage tmux-specific options elsewhere if desired.
    };

    # Helpful activation message
    home.activation.tmuxInfo = {
      text = ''
        echo "setup-config: tmux module applied."
        if [ "${toString ${lib.toString hasConfigDir}}" = "true" ]; then
          echo " - Managing ~/.config/tmux from the flake tmux package."
        fi
        if [ "${toString ${lib.toString hasConfLocal}}" = "true" ]; then
          echo " - Managing ~/.tmux.conf.local from the flake tmux package."
        fi
        if [ "${toString ${lib.toString hasConfigDir}}" = "false" ] && [ "${toString ${lib.toString hasConfLocal}}" = "false" ]; then
          echo " - Warning: no tmux config found at the expected flake paths (${toString src})."
+          echo "   If your tmux package lives elsewhere in the flake, set setupConfig.tmux.source to its path."
        fi
        echo " - To experiment with stow-style symlinks, consider enabling the shared dotfiles module's autoStow option or running 'cd ~/.dotfiles && stow tmux' manually."
      '';
    };
  })
}
