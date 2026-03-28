{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "subcog";
  manifest.description = "Persistent agent memory with hybrid search, knowledge graph, and namespace-scoped retention";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "subcog memory server (Rust binary + Caddy, external PostgreSQL)";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the subcog instance (e.g., subcog.swancloud.net)";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 8421;
            description = "HTTP port for the subcog server";
          };
          llmProvider = lib.mkOption {
            type = lib.types.enum [
              "anthropic"
              "openai"
              "ollama"
            ];
            default = "anthropic";
            description = "LLM provider for enrichment, consolidation, and auto-capture analysis";
          };
          llmModel = lib.mkOption {
            type = lib.types.str;
            default = "";
            description = "LLM model name (empty = provider default)";
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
            needsApiKey = builtins.elem settings.llmProvider [
              "anthropic"
              "openai"
            ];
            dbPasswordPath = config.clan.core.vars.generators."subcog-db-password".files."password".path;
            jwtSecretPath = config.clan.core.vars.generators."subcog-jwt-secret".files."secret".path;
            apiKeyPath =
              if needsApiKey then
                config.clan.core.vars.generators."subcog-llm-api-key".files."api-key".path
              else
                "";
            tlsConfig = config.caddy-cloudflare.tls;
            port = toString settings.port;
          in
          {
            # ── Vars generators ──────────────────────────────────────────────

            clan.core.vars.generators."subcog-db-password" = {
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

            clan.core.vars.generators."subcog-jwt-secret" = {
              share = true;
              files."secret" = {
                secret = true;
                mode = "0440";
              };
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -base64 32 > $out/secret
              '';
            };

            clan.core.vars.generators."subcog-jwt-token" = {
              share = true;
              files."token" = {
                secret = true;
                mode = "0440";
              };
              runtimeInputs = [
                pkgs.openssl
                pkgs.coreutils
              ];
              script = ''
                SECRET=$(cat ${jwtSecretPath})
                # base64url encode (RFC 7515)
                b64url() { openssl base64 -e | tr -d '=\n' | tr '/+' '_-'; }
                HEADER=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
                EXP=$(( $(date +%s) + 315360000 ))
                IAT=$(date +%s)
                PAYLOAD=$(printf '{"sub":"agentplot","scopes":["*"],"exp":%d,"iat":%d}' "$EXP" "$IAT" | b64url)
                SIG=$(printf '%s.%s' "$HEADER" "$PAYLOAD" | openssl dgst -sha256 -hmac "$SECRET" -binary | b64url)
                printf '%s.%s.%s' "$HEADER" "$PAYLOAD" "$SIG" > $out/token
              '';
            };

            clan.core.vars.generators."subcog-llm-api-key" = lib.mkIf needsApiKey {
              prompts."api-key" = {
                type = "hidden";
                description = "API key for ${settings.llmProvider} LLM provider";
              };
              files."api-key" = {
                secret = true;
              };
              script = ''
                cp "$prompts/api-key" "$out/api-key"
              '';
            };

            # ── Env file preparation ─────────────────────────────────────────

            systemd.services.subcog-env = {
              description = "Prepare subcog environment file";
              before = [ "subcog.service" ];
              requiredBy = [ "subcog.service" ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script =
                let
                  staticVars = lib.concatStringsSep "\n" (
                    [
                      "SUBCOG_STORAGE_BACKEND=postgresql"
                      "SUBCOG_PORT=${port}"
                      "SUBCOG_HOST=127.0.0.1"
                      "SUBCOG_LLM_PROVIDER=${settings.llmProvider}"
                    ]
                    ++ lib.optional (settings.llmModel != "") "SUBCOG_LLM_MODEL=${settings.llmModel}"
                  );
                in
                ''
                  DB_PASSWORD=$(cat ${dbPasswordPath})
                  JWT_SECRET=$(cat ${jwtSecretPath})
                  {
                    printf 'SUBCOG_STORAGE_CONNECTION_STRING=postgresql://subcog:%s@10.0.0.1/subcog\n' "$DB_PASSWORD"
                    printf 'SUBCOG_MCP_JWT_SECRET=%s\n' "$JWT_SECRET"
                    printf '%s\n' ${lib.escapeShellArg staticVars}
                '' + lib.optionalString needsApiKey ''
                    printf 'SUBCOG_LLM_API_KEY=%s\n' "$(cat ${apiKeyPath})"
                '' + ''
                  } > /run/subcog.env
                '';
            };

            systemd.services.subcog = {
              description = "subcog persistent memory server";
              after = [
                "network.target"
                "subcog-env.service"
              ];
              wantedBy = [ "multi-user.target" ];

              serviceConfig = {
                Type = "simple";
                User = "subcog";
                Group = "subcog";
                EnvironmentFile = "/run/subcog.env";
                ExecStart = "${pkgs.llm-agents.subcog}/bin/subcog serve --transport http --port ${port}";
                Restart = "on-failure";
                RestartSec = 5;

                # Hardening
                NoNewPrivileges = true;
                ProtectSystem = "strict";
                ProtectHome = true;
                ReadWritePaths = [ "/persist/subcog" ];
              };
            };

            users.users.subcog = {
              isSystemUser = true;
              group = "subcog";
              home = "/persist/subcog";
              createHome = true;
            };
            users.groups.subcog = { };

            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:${port}
                '';
              };
            };

            networking.firewall.allowedTCPPorts = [ 443 ];

            clan.core.state.subcog.folders = [ "/persist/subcog" ];

            systemd.tmpfiles.rules = [
              "d /persist/subcog 0750 subcog subcog"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "subcog";
        capabilities = {
          skills = [ ./skills/cli/SKILL.md ];
          secret = [
            {
              name = "db-password";
              mode = "shared";
              generator = "subcog-db-password";
              file = "password";
            }
            {
              name = "jwt-token";
              mode = "shared";
              generator = "subcog-jwt-token";
              file = "token";
            }
          ];
          cli = {
            package = ./packages/subcog-cli;
            wrapperName = client: "subcog-${client.name}";
            envVars = client: {
              SUBCOG_DOMAIN = client.domain;
              SUBCOG_STORAGE_BACKEND = "postgresql";
              SUBCOG_STORAGE_CONNECTION_STRING = "postgresql://subcog:$(cat ${client.secretPaths."db-password"})@${client.domain}/subcog";
            };
          };
          mcp = {
            type = "http";
            urlTemplate = client: "https://${client.domain}/mcp";
            extraConfig = client: {
              tokenFile = client.secretPaths."jwt-token";
            };
          };
        };
        extraClientOptions = { lib, ... }: {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN of the subcog server (e.g., subcog.swancloud.net)";
          };
          namespace = lib.mkOption {
            type = lib.types.str;
            default = "default";
            description = "Memory namespace for scoping";
          };
        };
      };
    in
    {
      description = "subcog MCP client (HTTP endpoint, CLI, skills, HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
