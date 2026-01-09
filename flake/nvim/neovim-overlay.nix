# Neovim overlay using nixCats-nvim
# nixCats provides a flexible way to configure neovim with nix
{inputs}: final: prev:
let
  inherit (inputs.nixcats-nvim) utils;
  
  # Build neovim with nixCats
  nixCatsBuilder = utils.baseBuilder prev.lua5_1.luaPath {
    pkgs = prev;
    nixpkgs_version = prev.lib.version;
  } {
    # Configure what to include
    categoryDefinitions = { pkgs, settings, categories, name, ... }: {
      # LSPs and formatters available in PATH
      lspsAndRuntimeDeps = with pkgs; {
        general = [
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
          stylua
          black
          isort
          prettier
          shfmt
          nixfmt-rfc-style
          shellcheck
          ripgrep
          fd
          lazygit
          tree-sitter
        ];
      };
      
      # Let AstroNvim/Lazy manage plugins
      startupPlugins = { general = []; };
      optionalPlugins = { general = []; };
      sharedLibraries = { general = []; };
      environmentVariables = { general = {}; };
      extraWrapperArgs = { general = []; };
      extraPython3Packages = { general = _: []; };
      extraLuaPackages = { general = []; };
    };
    
    # Package definition
    packageDefinitions = {
      sysflake-nvim = { pkgs, ... }: {
        settings = {
          wrapRc = true;
          viAlias = true;
          vimAlias = true;
          withNodeJs = true;
          withPython3 = true;
          withRuby = false;
        };
        categories = {
          general = true;
        };
      };
    };
  };
in {
  # The final neovim package
  nvim-pkg = nixCatsBuilder.sysflake-nvim;
  nvim-dev = nixCatsBuilder.sysflake-nvim;
}
