{ ... }:
{
  _class = "clan.service";
  manifest.name = "linkding";
  manifest.description = "linkding bookmark manager with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "linkding instance (OCI container + Caddy + PostgreSQL)";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the linkding instance";
          };
          oidc = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable OIDC authentication via Kanidm";
            };
            issuerDomain = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = "Kanidm server domain for OIDC endpoint construction";
            };
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
            oidcEnabled = settings.oidc.enable;
            issuerDomain = settings.oidc.issuerDomain;
            clientId = machine.name;
            secretPath =
              if oidcEnabled
              then config.clan.core.vars.generators."kanidm-oidc-${machine.name}".files."client-secret".path
              else "";
            dbPasswordPath = config.clan.core.vars.generators."linkding-db-password".files."password".path;
            tlsConfig = config.caddy-cloudflare.tls;
          in
          {
            clan.core.vars.generators."linkding-db-password" = {
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

            virtualisation.oci-containers = {
              backend = "podman";
              containers.linkding = {
                image = "sissbruecker/linkding:latest";
                ports = [ "9090:9090" ];
                volumes = [
                  "/persist/linkding:/etc/linkding/data"
                ];
                environment = {
                  LD_SERVER_PORT = "9090";
                  LD_DB_ENGINE = "postgres";
                  LD_DB_HOST = "10.0.0.1";
                  LD_DB_PORT = "5432";
                  LD_DB_DATABASE = "linkding";
                  LD_DB_USER = "linkding";
                } // lib.optionalAttrs oidcEnabled {
                  LD_ENABLE_OIDC = "True";
                  OIDC_USE_PKCE = "True";
                  LD_CSRF_TRUSTED_ORIGINS = "https://${settings.domain}";
                  OIDC_VERIFY_SSL = "True";
                };
                environmentFiles = [ "/run/linkding-db.env" ] ++ lib.optionals oidcEnabled [ "/run/linkding-oidc.env" ];
              };
            };

            systemd.services."podman-linkding" = {
              preStart = lib.mkBefore (
                ''
                  DB_PASSWORD=$(cat ${dbPasswordPath})
                  printf 'LD_DB_PASSWORD=%s\n' "$DB_PASSWORD" > /run/linkding-db.env
                ''
                + lib.optionalString oidcEnabled ''
                  SECRET=$(cat ${secretPath})
                  printf '%s\n' \
                    "OIDC_OP_AUTHORIZATION_ENDPOINT=https://${issuerDomain}/ui/oauth2" \
                    "OIDC_OP_TOKEN_ENDPOINT=https://${issuerDomain}/oauth2/token" \
                    "OIDC_OP_USER_ENDPOINT=https://${issuerDomain}/oauth2/openid/${clientId}/userinfo" \
                    "OIDC_OP_JWKS_ENDPOINT=https://${issuerDomain}/oauth2/openid/${clientId}/public_key.jwk" \
                    "OIDC_RP_CLIENT_ID=${clientId}" \
                    "OIDC_RP_CLIENT_SECRET=$SECRET" \
                    "OIDC_RP_SIGN_ALGO=ES256" \
                    > /run/linkding-oidc.env
                ''
              );
            };

            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:9090
                '';
              };
            };

            networking.firewall.allowedTCPPorts = [ 443 ];

            systemd.tmpfiles.rules = [
              "d /persist/linkding 0755 root root"
              "d /persist/caddy 0700 caddy caddy"
            ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client = {
    description = "linkding agent tooling (CLI wrappers, skills, MCP, downstream HM delegation)";

    interface =
      { lib, ... }:
      let
        profileSubmodule = lib.types.submodule {
          options.mcp.enabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Add linkding MCP server entry to this Claude Code profile";
          };
        };

        clientSubmodule = lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "CLI binary name and integration identifier (e.g., 'linkding', 'linkding-biz')";
            };
            base_url = lib.mkOption {
              type = lib.types.str;
              description = "Base URL of the linkding instance (e.g., 'https://links.example.com')";
            };
            default_tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [ ];
              description = "Default tags for bookmarks created by this client";
            };
            cli.enabled = lib.mkOption {
              type = lib.types.bool;
              default = true;
              description = "Install per-client CLI wrapper script";
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
            agent-skills.enabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Distribute skill via agent-skills module (Phase 2)";
            };
            agent-deck.mcp.enabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Add agent-deck MCP entry (Phase 2)";
            };
            openclaw.skill.enabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Add OpenClaw skill (Phase 2)";
            };
            claude-tools.enabled = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Install via claude-plugins marketplace (Phase 2)";
            };
          };
        };
      in
      {
        options.clients = lib.mkOption {
          type = lib.types.attrsOf clientSubmodule;
          default = { };
          description = "Named client configurations for linkding instances";
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
            baseCli = pkgs.callPackage ./packages/linkding-cli { };
            skillTemplate = ./skills/SKILL.md;

            mkClientConfig =
              clientName: clientSettings:
              let
                tokenPath = config.clan.core.vars.generators."agentplot-linkding-${clientName}-api-token".files."token".path;
                cliName = clientSettings.name;
                baseUrl = clientSettings.base_url;

                # Per-client CLI wrapper
                cliWrapper = pkgs.writeShellApplication {
                  name = cliName;
                  runtimeInputs = [ baseCli ];
                  text = ''
                    export LINKDING_API_TOKEN="$(cat ${tokenPath})"
                    export LINKDING_BASE_URL="${baseUrl}"
                    exec linkding-cli "$@"
                  '';
                };

                # Per-client SKILL.md with CLI name substituted
                clientSkill = pkgs.runCommand "linkding-skill-${cliName}" { } ''
                  ${pkgs.gnused}/bin/sed 's/linkding-cli/${cliName}/g' ${skillTemplate} > $out
                '';

                # Claude Code MCP server config for this client
                mcpConfig = {
                  command = "${cliWrapper}/bin/${cliName}";
                  args = [ "mcp" ];
                  env = {
                    LINKDING_API_TOKEN_FILE = tokenPath;
                    LINKDING_BASE_URL = baseUrl;
                  };
                };
              in
              {
                # Clan vars generator for this client's API token
                vars = {
                  "agentplot-linkding-${clientName}-api-token" = {
                    prompts."token" = {
                      type = "hidden";
                      description = "API token for linkding client '${clientName}' at ${baseUrl}";
                    };
                    files."token" = {
                      secret = true;
                    };
                  };
                };

                # HM module for this client
                hmModule = { ... }: {
                  home.packages = lib.optionals clientSettings.cli.enabled [ cliWrapper ];

                  programs.claude-code = lib.mkMerge [
                    (lib.mkIf clientSettings.claude-code.skill.enabled {
                      skills.${cliName} = clientSkill;
                    })
                    (lib.mkIf clientSettings.claude-code.mcp.enabled {
                      mcpServers.${cliName} = mcpConfig;
                    })
                    (lib.mkIf (clientSettings.claude-code.profiles != { }) {
                      profiles = lib.mapAttrs (
                        profileName: profileSettings:
                        lib.mkIf profileSettings.mcp.enabled {
                          mcpServers.${cliName} = mcpConfig;
                        }
                      ) clientSettings.claude-code.profiles;
                    })
                  ];

                  # Phase 2 delegation stubs
                  programs.agent-skills = lib.mkIf clientSettings.agent-skills.enabled {
                    sources."agentplot-linkding" = {
                      type = "path";
                      path = "${./skills}";
                    };
                    skills.explicit.${cliName} = {
                      source = "agentplot-linkding";
                      packages = [ cliWrapper ];
                      transform = content:
                        builtins.replaceStrings [ "linkding-cli" ] [ cliName ] content;
                    };
                    targets.claude.enable = true;
                  };

                  programs.agent-deck = lib.mkIf clientSettings.agent-deck.mcp.enabled {
                    mcps.${cliName} = mcpConfig;
                  };

                  programs.openclaw = lib.mkIf clientSettings.openclaw.skill.enabled {
                    skills = [
                      {
                        name = cliName;
                        mode = "symlink";
                        content = clientSkill;
                      }
                    ];
                  };

                  programs.claude-tools = lib.mkIf clientSettings.claude-tools.enabled {
                    skills-installer.skillsByClient.claude-code.${cliName} = "symlink";
                  };
                };
              };

            clientConfigs = lib.mapAttrs mkClientConfig settings.clients;
          in
          {
            # Register clan vars generators for all clients
            clan.core.vars.generators = lib.mkMerge (
              lib.mapAttrsToList (_: cc: cc.vars) clientConfigs
            );

            # Wire HM modules through the agentplot passthrough
            agentplot.hmModules = lib.mapAttrs' (
              clientName: cc:
              lib.nameValuePair "linkding-${clientName}" cc.hmModule
            ) clientConfigs;
          };
      in
      {
        nixosModule = clientModule;
        darwinModule = clientModule;
      };
  };
}
