# Overlays for custom packages and modifications
{ inputs, ... }:
{
  flake.overlays = {
    # Default overlay includes neovim customization
    default = inputs.self.overlays.neovim-custom;

    # Neovim-nightly overlay from nixpkgs
    nixcats-nvim = inputs.nixcats-nvim.overlays.nixcats-nvim;

    # Custom neovim configuration overlay
    neovim-custom = final: prev:
      let
        neovimOverlay = import ./nvim/neovim-overlay.nix { inherit inputs; };
      in
        neovimOverlay final prev;
  };
}
