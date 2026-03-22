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
        };
      };
    in
    {
      description = "Paperless-ngx agent tooling (skills, evernote conversion, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
