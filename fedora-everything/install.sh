#!/bin/bash
set -euo pipefail

# Fedora Everything Niri Setup Script

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DOTFILES_DIR="$REPO_ROOT/dotfiles"
AXIDEV_OSK_RELEASE_API="https://api.github.com/repos/axide-dev/axidev-osk/releases/latest"
AXIDEV_OSK_SOURCE_ZIP_URL="https://github.com/axide-dev/axidev-osk/releases/latest/download/axidev-osk-source.zip"
AXIDEV_OSK_INSTALL_DIR="/opt/axidev-osk"
AXIDEV_OSK_VENV_DIR="$AXIDEV_OSK_INSTALL_DIR/.venv"
AXIDEV_OSK_BIN="/usr/local/bin/axidev-osk"
KANATA_RELEASE_API="https://api.github.com/repos/jtroo/kanata/releases/latest"
KANATA_BIN="/usr/local/bin/kanata"
SYSTEM_LOCALE="en_US.UTF-8"
SYSTEM_XKB_LAYOUT="us"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SHARED_DOTFILE_PACKAGES=(
    fuzzel
    lazygit
    mako
    autostart
    display
    niri
    kanata
    local
    nvim
    tmux
    waybar
    wezterm
    yazi
    zsh
)

CORE_STOW_PACKAGES=(
    fuzzel
    mako
    autostart
    display
    niri
    kanata
    local
    waybar
)

OPTIONAL_STOW_PACKAGES=(
    lazygit
    nvim
    wezterm
)

MANAGE_NIRI_DOTFILES=1
GREETER_USER=""

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

    for cmd in dnf systemctl systemd-tmpfiles install getent id cut efibootmgr findmnt lsblk mktemp localectl localedef; do
        require_command "$cmd"
    done
}

ensure_bootstrap_command() {
    local command_name="$1"
    local package_name="$2"

    if command -v "$command_name" >/dev/null 2>&1; then
        return
    fi

    log_info "Installing missing bootstrap dependency: $package_name"
    dnf install -y "$package_name"
    require_command "$command_name"
}

install_bootstrap_dependencies() {
    log_info "Installing bootstrap dependencies used by the installer"
    ensure_bootstrap_command rsync rsync
    ensure_bootstrap_command runuser util-linux
    # dnf-plugins-core is required for `dnf copr` and `dnf config-manager`
    # which we use to front-load all third-party repos before the main
    # install transaction.
    if ! rpm -q dnf-plugins-core >/dev/null 2>&1; then
        log_info "Installing dnf-plugins-core for repo management"
        dnf install -y dnf-plugins-core
    fi
    log_success "Bootstrap dependencies installed"
}

detect_target_user() {
    if [[ -n "${SUDO_USER:-}" && "$SUDO_USER" != "root" ]]; then
        USERNAME="$SUDO_USER"
    else
        read -rp "Username: " USERNAME
    fi

    id "$USERNAME" >/dev/null 2>&1 || log_error "User '$USERNAME' was not found."
    USER_HOME="$(getent passwd "$USERNAME" | cut -d: -f6)"
    USER_DOTFILES_DIR="$USER_HOME/dotfiles"
}

detect_greeter_user() {
    if id greeter >/dev/null 2>&1; then
        GREETER_USER="greeter"
        return
    fi

    if id greetd >/dev/null 2>&1; then
        GREETER_USER="greetd"
        return
    fi

    log_error "Could not find a greetd system user (expected 'greeter' or 'greetd')."
}

decide_niri_dotfiles_management() {
    local session_config="$USER_HOME/.config/niri/config.kdl"

    if [[ -e "$session_config" && ! -L "$session_config" ]]; then
        MANAGE_NIRI_DOTFILES=0
        log_warning "Existing Niri session config detected at $session_config; it will be left untouched."
        return
    fi

    MANAGE_NIRI_DOTFILES=1
}

log_install_context() {
    echo ""
    echo "User: $USERNAME"
    echo "Home: $USER_HOME"
    echo "Dotfiles: $USER_DOTFILES_DIR"
    if [[ "$MANAGE_NIRI_DOTFILES" -eq 0 ]]; then
        echo "Niri session config: keep existing ~/.config/niri/config.kdl"
    fi
    echo ""
}

ensure_user_owned_dir() {
    local dir="$1"
    install -d -o "$USERNAME" -g "$USERNAME" "$dir"
}

ensure_user_owns_home_tree() {
    log_info "Fixing ownership under $USER_HOME"

    if find "$USER_HOME" -xdev -exec chown -h "$USERNAME:$USERNAME" {} + 2>/dev/null; then
        log_success "Ownership fixed for $USER_HOME"
    else
        log_warning "Some entries under $USER_HOME could not be re-owned automatically"
    fi
}

ensure_user_controls_dotfiles_tree() {
    if [[ ! -d "$USER_DOTFILES_DIR" ]]; then
        return 0
    fi

    log_info "Ensuring $USERNAME can edit all managed dotfiles"
    chown -R "$USERNAME:$USERNAME" "$USER_DOTFILES_DIR"
    chmod -R u+rwX "$USER_DOTFILES_DIR"
    log_success "Managed dotfiles are user-writable"
}

run_as_user() {
    runuser -u "$USERNAME" -- "$@"
}

configure_third_party_repos() {
    log_info "Configuring third-party repositories (COPRs, 1Password, Docker)"

    # COPRs — keep optional so a broken COPR doesn't abort the installer.
    if ! dnf -y copr enable lihaohong/yazi; then
        log_warning "Could not enable the Yazi COPR; continuing without it"
    fi

    if ! dnf -y copr enable dejan/lazygit; then
        log_warning "Could not enable the Lazygit COPR; continuing without it"
    fi

    if ! dnf -y copr enable wezfurlong/wezterm-nightly; then
        log_warning "Could not enable the WezTerm COPR; continuing without it"
    fi

    if ! dnf -y copr enable sureclaw/codex; then
        log_warning "Could not enable the Codex COPR; continuing without it"
    fi

    if ! dnf -y copr enable burningpho3nix/T3-Code; then
        log_warning "Could not enable the T3 Code COPR; continuing without it"
    fi

    configure_1password_repo
    configure_docker_repo || log_warning "Docker repository setup failed; docker-ce packages will be skipped"

    # RPM Fusion 
    log_info "Configuring RPM Fusion repositories (free and nonfree)"

    if ! dnf -y install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm; then
        log_warning "Could not configure RPM Fusion Free repository; multimedia packages may be unavailable"
    fi

    if ! dnf -y install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm; then
        log_warning "Could not configure RPM Fusion Nonfree repository; some gaming packages may be unavailable"
    fi

    log_success "Third-party repositories configured"
}

configure_1password_repo() {
    log_info "Configuring the 1Password repository"
    rpm --import https://downloads.1password.com/linux/keys/1password.asc
    cat > /etc/yum.repos.d/1password.repo <<'EOF'
[1password]
name=1Password Stable Channel
baseurl=https://downloads.1password.com/linux/rpm/stable/$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://downloads.1password.com/linux/keys/1password.asc
EOF
    log_success "1Password repository configured"
}

configure_docker_repo() {
    if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
        log_success "Docker repository is already configured"
        return 0
    fi

    log_info "Configuring Docker repository"
    if dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo 2>/dev/null; then
        log_success "Docker repository configured"
        return 0
    fi

    if dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo; then
        log_success "Docker repository configured"
        return 0
    fi

    log_warning "Could not configure Docker repository"
    return 1
}

install_all_packages() {
    local arch
    arch="$(uname -m)"

    log_info "Refreshing DNF metadata"
    dnf makecache -y

    # One big transaction. --skip-unavailable means a missing COPR package
    # (or a failed Docker repo) won't abort the whole installer; the rest
    # still lands. The dependency solver also does a much better job when
    # it can see every package at once.
    local -a packages=(
        # Core system / boot
        grub2-efi-x64
        grub2-common
        shim-x64
        efibootmgr
        rEFInd
        git
        curl
        wget
        rsync
        stow
        zsh
        tar
        unzip
        xz
        fontconfig
        glibc-langpack-en
        glibc-locale-source
        kmod
        NetworkManager
        NetworkManager-wifi
        wpa_supplicant
        iwlwifi-mvm-firmware
        iwlwifi-mld-firmware
        network-manager-applet
        nm-connection-editor

        # Niri session + greeter
        greetd
        gtkgreet
        niri
        python3
        python3-pip
        python3-setuptools
        python3-wheel
        python3-pyside6
        qt6-qtwayland
        layer-shell-qt
        libinput-devel
        systemd-devel
        systemd-libs
        libxkbcommon-devel
        python3-devel
        waybar
        yad
        fuzzel
        mako
        swww
        grim
        slurp
        wl-clipboard

        # Audio stack
        pipewire
        pipewire-pulseaudio
        pipewire-alsa
        pipewire-jack-audio-connection-kit
        pipewire-utils
        wireplumber
        alsa-utils
        alsa-firmware
        sof-firmware
        pamixer
        # Flatpak runtime so we can install pwvucontrol from Flathub
        # (pwvucontrol is not in Fedora's main repos and upstream only
        # officially supports Flatpak).
        flatpak

        # Desktop integration
        xdg-desktop-portal
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
        adwaita-qt5
        adwaita-qt6
        qt5ct
        qt6ct
        brightnessctl
        thunar
        thunar-volman
        thunar-archive-plugin
        file-roller
        gvfs
        gvfs-mtp
        gvfs-gphoto2
        gvfs-smb
        gvfs-afc
        udisks2
        udiskie
        ffmpegthumbnailer
        tumbler
        lxappearance
        exo
        xfconf
        kde-connect
        firewalld

        # CLI tooling
        fd-find
        ripgrep
        fzf
        zoxide
        jq
        less
        file
        inxi
        wdisplays
        audacity
        alsa-sof-firmware
        alsa-ucm
        google-noto-sans-cjk-ttc-fonts
        google-noto-color-emoji-fonts
        google-noto-fonts-all
        langpacks-en
        langpacks-ko

        # Optional user tools (from COPRs and Fedora main)
        neovim
        tmux
        lazygit
        eza
        bat
        fastfetch
        yazi
        wezterm
        btop
        tokei
        tree-sitter-cli
        golang
        rustup
        java-latest-openjdk-devel
        # Note: NVM intentionally not installed via dnf — install_nvm_and_node()
        # clones the upstream repo into ~/.nvm per NVM's official install method.
        maven
        gcc
        llvm
        cmake
        make
        meson
        conan
        zig
        ffmpeg
        p7zip
        p7zip-plugins
        7zip
        7zip-plugins
        poppler-utils
        resvg
        ImageMagick
        blender
        krita
        kdenlive
        codex
        t3code
        akmods
        mokutil
        openssl
        sbsigntools
        akmod-nvidia
        xorg-x11-drv-nvidia-cuda
        switcheroo-control
        nvidia-settings

        # Desktop apps
        1password
        1password-cli

        # Docker
        docker-ce
        docker-ce-cli
        containerd.io
        docker-buildx-plugin
        docker-compose-plugin

        # G@MING 
        lutris 
        steam
    )

    # Google Chrome ships only for x86_64 as a direct RPM URL; dnf accepts
    # URLs in the install list so it joins the same transaction.
    if [[ "$arch" == "x86_64" ]]; then
        packages+=(https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm)
    else
        log_warning "Google Chrome is only configured for x86_64 in this installer; detected architecture: $arch"
    fi

    log_info "Installing all Fedora packages in a single transaction (this is the slow part)"
    dnf install -y --skip-unavailable "${packages[@]}"
    log_success "Packages installed"
}

post_install_docker() {
    if ! command -v docker >/dev/null 2>&1; then
        log_warning "Docker CLI not found after install; skipping docker service setup"
        return 1
    fi

    groupadd -f docker
    usermod -aG docker "$USERNAME"
    systemctl enable --now docker || log_warning "Docker was installed, but the service could not be enabled"
    log_success "Docker service enabled"
}

configure_system_locale() {
    log_info "Configuring system locale to $SYSTEM_LOCALE"

    if ! locale -a 2>/dev/null | grep -Eqi '^en_US\.(utf8|utf-8)$'; then
        log_info "Generating missing locale $SYSTEM_LOCALE"
        localedef -i en_US -f UTF-8 "$SYSTEM_LOCALE"
    fi

    localectl set-locale "LANG=$SYSTEM_LOCALE"
    log_success "System locale configured"
}

configure_system_keyboard() {
    log_info "Configuring system keyboard layout to $SYSTEM_XKB_LAYOUT"
    localectl set-keymap "$SYSTEM_XKB_LAYOUT"
    localectl set-x11-keymap "$SYSTEM_XKB_LAYOUT"
    log_success "System keyboard layout configured"
}

install_nvm_and_node() {
    local nvm_dir="$USER_HOME/.nvm"
    local latest_tag

    if [[ -d "$nvm_dir/.git" ]]; then
        log_info "Updating NVM"
        run_as_user git -C "$nvm_dir" fetch --tags --prune
    else
        log_info "Installing NVM"
        run_as_user git clone https://github.com/nvm-sh/nvm.git "$nvm_dir"
    fi

    latest_tag="$(git -C "$nvm_dir" tag -l 'v*' | sort -V | tail -n1)"
    if [[ -z "$latest_tag" ]]; then
        log_warning "Could not resolve an NVM release tag"
        return 1
    fi

    run_as_user git -C "$nvm_dir" checkout -q "$latest_tag"
    run_as_user bash -lc "export NVM_DIR='$nvm_dir'; . '$nvm_dir/nvm.sh'; nvm install --lts; nvm alias default 'lts/*'"
    log_success "NVM and Node.js LTS installed"
}

install_ollama() {
    if command -v ollama >/dev/null 2>&1; then
        log_success "Ollama is already installed"
        return 0
    fi

    log_info "Installing Ollama"
    curl -fsSL https://ollama.com/install.sh | sh
    systemctl enable --now ollama || log_warning "Ollama was installed, but the service could not be enabled"
    log_success "Ollama installed"
}

secure_boot_enabled() {
    local secure_boot_var

    secure_boot_var="$(find /sys/firmware/efi/efivars -maxdepth 1 -name 'SecureBoot-*' 2>/dev/null | head -n1 || true)"
    if [[ -z "$secure_boot_var" ]]; then
        return 1
    fi

    local value
    value="$(od -An -j4 -N1 -t u1 "$secure_boot_var" 2>/dev/null | tr -d '[:space:]')"
    [[ "$value" == "1" ]]
}

enable_refind_mouse() {
    local refind_dir="/boot/efi/EFI/refind"
    local refind_conf="$refind_dir/refind.conf"
    local sample_conf="$refind_dir/refind.conf-sample"
    local managed_comment="# Managed by setup-config: enable rEFInd mouse input"

    if [[ ! -d "$refind_dir" ]]; then
        log_warning "rEFInd directory was not found at $refind_dir; skipping mouse configuration."
        return
    fi

    if [[ ! -f "$refind_conf" && -f "$sample_conf" ]]; then
        cp "$sample_conf" "$refind_conf"
        log_info "Created rEFInd config from $sample_conf"
    fi

    if [[ ! -f "$refind_conf" ]]; then
        log_warning "rEFInd config was not found at $refind_conf; skipping mouse configuration."
        return
    fi

    if grep -Fq "$managed_comment" "$refind_conf"; then
        sed -i "\|$managed_comment|,+1d" "$refind_conf"
    fi

    printf '\n%s\nenable_mouse true\n' "$managed_comment" >> "$refind_conf"
    log_success "rEFInd mouse support enabled"
}

configure_refind_theme() {
    local refind_dir="/boot/efi/EFI/refind"
    local refind_conf="$refind_dir/refind.conf"
    local theme_dir="$refind_dir/themes/black-pink"
    local theme_conf="$theme_dir/theme.conf"
    local managed_comment="# Managed by setup-config: black-pink minimal theme"
    local image_tool=""

    if [[ ! -d "$refind_dir" || ! -f "$refind_conf" ]]; then
        log_warning "rEFInd config was not found; skipping rEFInd theme setup."
        return
    fi

    if command -v magick >/dev/null 2>&1; then
        image_tool="magick"
    elif command -v convert >/dev/null 2>&1; then
        image_tool="convert"
    else
        log_warning "ImageMagick was not found; skipping rEFInd theme asset generation."
        return
    fi

    log_info "Installing black-pink rEFInd theme"

    install -d "$theme_dir"

    "$image_tool" -size 1920x1080 xc:'#000000' \
        -fill '#ff4ead' -draw 'rectangle 0,1076 1920,1080' \
        "$theme_dir/banner.png"
    "$image_tool" -size 144x144 xc:none \
        -fill 'rgba(255,78,173,0.16)' -draw 'roundrectangle 2,2 142,142 12,12' \
        -stroke '#ff4ead' -strokewidth 3 -fill none -draw 'roundrectangle 2,2 142,142 12,12' \
        "$theme_dir/selection_big.png"
    "$image_tool" -size 64x64 xc:none \
        -fill 'rgba(255,78,173,0.16)' -draw 'roundrectangle 1,1 63,63 6,6' \
        -stroke '#ff4ead' -strokewidth 2 -fill none -draw 'roundrectangle 1,1 63,63 6,6' \
        "$theme_dir/selection_small.png"

    cat > "$theme_conf" <<'EOF'
# Managed by setup-config.
banner themes/black-pink/banner.png
banner_scale fillscreen
selection_big themes/black-pink/selection_big.png
selection_small themes/black-pink/selection_small.png
hideui hints,label,singleuser,arrows,badges
showtools reboot,shutdown,firmware
use_graphics_for linux,windows
EOF

    if grep -Fq "$managed_comment" "$refind_conf"; then
        sed -i "\|$managed_comment|,+1d" "$refind_conf"
    fi

    printf '\n%s\ninclude themes/black-pink/theme.conf\n' "$managed_comment" >> "$refind_conf"
    log_success "rEFInd black-pink theme installed"
}

install_refind() {
    local shim_path=""
    local -a cmd=(refind-install --yes)

    if [[ ! -d /sys/firmware/efi ]]; then
        log_warning "Legacy BIOS detected; skipping rEFInd installation."
        return
    fi

    require_command refind-install

    if secure_boot_enabled; then
        if [[ -e /boot/efi/EFI/fedora/shimx64.efi ]]; then
            shim_path="/boot/efi/EFI/fedora/shimx64.efi"
        elif [[ -e /boot/efi/EFI/fedora/shim.efi ]]; then
            shim_path="/boot/efi/EFI/fedora/shim.efi"
        fi

        if [[ -n "$shim_path" ]]; then
            cmd+=(--shim "$shim_path")
        else
            log_warning "Secure Boot appears enabled, but no Fedora shim binary was found. Falling back to plain refind-install."
        fi
    fi

    log_info "Installing rEFInd into the EFI System Partition"
    "${cmd[@]}"
    enable_refind_mouse
    configure_refind_theme
    log_success "rEFInd installed"
}

write_axidev_osk_wrapper() {
    local osk_entrypoint="$AXIDEV_OSK_VENV_DIR/bin/axidev-osk"

    cat > "$AXIDEV_OSK_BIN" <<EOF
#!/usr/bin/env bash
set -euo pipefail

for plugin_root in /usr/lib64/qt6/plugins /usr/lib/qt6/plugins /usr/local/lib64/qt6/plugins /usr/local/lib/qt6/plugins
do
    if [[ -f "\$plugin_root/wayland-shell-integration/liblayer-shell.so" ]]; then
        if [[ -n "\${QT_PLUGIN_PATH:-}" ]]; then
            export QT_PLUGIN_PATH="\$plugin_root:\$QT_PLUGIN_PATH"
        else
            export QT_PLUGIN_PATH="\$plugin_root"
        fi
        break
    fi
done

export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_QUICK_CONTROLS_STYLE=Fusion
export QT_WAYLAND_SHELL_INTEGRATION=layer-shell
export AXIDEV_OSK_OVERLAY_BACKEND=wayland-layer-shell

exec "$osk_entrypoint" "\$@"
EOF

    chmod 0755 "$AXIDEV_OSK_BIN"

    if command -v restorecon >/dev/null 2>&1; then
        restorecon -Fv "$AXIDEV_OSK_BIN" >/dev/null 2>&1 || true
    fi
}

label_axidev_osk_install() {
    # The greeter runs confined enough that a copied venv labeled user_home_t can
    # look executable but still fail with EACCES under SELinux.
    if command -v restorecon >/dev/null 2>&1; then
        restorecon -RFv "$AXIDEV_OSK_INSTALL_DIR" >/dev/null 2>&1 || true
    fi

    if command -v chcon >/dev/null 2>&1; then
        chcon -R -t bin_t "$AXIDEV_OSK_INSTALL_DIR" >/dev/null 2>&1 || true
    fi
}

install_axidev_osk() {
    local arch release_json version tmp_dir archive_path extracted_dir source_dir
    local osk_entrypoint="$AXIDEV_OSK_VENV_DIR/bin/axidev-osk"

    arch="$(uname -m)"
    if [[ "$arch" != "x86_64" ]]; then
        log_error "Axidev OSK source install is currently supported only on x86_64 by this installer; detected architecture: $arch"
    fi

    log_info "Resolving latest Axidev OSK release"
    release_json="$(curl -fsSL "$AXIDEV_OSK_RELEASE_API")"
    version="$(jq -r '.tag_name // empty' <<< "$release_json")"

    if [[ -z "$version" ]]; then
        log_error "Could not determine the latest Axidev OSK release tag."
    fi

    if [[ -x "$osk_entrypoint" && -f "$AXIDEV_OSK_INSTALL_DIR/.version" ]] &&
        [[ "$(cat "$AXIDEV_OSK_INSTALL_DIR/.version")" == "$version" ]]; then
        label_axidev_osk_install
        write_axidev_osk_wrapper
        log_success "Axidev OSK $version is already installed"
        return
    fi

    log_info "Installing Axidev OSK $version from source"
    tmp_dir="$(mktemp -d)"
    archive_path="$tmp_dir/axidev-osk-source.zip"
    extracted_dir="$tmp_dir/extracted"

    if [[ "$AXIDEV_OSK_INSTALL_DIR" != "/opt/axidev-osk" ]]; then
        rm -rf "$tmp_dir"
        log_error "Refusing to replace unexpected Axidev OSK install directory: $AXIDEV_OSK_INSTALL_DIR"
    fi

    if ! curl -fL "$AXIDEV_OSK_SOURCE_ZIP_URL" -o "$archive_path"; then
        rm -rf "$tmp_dir"
        log_error "Could not download Axidev OSK source archive from $AXIDEV_OSK_SOURCE_ZIP_URL"
    fi

    install -d "$extracted_dir"
    unzip -q "$archive_path" -d "$extracted_dir"
    source_dir="$extracted_dir/axidev-osk"

    if [[ ! -f "$source_dir/pyproject.toml" || ! -d "$source_dir/vendor/axidev-io-python" ]]; then
        rm -rf "$tmp_dir"
        log_error "Axidev OSK source archive is missing expected project files or vendored sources."
    fi

    rm -rf -- "$AXIDEV_OSK_INSTALL_DIR"
    install -d "$(dirname "$AXIDEV_OSK_INSTALL_DIR")"
    mv "$source_dir" "$AXIDEV_OSK_INSTALL_DIR"
    python3 -m venv --system-site-packages "$AXIDEV_OSK_VENV_DIR"
    "$AXIDEV_OSK_VENV_DIR/bin/python" -m ensurepip --upgrade >/dev/null 2>&1 || true
    "$AXIDEV_OSK_VENV_DIR/bin/python" -m pip install --upgrade pip setuptools wheel
    "$AXIDEV_OSK_VENV_DIR/bin/python" -m pip install -e "$AXIDEV_OSK_INSTALL_DIR/vendor/axidev-io-python" --no-deps
    "$AXIDEV_OSK_VENV_DIR/bin/python" -m pip install -e "$AXIDEV_OSK_INSTALL_DIR" --no-deps
    printf '%s\n' "$version" > "$AXIDEV_OSK_INSTALL_DIR/.version"
    chown -R root:root "$AXIDEV_OSK_INSTALL_DIR"
    label_axidev_osk_install
    write_axidev_osk_wrapper
    rm -rf "$tmp_dir"

    log_success "Axidev OSK $version installed"
}

install_kanata() {
    local arch release_json version download_url tmp_dir archive_path extracted_dir candidate

    arch="$(uname -m)"
    if [[ "$arch" != "x86_64" ]]; then
        log_error "Kanata upstream Linux binaries are only published for x86_64; detected architecture: $arch"
    fi

    log_info "Resolving latest Kanata release"
    release_json="$(curl -fsSL "$KANATA_RELEASE_API")"
    version="$(jq -r '.tag_name // empty' <<< "$release_json")"
    download_url="$(
        jq -r '
            .assets[].browser_download_url
            | select(test("kanata-linux.*x64.*\\.zip$") or test("linux-binaries.*x64.*\\.zip$"))
        ' <<< "$release_json" | head -n1
    )"

    if [[ -z "$version" || -z "$download_url" ]]; then
        log_error "Could not determine the latest Kanata Linux release asset."
    fi

    if [[ -x "$KANATA_BIN" && -f /usr/local/share/kanata.version ]] &&
        [[ "$(cat /usr/local/share/kanata.version)" == "$version" ]]; then
        log_success "Kanata $version is already installed"
        return
    fi

    log_info "Installing Kanata $version"
    tmp_dir="$(mktemp -d)"
    archive_path="$tmp_dir/kanata-linux-x64.zip"
    extracted_dir="$tmp_dir/extracted"

    if ! curl -fL "$download_url" -o "$archive_path"; then
        rm -rf "$tmp_dir"
        log_error "Could not download Kanata from $download_url"
    fi

    install -d "$extracted_dir"
    unzip -q "$archive_path" -d "$extracted_dir"

    candidate="$(find "$extracted_dir" -type f \( -name kanata -o -name 'kanata_linux_x64*' -o -name 'kanata*linux*x64*' \) |
        grep -Ev 'cmd_allowed|legacy|\.exe$|\.kbd$' |
        sort |
        head -n1 || true)"

    if [[ -z "$candidate" ]]; then
        rm -rf "$tmp_dir"
        log_error "Kanata archive did not contain an expected Linux binary."
    fi

    install -m 0755 "$candidate" "$KANATA_BIN"
    install -d /usr/local/share
    printf '%s\n' "$version" > /usr/local/share/kanata.version
    rm -rf "$tmp_dir"

    log_success "Kanata $version installed"
}

setup_axidev_osk_permissions() {
    local rule_path="/etc/udev/rules.d/70-axidev-io-uinput.rules"
    local -a osk_users=("$USERNAME")
    local user

    if [[ -n "$GREETER_USER" && "$GREETER_USER" != "$USERNAME" ]]; then
        osk_users+=("$GREETER_USER")
    fi

    log_info "Configuring Axidev OSK uinput permissions"
    modprobe uinput
    groupadd -f input

    for user in "${osk_users[@]}"; do
        usermod -aG input "$user"
    done

    install -d /etc/udev/rules.d /etc/modules-load.d
    printf '%s\n' 'KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"' > "$rule_path"
    printf '%s\n' 'uinput' > /etc/modules-load.d/uinput.conf
    udevadm control --reload-rules
    udevadm trigger /dev/uinput >/dev/null 2>&1 || true

    log_success "Axidev OSK uinput permissions configured for: ${osk_users[*]}"
}

setup_kanata_permissions() {
    local rule_path="/etc/udev/rules.d/71-kanata-input.rules"

    log_info "Configuring Kanata input and uinput permissions"
    modprobe uinput
    groupadd -f input
    usermod -aG input "$USERNAME"

    install -d /etc/udev/rules.d /etc/modules-load.d
    cat > "$rule_path" <<'EOF'
KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"
SUBSYSTEM=="input", KERNEL=="event*", MODE="0660", GROUP="input"
EOF
    printf '%s\n' 'uinput' > /etc/modules-load.d/uinput.conf
    udevadm control --reload-rules
    udevadm trigger /dev/uinput >/dev/null 2>&1 || true
    udevadm trigger --subsystem-match=input >/dev/null 2>&1 || true

    log_success "Kanata permissions configured for user: $USERNAME"
}

configure_audio_stack() {
    log_info "Configuring PipeWire audio stack for $USERNAME"

    local pipewire_conf_dir="$USER_HOME/.config/pipewire/pipewire.conf.d"

    # Ensure the user can access audio devices directly (ALSA fallback paths,
    # Bluetooth audio helpers, and some pro-audio tools still check group audio).
    groupadd -f audio
    usermod -aG audio "$USERNAME"

    # Make sure the PulseAudio-compat service from the PulseAudio package is
    # not running in parallel with pipewire-pulse. Fedora ships PipeWire as
    # default, but a stray pulseaudio.socket from an upgrade path will cause
    # glitches like silent outputs and "dummy output" devices.
    if run_as_user systemctl --user list-unit-files pulseaudio.socket >/dev/null 2>&1; then
        run_as_user systemctl --user mask --now pulseaudio.service pulseaudio.socket >/dev/null 2>&1 || true
    fi

    # Enable and start the PipeWire user services so audio works immediately
    # after the first login (also re-enabled every boot via systemd --user).
    local unit
    for unit in pipewire.socket pipewire.service pipewire-pulse.socket pipewire-pulse.service wireplumber.service; do
        run_as_user systemctl --user enable "$unit" >/dev/null 2>&1 || true
    done

    ensure_user_owned_dir "$pipewire_conf_dir"
    cat > "$pipewire_conf_dir/rate.conf" <<'EOF'
context.properties = {
    default.clock.rate = 48000
}
EOF
    cat > "$pipewire_conf_dir/latency.conf" <<'EOF'
context.properties = {
    default.clock.quantum = 128
    default.clock.min-quantum = 64
    default.clock.max-quantum = 256
}
EOF
    cat > "$pipewire_conf_dir/disable-suspend.conf" <<'EOF'
context.properties = {
    session.suspend-timeout-seconds = 0
}
EOF
    chown -R "$USERNAME:$USERNAME" "$USER_HOME/.config/pipewire"
    run_as_user systemctl --user restart pipewire pipewire-pulse >/dev/null 2>&1 || true

    # Allow systemd --user services to keep running when $USERNAME is not
    # logged in graphically yet (helps greetd handoff and Bluetooth audio).
    loginctl enable-linger "$USERNAME" >/dev/null 2>&1 || true

    log_success "PipeWire audio stack configured"
}

configure_networking() {
    log_info "Configuring NetworkManager and Wi-Fi"

    systemctl enable --now NetworkManager
    nmcli radio wifi on || true

    log_success "NetworkManager configured"
}

configure_file_management() {
    log_info "Configuring file-management integration"

    run_as_user xfconf-query -c xfce4-session -p /general/TerminalEmulator -s wezterm --create -t string || true

    log_success "File-management integration configured"
}

configure_kde_connect() {
    log_info "Configuring KDE Connect"

    systemctl enable --now firewalld
    firewall-cmd --permanent --add-service=kdeconnect || log_warning "Could not add KDE Connect firewall service"
    firewall-cmd --reload || log_warning "Could not reload firewalld"

    log_success "KDE Connect configured"
}

configure_nvidia_stack() {
    local helper_script="$USER_HOME/enroll-secure-boot-nvidia.sh"

    log_info "Configuring NVIDIA Optimus support and shared rEFInd/NVIDIA MOK signing"

    systemctl enable --now switcheroo-control || log_warning "Could not enable switcheroo-control"

    cat > "$helper_script" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

warn() { printf '[WARNING] %s\n' "$*" >&2; }
info() { printf '[INFO] %s\n' "$*"; }

require_command() {
    command -v "$1" >/dev/null 2>&1 || {
        warn "Missing required command: $1"
        exit 1
    }
}

require_command sudo
require_command openssl
require_command mokutil
require_command sbsign

info "Generating the single shared akmods MOK key if it does not already exist"
info "This same MOK key is used for NVIDIA kernel modules and for signing rEFInd."
info "Run this even on AMD-only systems when Secure Boot should trust the signed rEFInd binary."
sudo kmodgenca

der_cert="/etc/pki/akmods/certs/public_key.der"
pem_cert="/etc/pki/akmods/certs/public_key.pem"
private_key="/etc/pki/akmods/private/private_key.priv"
refind_grub="/boot/efi/EFI/refind/grubx64.efi"

if [[ ! -f "$der_cert" || ! -f "$private_key" ]]; then
    warn "akmods key material was not found under /etc/pki/akmods after kmodgenca."
    exit 1
fi

info "Converting the akmods public key to PEM for sbsign"
sudo openssl x509 -in "$der_cert" -inform DER -out "$pem_cert" -outform PEM

if [[ -f "$refind_grub" ]]; then
    signed_refind="$(mktemp)"
    info "Signing $refind_grub with the same akmods MOK key used for NVIDIA modules"
    sudo sbsign --key "$private_key" --cert "$pem_cert" --output "$signed_refind" "$refind_grub"
    sudo install -m 0644 "$signed_refind" "$refind_grub"
    rm -f "$signed_refind"
else
    warn "$refind_grub was not found; skipping rEFInd GRUB driver signing."
fi

info "Building NVIDIA kernel modules for the running kernel; these modules use the same MOK key"
sudo akmods --force --kernels "$(uname -r)"

info "Regenerating initramfs"
sudo dracut --force

cat <<'MESSAGE'

Next, import the shared NVIDIA/rEFInd key into MOK. mokutil will ask you to create a one-time password.
Use something very easy to remember and type on the blue MOK screen, for example a single letter.
You only need it once during the next reboot, but you must remember exactly what you entered.

After reboot, the blue MOK Manager screen should appear. Choose:

Enroll MOK -> Continue -> Yes -> enter the one-time password -> Reboot

MESSAGE

sudo mokutil --import "$der_cert"
EOF
    chmod 755 "$helper_script"
    chown "$USERNAME:$USERNAME" "$helper_script"

    log_success "Shared NVIDIA/rEFInd MOK signing helper written to $helper_script"
}

configure_flatpak_apps() {
    if ! command -v flatpak >/dev/null 2>&1; then
        log_warning "flatpak command not found; skipping Flatpak app setup"
        return 0
    fi

    log_info "Configuring Flathub remote and installing Flatpak apps"

    # Add Flathub at the system level so every user (including greetd)
    # sees the same remotes. --if-not-exists keeps re-runs idempotent.
    if ! flatpak remote-add --if-not-exists --system flathub \
            https://flathub.org/repo/flathub.flatpakrepo; then
        log_warning "Could not add the Flathub remote; skipping Flatpak app install"
        return 0
    fi

    # pwvucontrol — PipeWire volume control. Upstream only officially
    # supports Flatpak, which is why this is not installed via dnf.
    # -y assumes yes, --noninteractive avoids the "1. platform 2. app" prompt.
    if ! flatpak install --system --noninteractive -y flathub com.saivert.pwvucontrol; then
        log_warning "Could not install pwvucontrol from Flathub"
    else
        log_success "pwvucontrol installed from Flathub"
    fi
}

write_dark_mode_preferences() {
    local env_dir="$USER_HOME/.config/environment.d"
    local gtk3_dir="$USER_HOME/.config/gtk-3.0"
    local gtk4_dir="$USER_HOME/.config/gtk-4.0"
    local qt5ct_dir="$USER_HOME/.config/qt5ct"
    local qt6ct_dir="$USER_HOME/.config/qt6ct"

    log_info "Writing dark-mode preferences for GTK, libadwaita, Qt, and Wayland apps"

    ensure_user_owned_dir "$env_dir"
    cat > "$env_dir/90-dark-mode.conf" <<'EOF'
# Managed by setup-config: prefer dark UI across Wayland toolkits.
GTK_THEME=Adwaita:dark
GTK_APPLICATION_PREFER_DARK_THEME=1
ADW_DISABLE_PORTAL=1
QT_QPA_PLATFORM=wayland;xcb
QT_QPA_PLATFORMTHEME=qt6ct
QT_QUICK_CONTROLS_STYLE=Fusion
ELECTRON_OZONE_PLATFORM_HINT=wayland
MOZ_ENABLE_WAYLAND=1
SDL_VIDEODRIVER=wayland
CLUTTER_BACKEND=wayland
GTK_USE_PORTAL=1
TERMINAL=wezterm
EOF

    ensure_user_owned_dir "$gtk3_dir"
    cat > "$gtk3_dir/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Adwaita
gtk-font-name=Iosevka 11
EOF

    ensure_user_owned_dir "$gtk4_dir"
    cat > "$gtk4_dir/settings.ini" <<'EOF'
[Settings]
gtk-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
gtk-icon-theme-name=Adwaita
gtk-font-name=Iosevka 11
EOF

    ensure_user_owned_dir "$qt5ct_dir"
    cat > "$qt5ct_dir/qt5ct.conf" <<'EOF'
[Appearance]
color_scheme_path=/usr/share/qt5ct/colors/darker.conf
custom_palette=false
icon_theme=Adwaita
standard_dialogs=default
style=Fusion

[Fonts]
fixed="Iosevka Nerd Font Mono,11,-1,5,50,0,0,0,0,0"
general="Iosevka,11,-1,5,50,0,0,0,0,0"
EOF

    ensure_user_owned_dir "$qt6ct_dir"
    cat > "$qt6ct_dir/qt6ct.conf" <<'EOF'
[Appearance]
color_scheme_path=/usr/share/qt6ct/colors/darker.conf
custom_palette=false
icon_theme=Adwaita
standard_dialogs=default
style=Fusion

[Fonts]
fixed="Iosevka Nerd Font Mono,11,-1,5,50,0,0,0,0,0"
general="Iosevka,11,-1,5,50,0,0,0,0,0"
EOF

    chown -R "$USERNAME:$USERNAME" "$env_dir" "$gtk3_dir" "$gtk4_dir" "$qt5ct_dir" "$qt6ct_dir"

    run_as_user dbus-run-session gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
    run_as_user dbus-run-session gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark >/dev/null 2>&1 || true
    run_as_user dbus-run-session gsettings set org.gnome.desktop.interface icon-theme Adwaita >/dev/null 2>&1 || true

    log_success "Dark-mode preferences written"
}

setup_user_dotfiles() {
    log_info "Copying shared dotfiles to $USER_DOTFILES_DIR"
    ensure_user_owned_dir "$USER_DOTFILES_DIR"

    for package in "${SHARED_DOTFILE_PACKAGES[@]}"; do
        if [[ "$package" == "niri" && "$MANAGE_NIRI_DOTFILES" -eq 0 ]]; then
            log_info "Skipping shared niri package copy to preserve the existing session config"
            continue
        fi

        if [[ -d "$SHARED_DOTFILES_DIR/$package" ]]; then
            install -d "$USER_DOTFILES_DIR/$package"
            rsync -a --update "$SHARED_DOTFILES_DIR/$package/" "$USER_DOTFILES_DIR/$package/"
            chown -R "$USERNAME:$USERNAME" "$USER_DOTFILES_DIR/$package"
        fi
    done

    ensure_user_controls_dotfiles_tree
    log_success "Shared dotfiles copied"
}

stow_package() {
    local package="$1"
    local target="${2:-$USER_HOME}"

    if [[ "$package" == "niri" && "$MANAGE_NIRI_DOTFILES" -eq 0 ]]; then
        log_info "Skipping stow for niri to preserve the existing session config"
        return 0
    fi

    if [[ ! -d "$USER_DOTFILES_DIR/$package" ]]; then
        log_warning "Package '$package' was not found in $USER_DOTFILES_DIR"
        return 0
    fi

    ensure_user_controls_dotfiles_tree
    ensure_user_owned_dir "$target"

    log_info "Stowing $package into $target"
    run_as_user stow --dir="$USER_DOTFILES_DIR" --target="$target" --adopt "$package" >/dev/null 2>&1 || true
    run_as_user stow --dir="$USER_DOTFILES_DIR" --target="$target" --restow --no-folding "$package"
    log_success "$package stowed"
}

install_oh_my_zsh() {
    local omz_dir="$USER_HOME/.oh-my-zsh"

    if [[ -d "$omz_dir" ]]; then
        log_success "Oh My Zsh is already installed"
        return
    fi

    log_info "Installing Oh My Zsh"
    run_as_user git clone https://github.com/ohmyzsh/ohmyzsh.git "$omz_dir"
    log_success "Oh My Zsh installed"
}

install_zsh_plugins() {
    local zsh_custom="$USER_HOME/.oh-my-zsh/custom"

    if [[ -d "$zsh_custom/plugins/zsh-autosuggestions" ]]; then
        log_success "zsh-autosuggestions is already installed"
    else
        log_info "Installing zsh-autosuggestions"
        run_as_user git clone https://github.com/zsh-users/zsh-autosuggestions "$zsh_custom/plugins/zsh-autosuggestions"
    fi

    if [[ -d "$zsh_custom/plugins/zsh-syntax-highlighting" ]]; then
        log_success "zsh-syntax-highlighting is already installed"
    else
        log_info "Installing zsh-syntax-highlighting"
        run_as_user git clone https://github.com/zsh-users/zsh-syntax-highlighting "$zsh_custom/plugins/zsh-syntax-highlighting"
    fi
}

install_terminal_font() {
    local font_dir="$USER_HOME/.local/share/fonts"
    local font_archive_url="https://github.com/ryanoasis/nerd-fonts/releases/latest/download/Iosevka.tar.xz"
    local build_dir archive_path

    if fc-list : family 2>/dev/null | grep -Fqi "Iosevka Nerd Font"; then
        log_success "Iosevka Nerd Font is already installed"
        return
    fi

    log_info "Installing Iosevka Nerd Font for WezTerm and Yazi icons"
    ensure_user_owned_dir "$font_dir"

    build_dir="$(mktemp -d)"
    archive_path="$build_dir/Iosevka.tar.xz"

    curl -fsSL "$font_archive_url" -o "$archive_path"
    tar -xJf "$archive_path" -C "$build_dir"

    find "$build_dir" -type f \( -name '*.ttf' -o -name '*.otf' \) -exec install -m 0644 -o "$USERNAME" -g "$USERNAME" -t "$font_dir" {} +
    run_as_user fc-cache -f "$font_dir" >/dev/null 2>&1 || fc-cache -f "$font_dir" >/dev/null 2>&1 || true

    rm -rf "$build_dir"
    log_success "Iosevka Nerd Font installed"
}

set_default_shell() {
    local zsh_path
    zsh_path="$(command -v zsh)"

    if [[ -z "$zsh_path" ]]; then
        log_warning "zsh not found in PATH, skipping default shell update"
        return
    fi

    if ! grep -Fxq "$zsh_path" /etc/shells; then
        echo "$zsh_path" >> /etc/shells
    fi

    if ! chsh -s "$zsh_path" "$USERNAME"; then
        log_warning "Failed to set zsh as the default shell"
        return
    fi

    log_success "Default shell set to zsh"
}

install_repo_zsh_profile() {
    local source_zshrc="$USER_DOTFILES_DIR/zsh/.zshrc"
    local target_zshrc="$USER_HOME/.zshrc"
    local backup_path

    if [[ ! -f "$source_zshrc" ]]; then
        log_warning "Repo zsh profile not found at $source_zshrc"
        return
    fi

    if [[ -f "$target_zshrc" ]] && ! grep -q "# Managed by setup-config" "$target_zshrc"; then
        backup_path="$target_zshrc.backup.$(date +%Y%m%d%H%M%S)"
        cp "$target_zshrc" "$backup_path"
        chown "$USERNAME:$USERNAME" "$backup_path"
        log_info "Backed up existing .zshrc to $backup_path"
    fi

    install -m 0644 -o "$USERNAME" -g "$USERNAME" "$source_zshrc" "$target_zshrc"
    log_success ".zshrc installed"
}

install_repo_zsh_custom_plugin() {
    local source_plugin_dir="$USER_DOTFILES_DIR/zsh/.oh-my-zsh/custom/plugins/inaya"
    local target_plugin_dir="$USER_HOME/.oh-my-zsh/custom/plugins/inaya"
    local old_plugin_dir="$USER_HOME/.oh-my-zsh/custom/plugins/zieds"

    if [[ ! -d "$source_plugin_dir" ]]; then
        log_warning "Repo zsh plugin not found at $source_plugin_dir"
        return
    fi

    ensure_user_owned_dir "$USER_HOME/.oh-my-zsh/custom/plugins"
    if [[ -f "$old_plugin_dir/zieds.plugin.zsh" ]] && grep -q "Zied's Oh My Zsh plugin" "$old_plugin_dir/zieds.plugin.zsh"; then
        rm -rf "$old_plugin_dir"
    fi
    install -d -o "$USERNAME" -g "$USERNAME" "$target_plugin_dir"
    rsync -a --delete "$source_plugin_dir/" "$target_plugin_dir/"
    chown -R "$USERNAME:$USERNAME" "$target_plugin_dir"
    log_success "Custom zsh plugin installed"
}

install_repo_zsh_custom_theme() {
    local source_theme_dir="$USER_DOTFILES_DIR/zsh/.oh-my-zsh/custom/themes"
    local target_theme_dir="$USER_HOME/.oh-my-zsh/custom/themes"

    if [[ ! -d "$source_theme_dir" ]]; then
        log_warning "Repo zsh themes not found at $source_theme_dir"
        return
    fi

    ensure_user_owned_dir "$target_theme_dir"
    rsync -a --delete "$source_theme_dir/" "$target_theme_dir/"
    chown -R "$USERNAME:$USERNAME" "$target_theme_dir"
    log_success "Custom zsh themes installed"
}

configure_shell_profile() {
    install_oh_my_zsh
    install_zsh_plugins
    install_repo_zsh_profile
    install_repo_zsh_custom_plugin
    install_repo_zsh_custom_theme
    set_default_shell
}

install_oh_my_tmux() {
    local oh_my_tmux_dir="$USER_HOME/.oh-my-tmux"

    if [[ -d "$oh_my_tmux_dir" ]]; then
        log_success "Oh My Tmux is already installed"
        return
    fi

    log_info "Installing Oh My Tmux"
    run_as_user git clone https://github.com/gpakosz/.tmux.git "$oh_my_tmux_dir"
    log_success "Oh My Tmux installed"
}

configure_tmux() {
    install_oh_my_tmux
    stow_package "tmux"
}

configure_yazi() {
    local source_dir="$USER_DOTFILES_DIR/yazi/.config/yazi/config"
    local target_dir="$USER_HOME/.config/yazi"
    local source_yazi_toml="$source_dir/yazi.toml"

    if [[ ! -d "$source_dir" ]]; then
        log_warning "Repo Yazi config not found at $source_dir"
        return
    fi

    log_info "Installing Yazi config into $target_dir"
    ensure_user_owned_dir "$target_dir"
    rsync -a "$source_dir/" "$target_dir/"
    chown -R "$USERNAME:$USERNAME" "$target_dir"

    if [[ ! -f "$source_yazi_toml" ]]; then
        log_warning "Repo Yazi config is missing yazi.toml; editor override was not installed"
    fi

    log_success "Yazi configured"
}

configure_core_shared_apps() {
    for package in "${CORE_STOW_PACKAGES[@]}"; do
        stow_package "$package"
    done

    if [[ -f "$USER_DOTFILES_DIR/kanata/.config/kanata/kanata-tray" ]]; then
        chmod 755 "$USER_DOTFILES_DIR/kanata/.config/kanata/kanata-tray"
    fi
}

configure_optional_user_apps() {
    for package in "${OPTIONAL_STOW_PACKAGES[@]}"; do
        stow_package "$package"
    done

    configure_tmux
    configure_yazi
}

run_optional_task() {
    local description="$1"
    shift

    if "$@"; then
        return 0
    fi

    log_warning "$description failed; continuing because it is optional"
    return 0
}

remove_duplicate_terminals() {
    local -a duplicate_terminals=(foot alacritty alacrity)
    local -a installed=()
    local package

    for package in "${duplicate_terminals[@]}"; do
        if rpm -q "$package" >/dev/null 2>&1; then
            installed+=("$package")
        fi
    done

    if [[ "${#installed[@]}" -eq 0 ]]; then
        log_success "No duplicate terminal packages found"
        return 0
    fi

    log_info "Removing duplicate terminal packages: ${installed[*]}"
    dnf remove -y "${installed[@]}"
    log_success "Duplicate terminal packages removed; WezTerm remains the configured terminal"
}

write_boot_order_guard() {
    log_info "Installing EFI boot-order guard"

    install -d /usr/local/sbin

    cat > /usr/local/sbin/ensure-primary-efi-entry <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

info() { echo "[efi-boot-order-guard] $*"; }
warn() { echo "[efi-boot-order-guard] $*" >&2; }

if [[ ! -d /sys/firmware/efi ]]; then
    info "Legacy BIOS detected, nothing to do."
    exit 0
fi

if ! command -v efibootmgr >/dev/null 2>&1; then
    warn "efibootmgr is not installed."
    exit 1
fi

find_refind_entry() {
    efibootmgr -v | awk '
        BEGIN { IGNORECASE=1 }
        /^Boot[0-9A-Fa-f]{4}\*?[[:space:]]+.*rEFInd/ ||
        (/^Boot[0-9A-Fa-f]{4}\*?[[:space:]]+/ && $0 ~ /\\\\EFI\\\\refind\\\\/) {
            match($0, /^Boot[0-9A-Fa-f]{4}/)
            print substr($0, 5, 4)
            exit
        }
    '
}

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

refind_bootnum="$(find_refind_entry || true)"
fedora_bootnum="$(find_fedora_entry || true)"
preferred_bootnum="$refind_bootnum"
preferred_label="rEFInd"

if [[ -z "$preferred_bootnum" ]]; then
    preferred_bootnum="$fedora_bootnum"
    preferred_label="Fedora"
fi

if [[ -z "$preferred_bootnum" ]]; then
    warn "No rEFInd or Fedora UEFI entry was found."
    exit 1
fi

current_order="$(efibootmgr | awk -F'BootOrder: ' '/BootOrder:/ {print $2}' | tr -d '[:space:]')"
if [[ -z "$current_order" ]]; then
    warn "Could not read the current BootOrder."
    exit 1
fi

IFS=',' read -r -a entries <<< "$current_order"
new_entries=("${preferred_bootnum^^}")

for entry in "${entries[@]}"; do
    entry="${entry^^}"
    [[ -z "$entry" || "$entry" == "${preferred_bootnum^^}" ]] && continue
    new_entries+=("$entry")
done

if [[ "${entries[0]^^}" == "${preferred_bootnum^^}" ]]; then
    info "$preferred_label is already first in BootOrder."
    exit 0
fi

new_order="$(IFS=,; echo "${new_entries[*]}")"
info "Setting BootOrder to $new_order"
efibootmgr -o "$new_order" >/dev/null
EOF

    chmod 755 /usr/local/sbin/ensure-primary-efi-entry

    cat > /etc/systemd/system/efi-boot-order-guard.service <<'EOF'
[Unit]
Description=Keep the preferred EFI boot entry first in UEFI BootOrder
After=local-fs.target
ConditionPathExists=/sys/firmware/efi

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/ensure-primary-efi-entry

[Install]
WantedBy=multi-user.target
EOF

    if systemctl list-unit-files fedora-grub-protector.service >/dev/null 2>&1; then
        systemctl disable --now fedora-grub-protector.service >/dev/null 2>&1 || true
        rm -f /etc/systemd/system/fedora-grub-protector.service /usr/local/sbin/ensure-fedora-grub-first
    fi

    systemctl daemon-reload
    /usr/local/sbin/ensure-primary-efi-entry || log_warning "Could not update UEFI BootOrder automatically"
    log_success "EFI boot-order guard installed"
}

write_session() {
    log_info "Writing Niri session files"

    install -d /usr/local/bin

    cat > /usr/local/bin/niri-session <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=niri
export GTK_USE_PORTAL=1

export GTK_THEME=Adwaita:dark
export GTK_APPLICATION_PREFER_DARK_THEME=1
export ADW_DISABLE_PORTAL=1
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland
export QT_QPA_PLATFORM='wayland;xcb'
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_QUICK_CONTROLS_STYLE=Fusion
export SDL_VIDEODRIVER=wayland
export CLUTTER_BACKEND=wayland
export TERMINAL=wezterm

systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS || true
dbus-update-activation-environment --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DBUS_SESSION_BUS_ADDRESS || true

exec niri
EOF

    chmod +x /usr/local/bin/niri-session
    ln -sfn /usr/local/bin/niri-session /usr/local/bin/Niri

    install -d /usr/share/wayland-sessions

    cat > /usr/share/wayland-sessions/niri.desktop <<'EOF'
[Desktop Entry]
Name=Niri
Comment=Launch Niri
Exec=/usr/local/bin/niri-session
Type=Application
DesktopNames=sway
EOF

    log_success "Session files written"
}

write_greeter_session() {
    log_info "Writing gtkgreet session wrapper"

    install -d /usr/local/bin

    cat > /usr/local/bin/gtkgreet-session <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cleanup() {
    niri msg action quit --skip-confirmation >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

env GTK_THEME=Adwaita:dark GTK_APPLICATION_PREFER_DARK_THEME=1 ADW_DISABLE_PORTAL=1 gtkgreet --layer-shell --command /usr/local/bin/niri-session
EOF

    cat > /usr/local/bin/greetd-axidev-osk <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

exec >>/tmp/greetd-axidev-osk.log 2>&1
echo "=== $(date -Is) greetd-axidev-osk starting ==="

for plugin_root in \
    /usr/lib64/qt6/plugins \
    /usr/lib/qt6/plugins \
    /usr/local/lib64/qt6/plugins \
    /usr/local/lib/qt6/plugins
do
    if [[ -f "$plugin_root/wayland-shell-integration/liblayer-shell.so" ]]; then
        if [[ -n "${QT_PLUGIN_PATH:-}" ]]; then
            export QT_PLUGIN_PATH="$plugin_root:$QT_PLUGIN_PATH"
        else
            export QT_PLUGIN_PATH="$plugin_root"
        fi
        break
    fi
done

export QT_QPA_PLATFORM=wayland
export QT_QPA_PLATFORMTHEME=qt6ct
export QT_QUICK_CONTROLS_STYLE=Fusion
export QT_WAYLAND_SHELL_INTEGRATION=layer-shell
export GTK_THEME=Adwaita:dark
export GTK_APPLICATION_PREFER_DARK_THEME=1
export ADW_DISABLE_PORTAL=1
export AXIDEV_OSK_OVERLAY_BACKEND=wayland-layer-shell
export XDG_SESSION_TYPE=wayland

echo "QT_PLUGIN_PATH=${QT_PLUGIN_PATH:-}"
echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-}"
echo "XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-}"
echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-}"

if [[ -n "${XDG_RUNTIME_DIR:-}" && -n "${WAYLAND_DISPLAY:-}" ]]; then
    for _ in $(seq 1 100); do
        if [[ -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then
            break
        fi
        sleep 0.1
    done
fi

if [[ -n "${XDG_RUNTIME_DIR:-}" && -n "${WAYLAND_DISPLAY:-}" && ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then
    echo "Wayland socket did not appear at $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
fi

status=1
for attempt in 1 2 3 4 5; do
    echo "Launching axidev-osk (attempt $attempt)"
    set +e
    /usr/local/bin/axidev-osk
    status=$?
    set -e
    if [[ "$status" -eq 0 ]]; then
        exit 0
    fi
    echo "axidev-osk exited with status $status"
    sleep 1
done

echo "axidev-osk failed after retries; ending greeter compositor so greetd fallback can take over"
niri msg action quit --skip-confirmation >/dev/null 2>&1 || true

exit "$status"
EOF

    chmod +x /usr/local/bin/gtkgreet-session
    chmod +x /usr/local/bin/greetd-axidev-osk

    if command -v restorecon >/dev/null 2>&1; then
        restorecon -Fv /usr/local/bin/gtkgreet-session >/dev/null 2>&1 || true
        restorecon -Fv /usr/local/bin/greetd-axidev-osk >/dev/null 2>&1 || true
    fi

    log_success "gtkgreet session wrapper written"
}

configure_greetd() {
    log_info "Configuring greetd with gtkgreet on Niri"

    install -d /etc/greetd

    cat > /etc/greetd/config.toml <<EOF
[terminal]
vt = 1

[default_session]
command = "env GTK_USE_PORTAL=0 GDK_DEBUG=no-portals niri --config /etc/greetd/niri-config.kdl"
user = "$GREETER_USER"

[initial_session]
command = "/usr/local/bin/niri-session"
user = "$USERNAME"
EOF

    cat > /etc/greetd/niri-config.kdl <<'EOF'
spawn-sh-at-startup "/usr/local/bin/gtkgreet-session"
spawn-sh-at-startup "/usr/local/bin/greetd-axidev-osk"

hotkey-overlay {
    skip-at-startup
}
EOF

    cat > /etc/greetd/environments <<'EOF'
Niri
EOF

    log_success "greetd configured"
}

enable_services() {
    log_info "Enabling services"
    systemctl set-default graphical.target
    systemctl enable NetworkManager
    systemctl enable greetd
    systemctl enable efi-boot-order-guard.service
    log_success "Services enabled"
}

main() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║         Fedora Everything Minimal Niri Setup                  ║"
    echo "║                  (Powered by GNU Stow)                        ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""

    check_requirements
    install_bootstrap_dependencies
    detect_target_user
    decide_niri_dotfiles_management
    log_install_context
    configure_third_party_repos
    install_all_packages
    configure_system_locale
    configure_system_keyboard
    run_optional_task "Docker service setup" post_install_docker
    run_optional_task "Ollama installation" install_ollama
    run_optional_task "NVM and Node.js installation" install_nvm_and_node
    run_optional_task "Terminal font installation" install_terminal_font
    install_refind
    detect_greeter_user
    install_axidev_osk
    install_kanata
    setup_axidev_osk_permissions
    setup_kanata_permissions
    configure_audio_stack
    configure_networking
    configure_file_management
    configure_kde_connect
    configure_nvidia_stack
    configure_flatpak_apps
    write_dark_mode_preferences
    ensure_user_owns_home_tree
    setup_user_dotfiles
    write_session
    write_greeter_session
    configure_greetd
    write_boot_order_guard
    configure_shell_profile
    configure_core_shared_apps
    run_optional_task "Optional user tool configuration" configure_optional_user_apps
    enable_services
    ensure_user_owns_home_tree
    run_optional_task "Duplicate terminal cleanup" remove_duplicate_terminals

    echo ""
    log_success "Setup complete"
    echo "Dotfiles are stored in $USER_DOTFILES_DIR and linked with GNU Stow."
    echo "IMPORTANT: Before rebooting with Secure Boot, run: $USER_HOME/enroll-secure-boot-nvidia.sh"
    echo "IMPORTANT: That script uses one shared MOK key for NVIDIA modules and rEFInd; run it even on AMD-only systems if Secure Boot should trust rEFInd."
    echo "Reboot and enjoy your new Niri desktop environment! If you want to customize further, add files to the appropriate package directories in $USER_DOTFILES_DIR and run stow again."
    echo ""
}

main "$@"
