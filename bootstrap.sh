#!/bin/bash

# Bootstrap Script for Setup Configuration
# Downloads and installs the complete development environment
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash -s -- macos
#   curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash -s -- ubuntu

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Repository configuration
REPO_OWNER="ZiedYousfi"
REPO_NAME="myconfig"
GITHUB_REPO="${REPO_OWNER}/${REPO_NAME}"

# Installation directory
INSTALL_DIR="${HOME}/.setup-config"
TEMP_DIR="/tmp/setup-config-$$"

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_banner() {
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║        Setup Configuration Bootstrap Script               ║
║                                                           ║
║        Automated Development Environment Setup            ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

detect_platform() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            echo "ubuntu"
        else
            echo "linux"
        fi
    else
        echo "unknown"
    fi
}

prompt_platform() {
    echo -e "${BOLD}Select your platform:${NC}"
    echo ""
    echo "  1) macOS"
    echo "  2) Ubuntu Server"
    echo "  3) Exit"
    echo ""

    while true; do
        read -p "Enter your choice (1-3): " choice
        case $choice in
            1)
                echo "macos"
                return 0
                ;;
            2)
                echo "ubuntu"
                return 0
                ;;
            3)
                log_info "Installation cancelled by user"
                exit 0
                ;;
            *)
                log_error "Invalid choice. Please enter 1, 2, or 3."
                ;;
        esac
    done
}

get_latest_release_tag() {
    log_info "Fetching latest release information..."

    local release_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
    local tag=$(curl -fsSL "$release_url" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

    if [ -z "$tag" ]; then
        log_warning "No releases found, will clone from main branch instead"
        echo "main"
    else
        echo "$tag"
    fi
}

download_and_extract() {
    local tag="$1"

    log_info "Creating temporary directory..."
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"

    if [ "$tag" = "main" ]; then
        log_info "Downloading repository from main branch..."
        local archive_url="https://github.com/${GITHUB_REPO}/archive/refs/heads/main.zip"
    else
        log_info "Downloading release $tag..."
        local archive_url="https://github.com/${GITHUB_REPO}/releases/download/${tag}/setup-config.zip"

        # If release asset doesn't exist, fall back to archive
        if ! curl -fsSL --head "$archive_url" > /dev/null 2>&1; then
            log_warning "Release asset not found, downloading from archive..."
            archive_url="https://github.com/${GITHUB_REPO}/archive/refs/tags/${tag}.zip"
        fi
    fi

    if ! curl -fsSL -o setup-config.zip "$archive_url"; then
        log_error "Failed to download from $archive_url"
        exit 1
    fi

    log_success "Downloaded successfully"

    log_info "Extracting archive..."
    if ! unzip -q setup-config.zip; then
        log_error "Failed to extract archive"
        exit 1
    fi

    # Find the extracted directory (handles both release and archive formats)
    local extracted_dir=$(find . -maxdepth 1 -type d -name "*${REPO_NAME}*" | head -n 1)

    if [ -z "$extracted_dir" ]; then
        # If no directory found, it might have extracted to current directory
        extracted_dir="."
    fi

    log_success "Extracted successfully"
    echo "$extracted_dir"
}

run_installation() {
    local platform="$1"
    local source_dir="$2"

    log_info "Preparing installation directory..."

    # Backup existing installation if it exists
    if [ -d "$INSTALL_DIR" ]; then
        local backup_dir="${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        log_warning "Backing up existing installation to $backup_dir"
        mv "$INSTALL_DIR" "$backup_dir"
    fi

    # Move extracted files to installation directory
    mkdir -p "$INSTALL_DIR"

    if [ "$source_dir" = "." ]; then
        # Files extracted to current directory
        mv * "$INSTALL_DIR/" 2>/dev/null || true
    else
        # Files in subdirectory
        mv "$source_dir"/* "$INSTALL_DIR/"
    fi

    log_success "Files copied to $INSTALL_DIR"

    # Make install scripts executable
    chmod +x "$INSTALL_DIR"/*/install.sh 2>/dev/null || true

    # Run the appropriate installation script
    log_info "Starting ${platform} installation..."
    echo ""

    case $platform in
        macos)
            if [ ! -f "$INSTALL_DIR/macos/install.sh" ]; then
                log_error "macOS install script not found at $INSTALL_DIR/macos/install.sh"
                exit 1
            fi
            cd "$INSTALL_DIR/macos"
            ./install.sh
            ;;
        ubuntu)
            if [ ! -f "$INSTALL_DIR/ubuntu-server/install.sh" ]; then
                log_error "Ubuntu install script not found at $INSTALL_DIR/ubuntu-server/install.sh"
                exit 1
            fi
            cd "$INSTALL_DIR/ubuntu-server"
            ./install.sh
            ;;
        *)
            log_error "Unsupported platform: $platform"
            exit 1
            ;;
    esac
}

cleanup() {
    log_info "Cleaning up temporary files..."
    rm -rf "$TEMP_DIR"
    log_success "Cleanup complete"
}

ensure_dependencies() {
    local platform="$1"
    local missing_deps=()

    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi

    if ! command -v unzip &> /dev/null; then
        missing_deps+=("unzip")
    fi

    if [ ${#missing_deps[@]} -eq 0 ]; then
        return 0
    fi

    log_info "Missing required dependencies: ${missing_deps[*]}"

    case $platform in
        ubuntu)
            log_info "Installing missing dependencies via apt-get..."
            sudo apt-get update
            sudo apt-get install -y "${missing_deps[@]}"
            ;;
        macos)
            if command -v brew &> /dev/null; then
                log_info "Installing missing dependencies via Homebrew..."
                brew install "${missing_deps[@]}"
            else
                log_error "Missing dependencies ${missing_deps[*]} and Homebrew is not installed."
                log_info "Please install Homebrew or manually install: ${missing_deps[*]}"
                exit 1
            fi
            ;;
        *)
            log_error "Please manually install the following dependencies: ${missing_deps[*]}"
            exit 1
            ;;
    esac
}

main() {
    print_banner

    # Check if platform was provided as argument
    local platform="${1:-}"

    if [ -z "$platform" ]; then
        # Auto-detect platform
        local detected_platform=$(detect_platform)

        if [ "$detected_platform" = "unknown" ]; then
            log_warning "Could not detect platform automatically"
            platform=$(prompt_platform)
        else
            log_info "Detected platform: $detected_platform"
            echo ""
            read -p "Is this correct? (Y/n): " confirm

            if [[ "$confirm" =~ ^[Nn] ]]; then
                platform=$(prompt_platform)
            else
                platform="$detected_platform"
            fi
        fi
    else
        # Normalize platform argument
        case "${platform,,}" in
            macos|mac|darwin)
                platform="macos"
                ;;
            ubuntu|linux|server)
                platform="ubuntu"
                ;;
            *)
                log_error "Unknown platform: $platform"
                log_info "Supported platforms: macos, ubuntu"
                exit 1
                ;;
        esac
    fi

    log_info "Selected platform: ${BOLD}${platform}${NC}"
    echo ""

    # Ensure required dependencies are installed
    ensure_dependencies "$platform"

    # Get latest release
    local release_tag=$(get_latest_release_tag)

    # Download and extract
    local extracted_dir=$(download_and_extract "$release_tag")

    # Run installation
    run_installation "$platform" "$extracted_dir"

    # Cleanup
    cleanup

    echo ""
    log_success "${BOLD}Installation complete!${NC}"
    echo ""
    log_info "Configuration installed to: $INSTALL_DIR"
    log_info "Dotfiles managed from: ~/dotfiles"
    echo ""
    log_info "Please restart your terminal or run: ${CYAN}source ~/.zshrc${NC}"
    echo ""
}

# Set up error handling
trap 'log_error "An error occurred. Cleaning up..."; cleanup; exit 1' ERR

# Run main function
main "$@"
