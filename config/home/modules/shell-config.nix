{ config, pkgs, ... }: {
  programs.bash = {
    enable = true;
    shellAliases = {
      nix-rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles#nixos";
    };
  };
}
