# Altair (EndevourOS) System Setup Guide

This guide covers system-level setup that needs to be done outside of Nix/home-manager.

## System Package Installation

Since you're running home-manager on EndevourOS (not NixOS), some packages need to be installed via pacman:

### CUPS Printing

```bash
# Install CUPS and drivers
sudo pacman -S cups cups-pdf

# Common printer drivers
sudo pacman -S \
  hplip \              # HP printers
  gutenprint \         # Wide driver support
  foomatic-db \        # Driver database
  foomatic-db-engine \ # Driver engine
  foomatic-db-nonfree  # Additional drivers

# Enable and start CUPS
sudo systemctl enable --now cups.service

# Add user to lp group
sudo usermod -aG lp $USER

# Configure printer (after logging out/in)
system-config-printer
```

### Wayland/X11 Support

EndevourOS uses GNOME with Wayland by default. Some Nix packages may have issues:

#### Fix Alacritty on Wayland

Option 1: Use system alacritty
```bash
sudo pacman -S alacritty
```

Option 2: Use another terminal from Nix that works well on Wayland
```bash
# Add to your home.nix packages:
# kitty    # Good Wayland support
# foot     # Native Wayland terminal
# wezterm  # Cross-platform with Wayland
```

Option 3: Force X11 mode (not recommended)
```bash
WAYLAND_DISPLAY= alacritty
```

### Samba for Network Printing

```bash
# Install Samba
sudo pacman -S samba

# Enable Samba service
sudo systemctl enable --now smb.service
```

## Display Server Notes

Your system is running:
- Display Server: **Wayland**
- Desktop Environment: **GNOME**

Some Nix packages may not have proper Wayland support. When this happens:

1. **Install from system package manager** (pacman) - recommended
2. **Use alternative packages** from Nix that support Wayland
3. **Force X11 compatibility mode** (may have issues)

## Recommended System Packages

These work better when installed via pacman on EndevourOS:

```bash
sudo pacman -S \
  cups cups-pdf \          # Printing
  alacritty \              # Terminal (better Wayland support)
  firefox \                # Browser (if not using Nix version)
  gnome-keyring \          # Credential storage
  seahorse                 # Keyring GUI
```

## After Installing System Packages

Some packages installed via pacman may conflict with Nix versions. To remove from Nix:

Edit `/home/efyis/projects/sysflake/hosts/altair/home.nix` and comment out:
```nix
# cups                    # Use system version
# system-config-printer   # Use system version
# alacritty               # If using system version
```

Then reapply:
```bash
nix run home-manager -- switch --flake .#altair
```

## Locale Configuration

Your home-manager config now sets English locale. To also set it system-wide:

```bash
# Edit /etc/locale.conf
sudo nano /etc/locale.conf

# Add:
LANG=en_US.UTF-8
LC_ALL=en_US.UTF-8

# Generate locales
sudo locale-gen
```

## Graphics Drivers

For better performance with GUI applications:

```bash
# For NVIDIA
sudo pacman -S nvidia nvidia-utils

# For AMD
sudo pacman -S mesa vulkan-radeon

# For Intel
sudo pacman -S mesa vulkan-intel
```

## Verify Setup

```bash
# Check CUPS
systemctl status cups
lpstat -p

# Check locale
locale

# Check display server
echo $XDG_SESSION_TYPE

# Test printer configuration
system-config-printer
```

## Troubleshooting

### "Unit cups.service not found"
→ Install cups via pacman: `sudo pacman -S cups`

### Alacritty display error
→ Install via pacman: `sudo pacman -S alacritty`
→ Or use kitty from Nix: Add `kitty` to home.packages

### Permission denied for printer
→ Add user to lp group: `sudo usermod -aG lp $USER`
→ Log out and back in

### Application won't start on Wayland
→ Try forcing X11: `WAYLAND_DISPLAY= application-name`
→ Or install system version via pacman
