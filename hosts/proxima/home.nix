{ pkgs, hostname, ... }:
{
  # Host-specific home-manager configuration for proxima
  # NixOS workstation - primary homelab machine with k3s
  #
  # Services running on this host:
  # - k3s (Kubernetes)
  # - Prometheus & Grafana (monitoring)
  # - Tailscale (mesh VPN)

  home.packages = with pkgs; [
    # Productivity
    obsidian
    zotero

    # Development
    devenv

    # Server/homelab management
    ncdu
    duf
    bandwhich

    # Remote access
    remmina
  ];

  # Machine identification
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "nixos";

    # k3s kubeconfig is copied to ~/.kube/config by system activation
    KUBECONFIG = "$HOME/.kube/config";
  };

  # Spotifyd configuration
  services.spotifyd.settings.global.device_name = "proxima";

  # GUI-specific overrides
  # programs.alacritty.settings.font.size = 11;
}
