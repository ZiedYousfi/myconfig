{
  description = "Multi-platform flake for the setup-config repository — home-manager + optional darwin/nixos scaffolding";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager";
    # Optional: nix-darwin for macOS system configuration (only used on darwin systems)
    nix-darwin.url = "github:LnL7/nix-darwin";
  };

  outputs = { self, nixpkgs, flake-utils, home-manager, nix-darwin ? null, ... }:
    let
      # Use self somewhere so the attribute doesn't appear unused to linters
      _selfUsed = self;

      lib = flake-utils.lib;

      # Systems we intend to support; adjust as needed.
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      # Load overlays from ./overlays if present.
      overlaysDir = ./overlays;
      overlays = if builtins.pathExists overlaysDir then
        let
          entries = builtins.attrNames (builtins.readDir overlaysDir);
          loadOverlay = p:
            let
              fp = if builtins.match ".*\\.nix$" p != null then overlaysDir + "/" + p else overlaysDir + "/" + p + ".nix";
            in if builtins.pathExists fp then import fp else null;
        in builtins.filter (o: o != null) (map loadOverlay entries)
      else
        [];

      # Safe optional import helper
      optionalImport = path: if builtins.pathExists path then import path else null;

    in
    lib.eachSystem supportedSystems (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = overlays;
        };

        defaultUser = "yourusername";
        defaultHome = "/home/${defaultUser}";

        # OS-specific module loader (optional)
        osModule =
          if builtins.match ".*-darwin" system != null && builtins.pathExists ./modules/macos.nix then
            import ./modules/macos.nix
          else if builtins.match ".*-linux" system != null && builtins.pathExists ./modules/linux.nix then
            import ./modules/linux.nix
          else
            null;

        # Use the home-manager lib exposed by the input when available, otherwise import the input.
        hmLib = if builtins.hasAttr "lib" home-manager then home-manager.lib else (import home-manager).lib;

        # Repository helper (optional repo-path module)
        repo = if builtins.pathExists ./modules/repo-path.nix then import ./modules/repo-path.nix else {
          dotfilesDir = "${toString (builtins.getEnv "HOME")}/.dotfiles";
        };

        # Build the home-manager configuration
        homeCfg = hmLib.homeManagerConfiguration {
          inherit pkgs;
          username = defaultUser;
          homeDirectory = defaultHome;

          configuration = { pkgs, ... }: let
            # Collect optional home modules from the tree. Placing this "modulesList" here
            # ensures it's in the same scope as configuration (avoids undefined-variable issues).
            modulesList = builtins.filter (m: m != null) [
              optionalImport ./modules/home/base.nix
              optionalImport ./modules/home/common-dotfiles.nix
              optionalImport ./modules/home/dotfiles.nix
              optionalImport ./modules/home/packages/tmux.nix
              optionalImport ./modules/home/packages/nvim/init.nix
              optionalImport ./modules/home/packages/zed.nix
              optionalImport ./modules/home/packages/zsh.nix
              optionalImport ./modules/macos/yabai.nix
              optionalImport ./modules/macos/sketchybar.nix
            ];
          in {
            imports = modulesList ++ (if osModule != null && osModule.home != null then [ osModule.home ] else []);

            # Enable home-manager and declare packages
            programs.home-manager.enable = true;

            home.packages = with pkgs; pkgs.lib.mkForce ([
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
            ] ++ pkgs.lib.optionals (pkgs ? ghostty) [ pkgs.ghostty ]
              ++ pkgs.lib.optionals (pkgs ? zed) [ pkgs.zed ]
              ++ pkgs.lib.optionals (pkgs ? yabai) [ pkgs.yabai ]
              ++ pkgs.lib.optionals (pkgs ? niri) [ pkgs.niri ]
              ++ pkgs.lib.optionals (pkgs ? waybar) [ pkgs.waybar ]
            );

            # Session variables (use defaultHome so we don't depend on runtime homeDirectory)
            home.sessionVariables = {
              XDG_CONFIG_HOME = "${defaultHome}/.config";
              XDG_CACHE_HOME  = "${defaultHome}/.cache";
              EDITOR          = "nvim";
              VISUAL          = "nvim";
              TERM            = "xterm-256color";
              LANG            = "fr_FR.UTF-8";
              LC_ALL          = "fr_FR.UTF-8";
              VI_MODE_SET_CURSOR = "true";
            };

            programs.zsh = {
              enable = true;
              enableZshenv = true;
              shellAliases = {
                v    = "nvim";
                vim  = "nvim";
                vi   = "nvim";
                ll   = "ls -la";
                lg   = "lazygit";
                ff   = "fastfetch";
              };
              interactiveShellInit = ''
                # Load custom zieds plugin if present in dotfiles
                if [ -d "${repo.dotfilesDir}/zsh/.oh-my-zsh/custom/plugins/zieds" ]; then
                  fpath+=("${repo.dotfilesDir}/zsh/.oh-my-zsh/custom/plugins/zieds")
                fi
              '';
            };

            # Minimal dotfiles placeholder
            home.file.".dotfiles/.gitignore".text = "# repo-managed dotfiles placeholder";

            # Activation script that copies ./dotfiles from the flake into the target dotfilesDir if empty
            home.activation.copyDotfiles = lib.mkIf true {
              text = ''
                mkdir -p "${repo.dotfilesDir}"
                if [ -z "$(ls -A "${repo.dotfilesDir}" 2>/dev/null)" ]; then
                  cp -r ${toString (builtins.toPath ./dotfiles)}/* "${repo.dotfilesDir}/" || true
                fi
              '';
            };
          };
        };

      in
      {
        devShells = {
          default = pkgs.mkShell {
            name = "setup-config-shell";
            buildInputs = with pkgs; [ git nix jq ];
            shellHook = ''
              echo "Entering setup-config devShell for ${system}."
              echo "Use home-manager activation commands to apply user configuration."
            '';
          };
        };

        # Expose the home-manager configuration
        homeConfigurations = {
          "${defaultUser}" = homeCfg;
        } // (if nix-darwin != null && builtins.match ".*-darwin" system != null then {
          darwinConfigurations = {
            "localhost" = if nix-darwin != null && builtins.pathExists ./modules/macos.nix then
              nix-darwin.lib.darwinSystem {
                inherit system;
                modules = builtins.filter (x: x != null) [ optionalImport ./modules/macos.nix ];
              }
            else null;
          };
        } else {});

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
