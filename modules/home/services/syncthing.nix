{ config, lib, pkgs, ... }:

{
  # Syncthing - continuous file synchronization service
  # Web interface will be available at http://localhost:8384
  services.syncthing = {
    enable = true;
    
    # Syncthing will run as a user service and start automatically
    # The systemd service is: syncthing.service
    
    # Data directory for syncthing database and config
    # Default: ~/.local/state/syncthing
    # tray.enable = true;  # Enable tray icon (requires GUI)
  };

  # Optional: Install syncthing-cli for command-line control
  home.packages = with pkgs; [
    syncthing
  ];
}
