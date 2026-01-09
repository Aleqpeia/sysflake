# Overlays for custom packages and modifications
{ inputs, ... }:
{
  flake.overlays = {
    # Default overlay includes neovim customization
    default = inputs.self.overlays.neovim-custom;

    # Custom neovim configuration overlay (using nixCats)
    neovim-custom = final: prev:
      let
        neovimOverlay = import ./nvim/neovim-overlay.nix { inherit inputs; };
      in
        neovimOverlay final prev;
  };
}
