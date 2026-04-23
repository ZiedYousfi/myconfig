#!/bin/bash
set -euo pipefail

# Fedora Everything Niri Setup Script
# Installs a minimal Wayland desktop based on Niri, greetd, gtkgreet, and shared repo dotfiles.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SHARED_DOTFILES_DIR="$REPO_ROOT/dotfiles"
AXIDEV_OSK_RELEASE_API="https://api.github.com/repos/axide-dev/axidev-osk/releases/latest"
AXIDEV_OSK_INSTALL_DIR="/opt/axidev-osk"
AXIDEV_OSK_BIN="/usr/local/bin/axidev-osk"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SHARED_DOTFILE_PACKAGES=(
    foot
    fuzzel
    lazygit
    mako
    niri
    nvim
    tmux
    waybar
    wezterm
    yazi
    zsh
)

CORE_STOW_PACKAGES=(
    foot
    fuzzel
    mako
    niri
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

    for cmd in dnf systemctl systemd-tmpfiles install getent id cut efibootmgr findmnt lsblk mktemp; do
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

confirm_continue() {
    echo ""
    echo "User: $USERNAME"
    echo "Home: $USER_HOME"
    echo "Dotfiles: $USER_DOTFILES_DIR"
    if [[ "$MANAGE_NIRI_DOTFILES" -eq 0 ]]; then
        echo "Niri session config: keep existing ~/.config/niri/config.kdl"
    fi
    echo ""

    read -rp "Continue? (y/N): " confirm
    [[ "$confirm" == "y" || "$confirm" == "Y" ]] || exit 0
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

run_as_user() {
    runuser -u "$USERNAME" -- "$@"
}

enable_third_party_repos() {
    log_info "Enabling third-party repositories for Yazi, WezTerm, Codex, and T3 Code"
    if ! dnf -y copr enable lihaohong/yazi; then
        log_warning "Could not enable the Yazi COPR; continuing without it"
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

    log_success "Third-party repository setup finished"
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

install_core_packages() {
    log_info "Refreshing DNF metadata"
    dnf makecache -y

    log_info "Installing core Fedora packages required for boot and the Niri session"
    dnf install -y --skip-unavailable \
        dnf-plugins-core \
        grub2-efi-x64 \
        grub2-common \
        shim-x64 \
        efibootmgr \
        rEFInd \
        git \
        curl \
        wget \
        rsync \
        stow \
        zsh \
        tar \
        unzip \
        xz \
        fontconfig \
        kmod \
        NetworkManager \
        greetd \
        gtkgreet \
        niri \
        layer-shell-qt \
        waybar \
        foot \
        fuzzel \
        mako \
        grim \
        slurp \
        wl-clipboard \
        pipewire \
        wireplumber \
        xdg-desktop-portal \
        xdg-desktop-portal-gtk \
        brightnessctl \
        playerctl \
        fd-find \
        ripgrep \
        fzf \
        zoxide \
        jq \
        less \
        file

    log_success "Core packages installed"
}

install_optional_user_tools() {
    log_info "Installing optional user tools"
    enable_third_party_repos

    dnf install -y --skip-unavailable \
        neovim \
        tmux \
        lazygit \
        eza \
        bat \
        fastfetch \
        yazi \
        wezterm \
        btop \
        tokei \
        tree-sitter-cli \
        python3 \
        golang \
        rustup \
        nvm \
        java-latest-openjdk-devel \
        maven \
        gcc \
        llvm \
        cmake \
        make \
        meson \
        conan \
        zig \
        ffmpeg \
        p7zip \
        p7zip-plugins \
        7zip \
        7zip-plugins \
        poppler-utils \
        resvg \
        ImageMagick \
        blender \
        krita \
        kdenlive \
        codex \
        t3code

    log_success "Optional user tools installed"
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

configure_docker_repo() {
    if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
        log_success "Docker repository is already configured"
        return 0
    fi

    log_info "Configuring Docker repository"
    if dnf config-manager addrepo --from-repofile=https://download.docker.com/linux/fedora/docker-ce.repo; then
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

install_docker() {
    configure_docker_repo || return 1

    log_info "Installing Docker"
    dnf install -y --skip-unavailable \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    groupadd -f docker
    usermod -aG docker "$USERNAME"
    systemctl enable --now docker || log_warning "Docker was installed, but the service could not be enabled"
    log_success "Docker installed"
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

install_desktop_apps() {
    local arch
    arch="$(uname -m)"

    configure_1password_repo

    log_info "Installing 1Password"
    dnf install -y --skip-unavailable 1password 1password-cli
    log_success "1Password installed"

    if [[ "$arch" == "x86_64" ]]; then
        log_info "Installing Google Chrome"
        dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
        log_success "Google Chrome installed"
    else
        log_warning "Google Chrome is only configured for x86_64 in this installer; detected architecture: $arch"
    fi
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
    log_success "rEFInd installed"
}

install_axidev_osk() {
    local arch release_json version download_url expected_digest expected_sha actual_sha
    local tmp_dir archive_path extracted_dir

    arch="$(uname -m)"
    if [[ "$arch" != "x86_64" ]]; then
        log_error "Axidev OSK only publishes a linux-x64 bundle right now; detected architecture: $arch"
    fi

    log_info "Resolving latest Axidev OSK Linux release"
    release_json="$(curl -fsSL "$AXIDEV_OSK_RELEASE_API")"
    version="$(jq -r '.tag_name // empty' <<< "$release_json")"
    download_url="$(jq -r '.assets[] | select(.name | test("linux-x64\\.zip$")) | .browser_download_url' <<< "$release_json" | head -n1)"
    expected_digest="$(jq -r '.assets[] | select(.name | test("linux-x64\\.zip$")) | .digest // empty' <<< "$release_json" | head -n1)"

    if [[ -z "$version" || -z "$download_url" ]]; then
        log_error "Could not find a Linux x64 Axidev OSK release asset."
    fi

    if [[ -x "$AXIDEV_OSK_INSTALL_DIR/axidev-osk" && -f "$AXIDEV_OSK_INSTALL_DIR/.version" ]] &&
        [[ "$(cat "$AXIDEV_OSK_INSTALL_DIR/.version")" == "$version" ]]; then
        ln -sfn "$AXIDEV_OSK_INSTALL_DIR/axidev-osk" "$AXIDEV_OSK_BIN"
        log_success "Axidev OSK $version is already installed"
        return
    fi

    log_info "Downloading Axidev OSK $version"
    tmp_dir="$(mktemp -d)"
    archive_path="$tmp_dir/axidev-osk-linux-x64.zip"
    extracted_dir="$tmp_dir/extracted"

    curl -fL "$download_url" -o "$archive_path"

    if [[ "$expected_digest" == sha256:* ]]; then
        expected_sha="${expected_digest#sha256:}"
        actual_sha="$(sha256sum "$archive_path" | awk '{print $1}')"
        if [[ "$actual_sha" != "$expected_sha" ]]; then
            rm -rf "$tmp_dir"
            log_error "Axidev OSK archive checksum mismatch."
        fi
    else
        log_warning "No SHA-256 digest was published for this Axidev OSK asset; skipping checksum verification."
    fi

    install -d "$extracted_dir"
    unzip -q "$archive_path" -d "$extracted_dir"

    if [[ ! -x "$extracted_dir/axidev-osk/axidev-osk" ]]; then
        rm -rf "$tmp_dir"
        log_error "Downloaded Axidev OSK archive did not contain the expected executable."
    fi

    if [[ "$AXIDEV_OSK_INSTALL_DIR" != "/opt/axidev-osk" ]]; then
        rm -rf "$tmp_dir"
        log_error "Refusing to replace unexpected Axidev OSK install directory: $AXIDEV_OSK_INSTALL_DIR"
    fi

    rm -rf -- "$AXIDEV_OSK_INSTALL_DIR"
    install -d "$(dirname "$AXIDEV_OSK_INSTALL_DIR")"
    mv "$extracted_dir/axidev-osk" "$AXIDEV_OSK_INSTALL_DIR"
    printf '%s\n' "$version" > "$AXIDEV_OSK_INSTALL_DIR/.version"
    chown -R root:root "$AXIDEV_OSK_INSTALL_DIR"
    chmod +x "$AXIDEV_OSK_INSTALL_DIR/axidev-osk" "$AXIDEV_OSK_INSTALL_DIR/setup_uinput_permissions.sh"
    ln -sfn "$AXIDEV_OSK_INSTALL_DIR/axidev-osk" "$AXIDEV_OSK_BIN"
    rm -rf "$tmp_dir"

    if command -v restorecon >/dev/null 2>&1; then
        restorecon -RFv "$AXIDEV_OSK_INSTALL_DIR" "$AXIDEV_OSK_BIN" >/dev/null 2>&1 || true
    fi

    log_success "Axidev OSK $version installed"
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

write_greeter_session() {
    log_info "Writing gtkgreet session wrapper"

    install -d /usr/local/bin

    cat > /usr/local/bin/gtkgreet-session <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

keyboard_pid=""

cleanup() {
    if [[ -n "$keyboard_pid" ]]; then
        kill "$keyboard_pid" >/dev/null 2>&1 || true
        wait "$keyboard_pid" 2>/dev/null || true
    fi

    niri msg action quit --skip-confirmation >/dev/null 2>&1 || true
}

trap cleanup EXIT INT TERM

QT_QPA_PLATFORM=wayland /usr/local/bin/axidev-osk >/dev/null 2>&1 &
keyboard_pid="$!"

env GTK_THEME=Adwaita:dark gtkgreet --layer-shell --command /usr/local/bin/niri-session
EOF

    chmod +x /usr/local/bin/gtkgreet-session

    if command -v restorecon >/dev/null 2>&1; then
        restorecon -Fv /usr/local/bin/gtkgreet-session >/dev/null 2>&1 || true
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
EOF

    cat > /etc/greetd/niri-config.kdl <<'EOF'
spawn-sh-at-startup "/usr/local/bin/gtkgreet-session"

hotkey-overlay {
    skip-at-startup
}
EOF

    cat > /etc/greetd/environments <<'EOF'
/usr/local/bin/niri-session
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
    confirm_continue
    install_core_packages
    run_optional_task "Optional user tool installation" install_optional_user_tools
    install_desktop_apps
    run_optional_task "Docker installation" install_docker
    run_optional_task "Ollama installation" install_ollama
    run_optional_task "NVM and Node.js installation" install_nvm_and_node
    run_optional_task "Terminal font installation" install_terminal_font
    install_refind
    detect_greeter_user
    install_axidev_osk
    setup_axidev_osk_permissions
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

    echo ""
    log_success "Setup complete"
    echo "Dotfiles are stored in $USER_DOTFILES_DIR and linked with GNU Stow."
    echo "Reboot and enjoy your new Niri desktop environment! If you want to customize further, add files to the appropriate package directories in $USER_DOTFILES_DIR and run stow again."
    echo ""
}

main "$@"
