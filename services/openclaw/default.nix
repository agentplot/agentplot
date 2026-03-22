{ mkClientTooling, openclaw-packages ? { }, lobster ? null, ... }:
{
  _class = "clan.service";
  manifest.name = "openclaw";
  manifest.description = "OpenClaw agent ecosystem with full CLI tooling";
  manifest.categories = [ "Application" ];

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
