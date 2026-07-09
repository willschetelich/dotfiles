{ config, pkgs, ... }: {
  imports = [
    ./shell-config.nix
    ./ssh.nix
    ./git.nix
    ./emacs.nix
    ./sway.nix
    ./waybar.nix
    ./foot.nix
    ./micro.nix
    ./fuzzel.nix
    ./gammastep.nix
    ./desktop.nix
  ];

  home.username = "will";
  home.homeDirectory = "/home/will";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  xdg.userDirs = {
    enable = true;
    createDirectories = false;
  };

  home.packages = with pkgs; [
    claude-code
    google-chrome
    obsidian
  ];
}
