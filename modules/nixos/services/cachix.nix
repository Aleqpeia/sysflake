{ config, lib, pkgs, ... }:

# Cachix - Nix binary cache agent
#
# This configures the Cachix agent to automatically push builds to your cache.
# Useful for sharing builds between machines in your homelab.
#
# Setup:
# 1. Create a cache at https://app.cachix.org
# 2. Generate an auth token
# 3. Store the token securely and reference it below
#
# Manual push: cachix push <cache-name> /nix/store/...

{
  # Cachix CLI tools
  environment.systemPackages = [ pkgs.cachix ];

  # Add your Cachix cache as a substituter (for pulling)
  nix.settings = {
    substituters = [
      # Add your cache URL here
      "https://elifsina.cachix.org"
    ];
    trusted-public-keys = [
      # Add your cache public key here
      "elifsina.cachix.org-1:RZ1Y/ZzeHBrm4z51PY+OyFZDW/BOXbprha65ysdkwKg="
    ];
  };

  # Cachix agent for automatic pushing (optional)
  # Uncomment and configure if you want automatic cache population
  #
  # services.cachix-agent = {
  #   enable = true;
  #   name = "your-agent-name";
  #   credentialsFile = "/run/secrets/cachix-agent-token";
  # };

  # Alternative: Use cachix-watch-store to push all builds
  # This requires a systemd service that watches the store
  #
  # systemd.services.cachix-watch-store = {
  #   description = "Cachix watch store";
  #   wantedBy = [ "multi-user.target" ];
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   serviceConfig = {
  #     ExecStart = "${pkgs.cachix}/bin/cachix watch-store your-cache-name";
  #     Restart = "on-failure";
  #     RestartSec = "5s";
  #     EnvironmentFile = "/run/secrets/cachix-token";
  #   };
  # };
}

