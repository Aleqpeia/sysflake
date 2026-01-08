# Neovim overlay - provides stable neovim
# LSPs and tools are provided by home-manager separately
{inputs}: final: prev:
{
  # Use stable neovim from nixpkgs
  nvim-pkg = prev.neovim-unwrapped;
  
  # For development/testing
  nvim-dev = prev.neovim-unwrapped;
}
