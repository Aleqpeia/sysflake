{ config, lib, pkgs, ... }:

# Prometheus - metrics collection and alerting
#
# This provides native NixOS Prometheus instead of containerized.
# Access the UI at: http://localhost:9090
#
# For homelab use, this scrapes:
# - Node exporter (system metrics)
# - k3s metrics (if enabled)
# - Any services exposing /metrics endpoints

{
  services.prometheus = {
    enable = true;
    port = 9090;

    # Retention period for metrics
    retentionTime = "30d";

    # Global scrape settings
    globalConfig = {
      scrape_interval = "15s";
      evaluation_interval = "15s";
    };

    # Scrape configurations
    scrapeConfigs = [
      # Prometheus itself
      {
        job_name = "prometheus";
        static_configs = [{
          targets = [ "localhost:9090" ];
        }];
      }

      # Node exporter - system metrics
      {
        job_name = "node";
        static_configs = [{
          targets = [ "localhost:9100" ];
        }];
      }

      # k3s metrics (if running k3s)
      # {
      #   job_name = "k3s";
      #   static_configs = [{
      #     targets = [ "localhost:10250" ];
      #   }];
      #   scheme = "https";
      #   tls_config = {
      #     insecure_skip_verify = true;
      #   };
      # }

      # Add more scrape targets as needed:
      # - Grafana: localhost:3000
      # - Your applications
    ];

    # Alert rules (optional)
    # rules = [
    #   ''
    #     groups:
    #     - name: system
    #       rules:
    #       - alert: HighCPUUsage
    #         expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    #         for: 5m
    #         labels:
    #           severity: warning
    #         annotations:
    #           summary: "High CPU usage on {{ $labels.instance }}"
    #   ''
    # ];
  };

  # Node exporter for system metrics
  services.prometheus.exporters.node = {
    enable = true;
    port = 9100;
    enabledCollectors = [
      "cpu"
      "diskstats"
      "filesystem"
      "loadavg"
      "meminfo"
      "netdev"
      "stat"
      "time"
      "vmstat"
      "systemd"
      "processes"
    ];
  };

  # Open firewall for Prometheus (only on trusted interfaces)
  networking.firewall.interfaces."tailscale0" = {
    allowedTCPPorts = [ 9090 9100 ];
  };
}

