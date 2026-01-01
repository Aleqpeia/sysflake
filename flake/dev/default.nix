# Dev partition - development shell and formatter
{ inputs, ... }:
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
