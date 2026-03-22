{ mkClientTooling, enex2paperless ? null, ... }:
{
  _class = "clan.service";
  manifest.name = "paperless";
  manifest.description = "Paperless-ngx document management with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Client Role ──────────────────────────────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "paperless";
        capabilities = {
          skills = [
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
