# Dev partition extra inputs
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs: {
    # Dev partition outputs will be handled by flake-parts
    inherit inputs;
  };
}
