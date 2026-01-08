{ pkgs, ... }:
{
  imports = [
    ./hardware.nix

    # Homelab services
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/k3s.nix
    ../../modules/nixos/services/prometheus.nix
    ../../modules/nixos/services/grafana.nix
    # ../../modules/nixos/services/cachix.nix  # Uncomment after configuring
  ];

  # ===========================================================================
  # Host-specific NixOS configuration for vega
  # Primary homelab server running k3s cluster
  # ===========================================================================

  # No GUI - headless server
  # Access via SSH or Tailscale

  # Audio (for spotifyd if running on this host)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # Graphics (minimal for headless)
  hardware.graphics.enable = true;

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Development
    gcc
    gnumake
    cmake

    # System monitoring
    nvtopPackages.nvidia  # if you have nvidia
    # nvtopPackages.amd    # if AMD
    iotop
    nethogs
    ncdu

    # Container debugging
    dive  # Explore container layers
    skopeo  # Container image operations
  ];

  # ===========================================================================
  # k3s Configuration Overrides
  # ===========================================================================

  # Disable built-in load balancer if using MetalLB
  # services.k3s.extraFlags = toString [
  #   "--disable servicelb"
  #   "--disable traefik"  # If using different ingress
  # ];

  # ===========================================================================
  # Storage for k8s (Longhorn requirements)
  # ===========================================================================

  # Longhorn needs open-iscsi
  services.openiscsi = {
    enable = true;
    name = "vega-iscsi";
  };

  # NFS for shared storage (optional)
  # services.nfs.server.enable = true;

  # ===========================================================================
  # Networking
  # ===========================================================================

  # Static IP recommended for k8s server
  # networking.interfaces.eth0.ipv4.addresses = [{
  #   address = "192.168.1.100";
  #   prefixLength = 24;
  # }];

  # Enable IP forwarding for k8s networking
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };
}
