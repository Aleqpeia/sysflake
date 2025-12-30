#!/usr/bin/env python3
"""
Registry management for syscfg.

Tracks GPG keys, SSH keys, devenv projects, and service status.

Usage:
  registry.py gpg list|add|remove|export
  registry.py ssh list|add|remove
  registry.py devenv list|add|remove|scan
  registry.py status [--json]
"""

from __future__ import annotations

import subprocess
import socket
import sys
import argparse
import json
import os
from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass, field, asdict
from typing import Optional

try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("Error: Please install tomli: pip install tomli --user", file=sys.stderr)
        sys.exit(1)

try:
    import tomli_w
except ImportError:
    print("Error: Please install tomli_w: pip install tomli_w --user", file=sys.stderr)
    sys.exit(1)


REGISTRY_DIR = Path.home() / ".config" / "syscfg"
REGISTRY_FILE = REGISTRY_DIR / "registry.toml"


def get_hostname() -> str:
    return socket.gethostname()


def load_registry() -> dict:
    """Load registry or create empty one."""
    REGISTRY_DIR.mkdir(parents=True, exist_ok=True)
    
    if not REGISTRY_FILE.exists():
        return {
            "meta": {
                "hostname": get_hostname(),
                "created": datetime.now(timezone.utc).isoformat(),
                "updated": datetime.now(timezone.utc).isoformat(),
            },
            "gpg": {"shared": {}, "local": {}},
            "ssh": {"shared": {}, "local": {}},
            "devenv": {},
            "services": {},
        }
    
    with open(REGISTRY_FILE, "rb") as f:
        return tomllib.load(f)


def save_registry(registry: dict) -> None:
    """Save registry to file."""
    registry["meta"]["updated"] = datetime.now(timezone.utc).isoformat()
    
    with open(REGISTRY_FILE, "wb") as f:
        tomli_w.dump(registry, f)
    
    print(f"Registry saved: {REGISTRY_FILE}")


# =============================================================================
# GPG Commands
# =============================================================================

def gpg_list(registry: dict) -> None:
    """List registered GPG keys."""
    print("GPG Keys:")
    print()
    
    for scope in ["shared", "local"]:
        keys = registry.get("gpg", {}).get(scope, {})
        if keys:
            print(f"  [{scope.upper()}]")
            for key_id, info in keys.items():
                purpose = info.get("purpose", "unknown")
                email = info.get("email", "")
                print(f"    {key_id}: {purpose} ({email})")
            print()
    
    if not registry.get("gpg", {}).get("shared") and not registry.get("gpg", {}).get("local"):
        print("  (no keys registered)")
        print()
        print("  Run: registry.py gpg add --scope shared --purpose git-signing")


def gpg_add(registry: dict, args) -> None:
    """Add a GPG key to registry."""
    # Get key info from gpg
    key_id = args.key_id
    
    if not key_id:
        # Interactive: list available keys
        result = subprocess.run(
            ["gpg", "--list-secret-keys", "--keyid-format=long"],
            capture_output=True, text=True
        )
        print("Available secret keys:")
        print(result.stdout)
        key_id = input("Enter key ID to register: ").strip()
    
    # Get fingerprint
    result = subprocess.run(
        ["gpg", "--fingerprint", key_id],
        capture_output=True, text=True
    )
    
    if result.returncode != 0:
        print(f"Error: Key {key_id} not found")
        sys.exit(1)
    
    # Parse fingerprint from output
    fingerprint = ""
    for line in result.stdout.split("\n"):
        if "fingerprint" in line.lower():
            fingerprint = line.split("=")[-1].strip().replace(" ", "")
            break
    
    # Get email
    email = args.email or ""
    if not email:
        for line in result.stdout.split("\n"):
            if "<" in line and ">" in line:
                email = line.split("<")[1].split(">")[0]
                break
    
    scope = args.scope or "local"
    purpose = args.purpose or "general"
    
    registry.setdefault("gpg", {}).setdefault(scope, {})[key_id] = {
        "fingerprint": fingerprint,
        "purpose": purpose,
        "email": email,
        "created": datetime.now(timezone.utc).isoformat(),
        "hostname": get_hostname(),
    }
    
    save_registry(registry)
    print(f"Registered GPG key {key_id} as {scope}/{purpose}")


def gpg_export(registry: dict, args) -> None:
    """Export shared GPG keys for transfer to another machine."""
    shared_keys = registry.get("gpg", {}).get("shared", {})
    
    if not shared_keys:
        print("No shared GPG keys to export")
        return
    
    export_dir = Path(args.output or "gpg-export")
    export_dir.mkdir(exist_ok=True)
    
    for key_id, info in shared_keys.items():
        # Export public key
        pub_file = export_dir / f"{key_id}.pub.asc"
        subprocess.run(
            ["gpg", "--armor", "--export", key_id],
            stdout=open(pub_file, "w"),
            check=True
        )
        print(f"Exported public key: {pub_file}")
        
        # Export secret key (will prompt for passphrase)
        if args.include_secret:
            sec_file = export_dir / f"{key_id}.sec.asc"
            subprocess.run(
                ["gpg", "--armor", "--export-secret-keys", key_id],
                stdout=open(sec_file, "w"),
                check=True
            )
            print(f"Exported secret key: {sec_file}")
    
    # Export registry info
    info_file = export_dir / "keys.toml"
    with open(info_file, "wb") as f:
        tomli_w.dump({"gpg": {"shared": shared_keys}}, f)
    print(f"Exported key info: {info_file}")


# =============================================================================
# SSH Commands  
# =============================================================================

def ssh_list(registry: dict) -> None:
    """List registered SSH keys."""
    print("SSH Keys:")
    print()
    
    for scope in ["shared", "local"]:
        keys = registry.get("ssh", {}).get(scope, {})
        if keys:
            print(f"  [{scope.upper()}]")
            for name, info in keys.items():
                registered = ", ".join(info.get("registered_at", []))
                print(f"    {name}: {info.get('pubkey_file', 'unknown')}")
                if registered:
                    print(f"           registered at: {registered}")
            print()
    
    if not registry.get("ssh", {}).get("shared") and not registry.get("ssh", {}).get("local"):
        print("  (no keys registered)")
        print()
        print("  Run: ssh-setup.sh init  # then register with:")
        print("  registry.py ssh add --scope shared --name github")


def ssh_add(registry: dict, args) -> None:
    """Add SSH key to registry."""
    scope = args.scope or "local"
    name = args.name
    
    if scope == "shared":
        key_dir = Path.home() / ".ssh" / "shared"
    else:
        key_dir = Path.home() / ".ssh" / "local"
    
    # Find the key file
    if args.file:
        key_file = Path(args.file)
    else:
        # Try common patterns
        for pattern in [f"{name}_ed25519", f"{name}", "id_ed25519"]:
            candidate = key_dir / pattern
            if candidate.exists():
                key_file = candidate
                break
        else:
            print(f"Could not find key file in {key_dir}")
            print("Specify with --file")
            sys.exit(1)
    
    pub_file = Path(str(key_file) + ".pub")
    if not pub_file.exists():
        print(f"Public key not found: {pub_file}")
        sys.exit(1)
    
    # Get fingerprint
    result = subprocess.run(
        ["ssh-keygen", "-lf", str(pub_file)],
        capture_output=True, text=True, check=True
    )
    fingerprint = result.stdout.split()[1]
    
    registry.setdefault("ssh", {}).setdefault(scope, {})[name] = {
        "fingerprint": fingerprint,
        "pubkey_file": pub_file.name,
        "created": datetime.now(timezone.utc).isoformat(),
        "registered_at": args.registered_at.split(",") if args.registered_at else [],
    }
    
    save_registry(registry)
    print(f"Registered SSH key {name} ({scope})")


# =============================================================================
# Devenv Commands
# =============================================================================

def devenv_list(registry: dict) -> None:
    """List registered devenv projects."""
    print("Devenv Projects:")
    print()
    
    projects = registry.get("devenv", {})
    if not projects:
        print("  (no projects registered)")
        print()
        print("  Run: registry.py devenv scan  # to find projects")
        print("  Or:  registry.py devenv add --path /path/to/project")
        return
    
    for name, info in projects.items():
        path = info.get("path", "unknown")
        proj_type = info.get("type", "unknown")
        desc = info.get("description", "")
        
        exists = "✓" if Path(path).exists() else "✗"
        has_devenv = "✓" if (Path(path) / "devenv.nix").exists() else "?"
        
        print(f"  {name} [{proj_type}] {exists}")
        print(f"    path: {path}")
        print(f"    devenv.nix: {has_devenv}")
        if desc:
            print(f"    desc: {desc}")
        print()


def devenv_scan(registry: dict, args) -> None:
    """Scan for devenv projects."""
    search_paths = [
        Path.home() / "projects",
        Path.home() / "work",
        Path.home() / "code",
        Path.home() / "dev",
        Path.home() / "src",
    ]
    
    if args.path:
        search_paths = [Path(args.path)]
    
    found = []
    for base in search_paths:
        if not base.exists():
            continue
        
        # Find devenv.nix files
        for devenv_file in base.rglob("devenv.nix"):
            project_dir = devenv_file.parent
            
            # Skip if inside .direnv or node_modules
            if ".direnv" in str(project_dir) or "node_modules" in str(project_dir):
                continue
            
            found.append(project_dir)
    
    if not found:
        print("No devenv projects found")
        return
    
    print(f"Found {len(found)} devenv projects:")
    print()
    
    for i, project_dir in enumerate(found):
        name = project_dir.name
        existing = registry.get("devenv", {}).get(name)
        status = "(registered)" if existing else "(new)"
        
        print(f"  [{i+1}] {name} {status}")
        print(f"      {project_dir}")
    
    print()
    if not args.no_interactive:
        response = input("Register all new projects? [y/N] ").strip().lower()
        if response == "y":
            for project_dir in found:
                name = project_dir.name
                if name not in registry.get("devenv", {}):
                    # Detect project type
                    proj_type = "unknown"
                    if (project_dir / "Cargo.toml").exists():
                        proj_type = "rust"
                    elif (project_dir / "pyproject.toml").exists() or (project_dir / "setup.py").exists():
                        proj_type = "python"
                    elif (project_dir / "package.json").exists():
                        proj_type = "node"
                    elif (project_dir / "flake.nix").exists():
                        proj_type = "nix"
                    
                    registry.setdefault("devenv", {})[name] = {
                        "path": str(project_dir),
                        "type": proj_type,
                        "description": "",
                        "registered": datetime.now(timezone.utc).isoformat(),
                    }
                    print(f"  Registered: {name}")
            
            save_registry(registry)


def devenv_add(registry: dict, args) -> None:
    """Add a devenv project manually."""
    path = Path(args.path).resolve()
    
    if not path.exists():
        print(f"Path does not exist: {path}")
        sys.exit(1)
    
    name = args.name or path.name
    
    registry.setdefault("devenv", {})[name] = {
        "path": str(path),
        "type": args.type or "unknown",
        "description": args.description or "",
        "registered": datetime.now(timezone.utc).isoformat(),
    }
    
    save_registry(registry)
    print(f"Registered devenv project: {name}")


# =============================================================================
# Environment Commands (devenv, docker, nix shells, etc.)
# =============================================================================

def env_list(registry: dict) -> None:
    """List all registered environments."""
    print("Development Environments:")
    print()
    
    envs = registry.get("environments", {})
    if not envs:
        print("  (no environments registered)")
        print()
        print("  Run: registry.py env scan")
        return
    
    # Group by type
    by_type = {}
    for name, info in envs.items():
        env_type = info.get("type", "unknown")
        by_type.setdefault(env_type, []).append((name, info))
    
    for env_type, items in sorted(by_type.items()):
        print(f"  [{env_type.upper()}]")
        for name, info in items:
            path = info.get("path", "")
            status = "✓" if Path(path).exists() else "✗"
            last_used = info.get("last_used", "never")[:10] if info.get("last_used") else "never"
            print(f"    {status} {name}")
            print(f"        {path}")
            if info.get("description"):
                print(f"        {info['description']}")
        print()


def env_scan(registry: dict, args) -> None:
    """Scan for all environment types."""
    search_paths = [
        Path.home() / "projects",
        Path.home() / "work",
        Path.home() / "code",
        Path.home() / "dev",
        Path.home() / "src",
        Path.home(),
    ]
    
    if args.path:
        search_paths = [Path(args.path)]
    
    found = {
        "devenv": [],
        "flake": [],
        "docker": [],
        "docker-compose": [],
        "nix-shell": [],
        "direnv": [],
    }
    
    for base in search_paths:
        if not base.exists():
            continue
        
        # Limit depth for home directory
        max_depth = 2 if base == Path.home() else 5
        
        for root, dirs, files in os.walk(base):
            # Skip hidden and vendor directories
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in 
                      ['node_modules', 'vendor', 'venv', '.venv', '__pycache__', 'target', 'build']]
            
            depth = len(Path(root).relative_to(base).parts)
            if depth > max_depth:
                dirs.clear()
                continue
            
            root_path = Path(root)
            
            # devenv.nix
            if "devenv.nix" in files:
                found["devenv"].append(root_path)
            
            # flake.nix (standalone, not devenv)
            elif "flake.nix" in files and "devenv.nix" not in files:
                found["flake"].append(root_path)
            
            # Dockerfile
            if "Dockerfile" in files:
                found["docker"].append(root_path)
            
            # docker-compose
            if any(f in files for f in ["docker-compose.yml", "docker-compose.yaml", "compose.yml", "compose.yaml"]):
                found["docker-compose"].append(root_path)
            
            # shell.nix (standalone)
            if "shell.nix" in files and "flake.nix" not in files and "devenv.nix" not in files:
                found["nix-shell"].append(root_path)
            
            # .envrc without devenv/flake
            if ".envrc" in files and "devenv.nix" not in files and "flake.nix" not in files:
                found["direnv"].append(root_path)
    
    total = sum(len(v) for v in found.values())
    if total == 0:
        print("No environments found")
        return
    
    print(f"Found {total} environments:")
    print()
    
    for env_type, paths in found.items():
        if not paths:
            continue
        
        print(f"  [{env_type.upper()}] ({len(paths)})")
        for p in paths[:10]:  # Limit display
            name = p.name
            existing = name in registry.get("environments", {})
            status = "(registered)" if existing else "(new)"
            print(f"    {p.relative_to(Path.home()) if str(p).startswith(str(Path.home())) else p} {status}")
        if len(paths) > 10:
            print(f"    ... and {len(paths) - 10} more")
        print()
    
    if not args.no_interactive:
        response = input("Register all new environments? [y/N] ").strip().lower()
        if response == "y":
            for env_type, paths in found.items():
                for project_dir in paths:
                    name = project_dir.name
                    # Make unique if duplicate name
                    base_name = name
                    counter = 1
                    while name in registry.get("environments", {}):
                        name = f"{base_name}-{counter}"
                        counter += 1
                    
                    registry.setdefault("environments", {})[name] = {
                        "path": str(project_dir),
                        "type": env_type,
                        "description": "",
                        "registered": datetime.now(timezone.utc).isoformat(),
                    }
                    print(f"  Registered: {name} ({env_type})")
            
            save_registry(registry)


def env_add(registry: dict, args) -> None:
    """Add environment manually."""
    path = Path(args.path).resolve()
    
    if not path.exists():
        print(f"Path does not exist: {path}")
        sys.exit(1)
    
    name = args.name or path.name
    
    # Auto-detect type if not specified
    env_type = args.type
    if not env_type:
        if (path / "devenv.nix").exists():
            env_type = "devenv"
        elif (path / "flake.nix").exists():
            env_type = "flake"
        elif (path / "Dockerfile").exists():
            env_type = "docker"
        elif any((path / f).exists() for f in ["docker-compose.yml", "compose.yml"]):
            env_type = "docker-compose"
        elif (path / "shell.nix").exists():
            env_type = "nix-shell"
        else:
            env_type = "unknown"
    
    registry.setdefault("environments", {})[name] = {
        "path": str(path),
        "type": env_type,
        "description": args.description or "",
        "registered": datetime.now(timezone.utc).isoformat(),
    }
    
    save_registry(registry)
    print(f"Registered environment: {name} ({env_type})")


def env_remove(registry: dict, args) -> None:
    """Remove environment from registry."""
    name = args.name
    
    if name not in registry.get("environments", {}):
        print(f"Environment not found: {name}")
        sys.exit(1)
    
    del registry["environments"][name]
    save_registry(registry)
    print(f"Removed: {name}")


def env_update_usage(registry: dict, args) -> None:
    """Update last_used timestamp for an environment."""
    name = args.name
    
    if name not in registry.get("environments", {}):
        # Try to find by path
        path = Path(args.name).resolve()
        for n, info in registry.get("environments", {}).items():
            if info.get("path") == str(path):
                name = n
                break
        else:
            print(f"Environment not found: {args.name}")
            sys.exit(1)
    
    registry["environments"][name]["last_used"] = datetime.now(timezone.utc).isoformat()
    save_registry(registry)


# =============================================================================
# Status Command
# =============================================================================

def show_status(registry: dict, args) -> None:
    """Show overall registry status."""
    
    # Count environments by type
    envs = registry.get("environments", {})
    env_counts = {}
    for info in envs.values():
        t = info.get("type", "unknown")
        env_counts[t] = env_counts.get(t, 0) + 1
    
    status = {
        "hostname": get_hostname(),
        "updated": registry.get("meta", {}).get("updated", "unknown"),
        "gpg_keys": {
            "shared": len(registry.get("gpg", {}).get("shared", {})),
            "local": len(registry.get("gpg", {}).get("local", {})),
        },
        "ssh_keys": {
            "shared": len(registry.get("ssh", {}).get("shared", {})),
            "local": len(registry.get("ssh", {}).get("local", {})),
        },
        "environments": env_counts,
        "environments_total": len(envs),
        "devenv_projects": len(registry.get("devenv", {})),  # Legacy compat
        "services": registry.get("services", {}),
    }
    
    if args.json:
        print(json.dumps(status, indent=2))
    else:
        print(f"Registry Status: {get_hostname()}")
        print(f"Last updated: {status['updated']}")
        print()
        print(f"GPG Keys:     {status['gpg_keys']['shared']} shared, {status['gpg_keys']['local']} local")
        print(f"SSH Keys:     {status['ssh_keys']['shared']} shared, {status['ssh_keys']['local']} local")
        print(f"Environments: {status['environments_total']} total")
        if env_counts:
            breakdown = ", ".join(f"{v} {k}" for k, v in sorted(env_counts.items()))
            print(f"              ({breakdown})")
        print()
        
        services = status["services"]
        if services:
            print("Services:")
            for name, info in services.items():
                last_status = info.get("last_status", "unknown")
                last_run = info.get("last_run", "never")
                print(f"  {name}: {last_status} (last: {last_run})")


# =============================================================================
# Main
# =============================================================================

def main():
    parser = argparse.ArgumentParser(description="Registry management for syscfg")
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # GPG commands
    gpg_parser = subparsers.add_parser("gpg", help="GPG key management")
    gpg_sub = gpg_parser.add_subparsers(dest="gpg_command")
    
    gpg_sub.add_parser("list", help="List registered GPG keys")
    
    gpg_add_p = gpg_sub.add_parser("add", help="Add GPG key to registry")
    gpg_add_p.add_argument("--key-id", help="GPG key ID")
    gpg_add_p.add_argument("--scope", choices=["shared", "local"], default="local")
    gpg_add_p.add_argument("--purpose", help="Key purpose (git-signing, encryption, etc)")
    gpg_add_p.add_argument("--email", help="Associated email")
    
    gpg_export_p = gpg_sub.add_parser("export", help="Export shared keys")
    gpg_export_p.add_argument("--output", "-o", help="Output directory")
    gpg_export_p.add_argument("--include-secret", action="store_true", help="Include secret keys")
    
    # SSH commands
    ssh_parser = subparsers.add_parser("ssh", help="SSH key management")
    ssh_sub = ssh_parser.add_subparsers(dest="ssh_command")
    
    ssh_sub.add_parser("list", help="List registered SSH keys")
    
    ssh_add_p = ssh_sub.add_parser("add", help="Add SSH key to registry")
    ssh_add_p.add_argument("--name", required=True, help="Key name (e.g., github, hpc)")
    ssh_add_p.add_argument("--scope", choices=["shared", "local"], default="local")
    ssh_add_p.add_argument("--file", help="Path to private key file")
    ssh_add_p.add_argument("--registered-at", help="Comma-separated list of hosts")
    
    # Devenv commands (legacy, now prefer 'env')
    devenv_parser = subparsers.add_parser("devenv", help="Devenv project management (legacy, use 'env')")
    devenv_sub = devenv_parser.add_subparsers(dest="devenv_command")
    
    devenv_sub.add_parser("list", help="List registered devenv projects")
    
    devenv_scan_p = devenv_sub.add_parser("scan", help="Scan for devenv projects")
    devenv_scan_p.add_argument("--path", help="Path to scan")
    devenv_scan_p.add_argument("--no-interactive", action="store_true")
    
    devenv_add_p = devenv_sub.add_parser("add", help="Add devenv project")
    devenv_add_p.add_argument("--path", required=True, help="Project path")
    devenv_add_p.add_argument("--name", help="Project name")
    devenv_add_p.add_argument("--type", help="Project type")
    devenv_add_p.add_argument("--description", help="Description")
    
    # Environment commands (new, unified)
    env_parser = subparsers.add_parser("env", help="Environment management (devenv, docker, flake, etc.)")
    env_sub = env_parser.add_subparsers(dest="env_command")
    
    env_sub.add_parser("list", help="List all environments")
    
    env_scan_p = env_sub.add_parser("scan", help="Scan for all environment types")
    env_scan_p.add_argument("--path", help="Path to scan")
    env_scan_p.add_argument("--no-interactive", action="store_true")
    
    env_add_p = env_sub.add_parser("add", help="Add environment")
    env_add_p.add_argument("--path", required=True, help="Project path")
    env_add_p.add_argument("--name", help="Environment name")
    env_add_p.add_argument("--type", choices=["devenv", "flake", "docker", "docker-compose", "nix-shell", "direnv", "other"])
    env_add_p.add_argument("--description", help="Description")
    
    env_remove_p = env_sub.add_parser("remove", help="Remove environment")
    env_remove_p.add_argument("name", help="Environment name")
    
    env_touch_p = env_sub.add_parser("touch", help="Update last_used timestamp")
    env_touch_p.add_argument("name", help="Environment name or path")
    
    # Status command
    status_parser = subparsers.add_parser("status", help="Show registry status")
    status_parser.add_argument("--json", action="store_true", help="Output as JSON")
    
    args = parser.parse_args()
    registry = load_registry()
    
    if args.command == "gpg":
        if args.gpg_command == "list" or not args.gpg_command:
            gpg_list(registry)
        elif args.gpg_command == "add":
            gpg_add(registry, args)
        elif args.gpg_command == "export":
            gpg_export(registry, args)
    
    elif args.command == "ssh":
        if args.ssh_command == "list" or not args.ssh_command:
            ssh_list(registry)
        elif args.ssh_command == "add":
            ssh_add(registry, args)
    
    elif args.command == "devenv":
        if args.devenv_command == "list" or not args.devenv_command:
            devenv_list(registry)
        elif args.devenv_command == "scan":
            devenv_scan(registry, args)
        elif args.devenv_command == "add":
            devenv_add(registry, args)
    
    elif args.command == "env":
        if args.env_command == "list" or not args.env_command:
            env_list(registry)
        elif args.env_command == "scan":
            env_scan(registry, args)
        elif args.env_command == "add":
            env_add(registry, args)
        elif args.env_command == "remove":
            env_remove(registry, args)
        elif args.env_command == "touch":
            env_update_usage(registry, args)
    
    elif args.command == "status":
        show_status(registry, args)
    
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
