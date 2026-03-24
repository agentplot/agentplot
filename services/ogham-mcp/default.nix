{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "ogham-mcp";
  manifest.description = "Persistent agent memory server with hybrid search, knowledge graph, and cognitive decay";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "ogham-mcp instance (systemd + Caddy, external PostgreSQL)";

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

            # ── Systemd service ──────────────────────────────────────────────

            systemd.services.ogham-mcp = {
              description = "ogham-mcp persistent agent memory server";
              after = [ "network.target" ];
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
                  dbUrl = "postgresql://ogham:${dbPassword}@10.0.0.1/ogham";
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

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "ogham-mcp";
        capabilities = {
          skills = [ ./skills/cli/SKILL.md ];
          mcp = {
            type = "sse";
            urlTemplate = client: "${client.url}/sse";
          };
        };
        extraClientOptions = { lib, ... }: {
          url = lib.mkOption {
            type = lib.types.str;
            description = "SSE endpoint URL (e.g., 'https://ogham.swancloud.net')";
          };
        };
      };
    in
    {
      description = "ogham-mcp agent tooling (MCP endpoint config, skills, HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
