{ lib, hostConfig, ... }:
let
  # Map profile names to modules
  profileModules = {
    base = ./profiles/base.nix;
    dev = ./profiles/dev.nix;
    gui = ./profiles/gui.nix;
  };

  enabledProfiles = map (p: profileModules.${p}) hostConfig.profiles;

in {
  imports = [
    ./programs/zsh.nix
    ./programs/git.nix
    ./programs/direnv.nix
    ./programs/neovim.nix
  ] ++ enabledProfiles;

  # Base home-manager config
  home = {
    username = lib.mkDefault hostConfig.username;
    homeDirectory = lib.mkDefault "/home/${hostConfig.username}";
    stateVersion = "24.05";
  };

  programs.home-manager.enable = true;

  # XDG directories
  xdg.enable = true;
}
