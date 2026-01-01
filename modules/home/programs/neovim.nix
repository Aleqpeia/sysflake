{ pkgs, self, ... }:
{
  # Use custom nvim from the flake's packages
  # This wraps your existing neovim configuration
  home.packages = [
    self.packages.${pkgs.system}.khanelivim
  ]
  ++ (with pkgs; [
    # Clipboard support
    wl-clipboard
    xclip

    # Tree-sitter CLI for grammar updates
    tree-sitter

    # Language-specific formatters/tools (supplement what's in nixvim)
    nodePackages.prettier
    shfmt
    stylua
    nixfmt-rfc-style
  ]);

  # Ensure nvim is the default editor
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };
}
