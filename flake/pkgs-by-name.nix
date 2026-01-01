# pkgs-by-name integration for custom packages
{ inputs, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem = { config, ... }: {
    # Point to the pkgs directory for custom packages
    # This allows organizing packages in pkgs/<name>/package.nix style
    _module.args.pkgsDirectory = ../pkgs;
  };
}
