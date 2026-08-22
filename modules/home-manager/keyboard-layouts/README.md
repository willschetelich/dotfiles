# Svalboard keymap (SiriusStarr layout)

QMK firmware for a Svalboard running SiriusStarr's layout, vendored into these dotfiles
and wired into `~/qmk_firmware` by [`../qmk.nix`](../qmk.nix).

## Provenance

Extracted from **<https://github.com/SiriusStarr/keyboard-layouts>** at commit
`6ea14f94c4ba648f1697df3cb8a6bf641612d2d0`.

Upstream splits the firmware across a QMK userspace and a thin keymap dir:

```
QMK/users/SiriusStarr/{,defs/,extensions/}     <- shared userspace
QMK/keyboards/svalboard/keymaps/SiriusStarr/   <- keymap.c + rules.mk
```

Everything here is **flattened into the single keymap directory**, and upstream's two
`rules.mk` files are **merged into one**. That works because
`builddefs/build_keyboard.mk` adds `$(KEYMAP_PATH)` to `VPATH`, and `common_rules.mk`
turns `VPATH` into `-I` flags — so every `SRC +=` entry and `#include "…"` resolves the
same as it did via `$(USER_PATH)/defs` and `$(USER_PATH)/extensions`. Upstream's
`VPATH += $(USER_PATH)/defs|extensions` lines are therefore dropped as redundant. There
are no basename collisions between upstream's `defs/`, `extensions/` and root, so nothing
was lost in the flattening.

Upstream's Atreus and Kaleidoscope material is deliberately not vendored.

## Deviations from upstream

Only one, in `process_record.c`:

```c
set_right_dpi(global_saved_values.right_dpi_index);
set_left_dpi(global_saved_values.left_dpi_index);
```

Upstream sets `right_dpi_index` / `left_dpi_index` in `keyboard_post_init_user()`, but
those assignments **never reach the sensors**: `keyboard_post_init_kb()` runs
`read_eeprom_kb(); set_dpi_from_eeprom();` *before* calling `keyboard_post_init_user()`,
and DPI only reaches hardware through `set_left_dpi()` / `set_right_dpi()`. Nothing calls
those afterward and `write_eeprom_kb()` is never invoked from the user hook, so upstream's
board actually boots at whatever EEPROM holds. These two lines push the values through.

The DPI *indices* match upstream (`5` on both sides). Note `dpi_choices[]` in
`keyboards/svalboard/svalboard.c` makes index 5 = **1600**; upstream's inline comment
saying 2400 is off by one, and the comments here are corrected.

Everything else — keymap, layers, Achordion, combos, adaptive keys, custom shifts, macros,
select-word, sentence-case, caps-word, the console keylogger — is byte-identical.

## Hardware difference

SiriusStarr runs a trackpoint on the left and a pmw3389 trackball on the right. This board
has **pmw3389 trackballs on both sides**. No keymap change is needed: with the SiriusStarr
keymap applied, `qmk info -f json` for `svalboard/trackpoint/left` vs
`svalboard/trackball/pmw3389/left` differs by exactly one key (`"driver": "vendor"`, the
PS/2 driver), and pmw3389 left vs right is identical.

One consequence: `left_scroll = 1` is kept as upstream has it, so the left ball scrolls.
Scroll *feel* will not match upstream — a trackpoint scrolls through PS/2 with a fixed
divisor, a pmw3389 scrolls through `axis_scale.c` at a DPI-governed rate. Tune it live with
the DPI up/down keys, which do persist to EEPROM.

## Build & flash

`qmk.nix` sets `QMK_HOME` and symlinks this directory to
`$QMK_HOME/keyboards/svalboard/keymaps/SiriusStarr`. The firmware tree itself is not
vendored — create it once with:

```bash
qmk setup svalboard/vial-qmk -b vial -y
```

Then flash one side at a time with the helpers `qmk.nix` installs:

```bash
flash-sval-left     # plug in the left half,  double-tap reset when prompted
flash-sval-right    # plug in the right half, double-tap reset when prompted
```

Each one compiles, waits for the RP2040 bootloader to appear as `RPI-RP2`, mounts it via
udisks2 (no sudo needed), copies the `.uf2` and confirms the board rebooted. They exist
because `qmk flash` hangs on NixOS; the equivalent by hand is `qmk compile -kb
svalboard/trackball/pmw3389/<side> -km SiriusStarr`, then mount `RPI-RP2` and copy the
`.uf2` across yourself.

## Keylogging

For heatmaps: set `CONSOLE_ENABLE = yes` in `rules.mk` and uncomment
`#define CONSOLE_KEY_LOGGER_ENABLE` in `config.h`. Reading the output needs `hid-listen`,
which is intentionally not in `qmk.nix` — add it there if you want this. Analyse the log
at <https://precondition.github.io/qmk-heatmap>.

## Re-syncing with upstream

```bash
git clone https://github.com/SiriusStarr/keyboard-layouts /tmp/ks
for f in /tmp/ks/QMK/users/SiriusStarr/{,defs/,extensions/}*.[ch] \
         /tmp/ks/QMK/users/SiriusStarr/defs/*.def \
         /tmp/ks/QMK/keyboards/svalboard/keymaps/SiriusStarr/keymap.c; do
  [ -f "$f" ] && diff -q "$f" "./QMK/keyboards/svalboard/keymaps/SiriusStarr/$(basename "$f")"
done
```

That compares all 26 source files; `rules.mk` is excluded because upstream has two and
this tree has one merged copy (diff those by hand). Expect exactly one hit,
`process_record.c`, for the DPI push above. Anything else is drift worth investigating.
