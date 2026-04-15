$ErrorActionPreference = 'Stop'

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw 'Run this script from an elevated PowerShell session.'
}

Write-Host 'Pointing Windows Boot Manager to Fedora shim...'
& bcdedit /set '{bootmgr}' path '\EFI\fedora\shimx64.efi'

Write-Host 'Windows Boot Manager now chainloads Fedora GRUB via shimx64.efi.'
