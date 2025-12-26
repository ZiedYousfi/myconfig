{ config, pkgs, lib, ... }:

/*
  common-dotfiles.nix

  Purpose:
    - Provide a single, reusable list of "common" dotfile packages (zed, tmux, zsh, neovim)
      so they can be included in the dotfiles management module for all platforms.
    - The module exposes `setupConfig.dotfiles.commonPackages` (a list of attrsets
      with `name` and `source`) and merges this list into `setupConfig.dotfiles.packages`
      so downstream modules (e.g. `home/dotfiles.nix`) will manage them under ~/.dotfiles.

  Design notes:
    - The default sources point at the flake's `nix/dotfiles/<pkg>` directory (relative path).
      If you move the dotfiles location in the flake, update these sources accordingly.
    - This module appends the common packages to any user-provided `setupConfig.dotfiles.packages`.
      It intentionally avoids destructive overrides: user-specified packages remain first.
    - If you need de-duplication behavior (avoid duplicates when a user also lists the same
      package), we can add a small dedupe step; for now the merge is a simple concatenation,
      which keeps the logic straightforward and predictable.
*/

let
  types = lib.types;

  # Default list of common packages (name + source path relative to this file).
  # Important: these relative paths assume this file is at:
  #   setup-config/nix/modules/home/common-dotfiles.nix
  # and the flake's dotfiles are available at:
  #   setup-config/nix/dotfiles/<pkg>
  defaultCommonPackages = [
    { name = "nvim"; source = ../../dotfiles/nvim; }
    { name = "zsh";  source = ../../dotfiles/zsh;  }
    { name = "tmux"; source = ../../dotfiles/tmux; }
    { name = "zed";  source = ../../dotfiles/zed;  }
  ];
in
{
  options = {
    setupConfig.dotfiles.commonPackages = lib.mkOption {
      type = types.listOf types.attrset;
      default = defaultCommonPackages;
      description = ''
        A list of common dotfile packages that should be exposed under the dotfiles target
        (each item must be an attrset with keys `name` and `source`).
        Example element:
          { name = "nvim"; source = ./../../dotfiles/nvim; }
      '';
    };
  };

  config = let
    # ensure we have always a list to concatenate
    existing = config.setupConfig.dotfiles.packages or [];
    common   = config.setupConfig.dotfiles.commonPackages or [];
  in {
    # Merge user-defined dotfiles.packages with the common list.
    # Existing (user) packages are kept first; common packages are appended.
    # Use mkForce so that the resultant merged list is the effective option value.
    setupConfig.dotfiles.packages = lib.mkForce (existing ++ common);
  };
}
