# rEFInd

Source-of-truth rEFInd configuration for the Fedora target.

This package is **not** stowed. rEFInd lives on the EFI System Partition
(ESP), which is FAT32 and mounted at `/boot/efi`, so symlinks from `$HOME`
would not work even if we wanted them to. Instead, the Fedora installer
(`fedora-everything/install.sh`) reads the files in this directory and
copies them onto the ESP under `/boot/efi/EFI/refind/`.

## Layout

```
dotfiles/refind/
├── README.md
├── global.conf                         # global overrides (mouse, etc.)
└── themes/
    └── black-pink/
        ├── theme.conf                  # the theme include file
        └── generate-theme-assets.sh    # regenerates banner + selection PNGs
```

## What goes where

| Repo path                                              | Installed path on the ESP                                       |
| ------------------------------------------------------ | --------------------------------------------------------------- |
| `dotfiles/refind/global.conf`                          | `/boot/efi/EFI/refind/managed.conf` (included from `refind.conf`) |
| `dotfiles/refind/themes/black-pink/theme.conf`         | `/boot/efi/EFI/refind/themes/black-pink/theme.conf`             |
| PNGs produced by `generate-theme-assets.sh`            | `/boot/efi/EFI/refind/themes/black-pink/{banner,selection_*}.png` |

Both snippets are wired into `refind.conf` via `include` directives, so
the only lines the installer adds to `refind.conf` itself are two managed
`# Managed by setup-config: …` markers each followed by a single
`include …` line. This keeps the live `refind.conf` close to upstream and
makes it easy to inspect or roll back.

The installer re-runs the asset generator each time, so editing colours or
sizes in `generate-theme-assets.sh` is enough to refresh the PNGs on the
next install.

## How to change the configuration

1. Edit the relevant file in this directory:
   - To toggle mouse support, change pointer size/speed, or add other
     rEFInd-wide options, edit `global.conf`.
   - To tweak the theme layout (banner scale, hidden UI elements,
     `showtools`, etc.), edit `themes/black-pink/theme.conf`.
   - To change the theme colours or image sizes, edit
     `themes/black-pink/generate-theme-assets.sh`.
2. Re-run the Fedora installer (or just the rEFInd portion of it) so the
   files are copied back onto the ESP:

   ```bash
   sudo bash fedora-everything/install.sh
   ```

   The installer is idempotent for these files — it removes the previously
   "Managed by setup-config" blocks from `refind.conf` before re-appending
   them, and overwrites the theme assets and `managed.conf` in place.

## Why the theme stays minimal

`theme.conf` deliberately does **not** set `showtools` or `scanfor`. The
stock `refind.conf` shipped by Fedora already provides a reasonable
`showtools` line, and re-declaring it from a theme include produced
visible duplicate icons on the second row (two reboot icons, two
shutdown icons, two "reboot to firmware" icons). Letting the stock
config own those tokens fixes the duplication.

If you want to customise the second-row tools or the scan sources,
edit `/boot/efi/EFI/refind/refind.conf` directly (or extend this
theme's snippet) — just don't set the same token in two places.

## Direct on-host editing

If you want to iterate on a running machine without re-running the full
installer, the live files are at:

- `/boot/efi/EFI/refind/refind.conf`
- `/boot/efi/EFI/refind/managed.conf`
- `/boot/efi/EFI/refind/themes/black-pink/theme.conf`
- `/boot/efi/EFI/refind/themes/black-pink/*.png`

Any changes there will be overwritten the next time `install.sh` runs, so
remember to backport edits you want to keep into this directory.
