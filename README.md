# Setup Config — Development Environment

This repository provides a single-script, idempotent setup for a development environment on macOS and Ubuntu. Each platform has a dedicated installer and its own configuration subtree so you can run the installer for the platform you need. The goal is to get from a clean or newly installed OS to a fully functional developer environment with one command.

This README explains how to use the scripts, what they install, where configuration files live, and tips for customization and troubleshooting.

Table of contents

- Quick start
- What it installs (overview)
- Installation details (macOS and Ubuntu)
- Post-install checks & steps
- Customization & editing configs
- Troubleshooting
- File and config reference

## Quick start

Clone the repository (replace `<repo_url>` with your repository's URL if remote):

```setup-config/README.md#L1-L3
git clone <repo_url>
cd setup-config
```

Choose the platform and run the installer script:

- macOS

```setup-config/macos/install.sh#L1-L3
bash macos/install.sh
```

- Ubuntu

```setup-config/ubuntu/install.sh#L1-L3
bash ubuntu/install.sh
```

Notes:

- The installers are idempotent — running them multiple times is safe.
- Some steps require `sudo` for installing system packages and changing shells. You will be prompted for your password as needed.
- Make sure you have a working network connection (the scripts fetch packages and remote repositories).

## What it installs (overview)

The installers add and configure the following tools (platform differences noted in the scripts):

- Shell and shell framework:
  - Zsh + Oh My Zsh, custom plugin `zieds`
- Terminal: Ghostty
- Multiplexer: tmux with Oh My Tmux
- Editor: Neovim (LazyVim configuration + custom plugins)
- CLI tools: zoxide, eza, fd, fzf, ripgrep, bat, lazygit, btop, fastfetch
- Development toolchain: Git, Go, LLVM/Clang
- Optional: OpenCode / SST (opencode CLI)
- Additional tools and packages necessary to build & run Ghostty (on Ubuntu)

Important: The installers try to be minimally intrusive but they install software system-wide; read the script before running if you want to know the specifics.

## Installation details

macOS

- Path to macOS installer:

```setup-config/macos/install.sh#L1-L3
bash macos/install.sh
```

- What this macOS script does (high level):
  - Installs Homebrew (if missing)
  - Uses `brew` to install packages and casks
  - Installs Oh My Zsh, zsh plugins and sets up `.zshrc` (managed by the script)
  - Configures tmux using Oh My Tmux and XDG config paths
  - Installs LazyVim and copies the platform-specific Neovim plugins
  - Configures Ghostty using platform-specific paths (Ghostty cask or build)
  - Applies macOS-specific settings (ex: disable press-and-hold for key repeats)

Ubuntu

- Path to Ubuntu installer:

```setup-config/ubuntu/install.sh#L1-L3
bash ubuntu/install.sh
```

- What this Ubuntu script does (high level):
  - Updates and upgrades system packages via `apt`
  - Installs default build tools and dependencies (`build-essential`, `zsh`, `tmux`, etc.)
  - Installs Go and configures its PATH (if not present)
  - Installs Clang/LLVM via `apt`
  - Installs Neovim from official GitHub release
  - Installs modern CLI tools (zoxide, eza, fd, fzf, ripgrep, bat, lazygit, fastfetch)
  - Builds Ghostty from source (Zig might be installed for this step)
  - Installs Oh My Zsh and zsh plugins from the platform-specific config
  - Sets up Oh My Tmux and LazyVim with the platform-specific Neovim plugins
  - Configures French locale if not present

## Configuration layout & per-platform files

Configuration files are grouped per-platform. You will find platform-specific plugin and configuration files here:

- macOS:

```
setup-config/macos/config/
├── ghostty/config
├── nvim/lua/plugins/
│   ├── avante.lua
│   ├── auto-save.lua
│   └── colorscheme.lua
└── zsh/zieds.plugin.zsh
```

- Ubuntu:

```
setup-config/ubuntu/config/
├── ghostty/config
├── nvim/lua/plugins/
│   ├── avante.lua
│   ├── auto-save.lua
│   └── colorscheme.lua
└── zsh/zieds.plugin.zsh
```

Notes:

- Both installers use the `PLATFORM_CONFIG_DIR` in their `install.sh` to copy platform-specific configs into `$XDG_CONFIG_HOME` or `$HOME` as appropriate.
- The Zsh plugin `zieds` is platform-specific. For example:
  - macOS: `macos/config/zsh/zieds.plugin.zsh` (uses `brew` for update)
  - Ubuntu: `ubuntu/config/zsh/zieds.plugin.zsh` (uses `apt` for update)

## Post-install checks & steps

- After installation, logout/login or run:

```setup-config/README.md#L1-L3
source ~/.zshrc
```

- Verify key tools:

```setup-config/README.md#L1-L9
git --version
zsh --version
nvim --version
go version
clang --version
zoxide --version
rg --version
bat --version
lazygit --version
```

- LazyVim plugin management:
  - Open Neovim and run `:Lazy sync` (or `:Lazy` follow prompts)
  - Alternatively, open `nvim` and the plugin manager should trigger Lazy to sync

## Customization

- Set a custom `XDG_CONFIG_HOME` before running the installer if you want the config to go to a different directory:

```setup-config/README.md#L1-L2
export XDG_CONFIG_HOME="$HOME/.config"
bash ubuntu/install.sh
```

- Edit plugins prior to installation:
  - Edit `macos/config/nvim/lua/plugins/*.lua` for macOS
  - Edit `ubuntu/config/nvim/lua/plugins/*.lua` for Ubuntu
  - For Zsh plugin, edit:
    - macOS: `macos/config/zsh/zieds.plugin.zsh`
    - Ubuntu: `ubuntu/config/zsh/zieds.plugin.zsh`

- If you want to skip some steps, read the script and comment or remove lines. Always review the script before running it in an unfamiliar environment.

## Troubleshooting & debugging

- The scripts are intended to be idempotent, but if you run into issues:
  - Inspect the script to find the failing step:

```setup-config/README.md#L1-L3
less ubuntu/install.sh
```

- Re-run the script with verbose debugging:

```setup-config/README.md#L1-L3
bash -x ubuntu/install.sh
```

- Check the command exit code and logs for the problematic step.
- Ensure `sudo` privileges are available when required.
- For Ghostty build issues on Ubuntu, verify the Zig and GTK dependencies are installed (`zig`, `libgtk4`, `libadwaita`).

- If parts of the environment are out of sync, remove old configuration and re-run:

```setup-config/README.md#L1-L4
rm -rf "$XDG_CONFIG_HOME/nvim"
rm -rf "$XDG_CONFIG_HOME/tmux"
bash macos/install.sh
```

- If the default shell is not set to zsh after install:
  - You may need to run:

```setup-config/README.md#L1-L2
chsh -s "$(which zsh)"
```

- Log out and log back in for the change to take effect.

## Known limitations & notes

- Ghostty on Ubuntu builds from source and may require additional dependencies, including `zig`, `gtk4`, and `libadwaita`. The installer attempts to handle that but build systems and system packages can vary.
- The scripts assume `amd64` architecture; if you use an ARM Linux system, adjust the downloads accordingly.
- The scripts will install system-wide software — if you are running on machines where you cannot use `sudo`, you may need to adapt the scripts for local installation (e.g., installing to `~/.local/bin` where appropriate).
- Neovim will be installed to `/opt/nvim` on Linux from a release tarball (config copy is automated to `XDG_CONFIG_HOME`).
- If you want to keep a shared central config, you can create a directory and symlink or copy the files into the platform-specific config directories.

## File reference

- Platform installers:
  - macOS: `macos/install.sh`
  - Ubuntu: `ubuntu/install.sh`

- Platform-specific config:
  - macOS: `macos/config/*`
  - Ubuntu: `ubuntu/config/*`

- Specification: `SPECS.md` — contains the desired environment specification.

## Contributing

If you want to improve, add, or remove packages or change configuration, please:

1. Edit the appropriate `install.sh` or platform `config/*` files
2. Test your changes on a fresh VM or a disposable machine
3. Raise a PR or commit changes into your forked repo

If you want me to add:

- A per-platform README as well (for deeper OS-specific details), or
- A rollback/uninstall script,

or anything more specific to the install, tell me which platform(s) and I’ll update the scripts and the README.

Enjoy the setup!
