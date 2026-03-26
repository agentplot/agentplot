{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "gno";
  manifest.description = "gno document search engine with hybrid RAG, wiki-link graph, and MCP tooling";
  manifest.categories = [ "Application" ];

  # ── Server Role ──────────────────────────────────────────────────────────────

  roles.server = {
    description = "gno instance (systemd + Caddy reverse proxy)";

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

            # Generate a JSON config for gno — paths reference host filesystem directly
            gnoConfigFile = pkgs.writeText "gno-config.json" (builtins.toJSON {
              inherit port;
              dataDir = "/persist/gno";
              collections = lib.mapAttrs (_name: col: {
                inherit (col) path pattern;
              }) settings.collections;
            });
          in
          {
            systemd.services.gno = {
              description = "gno document search engine";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              environment.GNO_CONFIG = toString gnoConfigFile;

              serviceConfig = {
                ExecStartPre = "+${pkgs.bash}/bin/bash -c 'test -d /persist/gno/.config/gno || (cd /persist/gno && HOME=/persist/gno ${pkgs.llm-agents.gno}/bin/gno init --yes)'";
                WorkingDirectory = lib.mkForce "/persist/gno";
                ExecStart = "${pkgs.llm-agents.gno}/bin/gno serve --port ${toString port}";
                Restart = "on-failure";
                RestartSec = 10;
                DynamicUser = true;
                StateDirectory = "gno";
                WorkingDirectory = "/persist/gno";
                ReadWritePaths = [ "/persist/gno" ];
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

            clan.core.state.gno.folders = [ "/persist/gno" ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "gno";
        capabilities = {
          skills = [ ./skills/cli/SKILL.md ];
          cli = {
            package = ./packages/gno-cli;
            wrapperName = client: "gno-${client.name}";
          };
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
      description = "gno agent tooling (CLI, skills, MCP endpoint, HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
