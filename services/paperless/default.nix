{ mkClientTooling, enex2paperless ? null, ... }:
{
  _class = "clan.service";
  manifest.name = "paperless";
  manifest.description = "Paperless-ngx document management system with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Server Role (ported from swancloud/clanServices/paperless) ─────────────

  roles.server = {
    description = "Paperless-ngx instance with PostgreSQL, Caddy, OIDC, borgbackup";

    interface =
      { lib, ... }:
      {
        options = {
          domain = lib.mkOption {
            type = lib.types.str;
            description = "FQDN for the paperless instance";
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
            dbPasswordPath = config.clan.core.vars.generators."paperless-db-password".files."password".path;
            adminPasswordPath = config.clan.core.vars.generators."paperless-admin-password".files."password".path;
            secretKeyPath = config.clan.core.vars.generators."paperless-secret-key".files."key".path;
            tlsConfig = config.caddy-cloudflare.tls;
          in
          {
            # --- Clan vars generators ---
            clan.core.vars.generators."paperless-db-password" = {
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

            clan.core.vars.generators."paperless-admin-password" = {
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

            clan.core.vars.generators."paperless-secret-key" = {
              share = true;
              files."key" = {
                secret = true;
                mode = "0440";
              };
              runtimeInputs = [ pkgs.openssl ];
              script = ''
                openssl rand -hex 50 > $out/key
              '';
            };

            # --- Paperless NixOS module ---
            services.paperless = {
              enable = true;
              dataDir = "/persist/paperless";
              configureTika = true;
              passwordFile = adminPasswordPath;
              settings = {
                PAPERLESS_DBHOST = "10.0.0.1";
                PAPERLESS_DBPORT = 5432;
                PAPERLESS_DBNAME = "paperless";
                PAPERLESS_DBUSER = "paperless";
                PAPERLESS_TIME_ZONE = "America/New_York";
                PAPERLESS_OCR_LANGUAGE = "eng";
                PAPERLESS_DATE_ORDER = "MDY";
                PAPERLESS_URL = "https://${settings.domain}";
                PAPERLESS_CSRF_TRUSTED_ORIGINS = "https://${settings.domain}";
                PAPERLESS_CONSUMER_POLLING = 30;
              } // lib.optionalAttrs oidcEnabled {
                PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
                PAPERLESS_SOCIALACCOUNT_SIGNUP = "false";
              };
            };

            # Oneshot service assembles environment file with secrets before paperless starts
            systemd.services.paperless-env = {
              description = "Generate Paperless environment with secrets";
              before = [
                "paperless-scheduler.service"
                "paperless-task-queue.service"
                "paperless-consumer.service"
                "paperless-web.service"
              ];
              requiredBy = [
                "paperless-scheduler.service"
              ];
              serviceConfig = {
                Type = "oneshot";
                RemainAfterExit = true;
              };
              script =
                ''
                  DB_PASSWORD=$(cat ${dbPasswordPath})
                  SECRET_KEY=$(cat ${secretKeyPath})
                  printf 'PAPERLESS_DBPASS=%s\nPAPERLESS_SECRET_KEY=%s\n' "$DB_PASSWORD" "$SECRET_KEY" > /run/paperless.env
                ''
                + lib.optionalString oidcEnabled ''
                  SECRET=$(cat ${secretPath})
                  cat >> /run/paperless.env <<EOF
                  PAPERLESS_SOCIALACCOUNT_PROVIDERS={"openid_connect":{"OAUTH_PKCE_ENABLED":true,"APPS":[{"provider_id":"kanidm","name":"Kanidm","client_id":"${clientId}","secret":"$SECRET","settings":{"server_url":"https://${issuerDomain}/oauth2/openid/${clientId}"}}]}}
                  EOF
                '';
            };

            systemd.services.paperless-scheduler.serviceConfig.EnvironmentFile = "/run/paperless.env";
            systemd.services.paperless-task-queue.serviceConfig.EnvironmentFile = "/run/paperless.env";
            systemd.services.paperless-consumer.serviceConfig.EnvironmentFile = "/run/paperless.env";
            systemd.services.paperless-web.serviceConfig.EnvironmentFile = "/run/paperless.env";

            # --- Caddy reverse proxy ---
            services.caddy = {
              enable = true;
              dataDir = "/persist/caddy";
              virtualHosts."${settings.domain}" = {
                extraConfig = ''
                  ${tlsConfig}
                  reverse_proxy http://localhost:28981
                '';
              };
            };

            networking.firewall.allowedTCPPorts = [ 443 ];

            systemd.tmpfiles.rules = [ "d /persist/caddy 0700 caddy caddy" ];

            # --- Borgbackup state ---
            clan.core.state.paperless.folders = [ "/persist/paperless" ];
          };
      };
  };

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "paperless";
        capabilities = {
          skills = [
            ./skills/SKILL.md
            ./skills/evernote-convert
          ];
          extraPackages = builtins.filter (p: p != null) [
            enex2paperless
          ];
          cli = {
            package = ./packages/paperless-cli;
            wrapperName = client: client.name;
            envVars = client: {
              PAPERLESS_API_TOKEN = "$(cat ${client.tokenPath})";
              PAPERLESS_BASE_URL = client.base_url;
            };
          };
          secret = {
            name = "api-token";
            mode = "prompted";
            description = client: "API token for Paperless client '${client.name}'";
          };
        };
        extraClientOptions = { lib, ... }: {
          base_url = lib.mkOption {
            type = lib.types.str;
            description = "Base URL of the Paperless-ngx instance";
          };
        };
      };
    in
    {
      description = "Paperless-ngx agent tooling (CLI wrappers, skills, evernote conversion, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
