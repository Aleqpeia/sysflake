#!/usr/bin/env bash
set -euo pipefail

# Sync syscfg and apply configuration
# Usage: sync.sh [--pull-only] [--no-push]

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

HOST="${SYSCFG_HOST:-$(hostname)}"
MODE="${SYSCFG_MODE:-auto}"

PULL_ONLY=false
NO_PUSH=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --pull-only) PULL_ONLY=true; shift ;;
        --no-push) NO_PUSH=true; shift ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

log() { echo "==> $*"; }
warn() { echo "==> WARNING: $*" >&2; }

# Detect mode if auto
if [[ "$MODE" == "auto" ]]; then
    if [[ -f /etc/NIXOS ]]; then
        MODE="nixos"
    else
        MODE="standalone"
    fi
fi

log "Syncing $HOST (mode: $MODE)"

# Stash any local changes
if ! git diff --quiet; then
    log "Stashing local changes..."
    git stash push -m "auto-stash before sync"
    STASHED=true
else
    STASHED=false
fi

# Pull latest
log "Pulling latest config..."
if ! git pull --rebase; then
    warn "Pull failed, trying to continue..."
    git rebase --abort 2>/dev/null || true
    git pull --rebase=false
fi

# Restore stash if we made one
if [[ "$STASHED" == "true" ]]; then
    log "Restoring stashed changes..."
    git stash pop || warn "Could not restore stash, check 'git stash list'"
fi

if [[ "$PULL_ONLY" == "true" ]]; then
    log "Pull complete (--pull-only specified)"
    exit 0
fi

# Apply nix config
case "$MODE" in
    nixos)
        log "Rebuilding NixOS..."
        sudo nixos-rebuild switch --flake ".#$HOST"
        ;;
    standalone)
        log "Switching home-manager..."
        if ! command -v home-manager &>/dev/null; then
            warn "home-manager not found. Run bootstrap.sh first."
            exit 1
        fi
        home-manager switch --flake ".#$HOST"
        ;;
esac

# Reconcile system packages on non-NixOS
if [[ "$MODE" == "standalone" ]] && [[ -f "manifests/$HOST.toml" ]]; then
    log "Checking system packages..."
    python3 scripts/manifest.py status --host="$HOST" || true
fi

# Update manifest from current state
if command -v dnf &>/dev/null && [[ -f "manifests/$HOST.toml" ]]; then
    log "Updating package manifest..."
    python3 scripts/manifest.py pull --host="$HOST"
fi

# Commit any changes
if ! git diff --quiet manifests/; then
    log "Committing manifest changes..."
    git add manifests/
    git commit -m "auto($HOST): update package manifest"
fi

# Push if we have commits and not disabled
if [[ "$NO_PUSH" != "true" ]]; then
    if [[ -n "$(git log @{u}..HEAD 2>/dev/null || echo '')" ]]; then
        log "Pushing changes..."
        git push
    fi
fi

log "Done ✓"
