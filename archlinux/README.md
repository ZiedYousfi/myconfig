# Arch Linux Development Environment

One-command installation from the Arch ISO to a fully configured development desktop.

## Quick Start

Boot from the Arch Linux ISO, connect to the internet, and run:

```bash
curl -sL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/archlinux/bootstrap-quick.sh | bash
```

Or clone first if you want to customize:

```bash
git clone https://github.com/ZiedYousfi/myconfig.git
cd myconfig/archlinux
./bootstrap.sh
```

## What You Get

- **Window Manager:** Niri (scrollable tiling Wayland compositor)
- **Status Bar:** Waybar with Monokai theme
- **Terminal:** Ghostty (fullscreen, auto-attaches to tmux)
- **Editor:** Neovim (LazyVim) + Zed
- **Shell:** Zsh with Oh My Zsh
- **Multiplexer:** tmux with Oh My Tmux
- **Tools:** Go, Clang, ripgrep, fzf, fd, eza, bat, lazygit, btop

## Scripts

| Script               | Purpose                                      |
| -------------------- | -------------------------------------------- |
| `bootstrap-quick.sh` | Run from ISO - interactive, self-contained   |
| `bootstrap.sh`       | Run from ISO - uses local config files       |
| `install.sh`         | Post-install setup on existing Arch system   |
| `uninstall.sh`       | Remove all configurations                    |

## Configuration

Edit files in `archinstall_config/` before running bootstrap:

- `user_configuration.json` - System settings (disk, locale, packages)
- `user_credentials.json` - User account credentials

## First Boot

After installation, the system automatically:

1. Installs AUR helper (paru)
2. Installs all packages (including AUR)
3. Configures dotfiles via GNU Stow
4. Sets up Oh My Zsh, Oh My Tmux, LazyVim

Monitor progress:

```bash
journalctl -f -u first-boot-setup.service
```

## Post-Install Only

Already have Arch? Just run:

```bash
./install.sh
```

## Documentation

See [SPECS.md](SPECS.md) for detailed configuration specifications.
