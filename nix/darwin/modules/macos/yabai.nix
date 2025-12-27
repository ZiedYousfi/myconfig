{ config, pkgs, lib, ... }:

/*
  yabai.nix

  Home Manager module to manage yabai configuration for macOS from the flake.

  Behavior:
  - Declaratively manages ~/.config/yabai/yabairc (symlinked from the flake) when present.
  - Exposes options for overriding the flake source and for an opt-in "installSudoRules"
    hint (the module will not change system-wide permissions automatically; it only
    prints guidance during activation if requested).
  - Provides activation messages guiding the user to grant accessibility permissions
    and to install any helper tools (skhd, yabai permissions) needed on macOS.

  Default source path (relative to this file):
    ../../dotfiles/yabai
*/

let
  types = lib.types;
in
{
  options = {
    setupConfig.macos.yabai = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable yabai module to manage ~/.config/yabai from the flake.";
      };

      # Optional override: a path (in the flake) that provides the yabai package
      source = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional override path in the flake for the yabai package (e.g. ./nix/dotfiles/yabai).";
      };

      # If true, activation will print guidance about rules and sudo wrappers (it will NOT modify system entitlements).
      installSudoRules = lib.mkOption {
        type = types.bool;
        default = false;
        description = "When true, print additional guidance about installing sudo rules and accessibility entitlements for yabai (no automatic changes).";
      };
    };
  };

  config = lib.mkIf config.setupConfig.macos.yabai.enable (let
    defaultSource = ../../dotfiles/yabai;
    src = if config.setupConfig.macos.yabai.source != null then config.setupConfig.macos.yabai.source else defaultSource;

    confDir = "${src}/.config/yabai";
    confFile = "${confDir}/yabairc";

    hasConf = builtins.pathExists confFile;

    # A short, idempotent activation helper that prints step-by-step hints for macOS security & helper installation.
    hintScript = ''
      echo "setup-config: yabai activation hints:"
      if [ "${toString hasConf}" = "1" ]; then
        echo " - yabai config will be managed at: ${config.home.homeDirectory}/.config/yabai/yabairc"
      else
        echo " - No yabairc found in the flake source. Add one at nix/dotfiles/yabai/.config/yabai/yabairc to have it managed."
      fi

      echo ""
      echo "Important macOS notes:"
      echo " - yabai requires Accessibility permissions and often a scripting addition to control windows."
      echo " - You must grant Accessibility (System Preferences → Security & Privacy → Privacy → Accessibility)."
      echo " - If you use the yabai scripting addition you may need to run its installer and follow manual steps."
      echo " - Helper tools commonly used with yabai: skhd (hotkey daemon). Consider installing it via Homebrew or Nix."
      echo ""
      if [ \"${toString config.setupConfig.macos.yabai.installSudoRules}\" = \"true\" ]; then
        echo "installSudoRules is enabled: the activation will NOT modify entitlements automatically,"
        echo "but you should ensure the following manual steps are completed:"
        echo "  1) Grant Accessibility to yabai/skhd in System Preferences."
        echo "  2) Follow yabai's docs to install the scripting addition (if you intend to use it)."
        echo "  3) If you want non-interactive restart/install, you may create helpers with proper entitlements and"
        echo "     run them with elevated privileges — do this manually and verify signatures/permissions."
      fi

      echo ""
      echo "To apply the config file now (stowed/managed), re-activate Home Manager or run:"
      echo "  home-manager switch  # if using standalone home-manager"
      echo "  # or via the flake activation package (nix run ... activationPackage)"
    '';

  in {
    # Merge the managed yabai file (if present) into home.file so home-manager symlinks it from the Nix store.
    home.file = lib.mkMerge [
      (config.home.file or {})
      (if hasConf then {
        ".config/yabai/yabairc" = {
          source = confFile;
          mode = "0755"; # yabairc is typically executable as it's a shell script
        };
      } else {})
    ];

    # Provide a small environment variable to point to the yabai config dir
    home.sessionVariables = lib.mkMerge [
      (config.home.sessionVariables or {})
      {
        YABAI_CONFIG_DIR = "${config.home.homeDirectory}/.config/yabai";
      }
    ];

    # Activation hook prints helpful hints and guidance (non-destructive)
    home.activation.yabaiInfo = {
      text = hintScript;
    };

    # Optionally ensure user knows to enable/disable services; do not auto-enable anything.
  })
}
