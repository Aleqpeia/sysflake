# Your existing pkgs-by-name config
# Copy your current pkgs-by-name.nix content here
{ inputs, ... }:
{
  imports = [
    inputs.pkgs-by-name-for-flake-parts.flakeModule
  ];

  perSystem = { ... }: {
    pkgsDirectory = ../pkgs;
  };
}
