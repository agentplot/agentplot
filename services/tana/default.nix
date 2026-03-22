{ mkClientTooling, ... }:
{
  _class = "clan.service";
  manifest.name = "tana";
  manifest.description = "Tana knowledge management with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Client Role (client-only service) ──────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "tana";
        capabilities = {
          skills = [ ./skills/SKILL.md ];
        };
      };
    in
    {
      description = "Tana agent tooling (skills, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
