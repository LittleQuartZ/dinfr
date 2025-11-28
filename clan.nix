{
  # Ensure this is unique among all clans you want to use.
  meta.name = "dinfra";
  meta.domain = "littlequartz";
  meta.description = "Dan's Personal Infra";

  inventory.machines = {
    # Define machines here.
    weaker = { };
  };

  # Docs: See https://docs.clan.lol/reference/clanServices
  inventory.instances = {

    # Docs: https://docs.clan.lol/reference/clanServices/admin/
    # Admin service for managing machines
    # This service adds a root password and SSH access.
    admin = {
      roles.default.tags.all = { };
      roles.default.settings.allowedKeys = {
        # Insert the public key that you want to use for SSH access.
        # All keys will have ssh access to all machines ("tags.all" means 'all machines').
        # Alternatively set 'users.users.root.openssh.authorizedKeys.keys' in each machine
        "twurbo" = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRFTvICtbBKC7UwKfyEAzDFi7FLSa5s9wGqckVOLlsU dan@twurbo.local";
      };
    };

    # Docs: https://docs.clan.lol/reference/clanServices/tor/
    # Tor network provides secure, anonymous connections to your machines
    # All machines will be accessible via Tor as a fallback connection method
    tor = {
      roles.server.tags.nixos = { };
    };

    "@littlequartz/tailscale" = {
      module.input = "self";
      module.name = "@littlequartz/tailscale";

      roles.client.machines.weaker = { };
    };
  };

  # Additional NixOS configuration can be added here.
  # machines/weaker/configuration.nix will be automatically imported.
  # See: https://docs.clan.lol/guides/more-machines/#automatic-registration
  machines = {
    weaker = { };
  };
}
