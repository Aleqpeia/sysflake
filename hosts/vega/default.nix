{ pkgs, ... }:
{
  imports = [
    ./hardware.nix
  ];

  # Host-specific NixOS configuration for vega
  # Full NixOS system

  # Desktop environment (vega has no GUI by default as per profiles)
  # Uncomment if you want a GUI on vega:
  # services.displayManager.gdm.enable = true;
  # services.desktopManager.gnome.enable = true;

  # Audio
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # Graphics (adjust for your hardware)
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  # Additional system packages specific to this machine
  environment.systemPackages = with pkgs; [
    # Development
    gcc
    gnumake
    cmake
    
    # System tools
    nvtopPackages.nvidia  # if you have nvidia
    # nvtopPackages.amd    # if AMD
  ];

  # Host-specific services
  # services.slurm = { ... };  # If running SLURM locally
}
