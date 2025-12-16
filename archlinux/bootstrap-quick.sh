#!/bin/bash

# Arch Linux Quick Bootstrap Script
# Self-contained script that can be run directly from the Arch ISO.
#
# Usage (from live ISO):
#   curl -sL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/archlinux/bootstrap-quick.sh | bash
#
# Or with a custom repo URL:
#   REPO_URL=https://github.com/ZiedYousfi/myconfig.git bash -c "$(curl -sL ...)"

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error()   { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()    { echo -e "${CYAN}[STEP]${NC} $1"; }

# Configuration - update this with your actual repository URL
REPO_URL="${REPO_URL:-https://github.com/ZiedYousfi/myconfig.git}"
REPO_BRANCH="${REPO_BRANCH:-main}"

# Will be set during execution
INSTALL_DISK=""
WORK_DIR=""
USERNAME=""
ENCRYPTED_PASSWORD=""

# Cleanup on exit
cleanup() {
    if [[ -n "${WORK_DIR:-}" ]] && [[ -d "$WORK_DIR" ]]; then
        rm -rf "$WORK_DIR"
    fi
}
trap cleanup EXIT

# Check if running from live ISO
check_live_environment() {
    if [[ ! -d /run/archiso ]]; then
        log_error "This script must be run from the Arch Linux live ISO!"
        log_info "Boot from the Arch ISO and run this script again."
        exit 1
    fi
    log_success "Running from Arch ISO"
}

# Check internet connectivity
check_internet() {
    log_info "Checking internet connectivity..."
    if ! ping -c 1 -W 5 archlinux.org &>/dev/null; then
        log_error "No internet connection. Please connect to the internet first."
        echo ""
        echo "For WiFi, use: iwctl"
        echo "  device list"
        echo "  station wlan0 scan"
        echo "  station wlan0 get-networks"
        echo "  station wlan0 connect <SSID>"
        echo ""
        echo "For wired connection, it should work automatically."
        echo "Try: dhcpcd"
        exit 1
    fi
    log_success "Internet connection available"
}

# Update system clock
sync_time() {
    log_info "Synchronizing system clock..."
    timedatectl set-ntp true
    sleep 2
    log_success "System clock synchronized"
}

# Install required tools
install_prerequisites() {
    log_info "Installing prerequisites..."
    pacman -Sy --noconfirm --needed git jq reflector &>/dev/null || true
    log_success "Prerequisites installed"
}

# Clone the repository
clone_repo() {
    log_info "Cloning configuration repository..."
    WORK_DIR=$(mktemp -d)
    git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$WORK_DIR/setup-config" 2>/dev/null
    log_success "Repository cloned to $WORK_DIR/setup-config"
}

# Collect user information
collect_user_info() {
    echo ""
    log_step "User Configuration"
    echo "────────────────────────────────────────"

    # Username
    read -rp "Enter username [ispaghul]: " input_username
    USERNAME="${input_username:-ispaghul}"

    # Password
    while true; do
        read -rsp "Enter password for $USERNAME: " password1
        echo ""
        read -rsp "Confirm password: " password2
        echo ""

        if [[ "$password1" == "$password2" ]]; then
            if [[ -z "$password1" ]]; then
                log_warning "Password cannot be empty!"
            else
                # Generate encrypted password using yescrypt
                ENCRYPTED_PASSWORD=$(echo "$password1" | openssl passwd -6 -stdin)
                break
            fi
        else
            log_warning "Passwords do not match. Try again."
        fi
    done

    log_success "User configured: $USERNAME"
}

# Select installation disk
select_disk() {
    echo ""
    log_step "Disk Selection"
    echo "────────────────────────────────────────"
    echo ""
    log_info "Available disks:"
    echo ""
    lsblk -d -o NAME,SIZE,MODEL,TYPE | grep -E "disk$" | head -10
    echo ""

    # Suggest the first suitable disk
    local default_disk
    default_disk=$(lsblk -d -n -o NAME,TYPE | grep "disk$" | grep -E "^(sd|nvme|vd)" | awk '{print $1}' | head -1)

    read -rp "Enter disk to install to [${default_disk}]: " selected_disk
    selected_disk="${selected_disk:-$default_disk}"

    # Handle nvme naming (nvme0n1 vs nvme0n1p1)
    if [[ ! -b "/dev/$selected_disk" ]]; then
        log_error "Disk /dev/$selected_disk does not exist!"
        exit 1
    fi

    echo ""
    log_warning "╔═══════════════════════════════════════════════════════════╗"
    log_warning "║  WARNING: ALL DATA ON /dev/$selected_disk WILL BE DESTROYED!  ║"
    log_warning "╚═══════════════════════════════════════════════════════════╝"
    echo ""
    read -rp "Type 'yes' to confirm: " confirm
    if [[ "$confirm" != "yes" ]]; then
        log_info "Installation cancelled."
        exit 0
    fi

    INSTALL_DISK="/dev/$selected_disk"
    log_success "Selected disk: $INSTALL_DISK"
}

# Select hostname
select_hostname() {
    echo ""
    read -rp "Enter hostname [archlinuxbtw]: " input_hostname
    HOSTNAME="${input_hostname:-archlinuxbtw}"
    log_success "Hostname: $HOSTNAME"
}

# Update configuration files with user selections
update_configs() {
    log_info "Updating configuration files..."

    local config_dir="$WORK_DIR/setup-config/archlinux/archinstall_config"

    # Update user_configuration.json with disk and hostname
    jq --arg disk "$INSTALL_DISK" --arg hostname "$HOSTNAME" \
       '.disk_config.device_modifications[0].device = $disk | .hostname = $hostname' \
       "$config_dir/user_configuration.json" > "$config_dir/user_configuration.json.tmp"
    mv "$config_dir/user_configuration.json.tmp" "$config_dir/user_configuration.json"

    # Update user_credentials.json with username and password
    cat > "$config_dir/user_credentials.json" << EOF
{
    "users": [
        {
            "enc_password": "$ENCRYPTED_PASSWORD",
            "groups": [],
            "sudo": true,
            "username": "$USERNAME"
        }
    ]
}
EOF

    log_success "Configuration files updated"
}

# Create first-boot setup service
create_first_boot_service() {
    log_info "Creating first-boot setup service..."

    # Create the setup script
    cat > "$WORK_DIR/first-boot-setup.sh" << 'SETUP_EOF'
#!/bin/bash
# First boot setup script - runs once after installation

set -euo pipefail

SETUP_LOG="/var/log/first-boot-setup.log"
REPO_URL="__REPO_URL__"
REPO_BRANCH="__REPO_BRANCH__"
USERNAME="__USERNAME__"

exec > >(tee -a "$SETUP_LOG") 2>&1

echo "[$(date)] Starting first-boot setup..."
echo "[$(date)] User: $USERNAME"
echo "[$(date)] Repo: $REPO_URL"

# Wait for network (max 60 seconds)
echo "[$(date)] Waiting for network..."
for i in {1..30}; do
    if ping -c 1 -W 2 archlinux.org &>/dev/null; then
        echo "[$(date)] Network available"
        break
    fi
    echo "[$(date)] Waiting for network... ($i/30)"
    sleep 2
done

# Ensure we have network
if ! ping -c 1 archlinux.org &>/dev/null; then
    echo "[$(date)] ERROR: No network connection after 60 seconds"
    exit 1
fi

# Clone the setup repository if not present
USER_HOME="/home/$USERNAME"
SETUP_DIR="$USER_HOME/setup-config"

if [[ ! -d "$SETUP_DIR" ]]; then
    echo "[$(date)] Cloning setup repository..."
    sudo -u "$USERNAME" git clone --depth 1 --branch "$REPO_BRANCH" "$REPO_URL" "$SETUP_DIR"
else
    echo "[$(date)] Setup repository already present at $SETUP_DIR"
fi

# Run the install script as the user
echo "[$(date)] Running install.sh..."
cd "$SETUP_DIR/archlinux"
sudo -u "$USERNAME" XDG_CONFIG_HOME="$USER_HOME/.config" XDG_CACHE_HOME="$USER_HOME/.cache" HOME="$USER_HOME" bash install.sh

# Disable this service after successful run
systemctl disable first-boot-setup.service

echo "[$(date)] First-boot setup completed successfully!"
echo "[$(date)] Please log out and back in for all changes to take effect."
SETUP_EOF

    # Replace placeholders
    sed -i "s|__REPO_URL__|$REPO_URL|g" "$WORK_DIR/first-boot-setup.sh"
    sed -i "s|__REPO_BRANCH__|$REPO_BRANCH|g" "$WORK_DIR/first-boot-setup.sh"
    sed -i "s|__USERNAME__|$USERNAME|g" "$WORK_DIR/first-boot-setup.sh"

    # Create systemd service
    cat > "$WORK_DIR/first-boot-setup.service" << 'SERVICE_EOF'
[Unit]
Description=First Boot Setup - Install dotfiles and configure development environment
After=network-online.target gdm.service
Wants=network-online.target
ConditionPathExists=!/var/lib/first-boot-setup-done

[Service]
Type=oneshot
ExecStart=/usr/local/bin/first-boot-setup.sh
ExecStartPost=/usr/bin/touch /var/lib/first-boot-setup-done
RemainAfterExit=yes
StandardOutput=journal+console
StandardError=journal+console
TimeoutStartSec=600

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    log_success "First-boot service created"
}

# Update mirrors for faster downloads
update_mirrors() {
    log_info "Updating mirror list for faster downloads..."
    reflector --country France,Germany,Switzerland,Netherlands --age 12 --protocol https --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true
    log_success "Mirrors updated"
}

# Run archinstall
run_archinstall() {
    log_step "Running archinstall..."
    echo ""

    local config_dir="$WORK_DIR/setup-config/archlinux/archinstall_config"

    archinstall --config "$config_dir/user_configuration.json" \
                --creds "$config_dir/user_credentials.json" \
                --silent

    log_success "Base system installed"
}

# Install post-install files to the new system
install_post_files() {
    log_info "Installing post-installation files..."

    local mnt="/mnt"

    # Copy first-boot script
    cp "$WORK_DIR/first-boot-setup.sh" "$mnt/usr/local/bin/first-boot-setup.sh"
    chmod +x "$mnt/usr/local/bin/first-boot-setup.sh"

    # Copy systemd service
    cp "$WORK_DIR/first-boot-setup.service" "$mnt/etc/systemd/system/first-boot-setup.service"

    # Enable the service
    arch-chroot "$mnt" systemctl enable first-boot-setup.service

    # Pre-copy the repository for faster first boot
    log_info "Copying configuration to new system..."
    mkdir -p "$mnt/home/$USERNAME"
    cp -r "$WORK_DIR/setup-config" "$mnt/home/$USERNAME/setup-config"
    arch-chroot "$mnt" chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/setup-config"

    log_success "Post-installation files installed"
}

# Display final summary
show_summary() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                    Installation Complete!                     ║"
    echo "╠══════════════════════════════════════════════════════════════╣"
    echo "║                                                              ║"
    echo "║  Your new Arch Linux system has been installed.             ║"
    echo "║                                                              ║"
    echo "║  On first boot, the system will automatically:              ║"
    echo "║  • Install development tools (Go, Clang, Neovim, etc.)      ║"
    echo "║  • Install AUR packages (Ghostty, Zed, etc.)                ║"
    echo "║  • Configure dotfiles (zsh, tmux, niri, waybar)             ║"
    echo "║  • Set up Oh My Zsh and Oh My Tmux                          ║"
    echo "║  • Configure LazyVim for Neovim                             ║"
    echo "║                                                              ║"
    echo "║  This process takes 5-15 minutes depending on your          ║"
    echo "║  internet connection. Check progress with:                   ║"
    echo "║                                                              ║"
    echo "║    journalctl -f -u first-boot-setup.service                ║"
    echo "║                                                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "  Username: $USERNAME"
    echo "  Hostname: $HOSTNAME"
    echo "  Disk:     $INSTALL_DISK"
    echo ""
}

# Main execution
main() {
    clear
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║        Arch Linux Automated Installation Script              ║"
    echo "║                                                              ║"
    echo "║  This will install Arch Linux with a full desktop setup:    ║"
    echo "║  • Niri (scrollable tiling Wayland compositor)              ║"
    echo "║  • Waybar, Ghostty, Zed, Neovim (LazyVim)                   ║"
    echo "║  • Development tools (Go, Clang, Git, ripgrep, etc.)        ║"
    echo "║  • Fully configured dotfiles and shell environment          ║"
    echo "║                                                              ║"
    echo "║  Repository: $REPO_URL"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""

    check_live_environment
    check_internet
    sync_time
    install_prerequisites
    clone_repo
    collect_user_info
    select_disk
    select_hostname
    update_configs
    create_first_boot_service
    update_mirrors
    run_archinstall
    install_post_files
    show_summary

    read -rp "Press Enter to reboot into your new system..."

    umount -R /mnt 2>/dev/null || true
    reboot
}

main "$@"
