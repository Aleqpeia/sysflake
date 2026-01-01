# Overlays for custom packages and modifications
{ inputs, ... }:
{
  flake.overlays = {
    # Default overlay includes neovim customization
    default = inputs.self.overlays.neovim-custom;

    # Neovim-nightly overlay from nixpkgs
    neovim-nightly = inputs.neovim-nightly-overlay.overlays.default;

    # Custom neovim configuration overlay
    neovim-custom = final: prev:
      let
        neovimOverlay = import ./nvim/neovim-overlay.nix { inherit inputs; };
      in
        neovimOverlay final prev;
  };
}
