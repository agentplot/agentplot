{ ... }:
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
            self,
            config,
            pkgs,
            lib,
            ...
          }:
          let
            qmdPackage = self.inputs.qmd.packages.${pkgs.system}.default;
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

  roles.client = {
    description = "qmd MCP endpoint configuration (claude-code, agent-deck)";

    interface =
      { lib, ... }:
      let
        profileSubmodule = lib.types.submodule {
          options.mcp.enabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Add qmd MCP server entry to this Claude Code profile";
          };
        };
      in
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN of the qmd server (e.g., qmd.swancloud.net)";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8423;
            description = "qmd server port";
          };
          claude-code = {
            mcp.enabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Configure Claude MCP server (default profile)";
            };
            profiles = lib.mkOption {
              type = lib.types.attrsOf profileSubmodule;
              default = { };
              description = "Per-profile MCP configuration";
            };
          };
          agent-deck.mcp.enabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Add agent-deck MCP entry";
          };
        };
      };

    perInstance =
      {
        settings,
        ...
      }:
      let
        mcpUrl = "https://${settings.domain}/mcp";

        mcpConfig = {
          type = "http";
          url = mcpUrl;
        };

        clientModule =
          { lib, ... }:
          {
            agentplot.hmModules.qmd-client = { ... }: {
              programs.claude-code = lib.mkMerge [
                (lib.mkIf settings.claude-code.mcp.enabled {
                  mcpServers.qmd = mcpConfig;
                })
                (lib.mkIf (settings.claude-code.profiles != { }) {
                  profiles = lib.mapAttrs (
                    _profileName: profileSettings:
                    lib.mkIf profileSettings.mcp.enabled {
                      mcpServers.qmd = mcpConfig;
                    }
                  ) settings.claude-code.profiles;
                })
              ];

              programs.agent-deck = lib.mkIf settings.agent-deck.mcp.enabled {
                mcps.qmd = mcpConfig;
              };
            };
          };
      in
      {
        nixosModule = clientModule;
        darwinModule = clientModule;
      };
  };
}
