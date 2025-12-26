{ config, pkgs, lib, ... }:

let
  inherit (lib) mkOption types mkIf optionalAttrs;

  # Helper to safely import a module file if it exists; returns null when absent.
  safeImport = path:
    if builtins.pathExists path then
      let imp = import path; in imp
    else
      null;

in

{
  options = {
    setupConfig.linux = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Enable the generic linux home-manager helper module.";
      };

      distro = mkOption {
        type = types.str;
        default = "auto";
        description = ''
          Target distribution identifier used to select a per-distro module.
          Supported values: \"arch\", \"ubuntu\", \"nixos\", \"generic\", \"auto\".

          - When set to \"auto\" this module will prefer the file order:
            archlinux.nix -> ubuntu.nix -> nixos.nix -> generic.nix
            (whichever file exists in the same folder).
          - When set explicitly, the module will attempt to import the corresponding file
            (e.g. \"arch\" -> ./archlinux.nix). If the file is missing the import is skipped.
        '';
      };

      # Allow consumers to provide a path override for dotfiles target (optional).
      dotfilesTarget = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Optional override for the user's dotfiles target directory (e.g. /home/me/.dotfiles).";
      };
    };
  };

  config = mkIf config.setupConfig.linux.enable {
    # Determine which per-distro module to load based on config.setupConfig.linux.distro
    # and on which module files exist in this directory.
    #
    # Per-distro files this module looks for (relative to this file):
    #  - ./archlinux.nix      (recommended name for Arch-specific module)
    #  - ./ubuntu.nix         (Ubuntu-specific module)
    #  - ./nixos.nix          (NixOS-specific module; may export both system and home parts)
    #  - ./generic.nix        (catch-all generic linux helper)
    #
    # Each target module can be either:
    #  - a home-manager module (i.e. a function returning a module set), or
    #  - an attribute set containing a `home` attribute with the home-manager module.
    #
    # We attempt to select the appropriate module and, if present, add it to imports.
    let
      distro = config.setupConfig.linux.distro;

      archModule = safeImport ./archlinux.nix;
      ubuntuModule = safeImport ./ubuntu.nix;
      nixosModule = safeImport ./nixos.nix;
      genericModule = safeImport ./generic.nix;

      # Selection logic: explicit mappings first; 'auto' falls back to the first existing file.
      selectedRaw = if distro == "arch" then archModule
        else if distro == "ubuntu" then ubuntuModule
        else if distro == "nixos" then nixosModule
        else if distro == "generic" then genericModule
        else if distro == "auto" then
          (if archModule != null then archModule
           else if ubuntuModule != null then ubuntuModule
           else if nixosModule != null then nixosModule
           else genericModule)
        else
          null;

      # If selectedRaw contains a `home` attribute, prefer that (home-manager module).
      selectedHomeModule = if selectedRaw != null && (selectedRaw.home or null) != null
        then selectedRaw.home
        else selectedRaw;

      # Expose a tiny helper variable for other modules / activations to use when copying dotfiles.
      dotfilesTarget = if config.setupConfig.linux.dotfilesTarget != null
        then config.setupConfig.linux.dotfilesTarget
        else null;
    in
    {
      # Import the selected per-distro home-manager module when present.
      imports = lib.optional (selectedHomeModule != null) selectedHomeModule;

      # Provide a small, safe activation stub that higher-level per-distro modules can consume.
      # This activation only runs when the per-distro module opts-in; it's intentionally minimal
      # and avoids overwriting existing user data.
      home.activation.setupConfigDotfiles = lib.optionalAttrs (dotfilesTarget != null) {
        text = ''
          mkdir -p "${if dotfilesTarget != null then dotfilesTarget else "${config.home.homeDirectory}/.dotfiles"}"
          # Leave the directory alone if non-empty; copying should be handled by per-distro modules
          # or by the shared repo-path helper in ./repo-path.nix.
          if [ -z "$(ls -A "${if dotfilesTarget != null then dotfilesTarget else "${config.home.homeDirectory}/.dotfiles"}" 2>/dev/null)" ]; then
            echo "Dotfiles target is empty. Consider running the flake activation to populate dotfiles from the flake."
          fi
        '';
      };

      # Make the detected selection available in the user environment so activation scripts
      # or interactive prompts can display which per-distro module was used.
      home.sessionVariables = {
        SETUP_CONFIG_SELECTED_DISTRO = lib.mkForce (if selectedRaw != null then (config.setupConfig.linux.distro) else "none");
      };

      # Helpful message at activation time to guide the user if no per-distro module was found.
      home.activation.postMessage.text = ''
        if [ "${if selectedRaw != null then "1" else "0"}" = "0" ]; then
          echo "setup-config: no per-distro linux module found for '${config.setupConfig.linux.distro}'."
          echo "  Place one of: archlinux.nix, ubuntu.nix, nixos.nix or generic.nix next to ${./linux.nix}"
          echo "  or set setupConfig.linux.distro to a supported value that matches an existing module file."
        else
          echo "setup-config: linux helper applied for distro='${config.setupConfig.linux.distro}'."
        fi
      '';
    }
  };
}
