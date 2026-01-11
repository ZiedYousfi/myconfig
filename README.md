# Setup Configuration

> A modular configuration bank for building reproducible development environments across platforms.

This repository provides automated setup scripts and dotfiles for macOS and Ubuntu Server, enabling consistent development environments with a single command.

## Quick Start

Bootstrap your entire development environment with one command:

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash -s -- macos
```

### Ubuntu Server

```bash
curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash -s -- ubuntu
```

### Interactive Mode (Auto-detect or Choose)

```bash
curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash
```

The bootstrap script will:

1. Download the latest release
2. Extract all configuration files
3. Run the appropriate platform installer
4. Set up dotfiles using GNU Stow
5. Install all necessary tools and packages

## What Gets Installed

### Common (Both Platforms)

- **Shell**: Zsh with Oh My Zsh
- **Terminal**: Ghostty
- **Editor**: Neovim with full configuration
- **Multiplexer**: Tmux
- **File Manager**: Yazi
- **Code Editor**: Zed
- **CLI Tools**: fzf, ripgrep, bat, eza, fd, and more

### macOS Specific

- Homebrew packages
- Window manager: Yabai
- Status bar: SketchyBar
- macOS system preferences

### Ubuntu Server Specific

- Homebrew for Linux
- Server-optimized tooling
- Systemd service configurations

## Manual Installation

If you prefer to inspect before running:

```bash
# Clone the repository
git clone https://github.com/ZiedYousfi/myconfig.git
cd myconfig

# Run the appropriate install script
./macos/install.sh          # For macOS
./ubuntu-server/install.sh  # For Ubuntu Server
```

## Dotfiles Structure

```
dotfiles/
├── ghostty/    # Terminal emulator config
├── nvim/       # Neovim configuration
├── tmux/       # Tmux configuration
├── yazi/       # File manager config
├── zed/        # Zed editor config
└── zsh/        # Zsh and Oh My Zsh config
```

## Creating a Release

To create a new release and trigger the packaging workflow:

```bash
# Tag a new version
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

Or manually trigger via GitHub Actions:

1. Go to Actions tab
2. Select "Create Release" workflow
3. Click "Run workflow"
4. Enter a tag name (e.g., v1.0.0)

## Features

- **Idempotent**: Safe to run multiple times without side effects
- **Modular**: Shared dotfiles with platform-specific additions
- **Automated**: Installs all dependencies and tools
- **Documented**: Full specifications in [SPECS.md](SPECS.md)
- **Backed Up**: Automatically backs up existing configurations

## Uninstalling

Each platform has an uninstall script:

```bash
./macos/uninstall.sh          # macOS
./ubuntu-server/uninstall.sh  # Ubuntu Server
```

## Documentation

See [SPECS.md](SPECS.md) for complete configuration specifications and details about all installed components.

## Requirements

Minimal requirements - the bootstrap script handles everything else:

- `curl` - for downloading
- `unzip` - for extracting archives
- Internet connection

## License

MIT License - see LICENSE file for details

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
