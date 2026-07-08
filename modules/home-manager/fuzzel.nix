{ config, pkgs, ... }: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        font = "monospace:size=11";
        lines = 12;
        width = 40;
      };
      # Muted dark theme (argb hex).
      colors = {
        background = "1a1a1aee";
        text = "ccccccff";
        selection = "333333ff";
        selection-text = "ffffffff";
        border = "555555ff";
      };
      border.width = 1;
    };
  };
}
