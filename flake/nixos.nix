{ inputs, self, lib, ... }:
let
  hosts = self.lib.hosts;
  nixosHosts = lib.filterAttrs (_: h: h.mode == "nixos") hosts;

  mkNixosConfiguration = hostname: hostCfg:
    inputs.nixpkgs.lib.nixosSystem {
      system = hostCfg.system;
      specialArgs = {
        inherit inputs self hostname;
        hostConfig = hostCfg;
      };
      modules = [
        inputs.home-manager.nixosModules.home-manager
        ../modules/nixos
        ../hosts/${hostname}
        {
          networking.hostName = hostname;
          
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            extraSpecialArgs = {
              inherit inputs self hostname;
              hostConfig = hostCfg;
            };
            users.${hostCfg.username} = { ... }: {
              imports = [
                ../../modules/home
                ./home.nix
              ] ++ lib.optional (builtins.pathExists ../../private/hosts/${hostname}/home.nix)
                   ../../private/hosts/${hostname}/home.nix;
            };
          };
        }
      ];
    };

in {
  flake.nixosConfigurations = lib.mapAttrs mkNixosConfiguration nixosHosts;
}
