# setup-config: darwin flake

This directory exports a macOS (darwin) flake that consumes the shared `nix/common` flake
and exposes a `homeConfigurations` and optional `darwinConfigurations`.

Quick steps (fresh macOS):

Prerequisites

- Install Nix following the official instructions: <https://nixos.org/install>
- Enable flakes & the new Nix CLI by adding the following to `/etc/nix/nix.conf` or `~/.config/nix/nix.conf`:

``` nix
experimental-features = nix-command flakes
```

Using the flake (repo checked out locally)

1. Clone this repo and change into it (if not already):

```bash
git clone https://github.com/ZiedYousfi/myconfig.git
cd myconfig
```

1. Verify the flake resolves:

```bash
nix --extra-experimental-features "nix-command flakes" flake metadata nix/darwin
```

1. Activate the home-manager configuration for a user.

- The flake exports `homeConfigurations.<username>`. Replace `<username>` with your macOS username or edit `nix/darwin/flake.nix` to change the default `defaultUser`.

Activate using Nix directly:

```bash
nix --extra-experimental-features "nix-command flakes" run nix/darwin#homeConfigurations.<username>.activationPackage
```

Or, if you have `home-manager` installed, you can:

```bash
home-manager switch --flake nix/darwin#<username>
```

1. (Optional) Apply the system configuration via nix-darwin if present in the flake:

```bash
# Use darwin-rebuild (nix-darwin)
darwin-rebuild switch --flake nix/darwin#localhost
```

Notes

- Dotfiles: the flake attempts to copy provided dotfiles into `~/.dotfiles` when the home activation runs. If you want to use local dotfiles instead, edit the `common` input in `nix/darwin/flake.nix` or provide your own repository.
- Customization: the `defaultUser` variable in `nix/darwin/flake.nix` is set to `yourusername` by default — change it to match your macOS account or invoke the activation for your username explicitly.
- If the repo is used as a flake input from elsewhere, use the flake reference `github:owner/repo?/nix/darwin` or a local path reference.

Troubleshooting

- If Nix complains about flakes, ensure `experimental-features = nix-command flakes` is present in your nix config and restart your shell.
- If dotfiles aren't copied, check the `home.activation.copyDotfiles` activation output and the `repo` fallback in `nix/darwin/flake.nix`.

Want me to run the activation for your current user now? Provide permission and your macOS username, and I'll run the activation command here.
