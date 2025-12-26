{
  description = "Multi-platform flake for the setup-config repository — home-manager + optional darwin/nixos scaffolding";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; # pick a stable channel you like
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    # Optional: nix-darwin for macOS system configuration (only used on darwin systems)
    nix-darwin.url = "github:LnL7/nix-darwin";
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-darwin ? null, ... }:
    let
      lib = flake-utils.lib;

      # Systems we intend to support. You can adjust as needed.
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Helper to load local overlay(s) if present. Keep overlays in ./overlays.
      overlays = builtins.filter (o: o != null) (map (p: import ./overlays/"${p}.nix" or null) (builtins.attrNames (builtins.readDir ./overlays)));
    in

    lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlays or [];
        };

        # Convenience: path to repository root inside the flake
        repo = (import ./modules/repo-path.nix) or {
          # If ./modules/repo-path.nix is not present, fall back to default values used below.
          dotfilesDir = "${toString (builtins.getEnv "HOME")}/.dotfiles";
        };

        # Default username & home directory — override in per-system modules below.
        defaultUser = "yourusername";
        defaultHome = "/home/${defaultUser}";

        # Load per-OS modules from ./modules (we expect files like macos.nix, ubuntu.nix, archlinux.nix).
        osModule = try (import ./modules/${if builtins.match ".*-darwin" system != null then "macos.nix" else if builtins.match ".*-linux" system != null then "linux.nix" else "default.nix"}) with e: null;

        # Home-manager configuration builder
        homeCfg = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          # You should set username and homeDirectory appropriately per-machine.
          username = defaultUser;
          homeDirectory = defaultHome;

          # A declarative list of home-manager modules. We include:
          # - a base module that sets XDG vars, EDITOR, LC_*, etc.
          # - a dotfiles module that copies/stows the repository's dotfiles into ~/.dotfiles and stows them
          # - OS-specific module (if present)
          configuration = { pkgs, ... }: {
            imports = [
              (import ./modules/home/base.nix or { })
              imports = [ (import ./modules/home/base.nix or { })
                          (import ./modules/home/common-dotfiles.nix or { })
                          (import ./modules/home/dotfiles.nix or { })
                          (import ./modules/home/packages/tmux.nix or { })
                          (import ./modules/home/packages/nvim/init.nix or { })
                          (import ./modules/home/packages/zed.nix or { })
                          (import ./modules/home/packages/zsh.nix or { })
                          (import ./modules/macos/yabai.nix or { })
                          (import ./modules/macos/sketchybar.nix or { })
                        ] ++ (if osModule != null then [ osModule.home or { } ] else []);

            # Example of declarative packages (CLI tools mentioned in SPECS.md)
            programs.home-manager.enable = true;

            home.packages = with pkgs; lib.mkForce ([
              git
              zsh
              tmux
              neovim
              fd
              ripgrep
              fzf
              bat
              eza
              btop
              lazygit
              zoxide
              fastfetch
              stow
            ] ++ (lib.optional (pkgs ? ghostty) ghostty)
              ++ (lib.optional (pkgs ? zed) zed)
              ++ (lib.optional (pkgs ? yabai) yabai)
              ++ (lib.optional (pkgs ? niri) niri)
              ++ (lib.optional (pkgs ? waybar) waybar)
            );

            # Example environment variables from SPECS.md
            home.sessionVariables = {
              XDG_CONFIG_HOME = "${homeDirectory}/.config";
              XDG_CACHE_HOME = "${homeDirectory}/.cache";
              EDITOR = "nvim";
              VISUAL = "nvim";
              TERM = "xterm-256color";
              LANG = "fr_FR.UTF-8";
              LC_ALL = "fr_FR.UTF-8";
              VI_MODE_SET_CURSOR = "true";
            };

            # Example: enable home-manager's zsh module and set up oh-my-zsh
            programs.zsh = {
              enable = true;
              enableZshenv = true;
              shellAliases = {
                v = "nvim";
                vim = "nvim";
                vi = "nvim";
                ll = "ls -la";
                lg = "lazygit";
                ff = "fastfetch";
              };
              interactiveShellInit = ''
                # Load custom zieds plugin if present in dotfiles
                if [ -d "${repo.dotfilesDir}/zsh/.oh-my-zsh/custom/plugins/zieds" ]; then
                  fpath+=("${repo.dotfilesDir}/zsh/.oh-my-zsh/custom/plugins/zieds")
                fi
              '';
            };

            # Example: simple home.file entries to stage the stowed dotfiles workflow.
            # Users should replace or extend ./modules/home/dotfiles.nix to provide finer control.
            home.file.".dotfiles/.gitignore".text = "# repo-managed dotfiles placeholder";

            # Provide simple activation script to copy `./dotfiles` in the flake to ~/.dotfiles on activation.
            # Note: This uses a home.activation script — you can expand this to a full stow workflow.
            home.activation.copyDotfiles = lib.mkIf true {
              text = ''
                mkdir -p "${repo.dotfilesDir}"
                # Copy dotfiles from the checked-out flake (this flake) into ~/.dotfiles if empty
                if [ -z "$(ls -A "${repo.dotfilesDir}" 2>/dev/null)" ]; then
                  cp -r ${toString (builtins.toPath ./dotfiles)}/* "${repo.dotfilesDir}/" || true
                fi
              '';
            };
          };
        };
      in

      {
        # Expose a packaged devShell for this system
        devShells.default = pkgs.mkShell {
          name = "setup-config-shell";
          buildInputs = with pkgs; [ git nix jq ];
          shellHook = ''
            echo "Entering setup-config devShell for ${system}."
            echo "Use home-manager activation commands to apply user configuration."
          '';
        };

        # Expose the home-manager configuration so users can apply it:
        # e.g. `nix run .#homeConfigurations.${system}.yourusername.activationPackage`
        homeConfigurations = {
          "${defaultUser}" = homeCfg;
        } // (if nix-darwin != null && builtins.match ".*-darwin" system != null then {
          # If nix-darwin is available and this is a darwin system, expose a darwin configuration stub.
          # Users should provide ./modules/macos.nix to fully configure nix-darwin.
          darwinConfigurations = {
            # host name placeholder — users should change to their real hostname or add per-host entries.
            "localhost" = if nix-darwin != null then
              nix-darwin.lib.darwinSystem {
                system = system;
                modules = [
                  (import ./modules/macos.nix or { })
                ];
              }
            else null;
          };
        } else {});

        # A small convenience package that prints where to look next
        packages = {
          setup-config-info = pkgs.stdenv.mkDerivation {
            pname = "setup-config-info";
            version = "0.1";
            buildCommand = ''
              mkdir -p $out/bin
              cat > $out/bin/README <<EOF
              This flake provides:
                - homeConfigurations.${system}.${defaultUser} (home-manager config)
                - devShells.default
                - (optional) darwinConfigurations if nix-darwin is available

              See ./modules/ to add OS-specific modules (macos.nix, linux.nix, archlinux.nix, ubuntu.nix)
              EOF
              chmod +x $out/bin/README
            '';
          };
        };
      }
    );
}
