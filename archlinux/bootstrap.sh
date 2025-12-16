#!/bin/bash

# Arch Linux Bootstrap Script
# Run this from the Arch ISO to install a fully configured system.
#
# Usage (from live ISO):
#   curl -sL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/archlinux/bootstrap.sh | bash
#   OR
#   git clone https://github.com/ZiedYousfi/myconfig.git && cd myconfig/archlinux && ./bootstrap.sh

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}
log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}
log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}
log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

REPO_URL="${REPO_URL:-https://github.com/ZiedYousfi/myconfig.git}"

# If executed from a file, BASH_SOURCE[0] exists; if piped, it doesn't.
if [[ -n "${BASH_SOURCE[0]-}" && -f "${BASH_SOURCE[0]-}" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  SCRIPT_DIR=""
fi

CONFIG_DIR="${SCRIPT_DIR:+$SCRIPT_DIR/archinstall_config}"

# Check if running from live ISO
check_live_environment() {
  if [[ ! -d /run/archiso ]]; then
    log_error "This script must be run from the Arch Linux live ISO!"
    exit 1
  fi
  log_success "Running from Arch ISO"
}

# Check internet connectivity
check_internet() {
  log_info "Checking internet connectivity..."
  if ! ping -c 1 archlinux.org &>/dev/null; then
    log_error "No internet connection. Please connect to the internet first."
    echo "For WiFi, use: iwctl"
    echo "  station wlan0 scan"
    echo "  station wlan0 get-networks"
    echo "  station wlan0 connect <SSID>"
    exit 1
  fi
  log_success "Internet connection available"
}

# Ensure required tools exist in the live environment
ensure_tools() {
  log_info "Ensuring required tools are installed (git)..."
  if ! command -v git &>/dev/null; then
    pacman -Sy --noconfirm --needed git ca-certificates
  fi
  log_success "Tools ready"
}

# Update system clock
sync_time() {
  log_info "Synchronizing system clock..."
  timedatectl set-ntp true
  sleep 2
  log_success "System clock synchronized"
}

# Clone or update repository if not already present
ensure_repo() {
  if [[ -n "${CONFIG_DIR-}" && -f "$CONFIG_DIR/user_configuration.json" ]]; then
    log_success "Configuration files found"
    return 0
  fi

  log_info "Configuration not found locally, cloning repository..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  git clone --depth 1 "$REPO_URL" "$tmp_dir/setup-config"
  SCRIPT_DIR="$tmp_dir/setup-config/archlinux"
  CONFIG_DIR="$SCRIPT_DIR/archinstall_config"
  log_success "Repository cloned"
}

# Select installation disk interactively
select_disk() {
  log_info "Available disks:"
  lsblk -d -o NAME,SIZE,MODEL | grep -v "loop\|sr"
  echo ""

  # Default to first disk found (usually sda or nvme0n1)
  local default_disk
  default_disk=$(lsblk -d -n -o NAME | grep -E "^(sd|nvme|vd)" | head -1)

  read -r -p "Enter disk to install to [${default_disk}]: " selected_disk </dev/tty
  selected_disk="${selected_disk:-$default_disk}"

  # Validate disk exists
  if [[ ! -b "/dev/$selected_disk" ]]; then
    log_error "Disk /dev/$selected_disk does not exist!"
    exit 1
  fi

  echo ""
  log_warning "ALL DATA ON /dev/$selected_disk WILL BE DESTROYED!"
  read -r -p "Are you sure? (yes/no): " confirm </dev/tty
  if [[ "$confirm" != "yes" ]]; then
    log_info "Installation cancelled."
    exit 0
  fi

  INSTALL_DISK="/dev/$selected_disk"
  log_success "Selected disk: $INSTALL_DISK"
}

# Update configuration with selected disk
update_config_disk() {
  log_info "Updating configuration for disk: $INSTALL_DISK"

  local tmp_config
  tmp_config=$(mktemp)

  # Use jq if available, otherwise use sed
  if command -v jq &>/dev/null; then
    jq --arg disk "$INSTALL_DISK" \
      '.disk_config.device_modifications[0].device = $disk' \
      "$CONFIG_DIR/user_configuration.json" >"$tmp_config"
  else
    # Fallback: use sed to replace the device path
    sed "s|/dev/sda|$INSTALL_DISK|g" "$CONFIG_DIR/user_configuration.json" \
      >"$tmp_config"
  fi

  mv "$tmp_config" "$CONFIG_DIR/user_configuration.json"
  log_success "Configuration updated"
}

# Create post-install script that will run on first boot
create_post_install_service() {
  log_info "Creating first-boot setup service..."

  # Create the setup script that will run on first boot
  cat >/tmp/first-boot-setup.sh <<'SETUP_SCRIPT'
#!/bin/bash
# First boot setup script - runs once after installation

set -euo pipefail

SETUP_LOG="/var/log/first-boot-setup.log"
REPO_URL="__REPO_URL__"
USERNAME="__USERNAME__"

exec > >(tee -a "$SETUP_LOG") 2>&1

echo "[$(date)] Starting first-boot setup..."

# Wait for network
for i in {1..30}; do
  if ping -c 1 archlinux.org &>/dev/null; then
    break
  fi
  sleep 2
done

# Clone the setup repository
if [[ ! -d "/home/$USERNAME/setup-config" ]]; then
  sudo -u "$USERNAME" git clone --depth 1 "$REPO_URL" \
    "/home/$USERNAME/setup-config"
fi

# Run the install script as the user
cd "/home/$USERNAME/setup-config/archlinux"
sudo -u "$USERNAME" bash install.sh

# Disable this service after successful run
systemctl disable first-boot-setup.service

echo "[$(date)] First-boot setup completed!"
SETUP_SCRIPT

  # Create the systemd service file
  cat >/tmp/first-boot-setup.service <<'SERVICE'
[Unit]
Description=First Boot Setup - Install dotfiles and configure system
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/var/lib/first-boot-setup-done

[Service]
Type=oneshot
ExecStart=/usr/local/bin/first-boot-setup.sh
ExecStartPost=/usr/bin/touch /var/lib/first-boot-setup-done
RemainAfterExit=yes
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
SERVICE

  log_success "Post-install service created"
}

# Run archinstall with configuration
run_archinstall() {
  log_info "Starting archinstall..."

  # Update pacman mirrors for faster downloads
  log_info "Updating mirror list..."
  reflector --country France,Germany,Switzerland --age 12 --protocol https \
    --sort rate --save /etc/pacman.d/mirrorlist 2>/dev/null || true

  # Run archinstall with our configuration files
  archinstall --config "$CONFIG_DIR/user_configuration.json" \
    --creds "$CONFIG_DIR/user_credentials.json" \
    --silent

  log_success "Base system installed"
}

# Copy post-install files to the new system
setup_post_install() {
  log_info "Setting up post-installation scripts..."

  local mnt="/mnt"

  # Get username from credentials
  local username
  username=$(
    grep -o '"username": "[^"]*"' "$CONFIG_DIR/user_credentials.json" |
      cut -d'"' -f4
  )

  # Update the first-boot script with actual values
  sed -i "s|__REPO_URL__|$REPO_URL|g" /tmp/first-boot-setup.sh
  sed -i "s|__USERNAME__|$username|g" /tmp/first-boot-setup.sh

  # Copy files to installed system
  cp /tmp/first-boot-setup.sh "$mnt/usr/local/bin/first-boot-setup.sh"
  chmod +x "$mnt/usr/local/bin/first-boot-setup.sh"

  cp /tmp/first-boot-setup.service \
    "$mnt/etc/systemd/system/first-boot-setup.service"

  # Enable the service
  arch-chroot "$mnt" systemctl enable first-boot-setup.service

  # Also copy the repo if running locally (for faster first boot)
  if [[ -n "${SCRIPT_DIR-}" && -d "$SCRIPT_DIR/dotfiles" ]]; then
    log_info "Copying configuration files to new system..."
    mkdir -p "$mnt/home/$username"
    cp -r "$(dirname "$SCRIPT_DIR")" "$mnt/home/$username/setup-config"
    arch-chroot "$mnt" chown -R "$username:$username" \
      "/home/$username/setup-config"
  fi

  log_success "Post-installation configured"
}

# Main execution
main() {
  echo ""
  echo "╔══════════════════════════════════════════════════════════════╗"
  echo "║          Arch Linux Automated Installation Script            ║"
  echo "║                                                              ║"
  echo "║  This will install Arch Linux with a full desktop setup:    ║"
  echo "║  - Niri (scrollable tiling Wayland compositor)              ║"
  echo "║  - Waybar, Ghostty, Zed, Neovim                             ║"
  echo "║  - Development tools (Go, Clang, Git, etc.)                 ║"
  echo "║  - Fully configured dotfiles                                 ║"
  echo "╚══════════════════════════════════════════════════════════════╝"
  echo ""

  check_live_environment
  check_internet
  sync_time
  ensure_tools
  ensure_repo
  select_disk
  update_config_disk
  create_post_install_service
  run_archinstall
  setup_post_install

  echo ""
  log_success "═══════════════════════════════════════════════════════════"
  log_success "Installation complete!"
  log_success "═══════════════════════════════════════════════════════════"
  echo ""
  log_info "The system will complete setup on first boot."
  log_info "This includes installing AUR packages and configuring dotfiles."
  echo ""
  read -rp "Press Enter to reboot into your new system..."

  umount -R /mnt 2>/dev/null || true
  reboot
}

main "$@"