{ inputs, self, lib, ... }:
let
  # Host registry: declares which hosts exist and their properties
  #
  # Both hosts use standalone mode (home-manager only).
  # System services (tailscale, k3s, etc.) are installed via the
  # system package manager or run as containers.
  hosts = {
    altair = {
      system = "x86_64-linux";
      mode = "standalone";  # EndevourOS with home-manager
      username = "efyis";
      profiles = [ "base" "dev" "gui" ];
    };
    proxima = {
      system = "x86_64-linux";
      mode = "standalone";  # NixOS with home-manager (system config via /etc/nixos)
      username = "efyis";
      profiles = [ "base" "dev" "gui" ];
    };
  };

  # Only standalone hosts get homeConfigurations output
  standaloneHosts = lib.filterAttrs (_: h: h.mode == "standalone") hosts;

  mkHomeConfiguration = hostname: hostCfg:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = import inputs.nixpkgs {
        system = hostCfg.system;
        overlays = lib.attrValues self.overlays;
        config.allowUnfree = true;
      };
      extraSpecialArgs = {
        inherit inputs self hostname;
        hostConfig = hostCfg;
      };
      modules = [
        ../modules/home
        ../hosts/${hostname}/home.nix
      ] ++ lib.optional (builtins.pathExists ../private/hosts/${hostname}/home.nix)
           ../private/hosts/${hostname}/home.nix;
    };

in {
  # Export host registry for use elsewhere
  flake.lib.hosts = hosts;

  # Generate homeConfigurations for standalone hosts
  flake.homeConfigurations = lib.mapAttrs mkHomeConfiguration standaloneHosts;
}
