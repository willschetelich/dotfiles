{ config, pkgs, ... }: {
  # Install Emacs into the user profile.
  # emacs-pgtk renders natively on Wayland (pure GTK build).
  home.packages = with pkgs; [ emacs-pgtk ];

  # Link our init.el to ~/.emacs.d/init.el.
  # Emacs prefers ~/.emacs.d over the XDG ~/.config/emacs location whenever
  # ~/.emacs.d exists (it already does here, holding eln-cache), so we target
  # it directly to be sure our config is the one that loads.
  home.file.".emacs.d/init.el".source = ./init.el;
}
