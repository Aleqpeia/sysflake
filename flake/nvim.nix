
# Custom Neovim configuration
# Uses mkNeovim.nix builder with overlay
{ ... }:
{
  perSystem = { pkgs, system, ... }: {
    # Expose neovim packages from the overlay
    packages = {
      # Main neovim package (used as default)
      efyisvim = pkgs.neovim-unwrapped;
      
      # Development version (loads config from ~/.config/nvim-dev)
      efyisvim-dev = pkgs.neovim-unwrapped;
      
      # Luarc for LSP integration in devshells
      nvim-luarc-json = pkgs.nvim-luarc-json;
    };
  };
}

