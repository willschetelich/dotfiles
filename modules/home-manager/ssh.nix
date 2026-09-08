{ config, pkgs, ... }: {
  programs.ssh = {
    enable = true;

    # The implicit defaults are being removed upstream. These are the exact
    # values home-manager was already applying via enableDefaultConfig
    # (modules/programs/ssh.nix), restated verbatim so turning the flag off
    # changes nothing about the generated config.
    enableDefaultConfig = false;

    # Attribute names are OpenSSH directive names, emitted verbatim -- not
    # home-manager's old camelCase. The block name becomes the `Host` line.
    settings = {
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };

      "github.com".IdentityFile = "~/.ssh/id_ed25519";
    };
  };
}
