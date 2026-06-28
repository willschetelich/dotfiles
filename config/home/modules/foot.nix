{ config, pkgs, ... }: {
  programs.foot = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=11";
        pad = "4x4";
      };
      # Simple dark theme, muted colors.
      colors = {
        background = "1a1a1a";
        foreground = "cccccc";
      };
    };
  };
}
