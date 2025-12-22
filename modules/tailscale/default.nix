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
    interface =
      { lib, ... }:
      {
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
    perInstance =
      { settings, ... }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            clan.core.vars.generators.tailscale = {
              prompts = {
                authKey = {
                  type = "line";
                  description = "Tailscale/Headscale auth key (tskey-auth-xyz or headscale preauthkey)";
                  display = {
                    label = "Tailscale Auth Key";
                    required = true;
                    helperText = "Create from Tailscale admin console, or for Headscale: headscale preauthkeys create --user <username>";
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
                lib.optional (
                  settings.loginServer != "https://controlplane.tailscale.com"
                ) "--login-server ${settings.loginServer}"
                ++ lib.optional settings.advertiseExitNode "--advertise-exit-node"
                ++ lib.optional (settings.advertiseRoutes != "") "--advertise-routes ${settings.advertiseRoutes}";
            };

            networking.firewall.checkReversePath = "loose";
            networking.firewall.trustedInterfaces = [ "tailscale0" ];

          };
      };
  };

  roles.server = {
    description = "Headscale coordination server - self-hosted Tailscale control plane";
    interface =
      { lib, ... }:
      {
        options.serverUrl = lib.mkOption {
          type = lib.types.str;
          description = "Public URL where Headscale will be accessible (e.g., https://headscale.example.com)";
          example = "https://headscale.example.com";
        };

        options.baseDomain = lib.mkOption {
          type = lib.types.str;
          description = "Base domain for MagicDNS (e.g., example.com results in machine.user.example.com)";
          example = "example.com";
        };

        options.useTraefik = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "If true, assumes Traefik handles TLS (only opens STUN port). If false, opens ports 80/443 directly.";
        };

        options.ipPrefixes = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [
            "100.64.0.0/10"
            "fd7a:115c:a1e0::/48"
          ];
          description = "IP prefixes to allocate addresses from (IPv4 and IPv6)";
        };

        options.dns = {
          nameservers = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "1.1.1.1"
              "8.8.8.8"
            ];
            description = "DNS servers to use for MagicDNS";
          };

          magicDns = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable MagicDNS for automatic DNS resolution within the tailnet";
          };
        };

        options.derp = {
          serverEnabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Run embedded DERP relay server";
          };

          serverRegionId = lib.mkOption {
            type = lib.types.int;
            default = 999;
            description = "Region ID for the embedded DERP server";
          };

          serverRegionName = lib.mkOption {
            type = lib.types.str;
            default = "headscale";
            description = "Region name for the embedded DERP server";
          };
        };

        options.oidc = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable OIDC authentication";
          };

          issuer = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "OIDC issuer URL";
          };

          clientId = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "OIDC client ID";
          };

          scope = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [
              "openid"
              "profile"
              "email"
            ];
            description = "OIDC scopes to request";
          };
        };

        options.aclPolicyFile = lib.mkOption {
          type = lib.types.nullOr lib.types.path;
          default = null;
          description = "Path to ACL policy file (HuJSON format)";
        };

        options.headplane = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable Headplane UI for Headscale management";
          };

          port = lib.mkOption {
            type = lib.types.int;
            default = 3000;
            description = "Port for Headplane to listen on";
          };

          agent = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Enable Headplane agent integration for node management";
            };
          };

          oidc = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable OIDC authentication for Headplane";
            };

            issuer = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "OIDC issuer URL for Headplane";
            };

            clientId = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "OIDC client ID for Headplane";
            };
          };
        };

        options.openFirewall = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Open firewall ports for Headscale (3478 UDP for STUN if DERP enabled, 80/443 TCP only when useTraefik=false)";
        };
      };
    perInstance =
      { settings, ... }:
      {
        nixosModule =
          {
            config,
            pkgs,
            inputs,
            ...
          }:
          {
            # Headscale OIDC client secret generator (only if OIDC enabled)
            clan.core.vars.generators.headscale = lib.mkIf settings.oidc.enable {
              prompts = {
                oidcClientSecret = {
                  type = "line";
                  description = "OIDC client secret for Headscale authentication";
                  display = {
                    label = "OIDC Client Secret";
                    required = true;
                    helperText = "Client secret from your OIDC provider";
                  };
                  persist = true;
                };
              };
            };

            # Headplane generators (only if headplane enabled)
            clan.core.vars.generators.headplane = lib.mkIf settings.headplane.enable {
              files = {
                cookieSecret = {
                  owner = "headscale";
                  group = "headscale";
                };
                oidcClientSecret = lib.mkIf settings.headplane.oidc.enable {
                  owner = "headscale";
                  group = "headscale";
                };
                agentPreauthKey = lib.mkIf settings.headplane.agent.enable {
                  owner = "headscale";
                  group = "headscale";
                };
              };
              prompts = {
                cookieSecret = {
                  type = "line";
                  description = "Headplane session cookie secret (32 characters)";
                  display = {
                    label = "Cookie Secret";
                    required = true;
                    helperText = "Used for session encryption - generate with: head -c 32 /dev/urandom | base64";
                  };
                  persist = true;
                };
                oidcClientSecret = lib.mkIf settings.headplane.oidc.enable {
                  type = "line";
                  description = "OIDC client secret for Headplane";
                  display = {
                    label = "OIDC Client Secret";
                    required = true;
                    helperText = "Client secret from your OIDC provider";
                  };
                  persist = true;
                };
                agentPreauthKey = lib.mkIf settings.headplane.agent.enable {
                  type = "line";
                  description = "Headscale pre-auth key for Headplane agent";
                  display = {
                    label = "Agent Pre-Auth Key";
                    required = true;
                    helperText = "Create with: headscale preauthkeys create --user admin --reusable --expiration=8760h";
                  };
                  persist = true;
                };
              };
            };

            # Headplane module and overlay (only when enabled)
            imports = lib.optionals settings.headplane.enable [
              inputs.headplane.nixosModules.headplane
            ];
            nixpkgs.overlays = lib.optionals settings.headplane.enable [
              inputs.headplane.overlays.default
            ];

            services.headscale = {
              enable = true;
              package = pkgs.headscale;

              settings = {
                server_url = settings.serverUrl;

                listen_addr = "127.0.0.1:8080";
                metrics_listen_addr = "127.0.0.1:9090";
                grpc_listen_addr = "127.0.0.1:50443";
                grpc_allow_insecure = false;

                prefixes = {
                  v4 = builtins.head (builtins.filter (p: builtins.match ".*:.*" p == null) settings.ipPrefixes);
                  v6 = builtins.head (builtins.filter (p: builtins.match ".*:.*" p != null) settings.ipPrefixes);
                };

                derp = {
                  server = {
                    enabled = settings.derp.serverEnabled;
                    region_id = settings.derp.serverRegionId;
                    region_code = "hs";
                    region_name = settings.derp.serverRegionName;
                    stun_listen_addr = "0.0.0.0:3478";
                  };
                  urls = lib.mkIf (!settings.derp.serverEnabled) [
                    "https://controlplane.tailscale.com/derpmap/default"
                  ];
                  auto_update_enabled = true;
                  update_frequency = "24h";
                };

                dns = {
                  base_domain = settings.baseDomain;
                  magic_dns = settings.dns.magicDns;
                  nameservers.global = settings.dns.nameservers;
                };

                database = {
                  type = "sqlite";
                  sqlite.path = "/var/lib/headscale/db.sqlite";
                };

                log = {
                  format = "json";
                  level = "info";
                };

                policy = lib.mkIf (settings.aclPolicyFile != null) {
                  path = settings.aclPolicyFile;
                };

                oidc = lib.mkIf settings.oidc.enable {
                  issuer = settings.oidc.issuer;
                  client_id = settings.oidc.clientId;
                  client_secret_path = config.clan.core.vars.generators.headscale.files.oidcClientSecret.path;
                  scope = settings.oidc.scope;
                };
              };
            };

            # Headplane UI
            services.headplane = lib.mkIf settings.headplane.enable {
              enable = true;
              settings = {
                server = {
                  host = "127.0.0.1";
                  port = settings.headplane.port;
                  cookie_secret_path = config.clan.core.vars.generators.headplane.files.cookieSecret.path;
                };
                headscale = {
                  url = "http://127.0.0.1:8080";
                  # Note: NixOS headscale module doesn't expose its config file path directly
                  # config_path is optional - headplane will work without it but some features
                  # like config display in the UI will be unavailable
                };
                integration = {
                  proc.enabled = true;
                  agent = lib.mkIf settings.headplane.agent.enable {
                    enabled = true;
                    pre_authkey_path = config.clan.core.vars.generators.headplane.files.agentPreauthKey.path;
                  };
                };
                oidc = lib.mkIf settings.headplane.oidc.enable {
                  issuer = settings.headplane.oidc.issuer;
                  client_id = settings.headplane.oidc.clientId;
                  client_secret_path = config.clan.core.vars.generators.headplane.files.oidcClientSecret.path;
                  redirect_uri = "${settings.serverUrl}/admin/oidc/callback";
                };
              };
            };

            networking.firewall = lib.mkIf settings.openFirewall (
              if settings.useTraefik then
                {
                  allowedUDPPorts = lib.mkIf settings.derp.serverEnabled [ 3478 ];
                }
              else
                {
                  allowedTCPPorts = [
                    80
                    443
                  ];
                  allowedUDPPorts = lib.mkIf settings.derp.serverEnabled [ 3478 ];
                }
            );

          };
      };
  };
}
