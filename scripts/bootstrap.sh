#!/usr/bin/env bash
set -euo pipefail

# Bootstrap script for new machines
# Usage: 
#   curl -sL https://raw.githubusercontent.com/YOUR_USER/syscfg/main/scripts/bootstrap.sh | bash -s <hostname>
#   # Or locally:
#   ./scripts/bootstrap.sh <hostname>

HOST="${1:-}"
if [[ -z "$HOST" ]]; then
    echo "Usage: $0 <hostname>"
    echo ""
    echo "Example: $0 proxima"
    exit 1
fi

log() { echo "==> $*"; }
warn() { echo "==> WARNING: $*" >&2; }
error() { echo "==> ERROR: $*" >&2; exit 1; }

# Detect distro
detect_distro() {
    if [[ -f /etc/NIXOS ]]; then
        echo "nixos"
    elif [[ -f /etc/fedora-release ]]; then
        echo "fedora"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    elif [[ "$(uname)" == "Darwin" ]]; then
        echo "darwin"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
log "Detected distro: $DISTRO"
log "Bootstrapping host: $HOST"

# Install dependencies based on distro
install_deps() {
    case "$DISTRO" in
        fedora)
            log "Installing Fedora dependencies..."
            sudo dnf install -y git curl zsh
            # Python deps for manifest script
            sudo dnf install -y python3-pip || true
            pip install --user tomli tomli_w || true
            ;;
        debian)
            log "Installing Debian/Ubuntu dependencies..."
            sudo apt update
            sudo apt install -y git curl zsh
            pip install --user tomli tomli_w || true
            ;;
        arch)
            log "Installing Arch dependencies..."
            sudo pacman -Syu --noconfirm git curl zsh
            pip install --user tomli tomli_w || true
            ;;
        darwin)
            log "Installing macOS dependencies..."
            # Assume Homebrew is available or will be
            brew install git curl zsh || true
            pip3 install --user tomli tomli_w || true
            ;;
        nixos)
            log "NixOS detected, dependencies managed by nix"
            ;;
        *)
            warn "Unknown distro, skipping dependency installation"
            ;;
    esac
}

# Install Nix if not present
install_nix() {
    if command -v nix &>/dev/null; then
        log "Nix already installed"
        return
    fi

    if [[ "$DISTRO" == "nixos" ]]; then
        log "NixOS detected, nix already available"
        return
    fi

    log "Installing Nix..."
    curl -L https://nixos.org/nix/install | sh -s -- --daemon

    # Source nix for this session
    if [[ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
        # shellcheck source=/dev/null
        . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    elif [[ -f "$HOME/.nix-profile/etc/profile.d/nix.sh" ]]; then
        # shellcheck source=/dev/null
        . "$HOME/.nix-profile/etc/profile.d/nix.sh"
    fi

    # Verify
    if ! command -v nix &>/dev/null; then
        error "Nix installation failed or not in PATH. Try opening a new terminal."
    fi

    log "Nix installed successfully"
}

# Clone or update syscfg
setup_syscfg() {
    SYSCFG_DIR="${SYSCFG_DIR:-$HOME/syscfg}"

    if [[ -d "$SYSCFG_DIR" ]]; then
        log "syscfg already exists at $SYSCFG_DIR"
        cd "$SYSCFG_DIR"
        git pull --rebase || warn "Could not pull latest"
    else
        log "Cloning syscfg..."
        # Replace with your actual repo URL
        REPO_URL="${SYSCFG_REPO:-https://github.com/YOUR_USERNAME/syscfg.git}"
        git clone "$REPO_URL" "$SYSCFG_DIR"
        cd "$SYSCFG_DIR"
    fi

    # Create host directory if needed
    if [[ ! -d "hosts/$HOST" ]]; then
        log "Creating host config for $HOST..."
        mkdir -p "hosts/$HOST"
        cat > "hosts/$HOST/home.nix" << EOF
{ pkgs, hostname, ... }:
{
  # Host-specific configuration for $HOST
  # Add your overrides here

  home.packages = with pkgs; [
    # Additional packages for this machine
  ];

  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "standalone";
  };

  systemd.user.startServices = "sd-switch";
}
EOF
        git add "hosts/$HOST"
        git commit -m "feat: add host config for $HOST" || true
    fi
}

# Setup home-manager
setup_home_manager() {
    cd "${SYSCFG_DIR:-$HOME/syscfg}"

    if [[ "$DISTRO" == "nixos" ]]; then
        log "NixOS detected, home-manager will be used as module"
        log "Run: sudo nixos-rebuild switch --flake .#$HOST"
        return
    fi

    log "Setting up home-manager for standalone use..."

    # Check if configuration exists
    if ! nix flake show --json 2>/dev/null | grep -q "\"$HOST\""; then
        warn "Host '$HOST' not found in homeConfigurations"
        warn "Available hosts:"
        nix flake show --json 2>/dev/null | grep -o '"[^"]*"' | head -20 || true
        error "Please add $HOST to flake/home-manager.nix hosts registry"
    fi

    if command -v home-manager &>/dev/null; then
        log "Switching to home-manager config..."
        home-manager switch --flake ".#$HOST"
    else
        log "Installing home-manager and applying config..."
        nix run home-manager/master -- switch --flake ".#$HOST"
    fi

    log "home-manager setup complete"
}

# Create initial manifest for non-NixOS
setup_manifest() {
    cd "${SYSCFG_DIR:-$HOME/syscfg}"

    if [[ "$DISTRO" == "nixos" ]]; then
        return
    fi

    if [[ ! -f "manifests/$HOST.toml" ]] && command -v dnf &>/dev/null; then
        log "Creating initial package manifest..."
        python3 scripts/manifest.py pull --host="$HOST"
        git add "manifests/$HOST.toml"
        git commit -m "feat($HOST): initial package manifest" || true
    fi
}

# Set shell to zsh
setup_shell() {
    if [[ "$SHELL" == *"zsh"* ]]; then
        log "Already using zsh"
        return
    fi

    ZSH_PATH=$(command -v zsh || echo "")
    if [[ -z "$ZSH_PATH" ]]; then
        warn "zsh not found, skipping shell change"
        return
    fi

    log "Changing default shell to zsh..."
    if chsh -s "$ZSH_PATH"; then
        log "Shell changed to zsh"
    else
        warn "Could not change shell automatically"
        echo "Run: chsh -s $ZSH_PATH"
    fi
}

# Main
main() {
    install_deps
    install_nix
    setup_syscfg
    setup_home_manager
    setup_manifest
    setup_shell

    echo ""
    log "Bootstrap complete! ✓"
    echo ""
    echo "Next steps:"
    echo "  1. Open a new terminal (or run: exec zsh)"
    echo "  2. Run: cd ~/syscfg && ./scripts/sync.sh"
    echo ""
    echo "Environment variables set:"
    echo "  SYSCFG_HOST=$HOST"
    echo "  SYSCFG_MODE=standalone"
}

main
