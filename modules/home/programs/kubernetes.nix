{ config, lib, pkgs, ... }:

# Kubernetes CLI tooling for development and cluster management
#
# This module provides the standard k8s toolchain for interacting
# with clusters. For k3s server setup, see modules/nixos/services/k3s.nix

{
  home.packages = with pkgs; [
    # Core Kubernetes tools
    kubectl           # Official k8s CLI
    kubernetes-helm   # Package manager for k8s
    kustomize         # Template-free k8s configuration

    # Cluster management
    k9s               # Terminal UI for k8s
    kubectx           # Switch between contexts/namespaces
    kubeseal          # Sealed secrets for GitOps

    # Development & debugging
    stern             # Multi-pod log tailing
    kubectl-neat      # Clean up kubectl output
    kubecolor         # Colorized kubectl output

    # ArgoCD CLI (for GitOps workflows)
    argocd

    # Lens alternative (terminal-based)
    # kdash           # Uncomment if you prefer kdash over k9s
  ];

  # Kubeconfig location
  home.sessionVariables = {
    KUBECONFIG = "${config.home.homeDirectory}/.kube/config";
  };

  # Shell aliases for common operations
  programs.zsh.shellAliases = {
    k = "kubectl";
    kx = "kubectx";
    kn = "kubens";
    kgp = "kubectl get pods";
    kgs = "kubectl get svc";
    kgn = "kubectl get nodes";
    kga = "kubectl get all";
    kd = "kubectl describe";
    kl = "kubectl logs";
    klf = "kubectl logs -f";
    kaf = "kubectl apply -f";
    kdf = "kubectl delete -f";
    kex = "kubectl exec -it";

    # Helm shortcuts
    h = "helm";
    hls = "helm list -A";
    hui = "helm upgrade --install";

    # k9s with default namespace
    k9 = "k9s";

    # ArgoCD
    argocd-login = "argocd login --insecure";
  };

  # Kubectl completion
  programs.zsh.initExtra = ''
    # Kubectl completion
    if command -v kubectl &> /dev/null; then
      source <(kubectl completion zsh)
    fi

    # Helm completion
    if command -v helm &> /dev/null; then
      source <(helm completion zsh)
    fi
  '';

  # Create .kube directory
  home.file.".kube/.keep".text = "";
}

