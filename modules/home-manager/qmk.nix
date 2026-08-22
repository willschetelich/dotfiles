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

  # Wire this dotfiles keymap into the svalboard firmware tree, doing what the
  # upstream flake's shellHook used to do. Guarded because the tree only exists
  # after `qmk setup`.
  home.activation.linkSvalboardKeymap =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      keymaps="${qmkHome}/keyboards/svalboard/keymaps"
      keymap="$keymaps/SiriusStarr"
      stray="${qmkHome}/users/SiriusStarr"

      if [ -d "$keymaps" ]; then
        # QMK sets USER_NAME := $(KEYMAP), so a users/SiriusStarr tree would be
        # compiled *alongside* the flat keymap and duplicate every SRC += file.
        # The flake cleared this on each shell entry; do the same, but only when
        # it is a symlink -- i.e. residue we can safely assume is ours.
        if [ -L "$stray" ]; then
          run rm -f $VERBOSE_ARG "$stray"
        elif [ -e "$stray" ]; then
          echo "ERROR: $stray exists as a real directory."
          echo "It shadows the flattened keymap and will break the build with duplicate symbols."
          echo "Remove or rename it, then re-run home-manager switch."
          exit 1
        fi

        # Never rm -rf here: if something real sits at the keymap path, stop and
        # let a human decide. (ln -sfn is NOT a substitute -- on a real directory
        # it silently creates the link *inside* it rather than failing.)
        if [ -e "$keymap" ] && [ ! -L "$keymap" ]; then
          echo "ERROR: $keymap exists and is not a symlink."
          echo "Refusing to replace it. Move it aside, then re-run home-manager switch."
          exit 1
        fi
        run rm -f $VERBOSE_ARG "$keymap"
        run ln -s $VERBOSE_ARG "${keymapSrc}" "$keymap"
      else
        echo "qmk_firmware not set up yet — run:"
        echo "  qmk setup svalboard/vial-qmk -b vial -y"
        echo "then re-run home-manager switch to link the SiriusStarr keymap."
      fi
    '';
}
