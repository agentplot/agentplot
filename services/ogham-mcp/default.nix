{ ... }:
{
  _class = "clan.service";
  manifest.name = "ogham-mcp";
  manifest.description = "Persistent agent memory server with hybrid search, knowledge graph, and cognitive decay";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "ogham-mcp instance (systemd + PostgreSQL/pgvector + Caddy)";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the ogham-mcp instance (e.g., ogham.swancloud.net)";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8420;
            description = "SSE listen port for ogham-mcp";
          };
          embeddingProvider = lib.mkOption {
            type = lib.types.enum [
              "openai"
              "ollama"
              "mistral"
              "voyage"
            ];
            default = "openai";
            description = "Embedding provider backend";
          };
          ollamaHost = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "Ollama server URL (only used when embeddingProvider = ollama)";
          };
          postgresHost = lib.mkOption {
            type = lib.types.str;
            default = "localhost";
            description = "PostgreSQL host address";
          };
        };
      };

    perInstance =
      {
        settings,
        machine,
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
            needsApiKey = builtins.elem settings.embeddingProvider [
              "openai"
              "mistral"
              "voyage"
            ];
            dbPasswordPath = config.clan.core.vars.generators."ogham-db-password".files."password".path;
            apiKeyPath =
              if needsApiKey then
                config.clan.core.vars.generators."ogham-embedding-api-key".files."api-key".path
              else
                "";
            tlsConfig = config.caddy-cloudflare.tls;
          in
          {
            # ── Vars generators ──────────────────────────────────────────────

            clan.core.vars.generators."ogham-db-password" = {
              share = true;
              files."password" = {
                secret = true;
                mode = "0440";
              };
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > $out/password
              '';
            };

            clan.core.vars.generators."ogham-embedding-api-key" = lib.mkIf needsApiKey {
              prompts."api-key" = {
                type = "hidden";
                description = "API key for ${settings.embeddingProvider} embedding provider";
              };
              files."api-key" = {
                secret = true;
              };
              script = ''
                cp "$prompts/api-key" "$out/api-key"
              '';
            };

            # ── PostgreSQL + pgvector ────────────────────────────────────────

            services.postgresql = {
              enable = true;
              extensions = ps: [ ps.pgvector ];
              ensureDatabases = [ "ogham" ];
              ensureUsers = [
                {
                  name = "ogham";
                  ensureDBOwnership = true;
                }
              ];
            };

            # ── Systemd service ──────────────────────────────────────────────

            systemd.services.ogham-mcp = {
              description = "ogham-mcp persistent agent memory server";
              after = [
                "network.target"
                "postgresql.service"
              ];
              requires = [ "postgresql.service" ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "simple";
                ExecStart = "${pkgs.uv}/bin/uvx ogham-mcp";
                Restart = "on-failure";
                RestartSec = 5;
                EnvironmentFile = "/run/ogham-mcp.env";
                DynamicUser = true;
                StateDirectory = "ogham-mcp";
              };

              preStart = lib.mkBefore (
                let
                  dbPassword = "$(cat ${dbPasswordPath})";
                  dbUrl = "postgresql://ogham:${dbPassword}@${settings.postgresHost}/ogham";
                in
                ''
                  printf '%s\n' \
                    "DATABASE_URL=${dbUrl}" \
                    "OGHAM_PORT=${toString settings.port}" \
                    "OGHAM_TRANSPORT=sse" \
                    "OGHAM_EMBEDDING_PROVIDER=${settings.embeddingProvider}" \
                ''
                + lib.optionalString (settings.ollamaHost != "") ''
                    "OGHAM_OLLAMA_HOST=${settings.ollamaHost}" \
                ''
                + lib.optionalString needsApiKey ''
                    "OGHAM_API_KEY=$(cat ${apiKeyPath})" \
                ''
                + ''
                    > /run/ogham-mcp.env
                ''
              );
            };

            # ── Caddy reverse proxy ──────────────────────────────────────────

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

            # ── Firewall ─────────────────────────────────────────────────────

            networking.firewall.allowedTCPPorts = [ 443 ];

            # ── Borgbackup state ─────────────────────────────────────────────

            clan.core.state.ogham-mcp.folders = [
              "/var/lib/postgresql"
              "/persist/ogham-mcp"
            ];

            # ── Tmpfiles ─────────────────────────────────────────────────────

            systemd.tmpfiles.rules = [
              "d /persist/ogham-mcp 0755 root root"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client = {
    description = "ogham-mcp agent tooling (MCP endpoint config, skills, HM delegation)";

    interface =
      { lib, ... }:
      let
        profileSubmodule = lib.types.submodule {
          options.mcp.enabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Add ogham-mcp MCP server entry to this Claude Code profile";
          };
        };

        clientSubmodule = lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Integration identifier (e.g., 'ogham-mcp', 'ogham-mcp-work')";
            };
            url = lib.mkOption {
              type = lib.types.str;
              description = "SSE endpoint URL (e.g., 'https://ogham.swancloud.net')";
            };
            claude-code = {
              skill.enabled = lib.mkOption {
                type = lib.types.bool;
                default = true;
                description = "Install Claude agent skill";
              };
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
      in
      {
        options.clients = lib.mkOption {
          type = lib.types.attrsOf clientSubmodule;
          default = { };
          description = "Named client configurations for ogham-mcp instances";
        };
      };

    perInstance =
      {
        settings,
        ...
      }:
      let
        clientModule =
          {
            config,
            pkgs,
            lib,
            ...
          }:
          let
            skillTemplate = ./skills/SKILL.md;

            mkClientConfig =
              clientName: clientSettings:
              let
                apiKeyPath = config.clan.core.vars.generators."agentplot-ogham-mcp-${clientName}-api-key".files."api-key".path;
                mcpName = clientSettings.name;
                sseUrl = clientSettings.url;

                clientSkill = builtins.replaceStrings
                  [ "name: ogham-mcp" ]
                  [ "name: ${mcpName}" ]
                  (builtins.readFile skillTemplate);

                mcpConfig = {
                  url = "${sseUrl}/sse";
                };
              in
              {
                vars = {
                  "agentplot-ogham-mcp-${clientName}-api-key" = {
                    prompts."api-key" = {
                      type = "hidden";
                      description = "API key for ogham-mcp client '${clientName}' at ${sseUrl}";
                    };
                    files."api-key" = {
                      secret = true;
                    } // lib.optionalAttrs (config ? agentplot && config.agentplot.user != null) {
                      owner = config.agentplot.user;
                      group = "staff";
                    };
                    script = ''
                      cp "$prompts/api-key" "$out/api-key"
                    '';
                  };
                };

                hmModule = { ... }: {
                  programs.claude-code = lib.mkMerge [
                    (lib.mkIf clientSettings.claude-code.skill.enabled {
                      skills.${mcpName} = clientSkill;
                    })
                    (lib.mkIf clientSettings.claude-code.mcp.enabled {
                      mcpServers.${mcpName} = mcpConfig;
                    })
                    (lib.mkIf (clientSettings.claude-code.profiles != { }) {
                      profiles = lib.mapAttrs (
                        profileName: profileSettings:
                        lib.mkIf profileSettings.mcp.enabled {
                          mcpServers.${mcpName} = mcpConfig;
                        }
                      ) clientSettings.claude-code.profiles;
                    })
                  ];

                  programs.agent-deck = lib.mkIf clientSettings.agent-deck.mcp.enabled {
                    mcps.${mcpName} = mcpConfig;
                  };
                };
              };

            clientConfigs = lib.mapAttrs mkClientConfig settings.clients;
          in
          {
            clan.core.vars.generators = lib.mkMerge (
              lib.mapAttrsToList (_: cc: cc.vars) clientConfigs
            );

            agentplot.hmModules = lib.mapAttrs' (
              clientName: cc:
              lib.nameValuePair "ogham-mcp-${clientName}" cc.hmModule
            ) clientConfigs;
          };
      in
      {
        nixosModule = clientModule;
        darwinModule = clientModule;
      };
  };
}
