
# Custom Neovim configuration
# Uses mkNeovim.nix builder with overlay
{ ... }:
{
  perSystem = { pkgs, system, ... }: {
    # Expose neovim packages from the overlay
    packages = {
      # Main neovim package (used as default)
      catvim = pkgs.nvim-pkg;
      
      # Development version (loads config from ~/.config/nvim-dev)
      catvim-dev = pkgs.nvim-dev;
      
      # Luarc for LSP integration in devshells
      nvim-luarc-json = pkgs.nvim-luarc-json;
    };
  };
}

