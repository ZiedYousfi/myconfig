{
  description = "Arch flake: consumes ../common (shared modules & dotfiles) and loads the Arch-specific module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";

    # Local common flake that exposes generic modules and dotfiles
    common = { url = "path:../common"; };
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, common, ... }:
    let
      lib = flake-utils.lib;

      # Architectures we support for Arch
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # Safe optional importer
      optionalImport = fp: if builtins.pathExists fp then import fp else null;

      # Prefer the common flake's on-disk paths; fall back to repo-relative locations
      commonModules = if common != null && common.raw ? modules then common.raw.modules else ../common/modules;
      commonDotfiles = if common != null && common.raw ? dotfiles then common.raw.dotfiles else ../dotfiles;
      commonRepoPath = if common != null && common.raw ? repoPath then common.raw.repoPath else ../common/modules/repo-path.nix;
    in

    lib.eachSystem systems (system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Prefer the home-manager lib exported by the input when available
        hmLib = if builtins.hasAttr "lib" home-manager then home-manager.lib else (import home-manager).lib;

        # Repo helper (dotfiles target + activation script)
        repo = if builtins.pathExists commonRepoPath then import commonRepoPath else {
          dotfilesDir = "${toString (builtins.getEnv "HOME")}/.dotfiles";
          activationScript = ''
            mkdir -p "${toString (builtins.getEnv "HOME")}/.dotfiles"
          '';
        };

        # Import the local Arch/distro-specific module (kept under this OS folder)
        archModule = optionalImport ./modules/archlinux.nix;

        defaultUser = "yourusername";
        defaultHome = "/home/${defaultUser}";

        # Build home-manager configuration by combining common (OS-agnostic) modules
        # and the Arch-specific module when present.
        homeCfg = hmLib.homeManagerConfiguration {
          inherit pkgs;
          username = defaultUser;
          homeDirectory = defaultHome;

          configuration = { pkgs, ... }: let
            sharedModules = builtins.filter (m: m != null) [
              optionalImport (commonModules + "/home/base.nix")
              optionalImport (commonModules + "/home/common-dotfiles.nix")
              optionalImport (commonModules + "/home/dotfiles.nix")
              optionalImport (commonModules + "/home/packages/tmux.nix")
              optionalImport (commonModules + "/home/packages/nvim/init.nix")
              optionalImport (commonModules + "/home/packages/zed.nix")
              optionalImport (commonModules + "/home/packages/zsh.nix")
            ];

            modulesList = sharedModules ++ (if archModule != null then [ archModule ] else []);
          in {
            imports = modulesList;

            programs.home-manager.enable = true;

            # Conservative default package set; Arch module may extend/override via imports
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

            # Activation to copy common dotfiles into the user's dotfiles dir if empty
            home.activation.copyDotfiles = {
              text = repo.activationScript;
            };

            # Small informative message on activation
            home.activation.postMessage = {
              text = ''
                echo "setup-config: Arch home-manager module applied for ${toString ${defaultUser}}."
                echo "Dotfiles target: ${repo.dotfilesDir}"
              '';
            };
          };
        };
      in {
        # Dev shell convenience
        devShells = {
          default = pkgs.mkShell {
            name = "setup-config-arch-shell";
            buildInputs = [ pkgs.git pkgs.nix pkgs.jq ];
            shellHook = ''
              echo "Entering setup-config devShell for ${system} (arch)."
            '';
          };
        };

        # Expose the home-manager configuration for the default user
        homeConfigurations = {
          "${defaultUser}" = homeCfg;
        };

        # Tiny informational package
        packages = {
          setup-config-arch-info = pkgs.stdenv.mkDerivation {
            pname = "setup-config-arch-info";
            version = "0.1";
            buildCommand = ''
              mkdir -p $out/bin
              cat > $out/bin/README <<EOF
This flake is the Arch entrypoint for the setup-config repository.
It consumes the shared common flake (inputs.common) for generic modules and dotfiles,
and imports the local ./modules/archlinux.nix Arch-specific module when present.

Apply with home-manager (flakes): e.g.
  home-manager switch --flake ./nix/arch#yourusername
EOF
              chmod +x $out/bin/README
            '';
          };
        };
      }
    );
}
