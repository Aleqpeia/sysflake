{ config, pkgs, lib, ... }:
{
  # Neovim configured via nixCats overlay
  # The overlay (flake/nvim/neovim-overlay.nix) already provides:
  # - neovim binary
  # - All LSPs and formatters in PATH
  # - Ready for AstroNvim to use
  
  programs.neovim = {
    enable = true;
    package = pkgs.nvim-pkg;  # From our nixCats overlay
    
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    
    # nixCats already handles these via the overlay
    withNodeJs = true;
    withPython3 = true;
  };
  
  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
