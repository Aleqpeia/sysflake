# Kubernetes Manifests for Homelab

This directory contains Kubernetes manifests for deploying infrastructure
components to the k3s cluster running on proxima.

## Prerequisites

1. k3s cluster running on proxima (NixOS workstation)
2. `kubectl` configured to access the cluster
3. `helm` installed (via home-manager modules)

## Deployment Order

Deploy components in this order:

1. **MetalLB** - Load balancer (required for external service access)
2. **Longhorn** - Distributed storage
3. **ArgoCD** - GitOps controller (can then manage itself and other apps)

## Quick Start

```bash
# On proxima (or from altair with kubeconfig copied)

# 1. Deploy MetalLB
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
# Edit k8s/metallb/config.yaml with your IP range first!
kubectl apply -f k8s/metallb/config.yaml

# 2. Deploy Longhorn
kubectl apply -f k8s/longhorn/namespace.yaml
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn -n longhorn-system -f k8s/longhorn/values.yaml

# 3. Deploy ArgoCD
kubectl apply -f k8s/argocd/namespace.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f k8s/argocd/service-nodeport.yaml
# Get initial admin password:
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

## Accessing Services

Access services locally on proxima or via Tailscale from other machines:

- **ArgoCD UI**: https://localhost:30080 (or https://proxima:30080 via Tailscale)
- **Longhorn UI**: http://localhost:30081
- **Grafana**: http://localhost:3000
- **Prometheus**: http://localhost:9090

## GitOps with ArgoCD

Once ArgoCD is running, you can configure it to manage this repository:

```bash
argocd login localhost:30080 --insecure
argocd repo add https://github.com/yourusername/sysflake --name sysflake
argocd app create homelab \
  --repo https://github.com/yourusername/sysflake \
  --path k8s/apps \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace default
```

