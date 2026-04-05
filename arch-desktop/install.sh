#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────

error() {
    echo "Error: $*" >&2
    exit 1
}

warn() {
    echo "Warning: $*" >&2
}

info() {
    echo "==> $*"
}

require_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]] || error "This script must be run as root."
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || error "Missing required command: $1"
}

check_requirements() {
    require_root
    for cmd in lsblk sgdisk parted mkfs.ext4 mount umount pacstrap genfstab arch-chroot chpasswd useradd sed systemctl; do
        require_command "$cmd"
    done
}

cleanup_mounts() {
    if mountpoint -q /mnt/home 2>/dev/null; then
        umount -R /mnt/home || true
    fi
    if mountpoint -q /mnt/boot/efi 2>/dev/null; then
        umount -R /mnt/boot/efi || true
    fi
    if mountpoint -q /mnt/boot 2>/dev/null; then
        umount -R /mnt/boot || true
    fi
    if mountpoint -q /mnt 2>/dev/null; then
        umount -R /mnt || true
    fi
}

disk_exists() {
    [[ -b "$1" ]]
}

get_disk_size_bytes() {
    blockdev --getsize64 "$1"
}

to_bytes() {
    numfmt --from=iec "$1"
}

print_disks() {
    echo ""
    echo "Available disks:"
    lsblk -d -o NAME,SIZE,TYPE | grep disk || true
    echo ""
}

confirm_or_abort() {
    local prompt="$1"
    read -rp "$prompt" CONFIRM
    [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]] || {
        echo "Aborted."
        exit 0
    }
}

# ─────────────────────────────────────────
# Initial checks
# ─────────────────────────────────────────

check_requirements

trap cleanup_mounts EXIT

# ─────────────────────────────────────────
# Mode selection
# ─────────────────────────────────────────

echo "==> Arch Linux Installation Script"
echo ""
echo "Select mode:"
echo "  1) Test mode (VM / small disk / quick validation)"
echo "  2) Normal mode"
echo ""

read -rp "Choice [default: 1]: " MODE_CHOICE
MODE_CHOICE=${MODE_CHOICE:-1}

if [[ "$MODE_CHOICE" == "1" ]]; then
    TEST_MODE="yes"
elif [[ "$MODE_CHOICE" == "2" ]]; then
    TEST_MODE="no"
else
    error "Invalid mode."
fi

# ─────────────────────────────────────────
# Defaults
# ─────────────────────────────────────────

if [[ "$TEST_MODE" == "yes" ]]; then
    HOSTNAME="archtest"
    USERNAME="testuser"
    USER_PASS="test"
    ROOT_PASS="root"
    TIMEZONE="UTC"
    WIFI_SSID=""
    INSTALL_MODE="bios-single-root"
else
    INSTALL_MODE="uefi-root-home"
fi

# ─────────────────────────────────────────
# User input
# ─────────────────────────────────────────

if [[ "$TEST_MODE" == "no" ]]; then
    read -rp "Hostname [default: archlinux]: " HOSTNAME
    HOSTNAME=${HOSTNAME:-archlinux}

    read -rp "Username [default: user]: " USERNAME
    USERNAME=${USERNAME:-user}

    read -rsp "User password: " USER_PASS
    echo ""
    read -rsp "Confirm user password: " USER_PASS_CONFIRM
    echo ""

    [[ "$USER_PASS" == "$USER_PASS_CONFIRM" ]] || error "User passwords do not match."

    read -rsp "Root password: " ROOT_PASS
    echo ""

    echo ""
    echo "Available timezones (e.g. Europe/Paris, America/New_York)"
    echo "Full list: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones"
    read -rp "Timezone [default: UTC]: " TIMEZONE
    TIMEZONE=${TIMEZONE:-UTC}

    if [[ ! -f "/usr/share/zoneinfo/$TIMEZONE" ]]; then
        warn "Timezone '$TIMEZONE' not found in live environment. Defaulting to UTC."
        TIMEZONE="UTC"
    fi
fi

# ─────────────────────────────────────────
# Disk selection
# ─────────────────────────────────────────

print_disks

if [[ "$TEST_MODE" == "yes" ]]; then
    read -rp "Target disk for test VM (e.g. sda, vda) [default: sda]: " DISK_NAME
    DISK_NAME=${DISK_NAME:-sda}
else
    read -rp "Target disk (e.g. nvme0n1, sda) [default: nvme0n1]: " DISK_NAME
    DISK_NAME=${DISK_NAME:-nvme0n1}
fi

DISK="/dev/$DISK_NAME"
disk_exists "$DISK" || error "Disk '$DISK' does not exist."

if [[ "$DISK_NAME" == nvme* ]]; then
    PART_PREFIX="${DISK}p"
else
    PART_PREFIX="${DISK}"
fi

# ─────────────────────────────────────────
# Partition layout
# ─────────────────────────────────────────

EFI_SIZE=""
ROOT_SIZE=""

if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    EFI_PART="${PART_PREFIX}1"
    ROOT_PART="${PART_PREFIX}2"
    HOME_PART="${PART_PREFIX}3"

    echo ""
    read -rp "EFI partition size (e.g. 512M) [default: 512M]: " EFI_SIZE
    EFI_SIZE=${EFI_SIZE:-512M}

    read -rp "Root partition size (e.g. 40G) [default: 40G]: " ROOT_SIZE
    ROOT_SIZE=${ROOT_SIZE:-40G}

    DISK_SIZE_BYTES=$(get_disk_size_bytes "$DISK")
    EFI_BYTES=$(to_bytes "$EFI_SIZE")
    ROOT_BYTES=$(to_bytes "$ROOT_SIZE")
    MIN_HOME_BYTES=$((1024**3))

    if (( EFI_BYTES + ROOT_BYTES + MIN_HOME_BYTES > DISK_SIZE_BYTES )); then
        error "Disk too small for requested layout. Need EFI + Root + at least 1GiB for Home."
    fi
else
    ROOT_PART="${PART_PREFIX}1"
fi

# ─────────────────────────────────────────
# Summary
# ─────────────────────────────────────────

echo ""
echo "==> Summary"
echo "  Mode      : $([[ "$TEST_MODE" == "yes" ]] && echo "test" || echo "normal")"
echo "  Hostname  : $HOSTNAME"
echo "  Username  : $USERNAME"
echo "  Disk      : $DISK"
if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    echo "  Layout    : EFI + Root + Home"
    echo "  EFI       : $EFI_SIZE"
    echo "  Root      : $ROOT_SIZE"
    echo "  Home      : remaining space"
else
    echo "  Layout    : single root partition"
    echo "  Boot mode : BIOS/MBR"
fi
echo "  Timezone  : $TIMEZONE"
echo ""

confirm_or_abort "Continue? (y/N): "

# ─────────────────────────────────────────
# Keyboard & network
# ─────────────────────────────────────────

loadkeys us || true

if [[ "$TEST_MODE" == "no" ]]; then
    echo ""
    echo "==> Wi-Fi setup (press Enter to skip)"
    read -rp "Wi-Fi SSID: " WIFI_SSID
    if [[ -n "$WIFI_SSID" ]]; then
        read -rsp "Wi-Fi password: " WIFI_PASS
        echo ""
        iwctl --passphrase "$WIFI_PASS" station wlan0 connect "$WIFI_SSID"
        sleep 3
    fi
fi

# ─────────────────────────────────────────
# Unmount previous mounts
# ─────────────────────────────────────────

cleanup_mounts

# ─────────────────────────────────────────
# Partitioning
# ─────────────────────────────────────────

info "Partitioning $DISK"

if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    sgdisk --zap-all "$DISK"
    sgdisk -n 1:0:+"$EFI_SIZE" -t 1:ef00 "$DISK"
    sgdisk -n 2:0:+"$ROOT_SIZE" -t 2:8300 "$DISK"
    sgdisk -n 3:0:0             -t 3:8300 "$DISK"
    partprobe "$DISK"
    sleep 2
else
    parted -s "$DISK" mklabel msdos
    parted -s "$DISK" mkpart primary ext4 1MiB 100%
    parted -s "$DISK" set 1 boot on
    partprobe "$DISK"
    sleep 2
fi

# verify partitions exist
if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    [[ -b "$EFI_PART" ]] || error "EFI partition was not created."
    [[ -b "$ROOT_PART" ]] || error "Root partition was not created."
    [[ -b "$HOME_PART" ]] || error "Home partition was not created."
else
    [[ -b "$ROOT_PART" ]] || error "Root partition was not created."
fi

# ─────────────────────────────────────────
# Formatting & mounting
# ─────────────────────────────────────────

info "Formatting"

if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    require_command mkfs.fat
    mkfs.fat -F32 "$EFI_PART"
    mkfs.ext4 -F "$ROOT_PART"
    mkfs.ext4 -F "$HOME_PART"
else
    mkfs.ext4 -F "$ROOT_PART"
fi

info "Mounting"

mount "$ROOT_PART" /mnt

if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    mkdir -p /mnt/boot/efi /mnt/home
    mount "$EFI_PART" /mnt/boot/efi
    mount "$HOME_PART" /mnt/home
fi

# ─────────────────────────────────────────
# Base install
# ─────────────────────────────────────────

info "Installing base packages"

if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    pacstrap /mnt \
        base base-devel linux linux-firmware \
        networkmanager sudo grub efibootmgr \
        vim git
else
    pacstrap /mnt \
        base base-devel linux linux-firmware \
        networkmanager sudo grub \
        vim git
fi

if [[ -f "$SCRIPT_DIR/post-install.sh" ]]; then
    install -Dm755 "$SCRIPT_DIR/post-install.sh" "/mnt/root/post-install.sh"
else
    warn "post-install.sh not found next to this script. Skipping copy."
fi

# ─────────────────────────────────────────
# fstab
# ─────────────────────────────────────────

genfstab -U /mnt >> /mnt/etc/fstab

# ─────────────────────────────────────────
# Chroot configuration
# ─────────────────────────────────────────

info "Configuring system"

arch-chroot /mnt bash <<EOF
set -euo pipefail

# Locale
grep -q '^en_US.UTF-8 UTF-8' /etc/locale.gen || echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Console keymap
echo "KEYMAP=us" > /etc/vconsole.conf

# Timezone
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# Hostname
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts <<HOSTS
127.0.0.1   localhost
::1         localhost
127.0.1.1   $HOSTNAME.localdomain $HOSTNAME
HOSTS

# Passwords
echo "root:$ROOT_PASS" | chpasswd

# User
id -u "$USERNAME" >/dev/null 2>&1 || useradd -m -G wheel,audio,video,input -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd

# Sudo
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers

# Services
systemctl enable NetworkManager

# Bootloader
if [[ "$INSTALL_MODE" == "uefi-root-home" ]]; then
    # Install GRUB (normal UEFI entry)
    grub-install \
        --target=x86_64-efi \
        --efi-directory=/boot/efi \
        --bootloader-id=GRUB \
        --recheck

    # Install fallback (important for VMs / broken firmware)
    grub-install \
        --target=x86_64-efi \
        --efi-directory=/boot/efi \
        --removable \
        --recheck
else
    grub-install --target=i386-pc "$DISK"
fi

grub-mkconfig -o /boot/grub/grub.cfg

grub-mkconfig -o /boot/grub/grub.cfg

# Optional post-install copy
if [[ -f /root/post-install.sh ]]; then
    cp /root/post-install.sh /home/$USERNAME/post-install.sh
    chown $USERNAME:$USERNAME /home/$USERNAME/post-install.sh
    chmod +x /home/$USERNAME/post-install.sh

    cat > /etc/systemd/system/post-install.service <<SERVICE
[Unit]
Description=Post-installation script
After=network.target

[Service]
Type=oneshot
User=$USERNAME
WorkingDirectory=/home/$USERNAME
ExecStart=/home/$USERNAME/post-install.sh
ExecStartPost=/bin/systemctl disable post-install.service
StandardOutput=journal+console

[Install]
WantedBy=multi-user.target
SERVICE

    systemctl enable post-install.service
fi
EOF

echo ""
echo "==> Done! You can now reboot 🌿"
