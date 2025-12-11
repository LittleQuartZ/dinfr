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
          default = "100.118.165.68:6379";
          description = "Redis endpoint for traefik-kop (Tailscale IP:port)";
        };

        options.enableApi = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Enable Traefik API/dashboard";
        };
      };
    perInstance =
      { settings, ... }:
      {
        nixosModule =
          { config, pkgs, ... }:
          {
            # Enable Docker for Traefik provider
            virtualisation.docker.enable = true;

            # Create traefik_proxy network
            systemd.services.docker-network-traefik_proxy = {
              description = "Create traefik_proxy Docker network";
              after = [ "docker.service" ];
              wantedBy = [ "multi-user.target" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script = ''
                ${pkgs.docker}/bin/docker network create traefik_proxy || true
              '';
            };

            # Traefik container
            virtualisation.oci-containers.backend = "docker";
            virtualisation.oci-containers.containers.traefik = {
              image = "traefik:v3.3";
              autoStart = true;

              cmd = [
                "--api=${lib.boolToString settings.enableApi}"
                "--providers.docker"
                "--providers.docker.watch=true"
                "--providers.docker.exposedbydefault=false"
                "--providers.redis.endpoints=${settings.redisEndpoint}"
                "--entryPoints.websecure.address=:443"
                "--entryPoints.web.address=:80"
                "--entryPoints.web.http.redirections.entryPoint.to=websecure"
                "--entryPoints.web.http.redirections.entryPoint.scheme=https"
                "--certificatesresolvers.myresolver.acme.tlschallenge=true"
                "--certificatesresolvers.myresolver.acme.email=${settings.acmeEmail}"
                "--certificatesresolvers.myresolver.acme.storage=/letsencrypt/acme.json"
              ];

              ports = [
                "80:80"
                "443:443"
              ];

              volumes = [
                "/var/run/docker.sock:/var/run/docker.sock:ro"
                "/var/lib/traefik/letsencrypt:/letsencrypt"
              ];

              extraOptions = [
                "--network=traefik_proxy"
                "--network=bridge"
              ];
            };

            # Ensure letsencrypt directory exists with correct permissions
            systemd.tmpfiles.rules = [
              "d /var/lib/traefik/letsencrypt 0700 root root -"
            ];

            # Open firewall ports
            networking.firewall.allowedTCPPorts = [
              80
              443
            ];
          };
      };
  };
}
