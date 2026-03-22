{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "qmd";
  manifest.description = "qmd document search engine with hybrid retrieval, query expansion, and reranking";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "qmd instance (systemd service + Caddy + borgbackup)";

    interface =
      { lib, ... }:
      let
        collectionSubmodule = lib.types.submodule {
          options = {
            path = lib.mkOption {
              type = lib.types.str;
              description = "Root directory path containing documents to index";
            };
            pattern = lib.mkOption {
              type = lib.types.str;
              default = "**/*.md";
              description = "Glob pattern for files to index";
            };
            exclude = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Glob patterns to exclude from indexing";
            };
          };
        };
      in
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the qmd instance (e.g., qmd.swancloud.net)";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8423;
            description = "HTTP listen port for qmd Streamable HTTP transport";
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
            qmdPackage = pkgs.llm-agents.qmd;
            tlsConfig = config.caddy-cloudflare.tls;

            # Generate qmd collection config as JSON
            collectionsConfig = builtins.toJSON (
              lib.mapAttrs (
                _name: col: {
                  inherit (col) path pattern exclude;
                }
              ) settings.collections
            );

            collectionsConfigFile = pkgs.writeText "qmd-collections.json" collectionsConfig;
          in
          {
            systemd.services.qmd = {
              description = "qmd document search engine";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                ExecStart = "${qmdPackage}/bin/qmd --transport http --port ${toString settings.port} --collections ${collectionsConfigFile}";
                Restart = "on-failure";
                RestartSec = 10;
                DynamicUser = true;
                StateDirectory = "qmd";
                WorkingDirectory = "/persist/qmd";
                ReadWritePaths = [ "/persist/qmd" ];
                TimeoutStartSec = 600;
              };
            };

            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:${toString settings.port}
                '';
              };
            };

            networking.firewall.allowedTCPPorts = [ 443 ];

            systemd.tmpfiles.rules = [
              "d /persist/qmd 0755 root root"
              "d /persist/caddy 0700 caddy caddy"
            ];

            services.borgbackup.jobs.system.paths = [ "/persist/qmd" ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "qmd";
        capabilities = {
          mcp = {
            type = "http";
            urlTemplate = client: "https://${client.domain}/mcp";
          };
        };
        extraClientOptions = { lib, ... }: {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN of the qmd server (e.g., qmd.swancloud.net)";
          };
        };
      };
    in
    {
      description = "qmd MCP endpoint configuration (claude-code, agent-deck)";
      inherit (tooling) interface perInstance;
    };
}
