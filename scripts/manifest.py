#!/usr/bin/env python3
"""
DNF package manifest reconciliation tool.

Usage:
  manifest.py status [--host=HOST]     Show drift between manifest and system
  manifest.py pull [--host=HOST]       Update manifest from current system state
  manifest.py apply [--host=HOST]      Install missing packages from manifest
  manifest.py diff [--host=HOST]       Show what apply would do (dry run)
"""

from __future__ import annotations

import subprocess
import socket
import sys
import argparse
from pathlib import Path
from datetime import datetime, timezone
from dataclasses import dataclass, field

# Handle both Python 3.11+ (tomllib builtin) and older versions
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


SCRIPT_DIR = Path(__file__).parent
REPO_ROOT = SCRIPT_DIR.parent
MANIFESTS_DIR = REPO_ROOT / "manifests"


@dataclass
class SystemState:
    """Current system package state."""
    packages: set[str] = field(default_factory=set)
    groups: set[str] = field(default_factory=set)
    flatpaks: set[str] = field(default_factory=set)
    copr_repos: set[str] = field(default_factory=set)


def get_hostname() -> str:
    return socket.gethostname()


def run_cmd(cmd: list[str], check: bool = True) -> subprocess.CompletedProcess:
    """Run a command and return the result."""
    return subprocess.run(cmd, capture_output=True, text=True, check=check)


def load_manifest(hostname: str) -> dict:
    """Load manifest for a host, or return empty template."""
    path = MANIFESTS_DIR / f"{hostname}.toml"
    if not path.exists():
        return {
            "meta": {
                "hostname": hostname,
                "updated": datetime.now(timezone.utc).isoformat(),
                "managed_by": "dnf",
            },
            "packages": {"system": [], "optional": [], "groups": []},
            "flatpak": {"packages": []},
            "copr": {"repos": []},
            "excluded": {"packages": []},
        }
    with open(path, "rb") as f:
        return tomllib.load(f)


def save_manifest(hostname: str, manifest: dict) -> None:
    """Save manifest to file."""
    manifest["meta"]["updated"] = datetime.now(timezone.utc).isoformat()
    path = MANIFESTS_DIR / f"{hostname}.toml"
    with open(path, "wb") as f:
        tomli_w.dump(manifest, f)
    print(f"Saved {path}")


def get_system_state() -> SystemState:
    """Query current system for installed packages."""
    state = SystemState()

    # DNF user-installed packages
    try:
        result = run_cmd(["dnf", "repoquery", "--userinstalled", "--qf", "%{name}"])
        state.packages = set(result.stdout.strip().split("\n")) - {""}
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("Warning: Could not query DNF packages", file=sys.stderr)

    # DNF groups
    try:
        result = run_cmd(["dnf", "group", "list", "--installed", "-q"], check=False)
        for line in result.stdout.strip().split("\n"):
            line = line.strip()
            if line and not line.startswith("Installed"):
                # Normalize group names
                state.groups.add(line.lower().replace(" ", "-"))
    except FileNotFoundError:
        pass

    # Flatpaks
    try:
        result = run_cmd(["flatpak", "list", "--app", "--columns=application"], check=False)
        if result.returncode == 0:
            state.flatpaks = set(result.stdout.strip().split("\n")) - {""}
    except FileNotFoundError:
        pass

    # COPR repos
    copr_dir = Path("/etc/yum.repos.d")
    if copr_dir.exists():
        for f in copr_dir.glob("_copr*.repo"):
            name = f.stem.replace("_copr:", "").replace("_copr_", "")
            state.copr_repos.add(name)

    return state


def status(hostname: str) -> int:
    """Show drift between manifest and system."""
    manifest = load_manifest(hostname)
    state = get_system_state()

    # Collect declared packages
    declared_pkgs = set(manifest.get("packages", {}).get("system", []))
    declared_pkgs |= set(manifest.get("packages", {}).get("optional", []))
    excluded = set(manifest.get("excluded", {}).get("packages", []))

    missing = declared_pkgs - state.packages
    extra = state.packages - declared_pkgs - excluded

    print(f"Host: {hostname}")
    print(f"Manifest packages: {len(declared_pkgs)}")
    print(f"System packages: {len(state.packages)}")
    print()

    if missing:
        print(f"❌ Missing from system ({len(missing)}):")
        for p in sorted(missing):
            print(f"  - {p}")
        print()

    if extra:
        print(f"➕ Extra on system, not in manifest ({len(extra)}):")
        for p in sorted(extra)[:30]:
            print(f"  + {p}")
        if len(extra) > 30:
            print(f"  ... and {len(extra) - 30} more")
        print()

    # Flatpaks
    declared_flatpaks = set(manifest.get("flatpak", {}).get("packages", []))
    missing_flatpaks = declared_flatpaks - state.flatpaks
    extra_flatpaks = state.flatpaks - declared_flatpaks

    if missing_flatpaks:
        print(f"❌ Missing flatpaks ({len(missing_flatpaks)}):")
        for p in sorted(missing_flatpaks):
            print(f"  - {p}")
        print()

    if extra_flatpaks:
        print(f"➕ Extra flatpaks ({len(extra_flatpaks)}):")
        for p in sorted(extra_flatpaks):
            print(f"  + {p}")
        print()

    if not missing and not extra and not missing_flatpaks:
        print("✓ System matches manifest")
        return 0

    return 1 if missing or missing_flatpaks else 0


def pull(hostname: str) -> None:
    """Update manifest from current system state."""
    manifest = load_manifest(hostname)
    state = get_system_state()

    # Get current manifest state
    current_system = set(manifest.get("packages", {}).get("system", []))
    current_optional = set(manifest.get("packages", {}).get("optional", []))
    excluded = set(manifest.get("excluded", {}).get("packages", []))

    # New packages go to optional by default
    all_declared = current_system | current_optional
    new_packages = state.packages - all_declared - excluded

    if new_packages:
        print(f"Adding {len(new_packages)} new packages to optional:")
        for p in sorted(new_packages)[:15]:
            print(f"  + {p}")
        if len(new_packages) > 15:
            print(f"  ... and {len(new_packages) - 15} more")

        manifest.setdefault("packages", {})
        manifest["packages"]["optional"] = sorted(current_optional | new_packages)

    # Update flatpaks
    current_flatpaks = set(manifest.get("flatpak", {}).get("packages", []))
    new_flatpaks = state.flatpaks - current_flatpaks
    if new_flatpaks:
        print(f"Adding {len(new_flatpaks)} new flatpaks:")
        for p in sorted(new_flatpaks):
            print(f"  + {p}")
        manifest.setdefault("flatpak", {})
        manifest["flatpak"]["packages"] = sorted(current_flatpaks | new_flatpaks)

    save_manifest(hostname, manifest)


def apply(hostname: str, dry_run: bool = False) -> None:
    """Install missing packages from manifest."""
    manifest = load_manifest(hostname)
    state = get_system_state()

    # Only apply 'system' packages (not optional)
    declared_pkgs = set(manifest.get("packages", {}).get("system", []))
    missing = declared_pkgs - state.packages

    declared_groups = set(manifest.get("packages", {}).get("groups", []))
    # Groups are harder to compare; skip for now

    declared_flatpaks = set(manifest.get("flatpak", {}).get("packages", []))
    missing_flatpaks = declared_flatpaks - state.flatpaks

    if not missing and not missing_flatpaks:
        print("✓ Nothing to install")
        return

    if missing:
        print(f"Installing {len(missing)} DNF packages:")
        for p in sorted(missing):
            print(f"  {p}")

        if not dry_run:
            subprocess.run(["sudo", "dnf", "install", "-y"] + sorted(missing), check=True)

    if missing_flatpaks:
        print(f"\nInstalling {len(missing_flatpaks)} Flatpaks:")
        for p in sorted(missing_flatpaks):
            print(f"  {p}")

        if not dry_run:
            for flatpak in sorted(missing_flatpaks):
                subprocess.run(["flatpak", "install", "-y", flatpak], check=True)

    if dry_run:
        print("\n(dry run, no changes made)")


def main():
    parser = argparse.ArgumentParser(
        description="DNF manifest reconciliation",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument(
        "command",
        choices=["status", "pull", "apply", "diff"],
        help="Command to run",
    )
    parser.add_argument(
        "--host",
        default=get_hostname(),
        help="Hostname (default: current host)",
    )
    args = parser.parse_args()

    if args.command == "status":
        sys.exit(status(args.host))
    elif args.command == "pull":
        pull(args.host)
    elif args.command == "apply":
        apply(args.host)
    elif args.command == "diff":
        apply(args.host, dry_run=True)


if __name__ == "__main__":
    main()
