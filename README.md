# syscfg

Multi-machine NixOS and home-manager configuration with support for mixed environments (NixOS + Fedora/etc).

## Structure

```
syscfg/
├── flake.nix                 # Main flake definition
├── flake/
│   ├── default.nix           # Flake-parts orchestration
│   ├── home-manager.nix      # Home-manager integration
│   ├── nixos.nix             # NixOS integration
│   ├── nixvim.nix            # Neovim configuration
│   ├── overlays.nix          # Nixpkgs overlays
│   └── pkgs-by-name.nix      # Custom packages
├── modules/
│   ├── home/                 # Home-manager modules
│   │   ├── profiles/         # Feature sets (base, dev, gui)
│   │   └── programs/         # Individual programs
│   └── nixos/                # NixOS-specific modules
├── hosts/
│   ├── altair/               # NixOS workstation
│   ├── proxima/              # Fedora home machine
│   └── vega/                 # Work machine
├── manifests/                # Non-nix package tracking
├── scripts/                  # Automation
└── private/                  # Gitignored local overrides
```

## Quick Start

### New Machine (Fedora/Ubuntu/etc)

```bash
# Bootstrap
curl -sL https://raw.githubusercontent.com/YOUR_USER/syscfg/main/scripts/bootstrap.sh | bash -s <hostname>

# Or if you already cloned:
./scripts/bootstrap.sh <hostname>
```

### Existing NixOS Machine

```bash
sudo nixos-rebuild switch --flake ~/syscfg#<hostname>
```

### Daily Sync

```bash
./scripts/sync.sh
```

## Adding a New Host

1. Add to host registry in `flake/home-manager.nix`:

```nix
hosts = {
  # ...existing hosts...
  newhost = {
    system = "x86_64-linux";
    mode = "standalone";  # or "nixos"
    username = "efyis";
    profiles = [ "base" "dev" ];
  };
};
```

2. Create host directory:

```bash
mkdir -p hosts/newhost
cat > hosts/newhost/home.nix << 'EOF'
{ pkgs, hostname, ... }:
{
  home.sessionVariables.SYSCFG_HOST = hostname;
  systemd.user.startServices = "sd-switch";
}
EOF
```

3. For NixOS, also create `hosts/newhost/default.nix` and `hardware.nix`

4. Apply:

```bash
# Standalone
home-manager switch --flake .#newhost

# NixOS
sudo nixos-rebuild switch --flake .#newhost
```

## Profiles

- **base**: Core utilities (ripgrep, fd, bat, eza, fzf, etc.)
- **dev**: Development tools (git, tmux, direnv, language tooling)
- **gui**: Desktop applications (alacritty, obsidian, fonts, theming)

## Package Management (Non-NixOS)

For Fedora/etc machines, system packages are tracked in `manifests/<hostname>.toml`:

```bash
# Show drift between manifest and system
./scripts/manifest.py status

# Update manifest from current system
./scripts/manifest.py pull

# Install missing packages from manifest
./scripts/manifest.py apply

# Dry run
./scripts/manifest.py diff
```

## Private Configuration

Machine-specific secrets go in `private/hosts/<hostname>/home.nix`:

```nix
{ ... }:
{
  programs.git.userEmail = "your.email@example.com";
  programs.git.signing.key = "ABC123...";
}
```

This directory is gitignored.

## Star Naming Convention

- **Workstations**: Named after bright stars (altair, vega, proxima, antares, betelgeuse)
- **Cloud machines**: Grouped by constellation, named after component stars
