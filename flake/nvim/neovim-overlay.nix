# Neovim overlay for AstroNvim
# This provides a minimal neovim with LSPs and tools, letting AstroNvim manage plugins
{inputs}: final: prev:
with final.pkgs.lib; let
  pkgs = final;
in {
  # Neovim with AstroNvim-compatible setup
  nvim-pkg = pkgs.neovim-unwrapped.overrideAttrs (old: {
    propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ (with pkgs; [
      # Language servers
      lua-language-server
      nil                    # Nix LSP
      nixd                   # Nix LSP (alternative)
      pyright                # Python LSP
      ruff                   # Python linter/formatter
      rust-analyzer          # Rust LSP
      typescript-language-server  # TypeScript/JavaScript LSP
      vscode-langservers-extracted  # HTML/CSS/JSON/ESLint LSPs
      yaml-language-server   # YAML LSP
      marksman               # Markdown LSP
      
      # Formatters
      stylua                 # Lua
      black                  # Python
      isort                  # Python imports
      prettier               # JS/TS/JSON/YAML/Markdown
      shfmt                  # Shell
      nixfmt-rfc-style       # Nix
      
      # Linters
      shellcheck             # Shell
      
      # DAP (Debug Adapter Protocol)
      # vscode-js-debug      # JavaScript/TypeScript debugging
      
      # Build tools
      gcc
      gnumake
      cmake
      
      # Essential tools
      git
      ripgrep
      fd
      lazygit
      tree-sitter
    ]);
  });

  # For development/testing
  nvim-dev = pkgs.nvim-pkg;
}
