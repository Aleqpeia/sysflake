{ config, pkgs, lib, ... }:
{
  # Neovim configured via home-manager
  # LSPs and tools are added to extraPackages
  # AstroNvim can then use them
  
  programs.neovim = {
    enable = true;
    
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    
    withNodeJs = true;
    withPython3 = true;
    
    # All LSPs and tools - will be in PATH when nvim runs
    extraPackages = with pkgs; [
      # Language servers
      lua-language-server
      nil
      nixd
      pyright
      ruff
      rust-analyzer
      typescript-language-server
      vscode-langservers-extracted
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
      
      # Essential tools
      gcc
      gnumake
      cmake
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
