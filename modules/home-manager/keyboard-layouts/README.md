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

**Three, all in `process_record.c`, all in the pointing path.** Verified against upstream
`6ea14f9`: 25 of the 28 source files are byte-identical, and the only other differences
are the two `rules.mk` merged into one (see Provenance above — behaviorally identical,
differing solely by two dead `VPATH` lines).

Typing is bit-for-bit SiriusStarr's: keymap, layers, home-row mods, Achordion, combos,
adaptive keys, custom shifts, macros, select-word, sentence-case, caps-word, keylogger.

### 1. DPI is pushed to the sensors — a bug fix, do not remove

```c
set_right_dpi(global_saved_values.right_dpi_index);
set_left_dpi(global_saved_values.left_dpi_index);
```

Upstream sets `right_dpi_index` / `left_dpi_index` in `keyboard_post_init_user()`, but
**those assignments never reach the hardware.** `keyboard_post_init_kb()` runs
`read_eeprom_kb(); set_dpi_from_eeprom();` *before* calling `keyboard_post_init_user()`,
and DPI only reaches a sensor via `set_left_dpi()` / `set_right_dpi()` →
`pointing_device_set_cpi_on_side()`. Nothing calls those afterward, and
`write_eeprom_kb()` is never invoked from the user hook. So SiriusStarr's board boots at
whatever EEPROM holds — Svalboard's default, index 3 = 800.

Consequence worth knowing: because this runs on **every** boot, the DPI up/down keys no
longer stick. They still write EEPROM, but `keyboard_post_init_user()` overwrites and
re-pushes the hardcoded value at next power-up. **Editing the firmware value is the only
change that persists.**

### 2. Right pointer DPI = index 3 (800), upstream says 5

A preference. Note it matches upstream's *effective* 800 anyway, per the bug above —
upstream's `5` is inert. Left stays at `5` and drives scroll speed, not cursor speed.

`dpi_choices[]` (`keyboards/svalboard/svalboard.c`):
`{200, 400, 600, 800, 1200, 1600, 2400, 3200, 4800, 6400, 12000}`

### 3. Horizontal scroll disabled — `pointing_device_task_combined_kb()`

```c
report_mouse_t pointing_device_task_combined_kb(report_mouse_t l, report_mouse_t r_) {
  report_mouse_t r = pointing_device_task_combined_user(l, r_);
  r.h = 0;
  return r;
}
```

The only deviation not explained by hardware. Requested to make the left (scroll) ball
vertical-only.

Why this hook: `keymap_support.c` already defines `pointing_device_task_combined_user()`
*and* `pointing_device_task_user()`, so both are unavailable. `pointing_device_task_combined_kb()`
is still the weak default in `quantum/pointing_device/pointing_device.c:552` and neither
`svalboard.c` nor `keymap_support.c` defines it — it is the one free seam. Confirmed with
`nm`: our `SiriusStarr.o` provides it as `T`, core's `pointing_device.o` as `W`.

Two limits, both inherent:
* It kills horizontal scroll **globally**, not just the left ball. `keymap_support.c` sums
  both pointers into shared `scroll_accumulator_h/v` before any keymap-reachable hook sees
  the report, so the origin is unrecoverable. Same thing in practice — the left ball is
  the only scroller by default — but holding the scroll-toggle to scroll with the right
  ball also loses horizontal. Separating them means vendoring a copy of the 18KB
  `keymap_support.c`; not worth it unless right-ball scrolling is actually used.
* It cannot affect typing. It runs *after* `pointing_device_task_combined_user()`, which
  has already called `mouse_mode(true)`.

## Not deviations — do not "fix" these

* **`VIAL_ENABLE = no` in `rules.mk`.** `qmk info` flags it as a stale option (a ☒ lint,
  not a build error). It is verbatim upstream; removing it would itself be a deviation.
* **Upstream's inline comments are off by one, twice.** They say `right_dpi_index = 5` is
  "2400" (index 5 is **1600**) and `mh_timer_index = 1` is "500 ms" (the table
  `{200, 300, 400, 500, 800, -1}` makes index 1 = **300 ms**). Comments here are
  corrected; the *values* match upstream.
* **The `⚠` wall on every compile** — rgblight declared in both `info.json` and
  `rules.mk`, deprecated `FORCE_NKRO`, missing `keyboard.json` marker. All from Svalboard's
  own keyboard definition, identical for upstream.

## The auto-mouse caveat

`auto_mouse = true` (upstream's setting, unchanged) means **any** pointer motion turns on
`MH_AUTO_BUTTONS_LAYER` (layer 15 = `DYNAMIC_KEYMAP_LAYER_COUNT - 1`). Svalboard's
`mouse_mode()` has *no* threshold — it fires on any nonzero report, not QMK's
`AUTO_MOUSE_THRESHOLD`. It clears after `mh_timer_choices[1]` = **300 ms** idle, provided
no mouse button is held.

While active, 15 keys change: the 8 home-row centers drop their tap half and become bare
modifiers (`t n s c a e i h` → `LSFT LCTL LALT LGUI` / `RSFT RCTL RALT RGUI`, so
Shift-click and Ctrl-click still work as the fingers expect), 6 souths become clicks
(`d l f u o y` → `BTN1 BTN3 BTN2`), and `k` becomes `SV_RECALIBRATE_POINTER`. Everything
else on the layer is `_______` — the whole north row, index inner column and all thumb
keys type normally throughout.

**This is the one place the hardware swap reaches typing.** Not through any config
difference, but because a coasting trackball and a self-centering trackpoint stop
reporting at different moments, so the 300 ms window opens and closes on a different
rhythm than upstream's. Outside that window the two boards are indistinguishable.

To opt out (would be a fourth deviation): `auto_mouse = false`, or `mh_timer_index = 0`
for a 200 ms window.

## Hardware difference

SiriusStarr runs a trackpoint on the left and a pmw3389 trackball on the right. This board
has **pmw3389 trackballs on both sides**. No keymap change is needed: with the SiriusStarr
keymap applied, `qmk info -f json` for `svalboard/trackpoint/left` vs
`svalboard/trackball/pmw3389/left` differs by exactly one key (`"driver": "vendor"`, the
PS/2 driver), and pmw3389 left vs right is identical.

One consequence: `left_scroll = 1` is kept as upstream has it, so the left ball scrolls.
Scroll *feel* will not match upstream — a trackpoint scrolls through PS/2 with a fixed
divisor, a pmw3389 scrolls through `axis_scale.c` at a DPI-governed rate, so the left DPI
index governs scroll speed. Retune by editing `left_dpi_index`, NOT with the DPI up/down
keys — see deviation 1, `keyboard_post_init_user()` overwrites them on every boot.
Horizontal scroll on this board is disabled outright (deviation 3).

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
