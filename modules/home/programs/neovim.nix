{ config, pkgs, lib, ... }:
{
  # Neovim for AstroNvim
  # AstroNvim will manage its own plugins via Lazy.nvim
  # This provides neovim + LSPs/tools from nix
  
  programs.neovim = {
    enable = true;
    package = pkgs.nixcats-nvim.packages.${pkgs.system}.default;
    
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    
    withNodeJs = true;
    withPython3 = true;
    
    extraPackages = with pkgs; [
      # Language servers (for Mason/AstroNvim to use)
      lua-language-server
      nil
      nixd
      pyright
      ruff
      rust-analyzer
      typescript-language-server
      vscode-langservers-extracted  # html, css, json, eslint
      yaml-language-server
      marksman
      
      # Formatters
      stylua
      black
      isort
      prettier
      shfmt
      nixfmt-rfc-style
      shellcheck
      
      # Build tools
      gcc
      gnumake
      cmake
      
      # Essential tools
      ripgrep
      fd
      lazygit
      tree-sitter
    ];
  };
  
  # Session variables
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
