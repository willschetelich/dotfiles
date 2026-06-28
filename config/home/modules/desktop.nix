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
  # Adjust output names/criteria to match your hardware (see `swaymsg -t get_outputs`).
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "undocked";
        profile.outputs = [
          { criteria = "eDP-1"; status = "enable"; }
        ];
      }
      {
        # Template: when an external display is connected, use it.
        # Replace the second criteria with your monitor's name/identifier.
        profile.name = "docked";
        profile.outputs = [
          { criteria = "eDP-1"; status = "enable"; position = "0,0"; }
          { criteria = "*"; status = "enable"; }
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
