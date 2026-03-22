{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "email";
  manifest.description = "Email management with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Client Role (client-only service) ──────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "email";
        capabilities = {
          skills = [ ./skills/SKILL.md ];
          cli = {
            package = ./packages/email-cli;
            wrapperName = client: client.name;
            envVars = _client: { };
          };
        };
        extraClientOptions = { lib, ... }: {
          default_folder = lib.mkOption {
            type = lib.types.str;
            default = "INBOX";
            description = "Default folder to list messages from";
          };
          notification.enabled = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Enable new mail notifications";
          };
        };
      };
    in
    {
      description = "Email agent tooling (CLI wrappers, skills, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
