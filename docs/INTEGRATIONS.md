# Integration Plan: FlakeHub, GitOps, Cachix

This document outlines the plan for connecting sysflake to external services.

---

## 1. Cachix (Binary Cache)

**Purpose:** Cache built derivations so you don't rebuild everything on each machine.

### Setup Steps

1. **Create cache at [cachix.org](https://app.cachix.org)**
   - Sign up / log in
   - Create a new cache (e.g., `efyis` or `sysflake`)
   - Note your auth token

2. **Configure local pushing:**
   ```bash
   # Install cachix
   nix profile install nixpkgs#cachix
   
   # Authenticate
   cachix authtoken <your-token>
   
   # Push builds to cache
   nix build .#homeConfigurations.proxima.activationPackage | cachix push efyis
   ```

3. **GitHub Actions for automatic pushing:**
   ```yaml
   # .github/workflows/build.yml
   name: Build and Cache
   on:
     push:
       branches: [master]
   
   jobs:
     build:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
         - uses: cachix/install-nix-action@v27
         - uses: cachix/cachix-action@v15
           with:
             name: efyis
             authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
         - run: nix build .#homeConfigurations.proxima.activationPackage
         - run: nix build .#homeConfigurations.altair.activationPackage
   ```

4. **Update flake.nix** (already has nix-community, add yours):
   ```nix
   nixConfig = {
     extra-substituters = [
       "https://nix-community.cachix.org"
       "https://efyis.cachix.org"
     ];
     extra-trusted-public-keys = [
       "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
       "efyis.cachix.org-1:YOUR_PUBLIC_KEY_HERE="
     ];
   };
   ```

---

## 2. FlakeHub (Determinate Systems)

**Purpose:** Publish your flake for discovery, versioning, and easy consumption.

### Setup Steps

1. **Sign up at [flakehub.com](https://flakehub.com)**
   - Connect your GitHub account
   - Authorize the FlakeHub app

2. **Add GitHub Action for publishing:**
   ```yaml
   # .github/workflows/flakehub.yml
   name: Publish to FlakeHub
   on:
     push:
       tags: ['v*']
     workflow_dispatch:
       inputs:
         tag:
           description: "Tag to publish"
           required: true
   
   jobs:
     publish:
       runs-on: ubuntu-latest
       permissions:
         id-token: write
         contents: read
       steps:
         - uses: actions/checkout@v4
         - uses: DeterminateSystems/nix-installer-action@main
         - uses: DeterminateSystems/flakehub-push@main
           with:
             visibility: "public"  # or "unlisted"
             name: "efyis/sysflake"
             rolling: true
   ```

3. **Create a release:**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

4. **Others can then use your flake:**
   ```bash
   nix flake show "https://flakehub.com/f/efyis/sysflake/*"
   ```

---

## 3. GitOps with ArgoCD

**Purpose:** Automatically deploy k8s manifests when you push changes.

### Prerequisites
- k3s running on proxima
- ArgoCD installed (see `k8s/README.md`)

### Setup Steps

1. **Install ArgoCD** (if not already):
   ```bash
   kubectl create namespace argocd
   kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
   kubectl apply -f k8s/argocd/service-nodeport.yaml
   ```

2. **Get initial admin password:**
   ```bash
   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
   ```

3. **Login to ArgoCD:**
   ```bash
   argocd login localhost:30080 --insecure --username admin --password <password>
   ```

4. **Add this repo:**
   ```bash
   argocd repo add https://github.com/Aleqpeia/sysflake --name sysflake
   ```

5. **Create an Application for the k8s manifests:**
   ```bash
   argocd app create homelab-infra \
     --repo https://github.com/Aleqpeia/sysflake \
     --path k8s \
     --dest-server https://kubernetes.default.svc \
     --dest-namespace default \
     --sync-policy automated \
     --self-heal
   ```

6. **Create ApplicationSet for multiple apps** (optional):
   ```yaml
   # k8s/argocd/applicationset.yaml
   apiVersion: argoproj.io/v1alpha1
   kind: ApplicationSet
   metadata:
     name: homelab-apps
     namespace: argocd
   spec:
     generators:
       - git:
           repoURL: https://github.com/Aleqpeia/sysflake
           revision: HEAD
           directories:
             - path: k8s/*
     template:
       metadata:
         name: '{{path.basename}}'
       spec:
         project: default
         source:
           repoURL: https://github.com/Aleqpeia/sysflake
           targetRevision: HEAD
           path: '{{path}}'
         destination:
           server: https://kubernetes.default.svc
           namespace: '{{path.basename}}'
         syncPolicy:
           automated:
             prune: true
             selfHeal: true
   ```

---

## Implementation Order

| Priority | Task | Effort | Dependencies |
|----------|------|--------|--------------|
| 1 | Cachix setup | Low | None |
| 2 | GitHub Actions for Cachix | Low | Cachix account |
| 3 | FlakeHub publishing | Low | None |
| 4 | ArgoCD installation | Medium | k3s running |
| 5 | GitOps configuration | Medium | ArgoCD |

---

## Required Secrets (GitHub)

Add these to your repo's Settings → Secrets → Actions:

| Secret Name | Where to get it |
|-------------|-----------------|
| `CACHIX_AUTH_TOKEN` | https://app.cachix.org → Settings → Auth Tokens |

FlakeHub uses OIDC, so no secret needed if you configure permissions correctly.

---

## File Structure After Integration

```
sysflake/
├── .github/
│   └── workflows/
│       ├── build.yml       # Cachix pushing
│       └── flakehub.yml    # FlakeHub publishing
├── k8s/
│   ├── argocd/
│   │   ├── applicationset.yaml  # GitOps config
│   │   └── ...
│   └── ...
└── ...
```

