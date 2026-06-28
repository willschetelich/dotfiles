{ config, pkgs, ... }: {
  programs.waybar = {
    enable = true;
    systemd.enable = true; # start with the sway session

    settings.mainBar = {
      layer = "top";
      position = "top";
      height = 26;

      modules-left = [ "sway/workspaces" "sway/mode" ];
      modules-center = [ "sway/window" ];
      modules-right = [ "cpu" "memory" "pulseaudio" "network" "battery" "clock" "tray" ];

      "sway/workspaces".disable-scroll = true;

      cpu.format = "CPU {usage}%";
      memory.format = "RAM {percentage}%";

      battery = {
        format = "BAT {capacity}%";
        format-charging = "CHG {capacity}%";
        states = { warning = 30; critical = 15; };
      };

      network = {
        format-wifi = "{essid} {signalStrength}%";
        format-ethernet = "ETH";
        format-disconnected = "offline";
        tooltip-format = "{ifname}: {ipaddr}";
      };

      pulseaudio = {
        format = "VOL {volume}%";
        format-muted = "muted";
        on-click = "pavucontrol";
      };

      clock = {
        format = "{:%a %b %d  %H:%M}";
        tooltip-format = "<tt>{calendar}</tt>";
      };

      tray.spacing = 8;
    };

    # Flat, muted, monochrome-ish styling — no flash, small footprint.
    style = ''
      * {
        font-family: "Noto Sans", "Font Awesome 6 Free";
        font-size: 12px;
        min-height: 0;
      }
      window#waybar {
        background: #1a1a1a;
        color: #cccccc;
      }
      #workspaces button {
        padding: 0 6px;
        background: transparent;
        color: #888888;
        border: none;
      }
      #workspaces button.focused {
        color: #ffffff;
        background: #333333;
      }
      #cpu, #memory, #pulseaudio, #network, #battery, #clock, #tray {
        padding: 0 8px;
      }
      #battery.warning { color: #d7af00; }
      #battery.critical { color: #d70000; }
    '';
  };
}
