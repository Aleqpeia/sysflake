{ config, lib, pkgs, ... }:

# Grafana - metrics visualization and dashboards
#
# Access at: http://localhost:3000
# Default login: admin / admin (change on first login)
#
# This is configured to work with the Prometheus instance from
# modules/nixos/services/prometheus.nix

{
  services.grafana = {
    enable = true;

    settings = {
      server = {
        http_addr = "0.0.0.0";  # Listen on all interfaces
        http_port = 3000;
        domain = "localhost";
        root_url = "http://localhost:3000";
      };

      # Security settings
      security = {
        admin_user = "admin";
        # Change this! Or use admin_password_file for secrets
        admin_password = "admin";
        # admin_password_file = "/run/secrets/grafana-admin-password";
      };

      # Anonymous access (disable for production)
      "auth.anonymous" = {
        enabled = false;
      };

      # Disable analytics
      analytics = {
        reporting_enabled = false;
        check_for_updates = false;
      };
    };

    # Provision datasources automatically
    provision = {
      enable = true;

      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:9090";
          isDefault = true;
          editable = false;
        }
      ];

      # Provision dashboards from a directory
      # dashboards.settings.providers = [
      #   {
      #     name = "default";
      #     options.path = "/var/lib/grafana/dashboards";
      #   }
      # ];
    };
  };

  # Open firewall for Grafana (only on trusted interfaces)
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 3000 ];
  };

  # Useful packages for dashboard management
  environment.systemPackages = with pkgs; [
    grafana-loki  # Log aggregation (optional)
  ];
}

