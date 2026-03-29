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

            # Declarative gno config — Nix owns this file
            collectionsYaml = lib.concatMapStringsSep "\n" (name:
              let col = settings.collections.${name}; in
              "  - name: \"${name}\"\n    path: \"${col.path}\"\n    pattern: \"${col.pattern}\""
            ) (builtins.attrNames settings.collections);

            gnoConfig = pkgs.writeText "index.yml" (lib.concatStringsSep "\n" ([
              "version: \"1.0\""
              "ftsTokenizer: snowball english"
            ] ++ (if settings.collections == { }
              then [ "collections: []" ]
              else [ "collections:" collectionsYaml ])
            ++ [
              "contexts: []"
              ""
            ]));
          in
          {
            systemd.services.gno = {
              description = "gno document search engine";
              after = [ "network.target" ];
              wantedBy = [ "multi-user.target" ];

              environment = {
                # node-llama-cpp: force CPU backend — prebuilt Vulkan/CUDA
                # binaries aren't compatible with NixOS and local builds
                # fail against the read-only nix store.
                NODE_LLAMA_CPP_GPU = "false";
              };

              serviceConfig = {
                ExecStartPre = "${pkgs.coreutils}/bin/install -m 644 -o gno -g gno ${gnoConfig} /persist/gno/.config/gno/index.yml";
                ExecStart = "${pkgs.llm-agents.gno}/bin/gno serve --port ${toString port}";
                Restart = "on-failure";
                RestartSec = 10;
                User = "gno";
                Group = "gno";
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

            users.users.gno = {
              isSystemUser = true;
              group = "gno";
              home = "/persist/gno";
              createHome = true;
            };
            users.groups.gno = { };

            networking.firewall.allowedTCPPorts = [ 443 ];

            systemd.tmpfiles.rules = [
              "d /persist/gno 0750 gno gno"
              "d /persist/gno/.config/gno 0750 gno gno"
              "Z /persist/gno 0750 gno gno"
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
