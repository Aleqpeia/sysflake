{ pkgs, hostname, ... }:
{
  # Host-specific home-manager configuration for altair
  # Your main NixOS workstation

  home.packages = with pkgs; [
    # Additional tools specific to this machine
    # gromacs  # if you need nix version
  ];

  # Machine identification
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "nixos";
  };

  # Host-specific program overrides
  # programs.alacritty.settings.font.size = 12;
}
