{ ... }:
{
  imports = [
    ./base.nix

    # Services - uncomment as needed per host
    # ./services/tailscale.nix
    # ./services/k3s.nix
    # ./services/prometheus.nix
    # ./services/grafana.nix
    # ./services/cachix.nix
  ];
}
