{
  description = "Common flake: exposes repository-shipped shared modules and dotfiles for OS-specific flakes. Contains no OS-specific logic.";

  # Intentionally no heavy inputs here — this flake only exposes on-disk paths
  # so other flakes can import the common modules/dotfiles via `inputs.common.raw`.
  inputs = { };

  outputs = { self, ... }:
    let
      # Paths are relative to this flake file.
      # - `modules` should live next to this flake in `./modules`
      # - `dotfiles` is expected to live at `../dotfiles` (repo layout: nix/common + nix/dotfiles)
      modulesPath  = ./modules;
      dotfilesPath = ../dotfiles;
      repoPathFile = ./modules/repo-path.nix;
    in
    {
      # `raw` is a lightweight convention: downstream flakes can reference
      # `inputs.common.raw.modules` or `inputs.common.raw.dotfiles` to get the
      # on-disk path and import files directly.
      raw = {
        modules  = modulesPath;
        dotfiles = dotfilesPath;
        repoPath = repoPathFile;

        doc = ''
          setup-config: common flake
          ==========================

          Purpose:
            - Expose on-disk locations for shared Nix modules and dotfiles so that
              per-OS flakes (e.g. nix/linux/flake.nix, nix/darwin/flake.nix) can
              import them via `inputs.common.raw`.

          Exposed paths (relative to this flake file):
            - modules:  ${builtins.toString modulesPath}
            - dotfiles: ${builtins.toString dotfilesPath}
            - repoPath: ${builtins.toString repoPathFile}

          Example usage in another flake:
            inputs = {
              common.url = "path:./nix/common";
            };

            outputs = { self, nixpkgs, common, ... }:
              let
                sharedModules = common.raw.modules;
              in {
                # import a shared module
                homeModule = import (sharedModules + "/home/base.nix") { inherit nixpkgs; };
              };

          NOTE:
            - This flake intentionally avoids pulling in `nixpkgs` or other heavy
              inputs so it can be imported quickly by OS-specific flakes.
            - Keep this flake OS-agnostic: do not add macOS/Linux specific logic here.
        '';
      };
    };
}
