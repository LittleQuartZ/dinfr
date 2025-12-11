{
  lib,
  ...
}:
{
  _class = "clan.service";
  manifest.name = "@littlequartz/traefik";
  manifest.description = "Traefik reverse proxy with Docker and Redis providers";
  manifest.categories = [ "Network" ];

  roles.server = {
    description = "Traefik reverse proxy with ACME TLS, Docker provider, and Redis for traefik-kop";
    interface =
      { lib, ... }:
      {
        options.acmeEmail = lib.mkOption {
          type = lib.types.str;
          description = "Email address for ACME/Let's Encrypt certificate notifications";
        };

        options.redisEndpoint = lib.mkOption {
          type = lib.types.str;
          default = "127.0.0.1:6379";
          description = "Redis endpoint for traefik-kop";
        };

        options.enableApi = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Traefik API/dashboard";
        };

        options.enableDocker = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Docker provider for container discovery";
        };

        options.routers = lib.mkOption {
          type = lib.types.attrsOf lib.types.attrs;
          default = {};
          description = "HTTP routers configuration (dynamicConfigOptions.http.routers)";
          example = {
            myapp = {
              rule = "Host(`myapp.example.com`)";
              service = "myapp";
              entryPoints = [ "websecure" ];
            };
          };
        };

        options.services = lib.mkOption {
          type = lib.types.attrsOf lib.types.attrs;
          default = {};
          description = "HTTP services configuration (dynamicConfigOptions.http.services)";
          example = {
            myapp.loadBalancer.servers = [
              { url = "http://localhost:8080"; }
            ];
          };
        };

        options.middlewares = lib.mkOption {
          type = lib.types.attrsOf lib.types.attrs;
          default = {};
          description = "HTTP middlewares configuration (dynamicConfigOptions.http.middlewares)";
          example = {
            auth.basicAuth.users = [ "user:$$apr1$$..." ];
          };
        };

        options.extraDynamicConfig = lib.mkOption {
          type = lib.types.attrs;
          default = {};
          description = "Extra dynamic config merged into dynamicConfigOptions (escape hatch)";
        };
      };
    perInstance =
      { settings, ... }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            # Enable Docker if Docker provider is used
            virtualisation.docker.enable = lib.mkIf settings.enableDocker true;

            # Add traefik user to docker group for socket access
            users.users.traefik.extraGroups = lib.mkIf settings.enableDocker [ "docker" ];

            services.traefik = {
              enable = true;

              staticConfigOptions = {
                # Entry points
                entryPoints = {
                  web = {
                    address = ":80";
                    http.redirections.entrypoint = {
                      to = "websecure";
                      scheme = "https";
                    };
                  };
                  websecure = {
                    address = ":443";
                    http.tls.certResolver = "letsencrypt";
                  };
                };

                # ACME/Let's Encrypt
                certificatesResolvers.letsencrypt.acme = {
                  email = settings.acmeEmail;
                  storage = "${config.services.traefik.dataDir}/acme.json";
                  tlsChallenge = {};
                };

                # Providers
                providers = {
                  # Docker provider
                  docker = lib.mkIf settings.enableDocker {
                    endpoint = "unix:///var/run/docker.sock";
                    watch = true;
                    exposedByDefault = false;
                  };

                  # Redis provider for traefik-kop
                  redis = {
                    endpoints = [ settings.redisEndpoint ];
                  };
                };

                # API/Dashboard
                api = {
                  dashboard = settings.enableApi;
                  # insecure = true; # Uncomment to access dashboard on :8080
                };

                # Logging
                log = {
                  level = "INFO";
                  filePath = "${config.services.traefik.dataDir}/traefik.log";
                  format = "json";
                };
              };

              dynamicConfigOptions = lib.mkMerge [
                {
                  http.routers = settings.routers;
                  http.services = settings.services;
                  http.middlewares = settings.middlewares;
                }
                settings.extraDynamicConfig
              ];
            };

            # Open firewall ports
            networking.firewall.allowedTCPPorts = [ 80 443 ];
          };
      };
  };
}
