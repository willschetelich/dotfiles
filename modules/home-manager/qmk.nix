{ config, lib, pkgs, ... }:
let
  # Editable working-tree copy of the flattened keymap (NOT the nix-store copy),
  # so edits reflect without a rebuild.
  keymapSrc =
    "${config.home.homeDirectory}/dotfiles/modules/home-manager/keyboard-layouts/QMK/keyboards/svalboard/keymaps/SiriusStarr";
  qmkHome = "${config.home.homeDirectory}/qmk_firmware";
in {
  home.packages = with pkgs; [
    qmk   # CLI + bundled avr/arm toolchain + flashing utils (dfu-util etc.)
    git   # required by `qmk setup`
  ];

  # So `qmk` finds the firmware without re-running setup each time.
  home.sessionVariables.QMK_HOME = qmkHome;

  # Symlink this dotfiles keymap into the svalboard firmware tree, mirroring the
  # old flake's `ln -fs`. Guarded because the tree only exists after `qmk setup`.
  home.activation.linkSvalboardKeymap =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      keymaps="${qmkHome}/keyboards/svalboard/keymaps"
      if [ -d "$keymaps" ]; then
        run rm -rf $VERBOSE_ARG "$keymaps/SiriusStarr"
        run ln -s $VERBOSE_ARG "${keymapSrc}" "$keymaps/SiriusStarr"
      else
        echo "qmk_firmware not set up yet — run:"
        echo "  qmk setup svalboard/vial-qmk -b vial -y"
        echo "then re-run home-manager switch to link the SiriusStarr keymap."
      fi
    '';
}
