# syscfg

Multi-machine NixOS and home-manager configuration with support for mixed environments (NixOS + Fedora/etc).

## Quick Start

```bash
# On new machine (Fedora/Arch/etc)
curl -sL https://raw.githubusercontent.com/USER/syscfg/main/scripts/bootstrap.sh | bash -s <hostname>

# Daily sync
~/syscfg/scripts/sync.sh
```

## Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   altair    │     │   proxima   │     │    vega     │
│  (NixOS)    │     │  (Fedora)   │     │  (Remote)   │
│  workstation│     │    home     │     │   work      │
└──────┬──────┘     └──────┬──────┘     └──────┬──────┘
       │                   │                   │
       └───────────────────┼───────────────────┘
                           │
                    ┌──────┴──────┐
                    │    GitHub   │
                    │   syscfg    │
                    └─────────────┘
```

## Phases

| Phase | Status | Features |
|-------|--------|----------|
| 1 ✅ | Complete | Git sync, home-manager, manifests |
| 2 ✅ | Complete | Systemd timers, drift detection, registry |
| 3 🔧 | Ready | Podman-compose monitoring stack |

## Key Features

### Keys Management (SSH + GPG)

```bash
# First machine - generate all keys
./scripts/ssh-setup.sh init
./scripts/gpg-setup.sh init

# Additional machines - local keys only, import shared
./scripts/ssh-setup.sh local
./scripts/gpg-setup.sh local
./scripts/gpg-setup.sh import ~/gpg-export

# View registered keys
./scripts/registry.py ssh list
./scripts/registry.py gpg list
```

### Devenv Project Tracking

```bash
# Scan for devenv projects
./scripts/registry.py devenv scan

# Add manually
./scripts/registry.py devenv add --path ~/projects/mdanalysis --type python

# List registered projects
./scripts/registry.py devenv list
```

### Package Manifest (non-NixOS)

```bash
# Check drift between manifest and system
./scripts/manifest.py status

# Update manifest from current system
./scripts/manifest.py pull

# Install missing packages
./scripts/manifest.py apply
```

### Phase 2: Automatic Sync

Enable in your host config:

```nix
# hosts/proxima/home.nix
{ ... }:
{
  imports = [ ../../modules/home/services/syscfg-timers.nix ];
  
  services.syscfg = {
    enable = true;
    syncInterval = "1h";
    driftCheckInterval = "6h";
  };
}
```

### Phase 3: Monitoring

```bash
cd ~/syscfg/monitoring
podman-compose up -d

# Access:
# - Dashboard: http://localhost:8080
# - Grafana:   http://localhost:3000
# - Prometheus: http://localhost:9090
```

Configure machines to report status:

```nix
services.syscfg = {
  enable = true;
  statusEndpoint = "http://proxima:8080/status";
};
```

## Directory Structure

```
syscfg/
├── flake.nix                 # Main flake
├── flake/
│   ├── home-manager.nix      # Host registry + standalone configs
│   ├── nixos.nix             # NixOS configs
│   ├── nvim/                 # Custom neovim build
│   └── overlays.nix          # Nixpkgs overlays
├── modules/
│   ├── home/
│   │   ├── profiles/         # base, dev, gui
│   │   ├── programs/         # zsh, git, ssh, gpg, etc
│   │   └── services/         # syncthing, syscfg-timers
│   └── nixos/                # NixOS modules
├── hosts/
│   ├── altair/               # NixOS workstation
│   ├── proxima/              # Fedora home
│   └── vega/                 # Work machine
├── manifests/                # DNF package tracking
├── monitoring/               # Phase 3 stack
├── scripts/
│   ├── bootstrap.sh          # New machine setup
│   ├── sync.sh               # Daily sync
│   ├── manifest.py           # Package management
│   ├── registry.py           # Keys/devenv registry
│   ├── ssh-setup.sh          # SSH key management
│   └── gpg-setup.sh          # GPG key management
└── private/                  # Gitignored secrets
```

## Adding a New Host

1. Add to registry in `flake/home-manager.nix`:

```nix
lyra = {
  system = "x86_64-linux";
  mode = "standalone";
  username = "efyis";
  profiles = [ "base" "dev" ];
};
```

2. Create host config:

```bash
mkdir -p hosts/lyra
cat > hosts/lyra/home.nix << 'EOF'
{ hostname, ... }:
{
  home.sessionVariables.SYSCFG_HOST = hostname;
  systemd.user.startServices = "sd-switch";
}
EOF
```

3. Apply:

```bash
nix run home-manager/master -- switch --flake .#lyra
```

## Star Naming Convention

- **Workstations**: Bright stars (altair, vega, proxima, antares, betelgeuse)
- **Cloud/VMs**: Grouped by constellation
