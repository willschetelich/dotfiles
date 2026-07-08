{ config, pkgs, ... }:
let
  lock = "${pkgs.swaylock}/bin/swaylock -f -c 1a1a1a";
in
{
  # Notifications.
  services.mako = {
    enable = true;
    settings = {
      background-color = "#1a1a1aee";
      text-color = "#cccccc";
      border-color = "#555555";
      border-size = 1;
      default-timeout = 5000;
    };
  };

  # Screen locker: plain dark lock screen.
  programs.swaylock = {
    enable = true;
    settings.color = "1a1a1a";
  };

  # Idle management: lock + screen off after idle, lock before suspend.
  services.swayidle = {
    enable = true;
    events = {
      before-sleep = lock;
      lock = lock;
    };
    timeouts = [
      { timeout = 300; command = lock; }
      {
        timeout = 360;
        command = "swaymsg 'output * power off'";
        resumeCommand = "swaymsg 'output * power on'";
      }
    ];
  };

  # Auto output profiles for laptop-only vs docked/external monitors.
  #
  # The two VG248 externals are matched by "make model serial" (from
  # `swaymsg -pt get_outputs`) rather than connector name, so each panel lands
  # in the same spot no matter which USB-C port / hub it comes in on. This T580
  # only routes one DisplayPort stream per USB-C port, so the two monitors must
  # be on separate ports (one may be behind a non-MST hub, the other on a direct
  # USB-C->DP adapter); a single hub cannot drive both.
  #
  # Layout (origin top-left, x right / y down): laptop is the centerpiece, the
  # left monitor is rotated 270deg (portrait) beside it, the third sits above:
  #
  #     +--------+   +-----------------+
  #     |        |   |      DP-2       |   above laptop   (1080,0)
  #     | DP-1   |   +-----------------+
  #     | 270deg |   |      eDP-1      |   laptop         (1080,1080)
  #     | (left) |   |                 |
  #     +--------+   +-----------------+
  #      (0,40)
  #
  # Profiles are matched top-down; the first whose listed outputs are all
  # connected wins, so the most specific (dual) profile comes first.
  services.kanshi = {
    enable = true;
    settings = [
      {
        # Both VG248 externals present: full docked layout.
        profile.name = "docked-dual";
        profile.outputs = [
          # Scaled to ~3/5 width so the laptop panel matches its smaller physical
          # size beneath the monitor above it. Waybar compensates for this scale
          # with a smaller font on eDP-1 (see waybar.nix).
          { criteria = "eDP-1"; status = "enable"; scale = 1.45; position = "1080,1080"; }
          # NOTE: kanshi names rotations counterclockwise (Wayland convention),
          # opposite to sway's clockwise `swaymsg output transform`. So kanshi
          # "90" here yields what sway reports as transform 270 -- the portrait
          # orientation we want. Do not "fix" this to 270; that flips it 180deg.
          { criteria = "Ancor Communications Inc VG248 H1LMQS084705";
            status = "enable"; mode = "1920x1080@60Hz"; transform = "90"; position = "0,40"; }
          { criteria = "Ancor Communications Inc VG248 G8LMQS035320";
            status = "enable"; mode = "1920x1080@60Hz"; position = "1080,0"; }
        ];
      }
      {
        # Any single external: place it to the right of the laptop.
        profile.name = "docked-single";
        profile.outputs = [
          { criteria = "eDP-1"; status = "enable"; position = "0,0"; }
          { criteria = "*"; status = "enable"; position = "1920,0"; }
        ];
      }
      {
        profile.name = "undocked";
        profile.outputs = [
          { criteria = "eDP-1"; status = "enable"; position = "0,0"; }
        ];
      }
    ];
  };

  # Consistent neutral theming for GTK apps (Thunar, Chrome dialogs, etc.).
  gtk = {
    enable = true;
    theme = { name = "Adwaita"; package = pkgs.gnome-themes-extra; };
    iconTheme = { name = "Adwaita"; package = pkgs.adwaita-icon-theme; };
  };

  home.pointerCursor = {
    name = "Adwaita";
    package = pkgs.adwaita-icon-theme;
    size = 24;
    gtk.enable = true;
  };

  home.packages = with pkgs; [
    grim
    slurp
    thunar # file manager (auto-mount via system gvfs/udisks2)
  ];
}
