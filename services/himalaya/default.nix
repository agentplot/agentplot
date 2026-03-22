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
                  passwordKey = lib.mkOption {
                    type = lib.types.str;
                    description = "SecretSpec key name for IMAP password (fetched at runtime)";
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
                  passwordKey = lib.mkOption {
                    type = lib.types.str;
                    description = "SecretSpec key name for SMTP password (fetched at runtime)";
                  };
                };
              };
            });
            default = { };
            description = "Email account definitions consumed by himalaya";
          };
        };
      };
    in
    {
      description = "Himalaya email agent tooling (CLI wrappers, skills, account config, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
