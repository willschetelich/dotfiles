{ config, pkgs, lib, ... }:
let
  # Common command shorthands.
  terminal = "foot";
  menu = "fuzzel";
  # Region screenshot to ~/Pictures with a timestamped name.
  screenshot = ''grim -g "$(slurp)" "$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"'';
in
{
  wayland.windowManager.sway = {
    enable = true;
    # Use the system-wide sway from programs.sway (avoids a second wrapped copy).
    package = null;

    config = {
      modifier = "Mod4"; # Super
      inherit terminal menu;

      # Plain dark background, no image — keeps it light and unflashy.
      output."*".bg = "#1a1a1a solid_color";

      # Let the standalone Waybar module own the bar.
      bars = [ ];

      keybindings = lib.mkOptionDefault {
        "Mod4+Return" = "exec ${terminal}";
        "Mod4+d" = "exec ${menu}";
        "Mod4+Shift+q" = "kill";
        "Mod4+Shift+e" = "exec swaymsg exit";
        "Mod4+Shift+c" = "reload";
        "Print" = "exec ${screenshot}";
      };

      # Start the graphical polkit agent for GUI auth prompts.
      startup = [
        { command = "${pkgs.lxqt.lxqt-policykit}/bin/lxqt-policykit-agent"; }
        # Force the initial workspace to 1 (sway otherwise picks the first
        # workspace referenced in the config, which lexical key sorting makes
        # "workspace number 10" from the Mod4+0 binding), then launch the
        # terminal in the same swaymsg call so it maps on workspace 1 rather
        # than racing the earlier switch and landing on 10.
        { command = "swaymsg 'workspace number 1; exec ${terminal}'"; }
      ];
    };

    # Media/brightness keys. Bound with --locked so they keep working on the
    # swaylock screen. notify-send gives a small mako popup as feedback.
    extraConfig = ''
      bindsym --locked XF86AudioRaiseVolume exec wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ && notify-send -t 800 -h string:x-canonical-private-synchronous:vol "Volume up"
      bindsym --locked XF86AudioLowerVolume exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && notify-send -t 800 -h string:x-canonical-private-synchronous:vol "Volume down"
      bindsym --locked XF86AudioMute exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && notify-send -t 800 -h string:x-canonical-private-synchronous:vol "Mute toggled"
      bindsym --locked XF86MonBrightnessUp exec brightnessctl set 5%+ && notify-send -t 800 -h string:x-canonical-private-synchronous:bright "Brightness up"
      bindsym --locked XF86MonBrightnessDown exec brightnessctl set 5%- && notify-send -t 800 -h string:x-canonical-private-synchronous:bright "Brightness down"
    '';
  };
}
