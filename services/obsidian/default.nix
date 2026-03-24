{ mkClientTooling, obsidian-cli ? null, ... }:
{
  _class = "clan.service";
  manifest.name = "obsidian";
  manifest.description = "Obsidian knowledge management with agent tooling";
  manifest.categories = [ "Application" ];

  # ── Client Role (client-only service) ──────────────────────────────────────

  roles.client =
    let
      tooling = mkClientTooling {
        serviceName = "obsidian";
        capabilities = {
          skills = [
            ./skills/SKILL.md
            ./skills/para
          ];
        } // (if obsidian-cli != null then {
          cli = {
            package = obsidian-cli;
            wrapperName = client: client.name;
            envVars = client: {
              OBSIDIAN_VAULTS = builtins.concatStringsSep ":" client.vaults;
              OBSIDIAN_VAULT_BASE_PATH = client.vaultBasePath;
            };
          };
        } else { });
        extraClientOptions = { lib, ... }: {
          vaults = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "List of Obsidian vault names for this client";
          };
          vaultBasePath = lib.mkOption {
            type = lib.types.str;
            default = "~/Documents/Obsidian";
            description = "Base directory containing Obsidian vaults";
          };
        };
      };
    in
    {
      description = "Obsidian agent tooling (CLI wrappers, skills, downstream HM delegation)";
      inherit (tooling) interface perInstance;
    };
}
