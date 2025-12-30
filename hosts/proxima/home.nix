{ pkgs, hostname, ... }:
{
  # Host-specific home-manager configuration for proxima
  # Your Fedora home workstation

  home.packages = with pkgs; [
    # Additional packages for this machine
    obsidian
    zotero
    
    # Things that work better via nix on Fedora
    devenv
  ];

  # Machine identification
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "standalone";
  };

  # Fedora-specific adjustments
  # Font size might differ from NixOS machine
  # programs.alacritty.settings.font.size = 11;

  # Systemd user services for standalone home-manager
  # (NixOS handles this differently)
  systemd.user.startServices = "sd-switch";
}
