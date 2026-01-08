{ config, lib, pkgs, ... }:

# Tailscale VPN daemon for NixOS
#
# Provides mesh VPN connectivity between all your machines.
# After enabling, authenticate with: sudo tailscale up
#
# For automated/headless auth, use an auth key:
#   sudo tailscale up --authkey=tskey-auth-xxx
#
# Generate auth keys at: https://login.tailscale.com/admin/settings/keys

{
  # Enable the Tailscale daemon
  services.tailscale = {
    enable = true;

    # Open firewall for Tailscale
    openFirewall = true;

    # Use userspace networking (for containers/VMs)
    # useRoutingFeatures = "client";  # or "server" for exit node

    # Automatically authenticate on boot (requires auth key)
    # authKeyFile = "/run/secrets/tailscale-auth-key";
  };

  # Allow Tailscale's UDP port through firewall
  networking.firewall = {
    # Tailscale uses UDP 41641 by default
    allowedUDPPorts = [ 41641 ];

    # Trust the Tailscale interface for services
    trustedInterfaces = [ "tailscale0" ];

    # Allow traffic from Tailscale network (100.x.x.x)
    # This lets other Tailscale machines access services
  };

  # Tailscale CLI tools
  environment.systemPackages = [ pkgs.tailscale ];

  # Enable IP forwarding if this machine will be a subnet router or exit node
  # boot.kernel.sysctl = {
  #   "net.ipv4.ip_forward" = 1;
  #   "net.ipv6.conf.all.forwarding" = 1;
  # };
}

