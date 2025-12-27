{
  description = "Linux-specific flake that consumes the shared ./common flake (modules + dotfiles) and exposes home-manager configurations for Linux systems.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";

    # Local common flake (shared modules, repo helper, dotfiles)
    common = { url = "path:../common"; };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, common, ... }:
    let
      lib = flake-utils.lib;

      # The Linux systems this flake will produce outputs for
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];

      # Helper to optionally import a Nix file if it exists
      optionalImport = fp: if builtins.pathExists fp then import fp else null;

      # Use the common flake's exposed on-disk paths when available, with a fallback
      commonModules = if common != null && common.raw ? modules then common.raw.modules else ../common/modules;
      commonDotfiles = if common != null && common.raw ? dotfiles then common.raw.dotfiles else ../dotfiles;
      commonRepoPath = if common != null && common.raw ? repoPath then common.raw.repoPath else ../common/modules/repo-path.nix;
    in

    lib.eachSystem linuxSystems (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Prefer the home-manager lib exported by the input; fall back to importing the input
        hmLib = if builtins.hasAttr "lib" home-manager then home-manager.lib else (import home-manager).lib;

        # Import the repository helper (repo-path.nix) if present in common
        repo = if builtins.pathExists commonRepoPath then import commonRepoPath else {
          dotfilesDir = "${toString (builtins.getEnv "HOME")}/.dotfiles";
          activationScript = ''
            mkdir -p "${toString (builtins.getEnv "HOME")}/.dotfiles"
          '';
        };

        defaultUser = "yourusername";
        defaultHome = "/home/${defaultUser}";

        # Build the home-manager configuration using modules from the shared common flake
        homeCfg = hmLib.homeManagerConfiguration {
          inherit pkgs;
          username = defaultUser;
          homeDirectory = defaultHome;

          configuration = { pkgs, ... }: let
            # Collect shared modules from the common flake; these are intentionally generic (no OS specifics).
            modulesList = builtins.filter (m: m != null) [
              optionalImport (commonModules + "/home/base.nix")
              optionalImport (commonModules + "/home/common-dotfiles.nix")
              optionalImport (commonModules + "/home/dotfiles.nix")
              optionalImport (commonModules + "/home/packages/tmux.nix")
              optionalImport (commonModules + "/home/packages/nvim/init.nix")
              optionalImport (commonModules + "/home/packages/zed.nix")
              optionalImport (commonModules + "/home/packages/zsh.nix")
            ];
          in {
            imports = modulesList;

            programs.home-manager.enable = true;

            home.packages = with pkgs; pkgs.lib.mkForce ([
              git zsh tmux neovim fd ripgrep fzf bat eza btop lazygit zoxide fastfetch stow
            ]);

            home.sessionVariables = {
              XDG_CONFIG_HOME = "${defaultHome}/.config";
              XDG_CACHE_HOME  = "${defaultHome}/.cache";
              EDITOR          = "nvim";
              VISUAL          = "nvim";
              LANG            = "en_US.UTF-8";
              LC_ALL          = "en_US.UTF-8";
            };

            # Minimal zsh settings are provided by the shared base module; keep this file conservative.
            programs.zsh = {
              enable = true;
              enableZshenv = true;
            };

            # Provide a tiny placeholder README in .dotfiles to help users discover the pattern
            home.file.".dotfiles/README".text = ''
              This directory is managed by the setup-config flake.
              Put stow-style dotfiles under packages (e.g. nvim/, zsh/, tmux/) and use GNU Stow or the provided activations to create symlinks in your home.
            '';

            # Activation that copies the flake-provided dotfiles (from common) into the user's dotfiles dir if it's empty
            home.activation.copyDotfiles = {
              text = ''
                mkdir -p "${repo.dotfilesDir}"
                if [ -z "$(ls -A "${repo.dotfilesDir}" 2>/dev/null)" ]; then
                  cp -r ${toString (builtins.toPath commonDotfiles)}/* "${repo.dotfilesDir}/" || true
                fi
              '';
            };
          };
        };
      in
      {
        devShells = {
          default = pkgs.mkShell {
            name = "setup-config-linux-shell";
            buildInputs = [ pkgs.git pkgs.nix pkgs.jq ];
            shellHook = ''
              echo "Entering setup-config devShell for ${system} (linux)."
            '';
          };
        };

        homeConfigurations = {
          # Expose the home-manager configuration for the default user.
          "${defaultUser}" = homeCfg;
        };

        packages = {
          setup-config-linux-info = pkgs.stdenv.mkDerivation {
            pname = "setup-config-linux-info";
            version = "0.1";
            buildCommand = ''
              mkdir -p $out/bin
              cat > $out/bin/README <<EOF
This flake is the Linux entrypoint for the setup-config repository.
It consumes the shared common flake (inputs.common) which provides generic modules and dotfiles.
Apply it with home-manager (flake) or inspect outputs with `nix flake show`.
EOF
              chmod +x $out/bin/README
            '';
          };
        };
      }
    );
}
