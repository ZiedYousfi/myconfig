{ config, pkgs, lib, ... }:

/*
  zed.nix

  Home Manager module to declaratively manage Zed editor configuration from the flake.

  Behavior:
  - Exposes Zed configuration files (typically ~/.config/zed/settings.json and ~/.config/zed/*)
    by symlinking them to the flake-provided content (via home.file.<path>.source).
  - Allows overriding the flake source path via `setupConfig.zed.source`.
  - Enables a small, non-invasive activation message and exposes ZED_CONFIG_DIR as a session variable.

  Default source:
    ../../../dotfiles/zed  (relative to this file: setup-config/nix/modules/home/packages/zed.nix)

  Options:
    setupConfig.zed.enable       : bool, enable this module (default: true)
    setupConfig.zed.source       : null | path, override source path in the flake
    setupConfig.zed.manageAll    : bool, if true manage whole `.config/zed` directory if present (default: true)
    setupConfig.zed.manageFile   : bool, if true manage `settings.json` specifically (default: true)

  Notes:
  - This module is conservative: it only manages files/dirs that exist in the flake at evaluation time.
  - If you want to manage additional Zed-related files add them by overriding options or editing the flake's zed package.
*/

let
  types = lib.types;

  # Default path inside the flake to the zed package (relative to this file)
  defaultSource = ../../../dotfiles/zed;

in
{
  options = {
    setupConfig.zed = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable the Zed home-manager module to manage Zed config from the flake.";
      };

      # Optional override path (a path in the flake)
      source = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional path in the flake to use as the Zed package source (defaults to the flake's nix/dotfiles/zed).";
      };

      # Manage the whole .config/zed directory if present
      manageAll = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When true, manage the entire .config/zed directory from the flake source (if present).";
      };

      # Manage the settings.json file specifically if present
      manageFile = lib.mkOption {
        type = types.bool;
        default = true;
        description = "When true, manage ~/.config/zed/settings.json from the flake source (if present).";
      };
    };
  };

  config = lib.mkIf config.setupConfig.zed.enable (let
    src = if config.setupConfig.zed.source != null then config.setupConfig.zed.source else defaultSource;

    # Candidate paths inside the flake source
    confDir     = "${src}/.config/zed";
    settingsInDir = "${confDir}/settings.json";
    settingsAtRoot = "${src}/settings.json";

    hasConfDir      = builtins.pathExists confDir;
    hasSettingsInDir = builtins.pathExists settingsInDir;
    hasSettingsAtRoot = builtins.pathExists settingsAtRoot;

    # Construct the home.file attributes conditionally
    zedAttrs = lib.mkMerge [
      (if config.setupConfig.zed.manageAll && hasConfDir then {
        ".config/zed" = {
          source = confDir;
          recursive = true;
        };
      } else {});

      (if config.setupConfig.zed.manageFile && hasSettingsInDir then {
        ".config/zed/settings.json" = {
          source = settingsInDir;
        };
      } else {});

      (if config.setupConfig.zed.manageFile && !hasSettingsInDir && hasSettingsAtRoot then {
        ".config/zed/settings.json" = {
          source = settingsAtRoot;
        };
      } else {})
    ];

  in
  {
    # Merge with any existing home.file entries to avoid clobbering other modules.
    home.file = lib.mkMerge [ (config.home.file or {}) zedAttrs ];

    # Provide an environment variable pointing to the expected config dir
    home.sessionVariables = {
      ZED_CONFIG_DIR = "${config.home.homeDirectory}/.config/zed";
    };

    # Activation message to quickly show what was applied
    home.activation.zedInfo = {
      text = ''
        echo "setup-config: Zed module activated."
        echo " - flake source used: ${toString src}"
        echo " - managed .config/zed directory: ${if (config.setupConfig.zed.manageAll && ${if hasConfDir then "1" else "0"}) == "1" then "yes" else "no"}"
        echo " - managed settings.json: ${if (config.setupConfig.zed.manageFile && ${if (hasSettingsInDir || hasSettingsAtRoot) then "1" else "0"}) == "1" then "yes" else "no"}"
        echo " - ZED_CONFIG_DIR -> ${config.home.homeDirectory}/.config/zed"
        echo "To experiment with stow-style symlinks, enable the dotfiles module's autoStow or run: cd ${config.home.homeDirectory}/.dotfiles && stow zed"
      '';
    };
  })
}
