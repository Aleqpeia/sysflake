# Sysflake Usage Guide

## Current Host Configuration

- **altair**: EndevourOS with home-manager (standalone mode)
- **proxima**: Standalone home-manager
- **vega**: Full NixOS system

## Quick Start

### New Machine (EndeavourOS/Arch/Fedora)

```bash
# 1. Install nix
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# 2. Clone repo
git clone git@github.com:YOUR_USER/sysflake.git ~/sysflake
cd ~/sysflake

# 3. Add host to registry (edit flake/home-manager.nix)
#    Add your hostname with mode = "standalone"

# 4. Apply
nix run home-manager/master -- switch --flake .#<hostname>
```

### Existing NixOS Machine

```bash
git clone git@github.com:YOUR_USER/sysflake.git ~/sysflake
cd ~/sysflake
sudo nixos-rebuild switch --flake .#<hostname>

# Example for vega (the NixOS machine):
sudo nixos-rebuild switch --flake .#vega
```

---

## Adding a New Host

### 1. Edit `flake/home-manager.nix`

```nix
hosts = {
  # ... existing hosts ...
  
  myhost = {
    system = "x86_64-linux";  # or "aarch64-linux"
    mode = "standalone";       # or "nixos"
    username = "efyis";
    profiles = [ "base" "dev" "gui" ];
  };
};
```

### 2. Create host config

```bash
mkdir -p hosts/myhost
```

**For standalone (Fedora/Arch/etc):** `hosts/myhost/home.nix`
```nix
{ hostname, ... }:
{
  home.sessionVariables.SYSCFG_HOST = hostname;
  systemd.user.startServices = "sd-switch";
  
  # Host-specific packages
  # home.packages = with pkgs; [ specific-tool ];
}
```

**For NixOS:** Also create `hosts/myhost/default.nix` and `hardware.nix`

### 3. Apply

```bash
# Standalone
nix run home-manager/master -- switch --flake .#myhost

# NixOS
sudo nixos-rebuild switch --flake .#myhost
```

---

## Daily Usage

### Sync Configuration

```bash
cd ~/syscfg
./scripts/sync.sh
```

### Check Status

```bash
./scripts/registry.py status
```

---

## Key Management

### SSH Keys

```bash
# First machine - generate shared + local keys
./scripts/ssh-setup.sh init

# Additional machines - local only
./scripts/ssh-setup.sh local

# Import shared keys from another machine
./scripts/ssh-setup.sh import ~/ssh-export
```

### GPG Keys

```bash
# First machine - generate keys
./scripts/gpg-setup.sh init

# Export for another machine
./scripts/gpg-setup.sh export ~/gpg-export

# On new machine - import
./scripts/gpg-setup.sh import ~/gpg-export

# Generate local-only key
./scripts/gpg-setup.sh local
```

---

## Environment Registry

Track devenv, docker, flake environments across machines.

```bash
# Scan and register all environments
./scripts/registry.py env scan

# List registered
./scripts/registry.py env list

# Add manually
./scripts/registry.py env add --path ~/projects/myproject

# Remove
./scripts/registry.py env remove myproject
```

Auto-tracking: direnv hooks update `last_used` when you enter a project.

---

## Package Manifests (Non-NixOS)

Track system packages installed via pacman/dnf.

```bash
# Check drift
./scripts/manifest.py status

# Update manifest from system
./scripts/manifest.py pull

# Install missing packages
./scripts/manifest.py apply
```

---

## Profiles

| Profile | Contents |
|---------|----------|
| `base` | Core utils: ripgrep, fd, bat, eza, fzf, htop |
| `dev` | Dev tools: git, tmux, direnv, LSPs, podman |
| `gui` | Desktop: alacritty, fonts, theming |

Configure per-host in `flake/home-manager.nix`:
```nix
myhost = {
  profiles = [ "base" "dev" ];  # No GUI for servers
};
```

---

## Private Configuration

Machine-specific secrets in `private/hosts/<hostname>/home.nix`:

```nix
{ ... }:
{
  programs.git.userEmail = "work@company.com";
  programs.git.signing.key = "ABCD1234";
  
  # Work-specific SSH
  programs.ssh.matchBlocks."work-*" = {
    user = "workuser";
    identityFile = "~/.ssh/local/work_ed25519";
  };
}
```

This directory is gitignored.

---

## Flake Commands Reference

```bash
# Build without switching
nix build .#homeConfigurations.myhost.activationPackage

# Show what would change
home-manager switch --flake .#myhost --dry-run

# Update flake inputs
nix flake update

# Update single input
nix flake lock --update-input nixpkgs

# Check flake validity
nix flake check

# Show flake outputs
nix flake show
```

---

## Troubleshooting

### "experimental-features" error
```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

### Home-manager not found
```bash
nix run home-manager/master -- switch --flake .#myhost
```

### Collision errors
Check for duplicate packages in profiles vs host config.

### Slow builds
Use binary cache:
```bash
nix build --accept-flake-config .#homeConfigurations.myhost.activationPackage
```

---

## Directory Structure

```
syscfg/
├── flake.nix                 # Entry point
├── flake/
│   ├── home-manager.nix      # Host registry
│   ├── nixos.nix             # NixOS configs
│   └── nvim/                 # Neovim config
├── modules/
│   ├── home/                 # Home-manager modules
│   │   ├── profiles/         # base, dev, gui
│   │   ├── programs/         # zsh, git, ssh, gpg...
│   │   └── services/         # timers, syncthing
│   └── nixos/                # NixOS modules
├── hosts/<hostname>/         # Per-machine config
├── private/                  # Gitignored secrets
├── manifests/                # Package tracking
├── monitoring/               # Phase 3 stack
└── scripts/                  # Automation
```