{ config, pkgs, lib, hostname, ... }:
{
  # Create a separate sysflake config file instead of managing .zshrc
  # Source this from your existing .zshrc by adding:
  #   [ -f ~/.config/zsh/sysflake.zsh ] && source ~/.config/zsh/sysflake.zsh
  
  home.file.".config/zsh/sysflake.zsh".text = ''
    # ============================================================================
    # Sysflake Environment Configuration
    # This file is managed by home-manager
    # ============================================================================


    # Environment variables
    export SYSCFG_HOST="${hostname}"
    export SYSCFG_ROOT="$HOME/projects/sysflake"
    
    # Aliases - Navigation
    alias ..="cd .."
    alias ...="cd ../.."
    alias ....="cd ../../.."

    # Aliases - Modern replacements
    alias ls="eza"
    alias ll="eza -la"
    alias la="eza -a"
    alias lt="eza --tree --level=2"
    alias cat="bat"
    
    # Aliases - Git (your existing config probably has these)
    alias g="git"
    alias gs="git status -sb"
    alias gd="git diff"
    alias gds="git diff --staged"
    alias gc="git commit"
    alias gca="git commit --amend"
    alias gco="git checkout"
    alias gb="git branch"
    alias gp="git push"
    alias gpl="git pull"
    alias gl="git log --oneline --graph -20"
    alias gla="git log --oneline --graph --all"

    # Aliases - Nix/Home Manager
    alias nrs="sudo nixos-rebuild switch --flake ~/projects/sysflake#${hostname}"
    alias nrb="sudo nixos-rebuild boot --flake ~/projects/sysflake#${hostname}"
    alias hms="home-manager switch --flake ~/projects/sysflake#${hostname}"
    alias nfu="nix flake update"
    alias nfc="nix flake check"
    alias nsh="nix-shell"
    alias ndev="nix develop"

    # Aliases - Editors
    alias v="nvim"
    alias vi="nvim"
    alias vim="nvim"

    # Aliases - System
    alias sc="sudo systemctl"
    alias scu="systemctl --user"
    alias jc="journalctl"
    alias jcu="journalctl --user"

    # Aliases - Quick edits
    alias zshrc="$EDITOR ~/projects/sysflake/modules/home/programs/zsh.nix"
    alias nixcfg="cd ~/projects/sysflake && $EDITOR ."

    # Kubernetes aliases (from kubernetes module)
    alias k="kubectl"
    alias kx="kubectx"
    alias kn="kubens"
    alias kgp="kubectl get pods"
    alias kgs="kubectl get svc"
    alias kgn="kubectl get nodes"
    alias kga="kubectl get all"
    alias kd="kubectl describe"
    alias kl="kubectl logs"
    alias klf="kubectl logs -f"
    alias kaf="kubectl apply -f"
    alias kdf="kubectl delete -f"
    alias kex="kubectl exec -it"
    alias h="helm"
    alias hls="helm list -A"
    alias hui="helm upgrade --install"
    alias k9="k9s"
    
    # Tailscale aliases
    alias ts="tailscale"
    alias tss="tailscale status"
    alias tsup="sudo tailscale up"
    alias tsdown="sudo tailscale down"
    alias tsip="tailscale ip -4"
    alias tsping="tailscale ping"

    # Load local overrides if present
    [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
  '';

  # Don't manage the main .zshrc, just provide environment
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_ROOT = "$HOME/projects/sysflake";
  };
}
