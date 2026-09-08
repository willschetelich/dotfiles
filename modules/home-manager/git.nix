{ config, pkgs, ... }: {
  programs.git = {
    enable = true;
    settings.user = {
      name = "willschetelich";
      email = "willschetelich@gmail.com";
    };
  };
}
