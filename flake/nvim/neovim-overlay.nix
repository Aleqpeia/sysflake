# Neovim overlay - minimal, just marks that neovim is available
# The actual configuration is done in home-manager
{inputs}: final: prev:
{
  # Just pass through neovim - home-manager will configure it
  nvim-pkg = prev.neovim;
  nvim-dev = prev.neovim;
}
