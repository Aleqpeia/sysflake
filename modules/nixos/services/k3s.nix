{ config, lib, pkgs, hostConfig, ... }:

# k3s - Lightweight Kubernetes for homelab
#
# This configures a single-node k3s cluster suitable for homelab use.
# For multi-node clusters, configure agents on other machines.
#
# After enabling:
# 1. Kubeconfig is at: /etc/rancher/k3s/k3s.yaml
# 2. Copy to user: sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $USER ~/.kube/config
# 3. Or use: export KUBECONFIG=/etc/rancher/k3s/k3s.yaml
#
# Default components installed:
# - CoreDNS
# - Traefik ingress (can be disabled)
# - Local-path provisioner (basic storage)
# - Metrics server

{
  services.k3s = {
    enable = true;
    role = "server";

    # Disable Traefik if you want to use your own ingress
    # extraFlags = toString [
    #   "--disable traefik"
    #   "--disable servicelb"  # Disable if using MetalLB
    # ];

    # For external access via Tailscale, advertise Tailscale IP
    # extraFlags = toString [
    #   "--tls-san=$(tailscale ip -4)"
    #   "--advertise-address=$(tailscale ip -4)"
    # ];
  };

  # Open firewall ports for k3s
  networking.firewall = {
    allowedTCPPorts = [
      6443  # Kubernetes API server
      10250 # Kubelet metrics
    ];

    # For Flannel VXLAN (default CNI)
    allowedUDPPorts = [ 8472 ];

    # If using NodePort services (30000-32767)
    allowedTCPPortRanges = [
      { from = 30000; to = 32767; }
    ];
  };

  # k3s uses containerd, but kubectl is useful on the host
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
  ];

  # Create convenience symlink for kubeconfig
  # The k3s service creates /etc/rancher/k3s/k3s.yaml
  system.activationScripts.k3s-kubeconfig = ''
    mkdir -p /home/${hostConfig.username}/.kube
    if [ -f /etc/rancher/k3s/k3s.yaml ]; then
      cp /etc/rancher/k3s/k3s.yaml /home/${hostConfig.username}/.kube/config
      chown ${hostConfig.username}:users /home/${hostConfig.username}/.kube/config
      chmod 600 /home/${hostConfig.username}/.kube/config
    fi
  '';
}

