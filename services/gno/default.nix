{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "gno";
  manifest.description = "gno document search engine with hybrid RAG, wiki-link graph, and MCP tooling";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "gno instance (OCI container + Caddy reverse proxy)";

    interface =
      { lib, ... }:
      let
        collectionSubmodule = lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.str;
              description = "Absolute path to the document directory on the host";
            };
            pattern = lib.mkOption {
              type = lib.types.str;
              default = "**/*.md";
              description = "Glob pattern for files to index within the collection";
            };
          };
        };
      in
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the gno instance";
          };
          port = lib.mkOption {
            type = lib.types.int;
            default = 8422;
            description = "HTTP listen port for the gno container";
          };
          collections = lib.mkOption {
            type = lib.types.attrsOf collectionSubmodule;
            default = { };
            description = "Named document collections to index";
          };
        };
      };

    perInstance =
      {
        settings,
        ...
      }:
      {
        nixosModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            port = settings.port;
            tlsConfig = config.caddy-cloudflare.tls;

            # Generate a JSON config for gno from Nix collection options
            gnoConfig = pkgs.writeText "gno-config.json" (builtins.toJSON {
              port = port;
              dataDir = "/data";
              collections = lib.mapAttrs (name: col: {
                path = "/collections/${name}";
                pattern = col.pattern;
              }) settings.collections;
            });

            # Build volume mounts: persistent data + per-collection bind-mounts
            collectionVolumes = lib.mapAttrsToList (
              name: col: "${col.path}:/collections/${name}:ro"
            ) settings.collections;
          in
          {
            virtualisation.oci-containers = {
              backend = "podman";
              containers.gno = {
                image = "ghcr.io/nicepkg/gno:latest";
                ports = [ "${toString port}:${toString port}" ];
                volumes = [
                  "/persist/gno:/data"
                  "${gnoConfig}:/app/gno-config.json:ro"
                ] ++ collectionVolumes;
                environment = {
                  GNO_CONFIG = "/app/gno-config.json";
                };
              };
            };

            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:${toString port}
                '';
              };
            };

            networking.firewall.allowedTCPPorts = [ 443 ];

            systemd.tmpfiles.rules = [
              "d /persist/gno 0755 root root"
              "d /persist/caddy 0700 caddy caddy"
            ];

            services.borgbackup.jobs = lib.mkIf (config ? services.borgbackup) {
              default.paths = [ "/persist/gno" ];
            };
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "gno";
        capabilities = {
          mcp = {
            type = "http";
            urlTemplate = client: "https://${client.domain}/mcp";
          };
        };
        extraClientOptions = { lib, ... }: {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN of the gno server instance";
          };
        };
      };
    in
    {
      description = "gno MCP endpoint configuration and HM module delegation";
      inherit (tooling) interface perInstance;
    };
}
