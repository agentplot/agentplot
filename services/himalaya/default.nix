{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "himalaya";
  manifest.description = "Himalaya email client with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Client Role (client-only service) ──────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "himalaya";
        capabilities = {
          skills = [ ./skills/SKILL.md ];
          cli = {
            package = ./packages/himalaya-cli;
            wrapperName = client: client.name;
            envVars = _client: { };
          };
        };
        extraClientOptions = { lib, ... }: {
          accounts = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {
              options = {
                email = lib.mkOption {
                  type = lib.types.str;
                  description = "Email address for this account";
                };
                displayName = lib.mkOption {
                  type = lib.types.str;
                  description = "Display name for outgoing mail";
                };
                default = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                  description = "Whether this is the default account";
                };
                backend = {
                  type = lib.mkOption {
                    type = lib.types.str;
                    default = "imap";
                    description = "Backend type (imap, maildir, etc.)";
                  };
                  host = lib.mkOption {
                    type = lib.types.str;
                    description = "IMAP server hostname";
                  };
                  port = lib.mkOption {
                    type = lib.types.port;
                    description = "IMAP server port";
                  };
                  login = lib.mkOption {
                    type = lib.types.str;
                    description = "IMAP login username";
                  };
                  passwordCmd = lib.mkOption {
                    type = lib.types.str;
                    description = "Shell command that outputs the IMAP password (used as backend.auth.cmd in himalaya config)";
                  };
                };
                smtp = {
                  host = lib.mkOption {
                    type = lib.types.str;
                    description = "SMTP server hostname";
                  };
                  port = lib.mkOption {
                    type = lib.types.port;
                    description = "SMTP server port";
                  };
                  login = lib.mkOption {
                    type = lib.types.str;
                    description = "SMTP login username";
                  };
                  encryption = lib.mkOption {
                    type = lib.types.nullOr (lib.types.enum [ "tls" "start-tls" "none" ]);
                    default = null;
                    description = "SMTP encryption type (null omits the setting)";
                  };
                  passwordCmd = lib.mkOption {
                    type = lib.types.str;
                    description = "Shell command that outputs the SMTP password (used as message.send.backend.auth.cmd in himalaya config)";
                  };
                };
              };
            });
            default = { };
            description = "Email account definitions consumed by himalaya";
          };
        };
      };

      # Generate himalaya TOML config from structured account definitions
      mkAccountToml = lib: name: acct:
        let
          lines = [
            "[accounts.${name}]"
          ]
          ++ lib.optional acct.default "default = true"
          ++ [
            ''email = "${acct.email}"''
            ''display-name = "${acct.displayName}"''
            ""
            ''backend.type = "${acct.backend.type}"''
            ''backend.host = "${acct.backend.host}"''
            "backend.port = ${toString acct.backend.port}"
            ''backend.login = "${acct.backend.login}"''
            ''backend.auth.type = "password"''
            ''backend.auth.cmd = "${acct.backend.passwordCmd}"''
            ""
            ''message.send.backend.type = "smtp"''
            ''message.send.backend.host = "${acct.smtp.host}"''
            "message.send.backend.port = ${toString acct.smtp.port}"
            ''message.send.backend.login = "${acct.smtp.login}"''
            ''message.send.backend.auth.type = "password"''
            ''message.send.backend.auth.cmd = "${acct.smtp.passwordCmd}"''
          ]
          ++ lib.optional (acct.smtp.encryption != null)
            ''message.send.backend.encryption = "${acct.smtp.encryption}"'';
        in
        builtins.concatStringsSep "\n" lines;
    in
    {
      description = "Himalaya email agent tooling (CLI wrappers, skills, account config, downstream HM delegation)";
      inherit (tooling) interface;

      # Wrap tooling's perInstance to add TOML config generation
      perInstance = { settings, ... }:
        let
          base = tooling.perInstance { inherit settings; };

          configModule = { lib, ... }: {
            agentplot.hmModules = lib.mapAttrs' (clientName: clientSettings:
              lib.nameValuePair "himalaya-config-${clientName}" ({ lib, ... }:
                let
                  accounts = clientSettings.accounts or { };
                  tomlContent = builtins.concatStringsSep "\n\n" (
                    lib.mapAttrsToList (mkAccountToml lib) accounts
                  );
                in
                lib.mkIf (accounts != { }) {
                  home.file.".config/himalaya/config.toml".text = tomlContent + "\n";
                }
              )
            ) settings.clients;
          };
        in
        {
          nixosModule = { imports = [ base.nixosModule configModule ]; };
          darwinModule = { imports = [ base.darwinModule configModule ]; };
        };
    };
}
