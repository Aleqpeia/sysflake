{ inputs, self, lib, ... }:
let
  # Host registry: declares which hosts exist and their properties
  hosts = {
    altair = {
      system = "x86_64-linux";
      mode = "standalone";  # EndevourOS with home-manager
      username = "efyis";
      profiles = [ "base" "dev" "gui" ];
    };
    proxima = {
      system = "x86_64-linux";
      mode = "standalone";
      username = "efyis";
      profiles = [ "base" "dev" "gui" ];
    };
    vega = {
      system = "x86_64-linux";
      mode = "nixos";  # Full NixOS system
      username = "efyis";
      profiles = [ "base" "dev" ];
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
