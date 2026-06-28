{ config, pkgs, ... }: {
  programs.git = {
    enable = true;
    userName = "willschetelich";
    userEmail = "willschetelich@gmail.com";
  };
}
