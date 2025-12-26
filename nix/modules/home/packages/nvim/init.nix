{ config, pkgs, lib, ... }:

/*
  nvim/init.nix

  Home Manager module to declaratively manage Neovim configuration from the flake.

  Features:
  - Enables `programs.neovim` (lightweight) and exposes Neovim configuration found in
    the flake's `nix/dotfiles/nvim` directory into the user's `~/.config/nvim` via
    `home.file.<...>.source` (symlinked to the Nix store).
  - Allows overriding the source path if your nvim package lives elsewhere in the flake.
  - Detects common layout variants and manages only paths that exist at evaluation time:
      - whole `.config/nvim` directory
      - `init.lua` or `init.vim` at the package root or inside `.config/nvim`
      - `lua/` tree for plugin/config modules
      - `lua/plugins/colorscheme.lua` placeholder (keeps colorscheme included)
  - Non-destructive: merges with existing `home.file` entries from other modules.
  - Provides activation messages to help users understand what got applied.

  Notes:
  - Default source path is `../../../../dotfiles/nvim` relative to this file which
    corresponds to `setup-config/nix/dotfiles/nvim` in the repository layout.
  - If you prefer to manage individual files instead of the whole directory, set
    `setupConfig.neovim.source` to a path pointing to the desired file(s) in the flake.
*/

let
  types = lib.types;

  # default path inside the flake to the nvim package (relative to this file)
  defaultSource = ../../../../dotfiles/nvim;

in
{
  options = {
    setupConfig.neovim = {
      enable = lib.mkOption {
        type = types.bool;
        default = true;
        description = "Enable the Neovim home-manager module to manage nvim configuration from the flake.";
      };

      # Optional override: a path in the flake to use as the neovim config source
      source = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional override path to the Neovim package in the flake (e.g. ./nix/dotfiles/nvim).";
      };

      # Optionally pick a specific neovim package (from nixpkgs) if you want to override
      neovimPackage = lib.mkOption {
        type = types.nullOr types.path;
        default = null;
        description = "Optional override for the Neovim package (a derivation), e.g. pkgs.neovimStable. If left null, default pkgs.neovim is used.";
      };
    };
  };

  config = lib.mkIf config.setupConfig.neovim.enable (let
    # effective source path inside the flake
    src = if config.setupConfig.neovim.source != null then config.setupConfig.neovim.source else defaultSource;

    # candidate paths we look for inside the package
    confDir        = "${src}/.config/nvim";
    initLuaRoot    = "${src}/init.lua";
    initVimRoot    = "${src}/init.vim";
    initLuaInDir   = "${confDir}/init.lua";
    initVimInDir   = "${confDir}/init.vim";
    luaTree        = "${src}/lua";
    luaInConf      = "${confDir}/lua";
    colorschemeLua = "${src}/lua/plugins/colorscheme.lua";
    colorschemeInConf = "${confDir}/lua/plugins/colorscheme.lua";

    # existence checks (at evaluation time)
    hasConfDir        = builtins.pathExists confDir;
    hasInitLuaRoot    = builtins.pathExists initLuaRoot;
    hasInitVimRoot    = builtins.pathExists initVimRoot;
    hasInitLuaInDir   = builtins.pathExists initLuaInDir;
    hasInitVimInDir   = builtins.pathExists initVimInDir;
    hasLuaTree        = builtins.pathExists luaTree;
    hasLuaInConf      = builtins.pathExists luaInConf;
    hasColorschemeLua = builtins.pathExists colorschemeLua;
    hasColorschemeInConf = builtins.pathExists colorschemeInConf;

    # build home.file attrset conditionally
    nvimAttrs = lib.mkMerge [
      (if hasConfDir then {
        # Manage the whole config directory (recursive)
        ".config/nvim" = {
          source = confDir;
          recursive = true;
        };
      } else {});

      (if hasInitLuaRoot then {
        # Manage top-level init.lua
        ".config/nvim/init.lua" = {
          source = initLuaRoot;
        };
      } else {});

      (if hasInitVimRoot then {
        ".config/nvim/init.vim" = {
          source = initVimRoot;
        };
      } else {});

      (if hasInitLuaInDir then {
        ".config/nvim/init.lua" = {
          source = initLuaInDir;
        };
      } else {});

      (if hasInitVimInDir then {
        ".config/nvim/init.vim" = {
          source = initVimInDir;
        };
      } else {});

      (if hasLuaTree then {
        ".config/nvim/lua" = {
          source = luaTree;
          recursive = true;
        };
      } else {});

      (if hasLuaInConf then {
        ".config/nvim/lua" = {
          source = luaInConf;
          recursive = true;
        };
      } else {});

      (if hasColorschemeLua then {
        ".config/nvim/lua/plugins/colorscheme.lua" = {
          source = colorschemeLua;
        };
      } else {});

      (if hasColorschemeInConf then {
        ".config/nvim/lua/plugins/colorscheme.lua" = {
          source = colorschemeInConf;
        };
      } else {})
    ];

    # Decide which neovim package to expose to home-manager's programs.neovim
    neovimPkg = if config.setupConfig.neovim.neovimPackage != null then config.setupConfig.neovim.neovimPackage else pkgs.neovim;

  in
  {
    # Merge with any existing home.file entries from other modules
    home.file = lib.mkMerge [ (config.home.file or {}) nvimAttrs ];

    # Enable the programs.neovim module with the chosen package
    programs.neovim = {
      enable = true;
      package = neovimPkg;
      # We avoid forcing plugin managers here; leave plugin installation up to the stowed config or
      # user-managed plugin manager so this module remains non-invasive.
    };

    # Helpful activation message telling the user what was managed
    home.activation.nvimInfo = {
      text = ''
        echo "setup-config: Neovim module applied."
        echo -n " - Managed entries: "
        if [ "${toString ${lib.toString hasConfDir}}" = "true" ]; then
          echo -n ".config/nvim (dir) "
        fi
        if [ "${toString ${lib.toString hasInitLuaRoot}}" = "true" ] || [ "${toString ${lib.toString hasInitLuaInDir}}" = "true" ]; then
          echo -n "init.lua "
        fi
        if [ "${toString ${lib.toString hasInitVimRoot}}" = "true" ] || [ "${toString ${lib.toString hasInitVimInDir}}" = "true" ]; then
          echo -n "init.vim "
        fi
        if [ "${toString ${lib.toString hasLuaTree}}" = "true" ] || [ "${toString ${lib.toString hasLuaInConf}}" = "true" ]; then
          echo -n "lua/ "
        fi
        echo
        echo " - If the expected config files were not found, set setupConfig.neovim.source to the correct flake path."
        echo " - For experimenting with stow-style symlinks, consider enabling the shared dotfiles module's autoStow option or run 'cd ~/.dotfiles && stow nvim' manually."
      '';
    };
  })
}
