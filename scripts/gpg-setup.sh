#!/usr/bin/env bash
set -euo pipefail

# Setup GPG keys for syscfg
# Usage:
#   gpg-setup.sh init           # First machine: generate shared + local keys
#   gpg-setup.sh local          # Additional machines: generate local keys only
#   gpg-setup.sh import <dir>   # Import shared keys from export
#   gpg-setup.sh export <dir>   # Export shared keys for another machine

SHARED_DIR="$HOME/.gnupg/shared"
LOCAL_DIR="$HOME/.gnupg/local"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() { echo "==> $*"; }
warn() { echo "==> WARNING: $*" >&2; }

mkdir -p "$SHARED_DIR" "$LOCAL_DIR"
chmod 700 "$SHARED_DIR" "$LOCAL_DIR" "$HOME/.gnupg"

generate_key() {
    local name="$1"
    local email="$2"
    local purpose="$3"
    local comment="${4:-}"
    
    log "Generating GPG key: $name <$email> ($purpose)"
    
    # Generate key using batch mode
    local batch_file=$(mktemp)
    cat > "$batch_file" << EOF
%echo Generating GPG key for $purpose
Key-Type: EDDSA
Key-Curve: ed25519
Key-Usage: sign
Subkey-Type: ECDH
Subkey-Curve: cv25519
Subkey-Usage: encrypt
Name-Real: $name
Name-Email: $email
${comment:+Name-Comment: $comment}
Expire-Date: 2y
%commit
%echo Done
EOF
    
    gpg --batch --gen-key "$batch_file"
    rm -f "$batch_file"
    
    # Get the key ID
    local key_id
    key_id=$(gpg --list-secret-keys --keyid-format=long "$email" 2>/dev/null | grep -m1 "sec" | awk '{print $2}' | cut -d'/' -f2)
    
    if [[ -n "$key_id" ]]; then
        log "Generated key: $key_id"
        echo "$key_id"
    else
        warn "Could not determine key ID"
    fi
}

cmd_init() {
    log "Initializing GPG keys (first machine setup)"
    
    echo ""
    echo "This will generate GPG keys for:"
    echo "  1. Shared signing key (for git commits, synced between machines)"
    echo "  2. Local encryption key (for this machine only)"
    echo ""
    
    read -p "Your full name: " name
    read -p "Your email (for shared key): " email
    
    # Generate shared signing key
    log "Generating shared signing key..."
    shared_key_id=$(generate_key "$name" "$email" "git-signing" "shared")
    
    # Generate local encryption key
    local_email="${email%%@*}+$(hostname)@${email#*@}"
    log "Generating local key..."
    local_key_id=$(generate_key "$name" "$local_email" "local-encryption" "$(hostname)")
    
    echo ""
    log "Keys generated!"
    echo ""
    echo "Shared key (for git signing): $shared_key_id"
    echo "Local key (for this machine): $local_key_id"
    echo ""
    
    # Configure git to use the shared key
    read -p "Configure git to use shared key for signing? [Y/n] " response
    if [[ "${response:-y}" =~ ^[Yy]$ ]]; then
        git config --global user.signingkey "$shared_key_id"
        git config --global commit.gpgsign true
        log "Git configured to sign commits with $shared_key_id"
    fi
    
    # Register in registry
    if [[ -f "$SCRIPT_DIR/registry.py" ]]; then
        log "Registering keys..."
        python3 "$SCRIPT_DIR/registry.py" gpg add --key-id "$shared_key_id" --scope shared --purpose git-signing --email "$email"
        python3 "$SCRIPT_DIR/registry.py" gpg add --key-id "$local_key_id" --scope local --purpose encryption --email "$local_email"
    fi
    
    echo ""
    log "Next steps:"
    echo "  1. Export your public key for GitHub/GitLab:"
    echo "     gpg --armor --export $shared_key_id"
    echo ""
    echo "  2. Add it to https://github.com/settings/keys"
    echo ""
    echo "  3. To transfer to another machine:"
    echo "     ./gpg-setup.sh export ~/gpg-export"
    echo "     # Copy gpg-export/ to new machine, then:"
    echo "     ./gpg-setup.sh import ~/gpg-export"
}

cmd_local() {
    log "Generating local keys only"
    
    read -p "Your full name: " name
    read -p "Your email: " email
    
    local_email="${email%%@*}+$(hostname)@${email#*@}"
    log "Generating local key..."
    local_key_id=$(generate_key "$name" "$local_email" "local-encryption" "$(hostname)")
    
    echo ""
    log "Local key generated: $local_key_id"
    
    if [[ -f "$SCRIPT_DIR/registry.py" ]]; then
        python3 "$SCRIPT_DIR/registry.py" gpg add --key-id "$local_key_id" --scope local --purpose encryption --email "$local_email"
    fi
    
    echo ""
    log "Don't forget to import shared keys if needed:"
    echo "  ./gpg-setup.sh import ~/gpg-export"
}

cmd_export() {
    local output_dir="${1:-gpg-export}"
    
    log "Exporting shared GPG keys to $output_dir"
    
    mkdir -p "$output_dir"
    chmod 700 "$output_dir"
    
    # Get shared keys from registry or prompt
    if [[ -f "$HOME/.config/syscfg/registry.toml" ]] && command -v python3 &>/dev/null; then
        # Use registry to find shared keys
        log "Reading shared keys from registry..."
        # Simple grep for now, registry.py export is more complete
        python3 "$SCRIPT_DIR/registry.py" gpg export --output "$output_dir" --include-secret
    else
        # Manual export
        echo "Enter the key ID of your shared signing key:"
        gpg --list-secret-keys --keyid-format=long
        read -p "Key ID: " key_id
        
        gpg --armor --export "$key_id" > "$output_dir/${key_id}.pub.asc"
        gpg --armor --export-secret-keys "$key_id" > "$output_dir/${key_id}.sec.asc"
        
        log "Exported to $output_dir"
    fi
    
    echo ""
    log "Transfer $output_dir to your other machine securely"
    echo "Then run: ./gpg-setup.sh import $output_dir"
}

cmd_import() {
    local import_dir="${1:-}"
    
    if [[ -z "$import_dir" ]] || [[ ! -d "$import_dir" ]]; then
        echo "Usage: $0 import <directory>"
        echo ""
        echo "Directory should contain .asc files from 'gpg-setup.sh export'"
        exit 1
    fi
    
    log "Importing GPG keys from $import_dir"
    
    # Import all keys
    for keyfile in "$import_dir"/*.asc; do
        if [[ -f "$keyfile" ]]; then
            log "Importing $keyfile..."
            gpg --import "$keyfile"
        fi
    done
    
    # Trust imported keys
    log "You may need to trust the imported keys:"
    gpg --list-secret-keys --keyid-format=long
    echo ""
    echo "To trust a key, run:"
    echo "  gpg --edit-key <KEY_ID>"
    echo "  gpg> trust"
    echo "  gpg> 5 (ultimate trust)"
    echo "  gpg> quit"
    
    # Register in registry
    if [[ -f "$import_dir/keys.toml" ]] && [[ -f "$SCRIPT_DIR/registry.py" ]]; then
        log "Updating registry..."
        # TODO: merge imported registry info
    fi
    
    # Configure git
    echo ""
    read -p "Configure git to use imported key for signing? [Y/n] " response
    if [[ "${response:-y}" =~ ^[Yy]$ ]]; then
        echo "Available keys:"
        gpg --list-secret-keys --keyid-format=long | grep -E "^sec"
        read -p "Enter key ID for git signing: " key_id
        git config --global user.signingkey "$key_id"
        git config --global commit.gpgsign true
        log "Git configured"
    fi
}

cmd_status() {
    log "GPG Key Status"
    echo ""
    
    echo "Secret keys:"
    gpg --list-secret-keys --keyid-format=long 2>/dev/null || echo "  (none)"
    
    echo ""
    echo "Git signing configuration:"
    echo "  user.signingkey = $(git config --global user.signingkey 2>/dev/null || echo '(not set)')"
    echo "  commit.gpgsign = $(git config --global commit.gpgsign 2>/dev/null || echo 'false')"
    
    if [[ -f "$SCRIPT_DIR/registry.py" ]]; then
        echo ""
        python3 "$SCRIPT_DIR/registry.py" gpg list
    fi
}

case "${1:-status}" in
    init)   cmd_init ;;
    local)  cmd_local ;;
    export) cmd_export "${2:-}" ;;
    import) cmd_import "${2:-}" ;;
    status) cmd_status ;;
    *)
        echo "Usage: $0 {init|local|export|import|status}"
        echo ""
        echo "Commands:"
        echo "  init          First machine: generate shared + local keys"
        echo "  local         Additional machines: local keys only"
        echo "  export <dir>  Export shared keys for transfer"
        echo "  import <dir>  Import shared keys from another machine"
        echo "  status        Show current key status"
        exit 1
        ;;
esac
