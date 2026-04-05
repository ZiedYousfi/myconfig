# This script is made to force windows to boot on grub
bcdedit /set '{bootmgr}' path '\EFI\GRUB\grubx64.efi'
