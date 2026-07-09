{ config, pkgs, ... }: {
  imports = [
    ../../modules/home-manager/base.nix
    ../../modules/home-manager/vscode.nix
  ];
}
