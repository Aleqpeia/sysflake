#!/usr/bin/env bash
set -euo pipefail

# Setup SSH keys for syscfg
# Usage:
#   ssh-setup.sh init           # First machine: generate shared + local keys
#   ssh-setup.sh local          # Additional machines: generate local keys only
#   ssh-setup.sh import <file>  # Import shared key from another source

SHARED_DIR="$HOME/.ssh/shared"
LOCAL_DIR="$HOME/.ssh/local"

log() { echo "==> $*"; }
warn() { echo "==> WARNING: $*" >&2; }

mkdir -p "$SHARED_DIR" "$LOCAL_DIR"
chmod 700 "$SHARED_DIR" "$LOCAL_DIR"

generate_key() {
    local name="$1"
    local path="$2"
    local comment="${3:-$USER@$(hostname)}"

    if [[ -f "$path" ]]; then
        warn "Key already exists: $path"
        read -p "Overwrite? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
    fi

    log "Generating $name key..."
    ssh-keygen -t ed25519 -C "$comment" -f "$path" -N ""
    chmod 600 "$path"
    chmod 644 "$path.pub"
    
    log "Public key:"
    cat "$path.pub"
}

cmd_init() {
    log "Initializing SSH keys (first machine setup)"
    
    # Shared key for GitHub/GitLab
    generate_key "shared GitHub" "$SHARED_DIR/github_ed25519" "github-shared"
    
    # Local machine key (general purpose)
    generate_key "local default" "$LOCAL_DIR/id_ed25519"
    
    # Local HPC key
    generate_key "local HPC" "$LOCAL_DIR/hpc_ed25519" "$USER@$(hostname)-hpc"

    echo ""
    log "Next steps:"
    echo "  1. Add the GitHub public key to https://github.com/settings/keys"
    echo "     $(cat "$SHARED_DIR/github_ed25519.pub")"
    echo ""
    echo "  2. Copy $SHARED_DIR to other machines (or use Syncthing)"
    echo ""
    echo "  3. Add HPC public key to your cluster's authorized_keys"
    echo "     $(cat "$LOCAL_DIR/hpc_ed25519.pub")"
}

cmd_local() {
    log "Generating local keys only"
    
    # Local machine key
    generate_key "local default" "$LOCAL_DIR/id_ed25519"
    
    # Local HPC key  
    generate_key "local HPC" "$LOCAL_DIR/hpc_ed25519" "$USER@$(hostname)-hpc"

    echo ""
    log "Next steps:"
    echo "  1. Ensure shared keys are in $SHARED_DIR"
    echo "     (copy from another machine or use Syncthing)"
    echo ""
    echo "  2. Add HPC public key to your cluster's authorized_keys"
    echo "     $(cat "$LOCAL_DIR/hpc_ed25519.pub")"
}

cmd_import() {
    local source="${1:-}"
    
    if [[ -z "$source" ]]; then
        echo "Usage: $0 import <source_dir_or_key>"
        exit 1
    fi

    if [[ -d "$source" ]]; then
        log "Importing from directory: $source"
        cp -v "$source"/* "$SHARED_DIR/"
    elif [[ -f "$source" ]]; then
        log "Importing key file: $source"
        cp -v "$source" "$SHARED_DIR/"
        [[ -f "$source.pub" ]] && cp -v "$source.pub" "$SHARED_DIR/"
    else
        echo "Error: $source not found"
        exit 1
    fi

    chmod 600 "$SHARED_DIR"/*
    chmod 644 "$SHARED_DIR"/*.pub 2>/dev/null || true
    
    log "Imported to $SHARED_DIR"
    ls -la "$SHARED_DIR"
}

cmd_status() {
    log "SSH key status"
    echo ""
    echo "Shared keys ($SHARED_DIR):"
    if [[ -d "$SHARED_DIR" ]] && ls "$SHARED_DIR"/*.pub &>/dev/null; then
        for pub in "$SHARED_DIR"/*.pub; do
            echo "  $(basename "$pub" .pub): $(cat "$pub")"
        done
    else
        echo "  (none)"
    fi
    
    echo ""
    echo "Local keys ($LOCAL_DIR):"
    if [[ -d "$LOCAL_DIR" ]] && ls "$LOCAL_DIR"/*.pub &>/dev/null; then
        for pub in "$LOCAL_DIR"/*.pub; do
            echo "  $(basename "$pub" .pub): $(cat "$pub")"
        done
    else
        echo "  (none)"
    fi
}

case "${1:-status}" in
    init)   cmd_init ;;
    local)  cmd_local ;;
    import) cmd_import "${2:-}" ;;
    status) cmd_status ;;
    *)
        echo "Usage: $0 {init|local|import|status}"
        echo ""
        echo "Commands:"
        echo "  init          First machine: generate shared + local keys"
        echo "  local         Additional machines: local keys only"
        echo "  import <src>  Import shared keys from another source"
        echo "  status        Show current key status"
        exit 1
        ;;
esac
