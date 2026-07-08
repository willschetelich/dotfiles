{ config, pkgs, ... }: {
  programs.bash = {
    enable = true;
    shellAliases = {
      nix-rebuild-thinkpad = "sudo nixos-rebuild switch --flake ~/dotfiles#thinkpad";
    };
  };
}
