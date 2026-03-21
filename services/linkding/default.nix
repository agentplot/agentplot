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
            oidcCfg = config.agentplot.oidc.clients.linkding;
            dbPasswordPath = config.clan.core.vars.generators."linkding-db-password".files."password".path;
            tlsConfig = config.caddy-cloudflare.tls;
          in
          {
            imports = [ ../../modules/oidc.nix ];

            agentplot.oidc.clients.linkding = lib.mkIf oidcEnabled {
              enable = true;
              provider = "kanidm";
              issuerUrl = settings.oidc.issuerDomain;
              clientId = machine.name;
            };

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
                  SECRET=$(cat ${config.clan.core.vars.generators."oidc-linkding".files."client-secret".path})
                  printf '%s\n' \
                    "OIDC_OP_AUTHORIZATION_ENDPOINT=${oidcCfg.endpoints.authorization}" \
                    "OIDC_OP_TOKEN_ENDPOINT=${oidcCfg.endpoints.token}" \
                    "OIDC_OP_USER_ENDPOINT=${oidcCfg.endpoints.userinfo}" \
                    "OIDC_OP_JWKS_ENDPOINT=${oidcCfg.endpoints.jwks}" \
                    "OIDC_RP_CLIENT_ID=${oidcCfg.clientId}" \
                    "OIDC_RP_CLIENT_SECRET=$SECRET" \
                    "OIDC_RP_SIGN_ALGO=${oidcCfg.signAlgorithm}" \
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
                    LINKDING_API_TOKEN="$(cat ${tokenPath})"
                    export LINKDING_API_TOKEN
                    export LINKDING_BASE_URL="${baseUrl}"
                    exec linkding-cli "$@"
                  '';
                };

                # Per-client SKILL.md with CLI name substituted
                clientSkill = builtins.replaceStrings
                  [ "name: linkding" "linkding-cli" ]
                  [ "name: ${cliName}" cliName ]
                  (builtins.readFile skillTemplate);

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
                    } // lib.optionalAttrs (config ? agentplot && config.agentplot.user != null) {
                      owner = config.agentplot.user;
                      group = "staff";
                    };
                    script = ''
                      cp "$prompts/token" "$out/token"
                    '';
                  };
                };

                # HM module for this client
                hmModule = { ... }: {
                  home.packages = lib.optionals clientSettings.cli.enabled [ cliWrapper ];

                  programs.claude-code = lib.mkMerge [
                    (lib.mkIf (clientSettings.claude-code.skill.enabled && !clientSettings.agent-skills.enabled) {
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

                  # Phase 2: agent-skills-nix delegation
                  programs.agent-skills = lib.mkIf clientSettings.agent-skills.enabled {
                    enable = true;
                    sources."agentplot-linkding" = {
                      path = ./skills;
                    };
                    skills.explicit.${cliName} = {
                      from = "agentplot-linkding";
                      packages = [ cliWrapper ];
                      transform = { original, ... }:
                        builtins.replaceStrings [ "name: linkding" "linkding-cli" ] [ "name: ${cliName}" cliName ] original;
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
