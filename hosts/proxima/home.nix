{ pkgs, hostname, ... }:
{
  # Host-specific home-manager configuration for proxima
  # NixOS workstation - primary homelab machine
  #
  # System services are managed separately:
  # - Tailscale: sudo systemctl enable --now tailscaled && sudo tailscale up
  # - k3s: See k8s/README.md for container-based or native setup
  # - Prometheus/Grafana: Use monitoring/podman-compose.yml

  home.packages = with pkgs; [
    # Productivity
    obsidian
    zotero

    # Development
    devenv

    # Homelab management
    ncdu
    duf
    bandwhich

    # Remote access
    remmina
  ];

  # Machine identification
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "standalone";

    # k3s kubeconfig (if running k3s)
    # KUBECONFIG = "$HOME/.kube/config";
  };

  # Spotifyd configuration
  services.spotifyd.settings.global.device_name = "proxima";

  # Systemd user services for standalone home-manager
  systemd.user.startServices = "sd-switch";
}
