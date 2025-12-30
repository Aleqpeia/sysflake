# Your existing overlays
# Copy your current overlays.nix content here
{ inputs, ... }:
{
  flake.overlays = {
    default = final: prev: {
      # Your overlays here
    };

    neovim-nightly = inputs.neovim-nightly-overlay.overlays.default;
  };
}
