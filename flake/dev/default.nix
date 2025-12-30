# Your existing dev partition
# Copy your current dev/default.nix content here
{ ... }:
{
  perSystem = { pkgs, ... }: {
    devShells.default = pkgs.mkShell {
      packages = with pkgs; [
        nixd
        nil
        nixfmt-rfc-style
      ];
    };

    formatter = pkgs.nixfmt-rfc-style;
  };
}
