{ config, pkgs, ... }: {
  # Apple "Night Shift" equivalent, but pinned ON all the time -- the screen
  # stays warm 24/7 rather than following sunrise/sunset. Gammastep is the
  # Wayland-native Redshift successor.
  services.gammastep = {
    enable = true;

    # Day and night use the SAME warm temperature, so the time of day never
    # changes the tint -- it's always in "night shift". Because the two
    # temperatures are identical, the location below is only a formal
    # requirement of continuous mode; it never affects the result. Lower the
    # value for warmer/redder, raise it toward 6500 for cooler/neutral.
    temperature = {
      day = 4500;
      night = 4500;
    };

    # Manual (offline) location so gammastep never depends on GeoClue/network.
    # Values are a placeholder in the America/New_York region; with a constant
    # temperature they have no visible effect.
    provider = "manual";
    latitude = 40.7;
    longitude = -74.0;
  };
}
