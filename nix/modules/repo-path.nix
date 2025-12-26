let
  /*
    repo-path.nix

    Helper used by home activation scripts and modules to determine:
      - where the user's dotfiles should live on the filesystem (default: $HOME/.dotfiles)
      - where the flake's shipped `./dotfiles` directory is (path inside the checked-out flake)
      - small shell snippets suitable for home-manager activations

    Usage:
      import ./repo-path.nix as rp;
      rp.dotfilesDir           -> string path (target location in the user's HOME)
      rp.flakeDotfilesPath     -> string path pointing to the flake's ./dotfiles directory
      rp.activationScript      -> shell snippet that safely copies flake dotfiles into dotfilesDir if empty
      rp.stowCommand           -> helper snippet that runs GNU Stow (if available)
  */

  envVar = builtins.getEnv "SETUP_CONFIG_DOTFILES";
  home = builtins.getEnv "HOME";
  dotfilesDir = if envVar != "" then envVar else "${home}/.dotfiles";

  # Path to the ./dotfiles directory shipped with the flake.
  # Relative to this file: modules/repo-path.nix  -> ../../dotfiles
  flakeDotfilesPath = toString (./../../dotfiles);
in
{
  dotfilesDir = dotfilesDir;
  flakeDotfilesPath = flakeDotfilesPath;

  # activationScript is a small, idempotent shell snippet suitable for use
  # as the body of a home.activation script. It:
  #  - creates the target directory
  #  - copies the flake-provided dotfiles into it only if the directory is empty
  #
  # Note: quoting here is important when this string is embedded in home-manager modules.
  activationScript = ''
    mkdir -p "${dotfilesDir}"
    # Only populate the target if it's empty to avoid overwriting existing user dotfiles.
    if [ -z "$(ls -A "${dotfilesDir}" 2>/dev/null)" ]; then
      # Copy contents from the flake's ./dotfiles into the user's dotfiles directory.
      # The copy is permissive (|| true) so activation won't fail on systems with odd permissions.
      cp -r ${flakeDotfilesPath}/* "${dotfilesDir}/" || true
    fi
  '';

  # A helper snippet that attempts to run GNU Stow to create symlinks from the
  # dotfiles repository into the user's home. This is conservative: it checks
  # for `stow` and prints a friendly message if missing.
  stowCommand = ''
    if command -v stow >/dev/null 2>&1; then
      echo "Running GNU Stow from ${dotfilesDir}..."
      cd "${dotfilesDir}" && stow -v *
    else
      echo "GNU Stow is not installed. Install it (e.g. 'nix-env -iA nixpkgs.stow' or via your package manager) to create symlinks automatically."
    fi
  '';

  # Minimal documentation accessible at runtime for users/operators.
  doc = ''
    repo-path.nix
    ==============
    dotfilesDir: ${dotfilesDir}
    flakeDotfilesPath: ${flakeDotfilesPath}

    Use rp.activationScript as the shell body for a home.activation to copy
    the flake's dotfiles into ${dotfilesDir} if it's empty. After copying,
    you can run the rp.stowCommand snippet (or install GNU Stow) to symlink
    individual packages into your home directory.

    You can override the target dotfiles directory by setting the environment
    variable SETUP_CONFIG_DOTFILES to an absolute path before activating the home-manager configuration.
  '';
}
