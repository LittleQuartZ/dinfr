{
  lib,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "@littlequartz/tailscale";
  manifest.description = "Tailscale VPN client/server for secure networking";
  manifest.categories = [ "Utility" ];

  roles.client = {
    description = "A machine connected to the Tailscale network";
    interface = { lib, ... }: {
      options.loginServer = lib.mkOption {
        type = lib.types.str;
        default = "https://controlplane.tailscale.com";
        description = "URL of the Tailscale control server";
        example = "https://headscale.example.com";
      };

      options.advertiseRoutes = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "List of IP routes to advertise to the Tailscale network (comma-separated, e.g. \"10.0.0.0/8,192.168.0.0/24\")";
      };

      options.advertiseExitNode = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to advertise this node as an exit node";
      };

    };
    perInstance = { settings, ... }: {
      nixosModule = { config, pkgs, ... }: {
        clan.core.vars.generators.tailscale = {
          prompts = {
            authKey = {
              type = "line";
              description = "Tailscale auth key (tskey-auth-xyz)";
              display = {
                label = "Tailscale Auth Key";
                required = true;
                helperText = "You can create an auth key from the Tailscale admin console or your headscale instance.";
              };
              persist = true;
            };
          };
        };

        services.tailscale = {
          enable = true;
          package = pkgs.tailscale;
          authKeyFile = config.clan.core.vars.generators.tailscale.files.authKey.path;
          extraUpFlags =
            lib.optional (settings.loginServer != "https://controlplane.tailscale.com") "--login-server ${settings.loginServer}" ++
            lib.optional settings.advertiseExitNode "--advertise-exit-node" ++
            lib.optional (settings.advertiseRoutes != "") "--advertise-routes ${settings.advertiseRoutes}";
        };

        networking.firewall.checkReversePath = "loose";
        networking.firewall.trustedInterfaces = [ "tailscale0" ];

      };
    };
  };
}
