{
  lib,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "@littlequartz/redis";
  manifest.description = "Redis key-value store for traefik-kop multi-host config sync";
  manifest.categories = [ "Database" ];

  roles.server = {
    description = "Redis server bound to Tailscale interface for traefik-kop";
    interface =
      { lib, ... }:
      {
        options.bindAddress = lib.mkOption {
          type = lib.types.str;
          default = "100.118.165.68";
          description = "IP address to bind Redis to (Tailscale IP for traefik-kop)";
        };

        options.port = lib.mkOption {
          type = lib.types.port;
          default = 6379;
          description = "Port for Redis to listen on";
        };
      };
    perInstance =
      { settings, ... }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            services.redis.servers.traefik-kop = {
              enable = true;
              bind = settings.bindAddress;
              port = settings.port;
              # Persistence for traefik-kop state
              save = [
                [ 900 1 ]   # Save after 900 sec if at least 1 key changed
                [ 300 10 ]  # Save after 300 sec if at least 10 keys changed
                [ 60 10000 ] # Save after 60 sec if at least 10000 keys changed
              ];
            };

            # Allow Redis on Tailscale interface
            networking.firewall.interfaces.tailscale0 = {
              allowedTCPPorts = [ settings.port ];
            };
          };
      };
  };
}
