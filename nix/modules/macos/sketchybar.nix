{ config, pkgs, lib, ... }:

/*
  sketchybar.nix

  Home Manager module to declaratively manage Sketchybar configuration for macOS.

  Behavior:
  - When present in the flake, the Sketchybar package under `nix/dotfiles/sketchybar`
    will be exposed to the user home via `home.file` so that `~/.config/sketchybar`
    is symlinked to the flake-provided content (immutable in the Nix store).
  - The module is conservative and only manages files/dirs that exist in the flake at
    evaluation time.
  - It provides an activation message with instructions on how to reload Sketchybar
    and how to install any required runtime dependencies (Homebrew, jq, etc.).
  - Default source path (relative to this file): ../../dotfiles/sketchybar

  Options:
    setupConfig.macos.sketchybar.enable      : bool (default true)
    setupConfig.macos.sketchybar.source      : null | path (override flake path)
    setupConfig.macos.sketchybar.autoReload  : bool (default false) - print reload hint on activation
*/

let
  types = lib.types;
in
{
  options = {
    setupConfig.macos.sketchybar = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable Sketchybar config management from the flake.";
      };

      source = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional override path in the flake for the sketchybar package (e.g. ./nix/dotfiles/sketchybar).";
      };

      autoReload = lib.mkOption {
        type = types.bool;
        default = false;
        description = "When true, activation will print an explicit sketchybar reload command hint.";
      };
    };
  };

  config = lib.mkIf config.setupConfig.macos.sketchybar.enable (let
    defaultSource = ../../dotfiles/sketchybar;
    src = if config.setupConfig.macos.sketchybar.source != null then config.setupConfig.macos.sketchybar.source else defaultSource;

    confDir = "${src}/.config/sketchybar";
    confFile = "${confDir}/sketchybarrc";
    pluginsDir = "${confDir}/plugins";

    hasConfDir = builtins.pathExists confDir;
    hasConfFile = builtins.pathExists confFile;
    hasPlugins = builtins.pathExists pluginsDir;

    # Helpful hint script printed during activation (non-destructive)
    hintScript = ''
      echo "setup-config: Sketchybar activation hints:"
      if [ "${toString hasConfFile}" = "1" ]; then
        echo " - sketchybarrc is managed at: ${config.home.homeDirectory}/.config/sketchybar/sketchybarrc"
      elif [ "${toString hasConfDir}" = "1" ]; then
        echo " - sketchybar directory is managed at: ${config.home.homeDirectory}/.config/sketchybar"
      else
        echo " - No Sketchybar config found in the flake. Add one under nix/dotfiles/sketchybar/.config/sketchybar/"
      fi

      if [ "${toString hasPlugins}" = "1" ]; then
        echo " - plugin scripts are present under ${config.home.homeDirectory}/.config/sketchybar/plugins"
        echo "   Ensure plugin scripts are executable if they are shell scripts (chmod +x ...)."
      fi

      echo ""
      echo "Common maintenance commands:"
      echo " - Reload Sketchybar: sketchybar --load ${config.home.homeDirectory}/.config/sketchybar/sketchybarrc"
      echo " - Stop Sketchybar:    sketchybar --killall"
      echo " - Start Sketchybar:   sketchybar --config ${config.home.homeDirectory}/.config/sketchybar"
      echo ""
      echo "Dependencies:"
      echo " - Sketchybar is typically installed via Homebrew (cask or formula) or Nix."
      echo " - Some plugin scripts may need utilities such as jq, yabai, osascript, etc."
      echo " - Install missing binaries via Homebrew (brew install jq) or add them to your Nix home.packages."
      if [ "${toString config.setupConfig.macos.sketchybar.autoReload}" = "1" ]; then
        echo ""
        echo "Auto-reload hint is enabled: run the reload command above after activation to apply changes."
      fi
    '';

  in
  {
    # Manage sketchybar config directory or the sketchybarrc file if present.
    home.file = lib.mkMerge [
      (config.home.file or {})
      (if hasConfDir then {
        ".config/sketchybar" = {
          source = confDir;
          recursive = true;
        };
      } else {})
      (if (!hasConfDir && hasConfFile) then {
        # if only the file exists (unlikely), manage that single file
        ".config/sketchybar/sketchybarrc" = {
          source = confFile;
          mode = "0755";
        };
      } else {})
    ];

    # Expose a helpful env var pointing to the sketchybar config directory
    home.sessionVariables = lib.mkMerge [
      (config.home.sessionVariables or {})
      {
        SKETCHYBAR_CONFIG_DIR = "${config.home.homeDirectory}/.config/sketchybar";
      }
    ];

    # Activation message and hints (non-destructive)
    home.activation.sketchybarInfo = {
      text = hintScript;
    };

    # Do not attempt to install or enable system services here; only manage files and provide guidance.
  })
}
