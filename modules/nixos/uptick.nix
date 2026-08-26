# Uptick work environment: everything the uptick_website_cms checkout in
# ~/uptick needs to build and run locally (TanStack Start landing site + CMS).
#
# This module is self-contained and is imported only by hosts/thinkpad. Nothing
# else in the config depends on it, so removing the import line from
# hosts/thinkpad/configuration.nix takes the whole toolchain with it.
{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # package.json declares engines.node ">=22.12.0 <26" and .nvmrc says 22.
    # nodejs_22 is 22.23.1 here, which satisfies both.
    nodejs_22

    # Toolchain fallback for node-gyp. sharp and argon2 both ship prebuilt
    # linux-x64 binaries and the package-lock already carries the linux
    # entries, so `npm ci` should never compile anything -- but if a prebuild
    # ever fails to match, argon2's node-gyp-build falls back to building from
    # source and dies without these. Uncomment if that happens.
    # gcc
    # gnumake
    # python3
  ];

  # The CMS is host-gated: src/lib/cms.server.ts (isCmsHost) only serves the
  # /login, /posts and /media routes when the request Host matches CMS_HOST,
  # so the public site and the CMS need two different hostnames even locally.
  # Chrome resolves *.localhost to 127.0.0.1 on its own, but node, curl and
  # the glibc resolver do not, so make it explicit.
  #
  # Public site -> http://localhost:3000/
  # CMS         -> http://cms.localhost:3000/login
  networking.hosts."127.0.0.1" = [ "cms.localhost" ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;

    ensureDatabases = [ "uptick" ];

    # ensureDBOwnership only grants ownership of a database named after the
    # role itself, so it cannot hand "uptick" to "will". Superuser is the
    # simpler route on a single-user dev box, and it keeps the default
    # "local all all peer" pg_hba rule working over the unix socket.
    ensureUsers = [{
      name = "will";
      ensureClauses.superuser = true;
    }];
  };
}
