{ config, lib, pkgs, ... }:

# Tailscale CLI tools and integration for home-manager
#
# NOTE: The tailscaled daemon must be installed and running at the system level:
# - NixOS: services.tailscale.enable = true (see modules/nixos/services/tailscale.nix)
# - Fedora: sudo dnf install tailscale && sudo systemctl enable --now tailscaled
# - Arch/EndevourOS: sudo pacman -S tailscale && sudo systemctl enable --now tailscaled
#
# This module provides the CLI tools and shell integration.

{
  home.packages = with pkgs; [
    tailscale
  ];

  # Shell aliases for common tailscale operations
  programs.zsh.shellAliases = {
    ts = "tailscale";
    tss = "tailscale status";
    tsup = "sudo tailscale up";
    tsdown = "sudo tailscale down";
    tsip = "tailscale ip -4";
    tsping = "tailscale ping";
  };

  # Environment variable for Tailscale API (if using programmatic access)
  # Set TS_AUTHKEY in your shell or secrets manager for automated provisioning
}

