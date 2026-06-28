{ config, pkgs, ... }: {
  imports = [
    ./modules/shell-config.nix
    ./modules/ssh.nix
    ./modules/git.nix
    ./modules/vscode.nix
    ./modules/emacs.nix
    ./modules/sway.nix
    ./modules/waybar.nix
    ./modules/foot.nix
    ./modules/fuzzel.nix
    ./modules/desktop.nix
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
