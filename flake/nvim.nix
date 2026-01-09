
# Custom Neovim configuration
# Uses nixCats overlay
{ ... }:
{
  perSystem = { pkgs, system, ... }: {
    # Expose neovim packages from the overlay
    packages = {
      # Main neovim package (used as default)
      catvim = pkgs.nvim-pkg;
      
      # Development version
      catvim-dev = pkgs.nvim-dev;
    };
  };
}

