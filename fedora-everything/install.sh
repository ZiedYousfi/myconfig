#!/bin/bash
set -euo pipefail

# Fedora Everything Minimal Niri Setup Script
# Installs a minimal Wayland desktop based on Niri and greetd.

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
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

require_root() {
    [[ "${EUID:-$(id -u)}" -eq 0 ]] || log_error "This script must be run as root."
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || log_error "Missing required command: $1"
}

check_requirements() {
    require_root

    for cmd in dnf systemctl install getent id cut efibootmgr findmnt lsblk; do
        require_command "$cmd"
    done
}

detect_target_user() {
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
        USERNAME="$SUDO_USER"
    else
        read -rp "Username: " USERNAME
    fi

    id "$USERNAME" >/dev/null 2>&1 || log_error "User '$USERNAME' was not found."
    USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
}

confirm_continue() {
    echo ""
    echo "User: $USERNAME"
    echo "Home: $USER_HOME"
    echo ""

    read -rp "Continue? (y/N): " confirm
    [[ "$confirm" == "y" || "$confirm" == "Y" ]] || exit 0
}

install_packages() {
    log_info "Refreshing DNF metadata"
    dnf makecache -y

    log_info "Installing Fedora packages"
    dnf install -y \
        grub2-efi-x64 \
        grub2-common \
        shim-x64 \
        efibootmgr \
        niri \
        NetworkManager \
        greetd \
        tuigreet \
        foot \
        fuzzel \
        waybar \
        mako \
        grim \
        slurp \
        wl-clipboard \
        pipewire \
        wireplumber \
        xdg-desktop-portal \
        xdg-desktop-portal-gtk \
        brightnessctl \
        playerctl

    log_success "Packages installed"
}

write_grub_protector() {
    log_info "Installing Fedora GRUB protector"

    install -d /usr/local/sbin

    cat > /usr/local/sbin/ensure-fedora-grub-first <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

info() { echo "[grub-protector] $*"; }
warn() { echo "[grub-protector] $*" >&2; }

if [[ ! -d /sys/firmware/efi ]]; then
    info "Legacy BIOS detected, nothing to do."
    exit 0
fi

if ! command -v efibootmgr >/dev/null 2>&1; then
    warn "efibootmgr is not installed."
    exit 1
fi

find_fedora_entry() {
    efibootmgr -v | awk '
        BEGIN { IGNORECASE=1 }
        /^Boot[0-9A-Fa-f]{4}\*?[[:space:]]+Fedora/ &&
        $0 ~ /\\\\EFI\\\\fedora\\\\(shimx64|shim)\.efi/ {
            match($0, /^Boot[0-9A-Fa-f]{4}/)
            print substr($0, 5, 4)
            exit
        }
    '
}

create_fedora_entry() {
    local efi_source efi_disk efi_part

    if [[ ! -e /boot/efi/EFI/fedora/shimx64.efi && ! -e /boot/efi/EFI/fedora/shim.efi ]]; then
        warn "Fedora shim was not found under /boot/efi/EFI/fedora."
        return 1
    fi

    efi_source="$(findmnt -no SOURCE /boot/efi 2>/dev/null || true)"
    if [[ -z "$efi_source" ]]; then
        warn "/boot/efi is not mounted."
        return 1
    fi

    efi_disk="/dev/$(lsblk -no PKNAME "$efi_source" 2>/dev/null | head -n1)"
    efi_part="$(lsblk -no PARTNUM "$efi_source" 2>/dev/null | head -n1)"

    if [[ -z "$efi_disk" || -z "$efi_part" ]]; then
        warn "Could not determine the EFI disk and partition."
        return 1
    fi

    info "Creating a Fedora UEFI boot entry."
    efibootmgr -c -d "$efi_disk" -p "$efi_part" -L Fedora -l '\EFI\fedora\shimx64.efi' >/dev/null
}

fedora_bootnum="$(find_fedora_entry || true)"
if [[ -z "$fedora_bootnum" ]]; then
    create_fedora_entry || true
    fedora_bootnum="$(find_fedora_entry || true)"
fi

if [[ -z "$fedora_bootnum" ]]; then
    warn "No Fedora UEFI entry was found or created."
    exit 1
fi

current_order="$(efibootmgr | awk -F'BootOrder: ' '/BootOrder:/ {print $2}' | tr -d '[:space:]')"
if [[ -z "$current_order" ]]; then
    warn "Could not read the current BootOrder."
    exit 1
fi

IFS=',' read -r -a entries <<< "$current_order"
new_entries=("${fedora_bootnum^^}")

for entry in "${entries[@]}"; do
    entry="${entry^^}"
    [[ -z "$entry" || "$entry" == "${fedora_bootnum^^}" ]] && continue
    new_entries+=("$entry")
done

if [[ "${entries[0]^^}" == "${fedora_bootnum^^}" ]]; then
    info "Fedora is already first in BootOrder."
    exit 0
fi

new_order="$(IFS=,; echo "${new_entries[*]}")"
info "Setting BootOrder to $new_order"
efibootmgr -o "$new_order" >/dev/null
EOF

    chmod 755 /usr/local/sbin/ensure-fedora-grub-first

    cat > /etc/systemd/system/fedora-grub-protector.service <<'EOF'
[Unit]
Description=Keep Fedora GRUB first in UEFI BootOrder
After=local-fs.target
ConditionPathExists=/sys/firmware/efi

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ensure-fedora-grub-first

[Install]
WantedBy=multi-user.target
EOF

    /usr/local/sbin/ensure-fedora-grub-first || log_warning "Could not update UEFI BootOrder automatically"
    log_success "Fedora GRUB protector installed"
}

write_session() {
    log_info "Writing Niri session files"

    install -d /usr/local/bin

    cat > /usr/local/bin/niri-session <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export XDG_CURRENT_DESKTOP=niri
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=niri

export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export SDL_VIDEODRIVER=wayland

exec niri
EOF

    chmod +x /usr/local/bin/niri-session

    install -d /usr/share/wayland-sessions

    cat > /usr/share/wayland-sessions/niri.desktop <<'EOF'
[Desktop Entry]
Name=Niri
Exec=/usr/local/bin/niri-session
Type=Application
DesktopNames=niri
EOF

    log_success "Session files written"
}

configure_greetd() {
    log_info "Configuring greetd with tuigreet"

    install -d /etc/greetd

    cat > /etc/greetd/config.toml <<'EOF'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --remember-session --asterisks --cmd /usr/local/bin/niri-session"
user = "greeter"
EOF

    log_success "greetd configured"
}

write_minimal_niri_config() {
    local conf="$USER_HOME/.config/niri/config.kdl"

    if [[ -e "$conf" ]]; then
        log_warning "Existing Niri config found at $conf, leaving it unchanged"
        return
    fi

    log_info "Writing minimal Niri config"

    install -d -o "$USERNAME" -g "$USERNAME" "$USER_HOME/.config/niri"

    cat > "$conf" <<'EOF'
input {
    keyboard {
        xkb { layout "us" }
    }
}

layout {
    gaps 16
}

spawn-at-startup "waybar"
spawn-at-startup "mako"

binds {
    Mod+Return { spawn "foot"; }
    Mod+D { spawn "fuzzel"; }
    Mod+Q { close-window; }
}
EOF

    chown "$USERNAME:$USERNAME" "$conf"
    log_success "Niri config created"
}

enable_services() {
    log_info "Enabling services"
    systemctl enable NetworkManager
    systemctl enable greetd
    systemctl enable fedora-grub-protector.service
    log_success "Services enabled"
}

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║            Fedora Everything Minimal Niri Setup               ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    check_requirements
    detect_target_user
    confirm_continue
    install_packages
    write_session
    configure_greetd
    write_grub_protector
    write_minimal_niri_config
    enable_services

    echo ""
    log_success "Setup complete"
    echo "Reboot and log in through greetd."
    echo ""
}

main "$@"
