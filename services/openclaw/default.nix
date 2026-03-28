{ mkClientTooling, openclaw-packages ? { }, lobster ? null, ... }:
{
  _class = "clan.service";
  manifest.name = "openclaw";
  manifest.description = "OpenClaw AI assistant — gateway + node architecture with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Server Role (ported from swancloud/clanServices/openclaw) ──────────────

  roles.server = {
    description = "OpenClaw gateway on a microvm with Caddy HTTPS";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the OpenClaw gateway (e.g. openclaw.swancloud.net)";
          };
          ip = lib.mkOption {
            type = lib.types.str;
            description = "Microvm IP address on the bridge network";
          };
          port = lib.mkOption {
            type = lib.types.port;
            default = 18789;
            description = "Gateway listen port (proxied by Caddy)";
          };
          providers = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options.apiKeyFile = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "Path to the API key file (set automatically from clan vars)";
              };
            });
            default = { };
            description = "Model provider configuration";
          };
          plugins = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "Custom plugin list passed through to nix-openclaw";
          };
          bundledPlugins = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Bundled plugin toggles passed through to programs.openclaw.bundledPlugins";
          };

          # Agents
          agents = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                id = lib.mkOption {
                  type = lib.types.str;
                  description = "Unique agent identifier";
                };
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name for the agent";
                };
                default = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether this is the default agent";
                };
                model = lib.mkOption {
                  type = lib.types.str;
                  default = "";
                  description = "Model override for this agent (e.g. anthropic/claude-sonnet-4-20250514)";
                };
              };
            });
            default = [ ];
            description = "Agent definitions";
          };
          agentDefaults = {
            model = lib.mkOption {
              type = lib.types.str;
              default = "anthropic/claude-sonnet-4-20250514";
              description = "Default model for agents";
            };
            thinkingDefault = lib.mkOption {
              type = lib.types.enum [ "off" "low" "medium" "high" ];
              default = "high";
              description = "Default thinking level";
            };
            maxConcurrent = lib.mkOption {
              type = lib.types.int;
              default = 4;
              description = "Max concurrent agent tasks";
            };
          };

          # Bindings (agent -> channel account)
          bindings = lib.mkOption {
            type = lib.types.listOf (lib.types.submodule {
              options = {
                agentId = lib.mkOption {
                  type = lib.types.str;
                  description = "Agent ID to bind";
                };
                channel = lib.mkOption {
                  type = lib.types.str;
                  description = "Channel type (e.g. telegram, discord)";
                };
                accountId = lib.mkOption {
                  type = lib.types.str;
                  description = "Account ID within the channel";
                };
              };
            });
            default = [ ];
            description = "Bindings mapping agents to channel accounts";
          };

          # Channels
          channels = {
            telegram = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable Telegram channel";
              };
              allowFrom = lib.mkOption {
                type = lib.types.listOf lib.types.int;
                default = [ ];
                description = "Telegram user/group IDs allowed to message the bots";
              };
              accounts = lib.mkOption {
                type = lib.types.attrsOf (lib.types.submodule {
                  options = {
                    dmPolicy = lib.mkOption {
                      type = lib.types.enum [ "pairing" "allowlist" "open" "disabled" ];
                      default = "pairing";
                      description = "DM policy for this account";
                    };
                    groupPolicy = lib.mkOption {
                      type = lib.types.enum [ "allowlist" "open" "disabled" ];
                      default = "allowlist";
                      description = "Group chat policy";
                    };
                    streamMode = lib.mkOption {
                      type = lib.types.enum [ "partial" "full" "disabled" ];
                      default = "partial";
                      description = "Message streaming mode";
                    };
                  };
                });
                default = { };
                description = "Telegram bot accounts (each gets its own bot token secret)";
              };
            };
            discord = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable Discord channel";
              };
            };
            bluebubbles = {
              enable = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Enable BlueBubbles (iMessage) channel";
              };
              serverUrl = lib.mkOption {
                type = lib.types.str;
                default = "";
                description = "BlueBubbles server URL (e.g. http://mac-studio.local:1234)";
              };
              webhookPath = lib.mkOption {
                type = lib.types.str;
                default = "/bluebubbles-webhook";
                description = "Webhook path for incoming BlueBubbles messages";
              };
            };
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
            tlsConfig = config.caddy-cloudflare.tls;
            providerNames = builtins.attrNames settings.providers;
            goplacesEnabled = (settings.bundledPlugins.goplaces.enable or false);
            telegramEnabled = settings.channels.telegram.enable;
            telegramAccountNames = builtins.attrNames settings.channels.telegram.accounts;
            discordEnabled = settings.channels.discord.enable;
            bluebubblesEnabled = settings.channels.bluebubbles.enable;
          in
          {
            clan.core.vars.generators = {
              # Shared gateway auth token
              openclaw-gateway-token = {
                share = true;
                files.token = {
                  secret = true;
                  owner = "openclaw";
                  group = "openclaw";
                };
                runtimeInputs = [ pkgs.openssl ];
                script = ''
                  openssl rand -hex 32 > $out/token
                '';
              };
            }
            # Provider API key generators
            // builtins.listToAttrs (map (name: {
              name = "openclaw-provider-${name}";
              value = {
                share = true;
                files.api-key = {
                  secret = true;
                  owner = "openclaw";
                  group = "openclaw";
                };
                prompts.api-key = {
                  description = "API key for ${name} provider";
                  type = "hidden";
                };
                script = ''
                  cp "$prompts/api-key" "$out/api-key"
                '';
              };
            }) providerNames)
            # Per-account Telegram bot token generators
            // builtins.listToAttrs (map (acct: {
              name = "openclaw-telegram-${acct}";
              value = {
                share = true;
                files.token = {
                  secret = true;
                  owner = "openclaw";
                  group = "openclaw";
                };
                prompts.token = {
                  description = "Telegram bot token for '${acct}' account (from @BotFather)";
                  type = "hidden";
                };
                script = ''
                  cp "$prompts/token" "$out/token"
                '';
              };
            }) telegramAccountNames)
            // lib.optionalAttrs goplacesEnabled {
              openclaw-goplaces-api-key = {
                share = true;
                files.api-key = {
                  secret = true;
                  owner = "openclaw";
                  group = "openclaw";
                };
                prompts.api-key = {
                  description = "Google Places API key for goplaces plugin";
                  type = "hidden";
                };
                script = ''
                  cp "$prompts/api-key" "$out/api-key"
                '';
              };
            }
            // lib.optionalAttrs discordEnabled {
              openclaw-discord-token = {
                share = true;
                files.token = {
                  secret = true;
                  owner = "openclaw";
                  group = "openclaw";
                };
                prompts.token = {
                  description = "Discord bot token";
                  type = "hidden";
                };
                script = ''
                  cp "$prompts/token" "$out/token"
                '';
              };
            }
            // lib.optionalAttrs bluebubblesEnabled {
              openclaw-bluebubbles-password = {
                share = true;
                files.password = {
                  secret = true;
                  owner = "openclaw";
                  group = "openclaw";
                };
                prompts.password = {
                  description = "BlueBubbles server password";
                  type = "hidden";
                };
                script = ''
                  cp "$prompts/password" "$out/password"
                '';
              };
            };

            # Service user with linger for systemd user services
            users.users.openclaw = {
              isSystemUser = true;
              group = "openclaw";
              home = "/home/openclaw";
              createHome = true;
              shell = pkgs.bash;
              linger = true;
            };
            users.groups.openclaw = { };

            # nix-openclaw via home-manager for the openclaw user
            home-manager.users.openclaw = {
              home = {
                username = "openclaw";
                homeDirectory = "/home/openclaw";
                stateVersion = "24.11";
              };
              programs.openclaw = {
                enable = true;
                bundledPlugins = lib.recursiveUpdate settings.bundledPlugins (
                  lib.optionalAttrs goplacesEnabled {
                    goplaces.config.env.GOOGLE_PLACES_API_KEY =
                      config.clan.core.vars.generators.openclaw-goplaces-api-key.files.api-key.path;
                  }
                );
                config = {
                  # Agent definitions
                  agents = lib.optionalAttrs (settings.agents != [ ]) {
                    defaults = {
                      model.primary = settings.agentDefaults.model;
                      thinkingDefault = settings.agentDefaults.thinkingDefault;
                      maxConcurrent = settings.agentDefaults.maxConcurrent;
                    };
                    list = map (a: {
                      inherit (a) id name;
                      default = a.default or false;
                    } // lib.optionalAttrs (a.model != "") {
                      model.primary = a.model;
                    }) settings.agents;
                  };

                  # Agent-to-channel bindings
                  bindings = map (b: {
                    agentId = b.agentId;
                    match = {
                      channel = b.channel;
                      accountId = b.accountId;
                    };
                  }) settings.bindings;

                  # Channels
                  channels = lib.filterAttrs (_: v: v != { }) {
                    telegram = lib.optionalAttrs telegramEnabled ({
                      enabled = true;
                      dmPolicy = "pairing";
                      allowFrom = settings.channels.telegram.allowFrom;
                      groupPolicy = "allowlist";
                      streamMode = "partial";
                      accounts = builtins.mapAttrs (acct: acctCfg: {
                        inherit (acctCfg) dmPolicy groupPolicy streamMode;
                        botTokenFile = config.clan.core.vars.generators."openclaw-telegram-${acct}".files.token.path;
                      }) settings.channels.telegram.accounts;
                    });
                    discord = lib.optionalAttrs discordEnabled {
                      tokenFile = config.clan.core.vars.generators.openclaw-discord-token.files.token.path;
                    };
                    bluebubbles = lib.optionalAttrs bluebubblesEnabled {
                      enabled = true;
                      serverUrl = settings.channels.bluebubbles.serverUrl;
                      passwordFile = config.clan.core.vars.generators.openclaw-bluebubbles-password.files.password.path;
                      webhookPath = settings.channels.bluebubbles.webhookPath;
                    };
                  };
                };
                instances.default = {
                  enable = true;
                  gatewayPort = settings.port;
                  systemd.enable = true;
                  stateDir = "/persist/openclaw";
                  plugins = settings.plugins;
                  config = {
                    gateway.mode = "local";
                    gateway.controlUi.allowedOrigins = [ "https://${settings.domain}" ];
                    gateway.trustedProxies = [ "127.0.0.1" ];
                  };
                };
              };

              # Pre-service to load provider API keys from clan vars into env file
              systemd.user.services.openclaw-provider-env = {
                Unit.Description = "Load OpenClaw provider API keys";
                Service = {
                  Type = "oneshot";
                  RemainAfterExit = true;
                  ExecStart = "${pkgs.writeShellScript "gen-provider-env" ''
                    export PATH="${lib.makeBinPath [ pkgs.coreutils ]}:$PATH"
                    mkdir -p /tmp/openclaw
                    {
                      echo "OPENCLAW_GATEWAY_TOKEN=$(cat ${config.clan.core.vars.generators.openclaw-gateway-token.files.token.path})";
                      ${lib.concatMapStringsSep "\n" (name:
                        "echo \"${lib.toUpper name}_API_KEY=$(cat ${config.clan.core.vars.generators."openclaw-provider-${name}".files.api-key.path})\";"
                      ) providerNames}
                    } > /tmp/openclaw/provider-env
                  ''}";
                };
                Install.WantedBy = [ "default.target" ];
              };

              # Inject provider env into the gateway service and ensure it auto-starts
              systemd.user.services.openclaw-gateway = {
                Unit.After = [ "openclaw-provider-env.service" ];
                Unit.Requires = [ "openclaw-provider-env.service" ];
                Service.EnvironmentFile = "/tmp/openclaw/provider-env";
                Service.StandardOutput = lib.mkForce "journal";
                Service.StandardError = lib.mkForce "journal";
                Install.WantedBy = [ "default.target" ];
              };
            };

            # Persistent state
            systemd.tmpfiles.rules = [
              "d /persist/openclaw 0750 openclaw openclaw"
              "d /persist/caddy 0700 caddy caddy"
            ];

            clan.core.state.openclaw.folders = [ "/persist/openclaw" ];

            # Caddy reverse proxy
            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://127.0.0.1:${toString settings.port}
                '';
              };
            };

            services.openssh = {
              enable = true;
              settings.PasswordAuthentication = false;
            };
            users.users.root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDLmvJz0ifloHcAUiyHTz43oXvByS9otzvi/EKtRnY7/"
            ];

            networking.firewall.allowedTCPPorts = [ 22 443 ];
          };
      };
  };

  # ── Node Role (ported from swancloud/clanServices/openclaw) ────────────────

  roles.node = {
    description = "OpenClaw node connecting to remote gateway";

    interface =
      { lib, ... }:
      {
        options = {
          plugins = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
            default = [ ];
            description = "Node-local custom plugins passed through to nix-openclaw";
          };
          bundledPlugins = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            description = "Bundled plugin toggles passed through to programs.openclaw.bundledPlugins";
          };
        };
      };

    perInstance =
      {
        settings,
        roles,
        ...
      }:
      let
        serverName = builtins.head (builtins.attrNames (roles.server.machines or { }));
        serverSettings = roles.server.machines.${serverName}.settings;
        # Placeholder that gets replaced at activation with the real token.
        # nix-openclaw expects gateway.remote.token to be a literal string,
        # but clan vars secrets only exist at runtime, not nix eval time.
        tokenPlaceholder = "__OPENCLAW_GATEWAY_TOKEN_PLACEHOLDER__";

        openclawHmConfig = config: {
          programs.openclaw = {
            enable = true;
            bundledPlugins = settings.bundledPlugins;
            instances.default = {
              enable = true;
              plugins = settings.plugins;
              launchd.enable = false;
              systemd.enable = false;
              config = {
                gateway.mode = "remote";
                gateway.remote = {
                  url = "wss://${serverSettings.domain}";
                  transport = "direct";
                  token = tokenPlaceholder;
                };
              };
            };
          };
        };

        # Activation script that replaces the token placeholder in openclaw.json
        # with the actual secret value. Runs after openclawConfigFiles which
        # symlinks the nix-store config into place.
        tokenActivation = { config, pkgs, lib, configPath }: {
          home.activation.openclawInjectToken = lib.hm.dag.entryAfter [ "openclawConfigFiles" ] ''
            _tokenFile="${config.clan.core.vars.generators.openclaw-gateway-token.files.token.path}"
            _configFile="${configPath}"
            if [ -f "$_tokenFile" ] && [ -e "$_configFile" ]; then
              _token="$(${lib.getExe' pkgs.coreutils "cat"} "$_tokenFile")"
              _tmpConfig="$(${lib.getExe' pkgs.coreutils "mktemp"}")"
              ${lib.getExe' pkgs.gnused "sed"} "s|${tokenPlaceholder}|$_token|g" "$_configFile" > "$_tmpConfig"
              ${lib.getExe' pkgs.coreutils "rm"} -f "$_configFile"
              ${lib.getExe' pkgs.coreutils "mv"} "$_tmpConfig" "$_configFile"
            fi
          '';
        };
      in
      {
        nixosModule =
          { config, pkgs, lib, ... }:
          {
            clan.core.vars.generators.openclaw-gateway-token = {
              share = true;
              files.token.secret = true;
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > $out/token
              '';
            };
            home-manager.users.openclaw = lib.recursiveUpdate (openclawHmConfig config)
              (tokenActivation { inherit config pkgs lib; configPath = "/home/openclaw/.openclaw/openclaw.json"; });
          };

        darwinModule =
          { config, pkgs, lib, ... }:
          {
            clan.core.vars.generators.openclaw-gateway-token = {
              share = true;
              files.token = {
                secret = true;
                owner = "chuck";
                group = "staff";
              };
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 32 > $out/token
              '';
            };
            home-manager.users.chuck = lib.recursiveUpdate (openclawHmConfig config)
              (tokenActivation { inherit config pkgs lib; configPath = "$HOME/.openclaw/openclaw.json"; });
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "openclaw";
        capabilities = {
          skills = [ ./skills/SKILL.md ];
          extraPackages = builtins.filter (p: p != null) [
            lobster
            (openclaw-packages.clawhub or null)
            (openclaw-packages.imsg or null)
            (openclaw-packages.gogcli or null)
            (openclaw-packages.remindctl or null)
            (openclaw-packages.blogwatcher or null)
            (openclaw-packages.memo or null)
            (openclaw-packages.defuddle or null)
          ];
        };
      };
    in
    {
      description = "OpenClaw agent tooling (CLI ecosystem, skills, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
