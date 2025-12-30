{ pkgs, ... }:
{
  home.packages = with pkgs; [
    # Core utils
    coreutils
    findutils
    ripgrep
    fd
    jq
    yq-go
    htop
    btop
    tree
    file
    which

    # Compression
    gzip
    unzip
    p7zip
    zstd

    # Network
    curl
    wget
    rsync

    # Text processing
    gawk
    gnused
    gnugrep

    # System info
    pciutils
    usbutils
    lsof
  ];

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
  };

  programs.bat = {
    enable = true;
    config = {
      theme = "TwoDark";
      style = "numbers,changes,header";
    };
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.tealdeer = {
    enable = true;
    settings = {
      updates.auto_update = true;
    };
  };
}
