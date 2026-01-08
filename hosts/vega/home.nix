{ pkgs, hostname, ... }:
{
  # Host-specific home-manager configuration for vega
  # Primary homelab server - no GUI, headless operation
  #
  # This host runs:
  # - k3s (Kubernetes)
  # - Prometheus & Grafana (monitoring)
  # - Tailscale (mesh VPN)

  home.packages = with pkgs; [
    # Development
    devenv

    # Server management
    ncdu      # Disk usage
    duf       # Modern df
    bandwhich # Network utilization
  ];

  # Machine identification
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "nixos";

    # k3s kubeconfig is copied to ~/.kube/config by system activation
    KUBECONFIG = "$HOME/.kube/config";
  };

  # Spotifyd - if you want music on the server
  services.spotifyd.settings.global.device_name = "vega";

  # Work-specific overrides
  # Different git email, etc. - put in private/hosts/vega/home.nix
}
