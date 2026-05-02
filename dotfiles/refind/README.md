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
├── mouse.conf                          # snippet appended to refind.conf
└── themes/
    └── black-pink/
        ├── theme.conf                  # the theme include file
        └── generate-theme-assets.sh    # regenerates banner + selection PNGs
```

## What goes where

| Repo path                                              | Installed path on the ESP                                       |
| ------------------------------------------------------ | --------------------------------------------------------------- |
| `dotfiles/refind/mouse.conf`                           | appended into `/boot/efi/EFI/refind/refind.conf`                |
| `dotfiles/refind/themes/black-pink/theme.conf`         | `/boot/efi/EFI/refind/themes/black-pink/theme.conf`             |
| PNGs produced by `generate-theme-assets.sh`            | `/boot/efi/EFI/refind/themes/black-pink/{banner,selection_*}.png` |

The installer re-runs the asset generator each time, so editing colours or
sizes in `generate-theme-assets.sh` is enough to refresh the PNGs on the
next install.

## How to change the configuration

1. Edit the relevant file in this directory:
   - To toggle mouse support or change rEFInd-wide options, edit
     `mouse.conf` (or extend the installer to ship more snippets).
   - To tweak the theme layout (banner scale, hidden UI elements, etc.),
     edit `themes/black-pink/theme.conf`.
   - To change the theme colours or image sizes, edit
     `themes/black-pink/generate-theme-assets.sh`.
2. Re-run the Fedora installer (or just the rEFInd portion of it) so the
   files are copied back onto the ESP:

   ```bash
   sudo bash fedora-everything/install.sh
   ```

   The installer is idempotent for these files — it removes the previously
   "Managed by setup-config" blocks from `refind.conf` before re-appending
   them, and overwrites the theme assets in place.

## Direct on-host editing

If you want to iterate on a running machine without re-running the full
installer, the live files are at:

- `/boot/efi/EFI/refind/refind.conf`
- `/boot/efi/EFI/refind/themes/black-pink/theme.conf`
- `/boot/efi/EFI/refind/themes/black-pink/*.png`

Any changes there will be overwritten the next time `install.sh` runs, so
remember to backport edits you want to keep into this directory.
