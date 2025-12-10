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
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "IP address to bind Redis to. If null, binds to 0.0.0.0 (firewall restricts to tailscale0).";
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
          let
            # Bind to specific IP if provided, otherwise 0.0.0.0
            # Security is enforced by firewall allowing only tailscale0
            bindAddr = if settings.bindAddress != null then settings.bindAddress else "0.0.0.0";
          in
          {
            services.redis.servers.traefik-kop = {
              enable = true;
              bind = bindAddr;
              port = settings.port;
              # Persistence for traefik-kop state
              save = [
                [ 900 1 ]   # Save after 900 sec if at least 1 key changed
                [ 300 10 ]  # Save after 300 sec if at least 10 keys changed
                [ 60 10000 ] # Save after 60 sec if at least 10000 keys changed
              ];
            };

            # IMPORTANT: Only allow Redis on Tailscale interface
            # This is the security boundary - Redis binds 0.0.0.0 but only
            # tailscale0 can reach it
            networking.firewall.interfaces.tailscale0 = {
              allowedTCPPorts = [ settings.port ];
            };
          };
      };
  };
}
