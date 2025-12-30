{ pkgs, lib, hostConfig, ... }:
{
  # Nix settings
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      trusted-users = [ "root" hostConfig.username ];
      
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      ];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 30d";
    };
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Boot
  boot = {
    loader = {
      systemd-boot.enable = lib.mkDefault true;
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    
    # Kernel
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    
    # Tmp on tmpfs
    tmp.useTmpfs = true;
  };

  # Timezone and locale
  time.timeZone = lib.mkDefault "Europe/Kyiv";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_TIME = "en_GB.UTF-8";
    };
  };

  # Console
  console = {
    font = "Lat2-Terminus16";
    keyMap = lib.mkDefault "us";
  };

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Users
  users.users.${hostConfig.username} = {
    isNormalUser = true;
    extraGroups = [ 
      "wheel" 
      "networkmanager" 
      "video" 
      "audio"
      "docker"
      "podman"
    ];
    shell = pkgs.zsh;
  };

  # Enable zsh system-wide
  programs.zsh.enable = true;

  # Essential system packages
  environment.systemPackages = with pkgs; [
    vim
    git
    curl
    wget
    htop
    pciutils
    usbutils
    lsof
    file
    tree
  ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Containers
  virtualisation = {
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
  };

  # Security
  security = {
    sudo.wheelNeedsPassword = true;
    rtkit.enable = true;  # For audio
  };

  # Documentation
  documentation = {
    enable = true;
    man.enable = true;
    dev.enable = true;
  };

  system.stateVersion = "24.05";
}
