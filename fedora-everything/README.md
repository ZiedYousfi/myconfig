# Fedora Everything Minimal Niri Setup

This target installs a small Fedora desktop based on `niri`, `greetd`, and `tuigreet`.

## Intended Install Flow

1. Install Fedora using the Everything (netinstall) ISO.
2. Choose a minimal install without GNOME or KDE.
3. Create your normal user during installation.
4. Boot into the new system.
5. Run the installer as root:

```bash
sudo bash install.sh
```

You can also run it through the repo bootstrap:

```bash
curl -fsSL https://raw.githubusercontent.com/ZiedYousfi/myconfig/main/bootstrap.sh | bash -s -- fedora
```

## What It Configures

- Installs `grub2-efi-x64`, `shim-x64`, and `efibootmgr`
- Installs `niri` and a minimal Wayland desktop stack
- Creates `/usr/local/bin/niri-session`
- Registers a `niri.desktop` wayland session
- Configures `greetd` to launch `tuigreet`
- Installs a `fedora-grub-protector.service` that keeps the Fedora UEFI entry first
- Creates a minimal per-user `~/.config/niri/config.kdl` if one does not exist
- Enables `NetworkManager` and `greetd`

## Notes

- Existing `~/.config/niri/config.kdl` is preserved.
- The script expects to be run on Fedora with `dnf` and `systemd`.
- For dual-boot systems with Windows, [grub-protector.ps1](grub-protector.ps1) can be run as Administrator in Windows to make Windows Boot Manager chainload Fedora's `shimx64.efi`.
- After the script finishes, reboot and log in through `greetd`.
