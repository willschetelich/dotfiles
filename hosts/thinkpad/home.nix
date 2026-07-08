{ config, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/shell-config.nix
    ../../modules/home-manager/ssh.nix
    ../../modules/home-manager/git.nix
    ../../modules/home-manager/vscode.nix
    ../../modules/home-manager/emacs.nix
    ../../modules/home-manager/sway.nix
    ../../modules/home-manager/waybar.nix
    ../../modules/home-manager/foot.nix
    ../../modules/home-manager/fuzzel.nix
    ../../modules/home-manager/desktop.nix
  ];

  home.username = "will";
  home.homeDirectory = "/home/will";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    claude-code
    google-chrome
    obsidian
  ];
}
