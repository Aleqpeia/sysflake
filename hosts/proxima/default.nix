{ pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix

    # Homelab services
    ../../modules/nixos/services/tailscale.nix
    ../../modules/nixos/services/k3s.nix
    ../../modules/nixos/services/prometheus.nix
    ../../modules/nixos/services/grafana.nix
    # ../../modules/nixos/services/cachix.nix  # Uncomment after configuring
  ];

  # ===========================================================================
  # Host-specific NixOS configuration for proxima
  # Primary NixOS workstation running homelab k3s cluster
  # ===========================================================================

  # Desktop environment
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Graphics
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Additional system packages
  environment.systemPackages = with pkgs; [
    # Development
    gcc
    gnumake
    cmake

    # System monitoring
    # nvtopPackages.nvidia  # Uncomment if you have nvidia
    # nvtopPackages.amd     # Uncomment if AMD
    iotop
    nethogs
    ncdu

    # Container debugging
    dive
    skopeo
  ];

  # ===========================================================================
  # k3s Configuration
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
    name = "proxima-iscsi";
  };

  # ===========================================================================
  # Networking
  # ===========================================================================

  # Enable IP forwarding for k8s networking
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };
}
