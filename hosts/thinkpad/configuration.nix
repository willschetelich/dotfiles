# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thinkpad"; # Define your hostname.
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # nix-ld provides a loader (/lib64/ld-linux-x86-64.so.2) so generic,
  # dynamically-linked Linux binaries can run on NixOS. The VSCode Claude Code
  # extension ships its own prebuilt `claude` binary (resources/native-binary/
  # claude) and runs that instead of the patched nixpkgs CLI on PATH; without
  # nix-ld it fails with "Could not start dynamically linked executable"
  # (exit 127). See https://nix.dev/permalink/stub-ld
  programs.nix-ld.enable = true;

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/New_York";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Wayland desktop: Sway compositor.
  # programs.sway sets up the session wrapper, dbus activation, XWayland and
  # the polkit integration; the actual sway config lives in home-manager.
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true; # GTK apps behave under sway
  };

  # Login via greetd + tuigreet (minimal TTY greeter that launches sway).
  services.greetd = {
    enable = true;
    settings.default_session = {
      # --remember pre-fills the username field with the last user that
      # logged in (will), so the greeter lands on the password prompt
      # instead of asking for a username first.
      command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd sway";
      user = "greeter";
    };
  };

  # Seed tuigreet's "last user" cache with "will" so the username is pre-filled
  # to will out of the box -- on a fresh install or after the cache is cleared,
  # not just after will's first interactive login. The 'f' rule only creates the
  # file when missing, so tuigreet's own --remember updates still take effect.
  systemd.tmpfiles.rules = [
    "d /var/cache/tuigreet 0755 greeter greeter - -"
    "f /var/cache/tuigreet/lastuser 0644 greeter greeter - will"
  ];

  # XDG portals: native file dialogs + screen sharing for GTK/Electron/Chromium.
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  # Console keymap (sway handles the Wayland keyboard layout itself).
  console.keyMap = "us";

  # Make Chromium/Electron apps (Chrome, VSCode, Obsidian) use native Wayland.
  environment.sessionVariables.NIXOS_OZONE_WL = "1";

  # Removable media auto-mount for Thunar.
  services.gvfs.enable = true;
  services.udisks2.enable = true;

  # Fonts: a base font plus an icon font for Waybar glyphs.
  fonts.packages = with pkgs; [ noto-fonts font-awesome ];

  # Lid close: lock (via swayidle before-sleep) then suspend, on AC or battery.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "suspend";
  };

  # Thunderbolt device management (boltd + boltctl). The Thunderbolt security
  # level defaults to "user", so the TB3 dock must be authorized before it is
  # fully brought up. macOS authorizes automatically; without bolt nothing does
  # here, which left the dock at authorized=0 and its second DisplayPort output
  # dead (only one external monitor lit). bolt remembers the dock and
  # auto-authorizes it at connect time, so the dock initializes both DP outputs.
  # After the first rebuild, enroll the dock once so future connects are
  # automatic:  boltctl enroll --policy auto <uuid>   (uuid from `boltctl list`).
  services.hardware.bolt.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Touchpad: sway/libinput handle this natively under Wayland (no config needed
  # for defaults; tweak via wayland.windowManager.sway input settings if wanted).

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."will" = {
    isNormalUser = true;
    description = "Will Schetelich";
    # video/input: let brightnessctl (via its udev rules) control the backlight.
    extraGroups = [ "networkmanager" "wheel" "video" "input" ];
    packages = with pkgs; [
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    brightnessctl              # backlight control (bound to brightness keys)
    wl-clipboard               # wl-copy / wl-paste
    lxqt.lxqt-policykit        # graphical polkit auth agent
    pavucontrol                # GUI audio mixer
    networkmanagerapplet       # nm-connection-editor
  #  vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
  #  wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?

}
