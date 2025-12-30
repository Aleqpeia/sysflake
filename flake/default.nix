{
  inputs,
  lib,
  self,
  ...
}:
{
  imports = [
    ./apps
    ./nvim.nix
    ./overlays.nix
    ./pkgs-by-name.nix
    ./home-manager.nix
    ./nixos.nix
    inputs.flake-parts.flakeModules.partitions
  ];

  partitions = {
    dev = {
      module = ./dev;
      extraInputsFlake = ./dev;
    };
  };

  partitionedAttrs = {
    checks = "dev";
    devShells = "dev";
    formatter = "dev";
  };

  perSystem =
    {
      config,
      system,
      ...
    }:
    {
      _module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = lib.attrValues self.overlays;
        config = {
          allowUnfree = true;
        };
      };
      # Default package is the custom neovim
      packages.default = config.packages.khanelivim;
    };
}
