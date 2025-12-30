{ pkgs, self, ... }:
{
  # Use nixvim from the flake's packages
  # This wraps your existing nixvim configuration
  home.packages = [
    self.packages.${pkgs.system}.khanelivim
  ];

  # Ensure nim is the default editor
  home.sessionVariables = {
    EDITOR = "nim";
    VISUAL = "nim";
  };

  # Additional neovim-related packages
  home.packages = with pkgs; [
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
  ];
}
