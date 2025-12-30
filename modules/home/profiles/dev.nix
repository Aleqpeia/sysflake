{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Build tools
    gnumake
    cmake
    ninja
    pkg-config
    autoconf
    automake
    libtool

    # Languages - base tooling
    python3
    python3Packages.pip
    python3Packages.ipython
    rustup
    cargo-watch
    cargo-edit

    # Language servers & dev tools
    nixd
    nil
    pyright
    ruff
    rust-analyzer

    # Git ecosystem
    gh
    git-lfs
    lazygit
    delta
    difftastic

    # Containers
    podman-compose

    # Data tools
    sqlite
    duckdb

    # Debugging & profiling
    gdb
    strace
    ltrace
    hyperfine

    # Documentation
    pandoc

    # HPC tools (common ones - machine-specific may override)
    # slurm  # usually system package
    parallel
  ];

  # Devenv for project environments
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # Tmux for session management
  programs.tmux = {
    enable = true;
    shell = "${pkgs.zsh}/bin/zsh";
    terminal = "tmux-256color";
    historyLimit = 50000;
    escapeTime = 0;
    keyMode = "vi";
    prefix = "C-a";
    
    extraConfig = ''
      # Split panes using | and -
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"
      unbind '"'
      unbind %

      # Vim-like pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # Mouse support
      set -g mouse on

      # Status bar
      set -g status-style 'bg=#333333 fg=#5eacd3'
      set -g status-left-length 50
      set -g status-right '%Y-%m-%d %H:%M '
    '';
  };
}
