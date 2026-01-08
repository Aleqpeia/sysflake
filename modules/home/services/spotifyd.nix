{ config, lib, pkgs, ... }:

# Spotifyd - lightweight Spotify daemon
#
# This runs a headless Spotify Connect daemon that appears as a device
# in Spotify apps. Control playback from phone/web/desktop client.
#
# Requirements:
# - Spotify Premium account
# - Audio output configured (PipeWire/PulseAudio)
#
# First-time setup:
# 1. Run: systemctl --user start spotifyd
# 2. Open Spotify on phone/web
# 3. Select this device from "Connect to a device"
#
# For credentials, either:
# - Set SPOTIFY_USERNAME and use password_cmd with a secrets manager
# - Use Spotify's device authorization (recommended)

let
  cfg = config.services.spotifyd;
in {
  services.spotifyd = {
    enable = true;

    settings = {
      global = {
        # Device name shown in Spotify Connect
        device_name = config.home.sessionVariables.SYSCFG_HOST or "nixos";

        # Audio backend - use pulseaudio for PipeWire compatibility
        backend = "pulseaudio";

        # Audio quality: normal (96kbps), high (160kbps), very_high (320kbps)
        bitrate = 320;

        # Volume normalization
        volume_normalisation = true;
        normalisation_pregain = -10;

        # Cache for offline capability and faster startup
        cache_path = "${config.xdg.cacheHome}/spotifyd";

        # Device type affects icon in Spotify app
        device_type = "computer";

        # Zeroconf for automatic discovery on local network
        zeroconf_port = 5354;

        # Credentials - uncomment and configure ONE method:
        #
        # Method 1: Environment variables (set SPOTIFY_USERNAME externally)
        # username_cmd = "echo $SPOTIFY_USERNAME";
        # password_cmd = "pass show spotify/password";  # or: secret-tool lookup service spotify
        #
        # Method 2: Explicit (NOT recommended - secrets in nix store)
        # username = "your_username";
        # password = "your_password";
      };
    };
  };

  # Spotify TUI client for terminal-based control
  home.packages = with pkgs; [
    spotify-tui  # ncurses Spotify client (spt command)
    spotify-player  # Alternative TUI player
  ];

  # Shell aliases
  programs.zsh.shellAliases = {
    spotify = "spotify_player";
    spt = "spt";  # spotify-tui
  };
}

