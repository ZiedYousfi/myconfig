{
  description = "macOS/darwin flake that consumes the shared `nix/common` flake (modules + dotfiles) and exposes home-manager + optional nix-darwin outputs.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    nix-darwin.url = "github:LnL7/nix-darwin";
    # Local common flake that exposes `raw.modules` and `raw.dotfiles`
    common = { url = "path:../common"; };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-darwin ? null, common, ... }:
    let
      lib = flake-utils.lib;

      # The darwin architectures we want to support
      systems = [ "x86_64-darwin" "aarch64-darwin" ];

      # Helper to import a file only if it exists
      optionalImport = path: if builtins.pathExists path then import path else null;

      # Resolve common on-disk paths (fall back to repository-relative locations if necessary)
      commonModules = if common != null && common.raw ? modules then common.raw.modules else ../common/modules;
      commonDotfiles = if common != null && common.raw ? dotfiles then common.raw.dotfiles else ../dotfiles;
      commonRepoPath = if common != null && common.raw ? repoPath then common.raw.repoPath else ../common/modules/repo-path.nix;

    in
    lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Use the home-manager lib exported by the input when available
        hmLib = if builtins.hasAttr "lib" home-manager then home-manager.lib else (import home-manager).lib;

        # Import the repo helper (if present) that provides dotfilesDir, activationScript, etc.
        repo = if builtins.pathExists commonRepoPath then import commonRepoPath else {
          dotfilesDir = "${toString (builtins.getEnv "HOME")}/.dotfiles";
          flakeDotfilesPath = toString (builtins.toPath commonDotfiles);
          activationScript = ''
            mkdir -p "${toString (builtins.getEnv "HOME")}/.dotfiles"
          '';
        };

        defaultUser = "yourusername";
        defaultHome = "/Users/${defaultUser}";

        # Build a home-manager configuration that consumes only generic shared modules
        # from the common flake (common should not contain OS-specific logic).
        homeCfg = hmLib.homeManagerConfiguration {
          inherit pkgs;
          username = defaultUser;
          homeDirectory = defaultHome;

          configuration = { pkgs, ... }: let
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

            # Conservative package list; OS-specific additions should be handled
            # in the nix-darwin module or user overrides.
            home.packages = with pkgs; [
              git zsh tmux neovim fd ripgrep fzf bat lazygit zoxide btop fastfetch stow
            ];

            home.sessionVariables = {
              XDG_CONFIG_HOME = "${defaultHome}/.config";
              XDG_CACHE_HOME  = "${defaultHome}/.cache";
              EDITOR          = "nvim";
              VISUAL          = "nvim";
              LANG            = "en_US.UTF-8";
              LC_ALL          = "en_US.UTF-8";
            };

            # Keep zsh minimal here; users may extend in dotfiles or additional modules.
            programs.zsh = {
              enable = true;
              enableZshenv = true;
            };

            # Activation: copy the flake-provided dotfiles into the user's dotfiles dir if empty.
            home.activation.copyDotfiles = {
              text = repo.activationScript or ''
                mkdir -p "${repo.dotfilesDir}"
                if [ -z "$(ls -A "${repo.dotfilesDir}" 2>/dev/null)" ]; then
                  cp -r ${toString (builtins.toPath commonDotfiles)}/* "${repo.dotfilesDir}/" || true
                fi
              '';
            };

            # Message to show after activation
            home.activation.postMessage = {
              text = ''
                echo "setup-config: darwin home-manager configuration applied for ${defaultUser}."
                echo "Dotfiles target: ${repo.dotfilesDir}"
              '';
            };
          };
        };

        # Optional nix-darwin system configuration: import a darwin module if present in the common tree
        # Note: common is intended to be OS-agnostic; this import is optional and only used when a darwin-specific
        # module exists in the common tree. Alternatively, you can keep darwin-specific modules in a dedicated
        # darwin modules directory and import them here.
        darwinModulePath = commonModules + "/macos.nix";
        darwinSys = if nix-darwin != null && builtins.pathExists darwinModulePath then
          nix-darwin.lib.darwinSystem {
            inherit system;
            modules = [ optionalImport darwinModulePath ];
          }
        else
          null;

      in {
        devShells = {
          default = pkgs.mkShell {
            name = "setup-config-darwin-shell";
            buildInputs = [ pkgs.git pkgs.nix pkgs.jq ];
            shellHook = ''
              echo "Entering setup-config darwin devShell for ${system}."
            '';
          };
        };

        # Expose the home-manager configuration for this flake
        homeConfigurations = {
          "${defaultUser}" = homeCfg;
        };

        # Expose nix-darwin system configuration when available
        darwinConfigurations = if darwinSys != null then {
          "localhost" = darwinSys;
        } else { };

        packages = {
          setup-config-darwin-info = pkgs.stdenv.mkDerivation {
            pname = "setup-config-darwin-info";
            version = "0.1";
            buildCommand = ''
              mkdir -p $out/bin
              cat > $out/bin/README <<EOF
This flake is the darwin entrypoint for the setup-config repository.
It consumes the shared common flake (inputs.common) which provides generic
modules and dotfiles. Use the homeConfigurations to apply the user configuration
and darwinConfigurations (if present) to apply system configuration via nix-darwin.
EOF
              chmod +x $out/bin/README
            '';
          };
        };
      }
    );
}
