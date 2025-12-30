{ pkgs, hostname, ... }:
{
  # Host-specific home-manager configuration for vega
  # Work-based workstation (no gui profile)

  home.packages = with pkgs; [
    # Work-specific tools
    devenv
  ];

  # Machine identification
  home.sessionVariables = {
    SYSCFG_HOST = hostname;
    SYSCFG_MODE = "standalone";
  };

  # Work-specific overrides
  # Different git email, etc. - put in private/hosts/vega/home.nix

  systemd.user.startServices = "sd-switch";
}
