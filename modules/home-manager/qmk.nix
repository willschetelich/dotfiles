{ config, lib, pkgs, ... }:
let
  # Editable working-tree copy of the flattened keymap (NOT the nix-store copy),
  # so edits reflect without a rebuild.
  keymapSrc =
    "${config.home.homeDirectory}/dotfiles/modules/home-manager/keyboard-layouts/QMK/keyboards/svalboard/keymaps/SiriusStarr";
  qmkHome = "${config.home.homeDirectory}/qmk_firmware";

  # `flash-sval-left` / `flash-sval-right`: compile, wait for the RP2040
  # bootloader, copy the UF2. Scripted rather than aliased because `qmk flash`
  # hangs on NixOS, so this drives the manual mount/copy route instead.
  mkFlash = side: pkgs.writeShellApplication {
    name = "flash-sval-${side}";
    runtimeInputs = with pkgs; [ qmk coreutils udisks2 util-linux ];
    text = ''
      export QMK_HOME="${qmkHome}"
      kb="svalboard/trackball/pmw3389/${side}"
      uf2="${qmkHome}/svalboard_trackball_pmw3389_${side}_SiriusStarr.uf2"
      dev=/dev/disk/by-label/RPI-RP2

      if [ ! -e "${qmkHome}/keyboards/svalboard/keymaps/SiriusStarr" ]; then
        echo "keymap not linked. Run:  qmk setup svalboard/vial-qmk -b vial -y" >&2
        echo "then:  sudo nixos-rebuild switch --flake ~/dotfiles#thinkpad" >&2
        exit 1
      fi

      echo "==> Compiling ${side} half"
      qmk compile -kb "$kb" -km SiriusStarr
      [ -f "$uf2" ] || { echo "expected firmware missing: $uf2" >&2; exit 1; }

      if [ -e "$dev" ]; then
        echo "==> RP2040 bootloader already connected"
      else
        echo ""
        echo "==> Plug in the ${side} half and double-tap its reset button"
        echo "    (waiting up to 120s; Ctrl-C to abort)"
        for _ in $(seq 1 120); do
          [ -e "$dev" ] && break
          sleep 1
        done
        [ -e "$dev" ] || { echo "RPI-RP2 never appeared" >&2; exit 1; }
      fi

      node=$(readlink -f "$dev")
      mnt=$(lsblk -no MOUNTPOINT "$node" | head -1)
      if [ -z "$mnt" ]; then
        udisksctl mount -b "$dev" >/dev/null
        mnt=$(lsblk -no MOUNTPOINT "$node" | head -1)
      fi
      [ -n "$mnt" ] || { echo "could not mount $dev" >&2; exit 1; }

      echo "==> Copying $(basename "$uf2") to $mnt"
      # The board reboots the instant the UF2 lands, so the tail of the copy and
      # any unmount are expected to fail. Success is judged by the bootloader
      # volume disappearing, not by cp's exit status.
      cp "$uf2" "$mnt/" 2>/dev/null || true
      sync 2>/dev/null || true
      udisksctl unmount -b "$dev" >/dev/null 2>&1 || true

      for _ in $(seq 1 15); do
        [ -e "$dev" ] || { echo "==> Done: ${side} half rebooted with new firmware"; exit 0; }
        sleep 1
      done
      echo "RPI-RP2 still present -- the copy may not have taken" >&2
      exit 1
    '';
  };
in {
  home.packages = with pkgs; [
    qmk   # CLI + bundled avr/arm toolchain + flashing utils (dfu-util etc.)
    git   # required by `qmk setup`

    (mkFlash "left")
    (mkFlash "right")
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
