{ config, pkgs, lib, ... }:

/*
  home/dotfiles.nix

  Home Manager module that exposes the repository-stored dotfiles as
  symlinked entries under ~/.dotfiles (managed declaratively via home.file).
  It also provides an optional activation to run GNU Stow to create the
  usual stow symlinks from ~/.dotfiles into the home.

  Features:
  - Declarative: each package directory under the flake's ./dotfiles is
    represented as a managed path (symlinked from the Nix store into ~/.dotfiles).
  - Safe: population is done by referencing flake paths; no imperative copying.
  - Flexible: you can add/remove packages via `setupConfig.dotfiles.packages`.
  - Optional: `autoStow` will run `stow -v *` inside ~/.dotfiles on activation if enabled
    and `stow` is available.
  - Customizable target: override the default ~/.dotfiles target with `target`.

  Example usage (in your flake inputs/home-manager configuration):
    setupConfig.dotfiles = {
      enable = true;
      target = null; # or "/home/you/.dotfiles"
      autoStow = true;
      packages = [
        { name = "nvim";  source = ./../../dotfiles/nvim; }
        { name = "zsh";   source = ./../../dotfiles/zsh; }
        { name = "tmux";  source = ./../../dotfiles/tmux; }
      ];
    };

  Note:
  - Each `source` must be a path expression (a file or directory) available
    when the flake/module is evaluated (commonly relative paths like
    `./../../dotfiles/...` when imported from the flake).
  - Home Manager will create symlinks to the Nix store entries for those sources.
*/

let
  types = lib.types;

  # Helper: build a list-to-attrs mapping suitable for assignment to home.file
  mkDotfilesAttrs = packages:
    builtins.listToAttrs (map (p:
      { name = ".dotfiles/${p.name}";
        value = {
          # Use `source` so home-manager places a symlink from $HOME/.dotfiles/<pkg> to the Nix store path.
          source = p.source;
          # When the source is a directory we want to keep its tree; recursive metadata isn't strictly required
          # but set `recursive = true` to indicate intention (home-manager will handle directories correctly).
          recursive = true;
        };
      }
    ) packages);

in

{
  options = {
    setupConfig.dotfiles = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable management of repository dotfiles under ~/.dotfiles via home-manager.";
      };

      # Optional override of target directory (defaults to $HOME/.dotfiles)
      target = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional override for the target dotfiles directory (e.g. /home/me/.dotfiles).";
      };

      # A list of packages describing the name (package directory) and the source path in the flake.
      # Each entry should be an attribute set with:
      #   { name = \"pkg-name\"; source = ./../../dotfiles/pkg-name; }
      packages = lib.mkOption {
        type = types.listOf types.attrset;
        default = [
          # Conservative defaults: only include placeholders if the paths exist when evaluated.
          # Users are expected to override this list in their flake/home configuration.
        ];
        description = ''
          List of dotfile packages to expose under the dotfiles target.
          Each list element must be an attrset with keys:
            - name (string)  : directory name under the dotfiles target
            - source (path)  : path to the package in the flake (file or directory)
        '';
      };

      # If true, attempt to run `stow -v *` inside the dotfiles target on activation.
      autoStow = lib.mkOption {
        type = types.bool;
        default = false;
        description = "If true, attempt to run `stow -v *` inside the dotfiles target during activation (no-op if stow is missing).";
      };
    };
  };

  config = lib.mkIf config.setupConfig.dotfiles.enable (let
    # compute effective target path
    dotfilesTarget = if config.setupConfig.dotfiles.target != null
                     then config.setupConfig.dotfiles.target
                     else "${config.home.homeDirectory}/.dotfiles";

    # effective package list (empty list by default)
    pkgsList = config.setupConfig.dotfiles.packages or [];

    # build the home.file attribute set for each package
    dotfilesAttrs = mkDotfilesAttrs pkgsList;

    # build a friendly message showing which packages will be managed
    pkgNames = lib.concatStringsSep ", " (map (p: p.name) pkgsList);
  in
  {
    # Merge the generated dotfiles entries into home.file so home-manager
    # declaratively manages the ~/.dotfiles/<package> symlinks to the flake sources.
    home.file = lib.mkMerge [
      (if pkgsList == [] then { } else dotfilesAttrs)

      # Provide a small marker README inside ~/.dotfiles to explain the structure.
      // {
        ".dotfiles/README".text = ''
          This directory is managed declaratively by Home Manager via the setup-config flake.
          Packages present here are symlinked from the Nix store to make them immutable, reproducible, and easy to switch.

          - To add or remove packages, update `setupConfig.dotfiles.packages` in your flake.
          - If you want to create symlinks into your home (stow behaviour), enable `setupConfig.dotfiles.autoStow`.
        '';
      // }
    ];

    # Optionally run GNU Stow after activation.
    home.activation.stowDotfiles = lib.mkIf config.setupConfig.dotfiles.autoStow {
      # The activation is intentionally conservative and non-failing:
      # - It checks for stow first and prints helpful messages otherwise.
      text = ''
        set -euo pipefail
        TARGET="${dotfilesTarget}"

        echo "setup-config: stow activation for ${TARGET}"

        if [ ! -d "${TARGET}" ]; then
          echo "Creating target directory ${TARGET}"
          mkdir -p "${TARGET}"
        fi

        # If there are no stow packages present, notify and exit cleanly
        if [ -z "$(ls -A "${TARGET}" 2>/dev/null || true)" ]; then
          echo "No packages found in ${TARGET}; nothing to stow."
          exit 0
        fi

        if command -v stow >/dev/null 2>&1; then
          echo "Running: cd \"${TARGET}\" && stow -v *"
          cd "${TARGET}" && stow -v * || echo "stow returned a non-zero status (continuing)"
        else
          echo "GNU Stow not found; to enable automatic symlinking install stow and re-run activation."
          echo "You can install stow via Nix (e.g. nix-env -iA nixpkgs.stow) or your platform package manager."
        fi
      '';
    };

    # Activation hint printed on each activation to help the user understand the dotfiles configuration.
    home.activation.dotfilesInfo = {
      text = ''
        echo "setup-config: dotfiles module applied."
        echo " - dotfiles target: ${dotfilesTarget}"
        echo " - managed packages: ${if pkgNames == \"\" then \"(none)\" else pkgNames}"
        if [ "${toString config.setupConfig.dotfiles.autoStow}" = "true" ]; then
          echo " - autoStow: enabled (stow will be invoked during activation if available)"
        else
          echo " - autoStow: disabled (set setupConfig.dotfiles.autoStow = true to enable)"
        fi
        echo "To manage added/removed dotfile packages, edit your flake's setupConfig.dotfiles.packages and re-activate home-manager."
      '';
    };
  })
}
