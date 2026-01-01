{ config, pkgs, lib, hostname, ... }:
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    enableCompletion = true;

    # Set dotDir to XDG config directory (new default in 26.05+)
    dotDir = "${config.xdg.configHome}/zsh";

    history = {
      size = 100000;
      save = 100000;
      path = "${config.xdg.dataHome}/zsh/history";
      ignoreDups = true;
      ignoreAllDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    shellAliases = {
      # Navigation
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";

      # Modern replacements
      ls = "eza";
      ll = "eza -la";
      la = "eza -a";
      lt = "eza --tree --level=2";
      cat = "bat";
      grep = "rg";
      find = "fd";
      
      # Git
      g = "git";
      gs = "git status -sb";
      gd = "git diff";
      gds = "git diff --staged";
      gc = "git commit";
      gca = "git commit --amend";
      gco = "git checkout";
      gb = "git branch";
      gp = "git push";
      gpl = "git pull";
      gl = "git log --oneline --graph -20";
      gla = "git log --oneline --graph --all";

      # Nix
      nrs = "sudo nixos-rebuild switch --flake ~/syscfg#${hostname}";
      nrb = "sudo nixos-rebuild boot --flake ~/syscfg#${hostname}";
      hms = "home-manager switch --flake ~/syscfg#${hostname}";
      nfu = "nix flake update";
      nfc = "nix flake check";
      nsh = "nix-shell";
      ndev = "nix develop";

      # Editors
      v = "nvim";
      vi = "nvim";
      vim = "nvim";

      # System
      sc = "sudo systemctl";
      scu = "systemctl --user";
      jc = "journalctl";
      jcu = "journalctl --user";

      # Quick edits
      zshrc = "$EDITOR ~/syscfg/modules/home/programs/zsh.nix";
      nixcfg = "cd ~/syscfg && $EDITOR .";

      # Safety
      rm = "rm -i";
      mv = "mv -i";
      cp = "cp -i";
    };

    # Zsh initialization content (replaces deprecated initExtraFirst/initExtra)
    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # Performance: only check compinit once a day
        autoload -Uz compinit
        if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
          compinit
        else
          compinit -C
        fi
      '')
      
      ''
        # History search with up/down arrows
        autoload -U up-line-or-beginning-search
        autoload -U down-line-or-beginning-search
        zle -N up-line-or-beginning-search
        zle -N down-line-or-beginning-search
        bindkey "^[[A" up-line-or-beginning-search
        bindkey "^[[B" down-line-or-beginning-search

        # Edit command in $EDITOR with Ctrl-X Ctrl-E
        autoload -z edit-command-line
        zle -N edit-command-line
        bindkey "^X^E" edit-command-line

        # Word navigation (Ctrl + arrows)
        bindkey "^[[1;5C" forward-word
        bindkey "^[[1;5D" backward-word

        # Better directory stack
        setopt AUTO_PUSHD
        setopt PUSHD_IGNORE_DUPS
        setopt PUSHD_SILENT

        # Globbing
        setopt EXTENDED_GLOB
        setopt NO_CASE_GLOB

        # Job control
        setopt NO_HUP
        setopt NO_BG_NICE

        # Host/mode identification
        export SYSCFG_HOST="${hostname}"

        # Load local overrides if present
        [[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
      ''
    ];
    plugins = [
      {
        name = "zsh-history-substring-search";
        src = pkgs.zsh-history-substring-search;
        file = "share/zsh-history-substring-search/zsh-history-substring-search.zsh";
      }
      {
        name = "zsh-nix-shell";
        src = pkgs.zsh-nix-shell;
        file = "share/zsh-nix-shell/nix-shell.plugin.zsh";
      }
    ];
  };

  programs.starship = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      add_newline = false;
      
      format = lib.concatStrings [
        "$username"
        "$hostname"
        "$directory"
        "$git_branch"
        "$git_status"
        "$python"
        "$rust"
        "$nix_shell"
        "$cmd_duration"
        "$line_break"
        "$character"
      ];

      character = {
        success_symbol = "[›](bold green)";
        error_symbol = "[›](bold red)";
        vimcmd_symbol = "[‹](bold green)";
      };

      directory = {
        truncation_length = 4;
        truncation_symbol = "…/";
        style = "bold cyan";
      };

      git_branch = {
        symbol = " ";
        style = "bold purple";
      };

      git_status = {
        format = "[$all_status$ahead_behind]($style) ";
        style = "bold red";
      };

      python = {
        symbol = " ";
        style = "bold yellow";
      };

      rust = {
        symbol = " ";
        style = "bold red";
      };

      nix_shell = {
        symbol = " ";
        format = "[$symbol$state]($style) ";
        style = "bold blue";
      };

      cmd_duration = {
        min_time = 2000;
        format = "[$duration]($style) ";
        style = "bold yellow";
      };

      hostname = {
        ssh_only = false;
        format = "[@$hostname]($style) ";
        style = "bold green";
      };

      username = {
        show_always = false;
        format = "[$user]($style)";
        style_user = "bold green";
      };
    };
  };
}
