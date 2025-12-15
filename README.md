# Setup Config — Development Environment

This repository provides a single-script, idempotent setup for a development environment on macOS and Ubuntu. Each platform has a dedicated installer and its own configuration subtree so you can run the installer for the platform you need. The goal is to get from a clean or newly installed OS to a fully functional developer environment with one command.

**Key Feature:** Dotfiles are managed using [GNU Stow](https://www.gnu.org/software/stow/), making it easy to modify configurations and keep them in sync.

Table of contents

- Quick start
- What it installs (overview)
- Installation details (macOS and Ubuntu)
- Dotfiles management with GNU Stow
- Post-install checks & steps
- Customization & editing configs
- Troubleshooting
- File and config reference

## Quick start

Clone the repository:

```
git clone https://github.com/ZiedYousfi/myconfig.git
cd setup-config
```

Choose the platform and run the installer script:

- macOS

```
bash macos/install.sh
```

- Ubuntu

```
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
- GNU Stow for dotfiles management

Important: The installers try to be minimally intrusive but they install software system-wide; read the script before running if you want to know the specifics.

## Installation details

### macOS

- Path to macOS installer:

```
bash macos/install.sh
```

- What this macOS script does (high level):
  - Installs Homebrew (if missing)
  - Uses `brew` to install packages and casks (including `stow`)
  - Installs Oh My Zsh, zsh plugins and sets up `.zshrc` (managed by the script)
  - **Uses GNU Stow** to symlink custom Zsh plugin, Neovim plugins, and Ghostty config
  - Configures tmux using Oh My Tmux and XDG config paths
  - Installs LazyVim and stows the platform-specific Neovim plugins
  - Configures Ghostty using stow for the config symlink
  - Applies macOS-specific settings (ex: disable press-and-hold for key repeats)

### Ubuntu

- Path to Ubuntu installer:

```
bash ubuntu/install.sh
```

- What this Ubuntu script does (high level):
  - Updates and upgrades system packages via `apt`
  - Installs default build tools and dependencies (`build-essential`, `zsh`, `stow`, etc.)
  - Installs Homebrew for Linux for additional package management
  - Installs modern CLI tools (zoxide, eza, fd, fzf, ripgrep, bat, lazygit, fastfetch)
  - Installs Ghostty via community script
  - Installs Oh My Zsh and **uses stow** for the custom zsh plugin
  - Sets up Oh My Tmux and LazyVim, **using stow** for custom Neovim plugins
  - Configures French locale if not present

## Dotfiles management with GNU Stow

This repository uses GNU Stow for managing dotfiles, which creates symlinks from your home directory to the actual config files in this repository. This approach offers several benefits:

- **Easy modification:** Edit files directly in the `dotfiles/` directory
- **Version control friendly:** All configs stay in the git repo
- **Clean separation:** Each package (ghostty, nvim, zsh) is a separate stow package
- **Idempotent:** Running stow multiple times is safe

### Stow package structure

Configuration files are organized per-platform in stow-compatible directories:

- macOS:

```
setup-config/macos/dotfiles/
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
├── nvim/
│   └── .config/
│       └── nvim/
│           └── lua/
│               └── plugins/
│                   ├── auto-save.lua
│                   └── colorscheme.lua
├── tmux/
│   └── .config/
│       └── tmux/
│           └── tmux.conf.local
└── zsh/
    └── .oh-my-zsh/
        └── custom/
            └── plugins/
                └── zieds/
                    └── zieds.plugin.zsh
```

- Ubuntu:

```
setup-config/ubuntu/dotfiles/
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config
├── nvim/
│   └── .config/
│       └── nvim/
│           └── lua/
│               └── plugins/
│                   ├── auto-save.lua
│                   └── colorscheme.lua
├── tmux/
│   └── .config/
│       └── tmux/
│           └── tmux.conf.local
└── zsh/
    └── .oh-my-zsh/
        └── custom/
            └── plugins/
                └── zieds/
                    └── zieds.plugin.zsh
```

### How stow is used

The install scripts call stow with these flags:

- `--restow`: Safely re-create symlinks (idempotent)
- `--no-folding`: Create actual directories instead of symlinking entire directories
- `--adopt`: If conflicts exist, adopt the existing file into the stow package

### Manual stow commands

After initial installation, you can manually manage dotfiles:

```bash
# Re-stow a package after editing (from the dotfiles directory)
cd macos/dotfiles
stow --target="$HOME" --restow ghostty

# Unstow a package (remove symlinks)
stow --target="$HOME" --delete nvim

# Stow all packages
for pkg in ghostty nvim zsh; do
  stow --target="$HOME" --restow "$pkg"
done
```

### How tmux works with stow

Tmux configuration uses Oh My Tmux as a base framework:

1. Oh My Tmux is cloned to `~/.oh-my-tmux/`
2. The main `tmux.conf` is symlinked from Oh My Tmux to `~/.config/tmux/tmux.conf`
3. Our custom `tmux.conf.local` is stowed to `~/.config/tmux/tmux.conf.local`

This is similar to how LazyVim works - the framework is installed first, then our custom config is stowed on top.

## Post-install checks & steps

- After installation, logout/login or run:

```
source ~/.zshrc
```

- Verify key tools:

```
git --version
zsh --version
nvim --version
go version
clang --version
zoxide --version
rg --version
bat --version
lazygit --version
stow --version
```

- LazyVim plugin management:
  - Open Neovim and run `:Lazy sync` (or `:Lazy` follow prompts)
  - Alternatively, open `nvim` and the plugin manager should trigger Lazy to sync

## Customization

### Editing configs with stow

The main advantage of stow is that you can edit the config files directly in the repository:

1. Edit files in `macos/dotfiles/` or `ubuntu/dotfiles/`
2. The changes are immediately reflected in your home directory (they're symlinked!)
3. Commit your changes to git

### Adding new config files

To add a new config file to an existing stow package:

1. Create the file with the correct path structure under `dotfiles/<package>/`
2. Run stow to create the symlink:

```bash
cd macos/dotfiles
stow --target="$HOME" --restow <package>
```

### Creating a new stow package

To add a new application's config:

1. Create a new directory under `dotfiles/` named after the package
2. Mirror the home directory structure inside it
3. Add the stow command to `install.sh` or run manually

Example for adding a hypothetical `starship` config:

```
dotfiles/
└── starship/
    └── .config/
        └── starship.toml
```

### Environment variables

Set a custom `XDG_CONFIG_HOME` before running the installer if you want the config to go to a different directory:

```
export XDG_CONFIG_HOME="$HOME/.config"
bash ubuntu/install.sh
```

## Troubleshooting & debugging

### General issues

- The scripts are intended to be idempotent, but if you run into issues:
  - Inspect the script to find the failing step:

```
less ubuntu/install.sh
```

- Re-run the script with verbose debugging:

```
bash -x ubuntu/install.sh
```

### Stow conflicts

If stow reports conflicts, it usually means a file already exists that isn't a symlink:

```bash
# Option 1: Let stow adopt the existing file
stow --target="$HOME" --adopt <package>

# Option 2: Manually remove the conflicting file first
rm ~/.config/ghostty/config
stow --target="$HOME" --restow ghostty
```

### Resetting configurations

If parts of the environment are out of sync, remove old configuration and re-run:

```
rm -rf "$XDG_CONFIG_HOME/nvim"
rm -rf "$XDG_CONFIG_HOME/tmux"
rm -rf "$XDG_CONFIG_HOME/ghostty"
bash macos/install.sh
```

### Shell not set to zsh

If the default shell is not set to zsh after install:

```
chsh -s "$(which zsh)"
```

Log out and log back in for the change to take effect.

## Known limitations & notes

- Tmux configuration is append-based rather than pure stow, because it extends Oh My Tmux's template.
- The scripts assume `amd64` architecture; if you use an ARM Linux system, adjust the downloads accordingly.
- The scripts will install system-wide software — if you are running on machines where you cannot use `sudo`, you may need to adapt the scripts for local installation.
- Neovim will be installed via Homebrew (both platforms).
- The Zsh plugin `zieds` is platform-specific (uses `brew` vs `apt` for updates).

## File reference

- Platform installers:
  - macOS: `macos/install.sh`
  - Ubuntu: `ubuntu/install.sh`

- Platform-specific dotfiles (stow packages):
  - macOS: `macos/dotfiles/*`
  - Ubuntu: `ubuntu/dotfiles/*`

- Specification: `SPECS.md` — contains the desired environment specification.

- Uninstall scripts:
  - macOS: `macos/uninstall.sh`
  - Ubuntu: `ubuntu/uninstall.sh`

## Uninstalling

To remove everything installed by the setup scripts, run the uninstall script for your platform:

**macOS:**

```
bash macos/uninstall.sh
```

**Ubuntu:**

```
bash ubuntu/uninstall.sh
```

The uninstall scripts will:

1. Unstow all dotfiles (remove symlinks)
2. Remove Oh My Zsh and plugins
3. Remove Oh My Tmux
4. Remove LazyVim/Neovim configuration and data
5. Remove Ghostty configuration
6. Remove Homebrew packages installed by the setup
7. Optionally remove Homebrew itself
8. Restore default system settings (macOS)

**Note:** The scripts will ask for confirmation before proceeding and offer choices for optional removals (like Homebrew itself).

## Contributing

If you want to improve, add, or remove packages or change configuration, please:

1. Edit the appropriate `install.sh` or `dotfiles/*` files
2. Test your changes on a fresh VM or a disposable machine
3. Raise a PR or commit changes into your forked repo

Enjoy the setup!
