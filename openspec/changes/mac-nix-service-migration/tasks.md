## 1. Miniflux Service — Server Role

- [x] 1.1 Create `services/miniflux/default.nix` with server role: OCI container (miniflux/miniflux), external PostgreSQL at 10.0.0.1:5432, Caddy TLS reverse proxy, borgbackup state dirs, firewall port 443
- [x] 1.2 Add kanidm OIDC support to miniflux server role using `agentplot.oidc.clients.miniflux` interface (optional, matching linkding pattern)
- [x] 1.3 Add clan vars generator `miniflux-db-password` with openssl random hex generation

## 2. Miniflux Service — Client Role

- [x] 2.1 Create `services/miniflux/packages/miniflux-cli/default.nix` — restish wrapper with bundled Miniflux v2 OpenAPI spec and X-Auth-Token header authentication
- [x] 2.2 Create `services/miniflux/skills/SKILL.md` — miniflux agent skill covering feed management, entry reading, category organization, OPML import/export via restish
- [x] 2.3 Add client role to `services/miniflux/default.nix` using mkClientTooling with cli, skills, secret (prompted api-token), and extraClientOptions (base_url)

## 3. Obsidian Service — Client-Only

- [x] 3.1 Create `services/obsidian/default.nix` with client-only role using mkClientTooling — obsidian-cli package, extraClientOptions for vaults (list of strings), vaultBasePath (string), syncthing.enable (bool)
- [x] 3.2 Create `services/obsidian/skills/SKILL.md` — obsidian agent skill covering vault operations, note search, creation, linking, and management via obsidian-cli
- [x] 3.3 Create `services/obsidian/skills/SKILL-para.md` — obsidian-para skill for PARA-based note organization with vault routing rules referencing client vault config
- [x] 3.4 Expose syncthing.enable and vault paths in interface (extraClientOptions) for consumer-level syncthing and backup wiring — no folder declarations in perInstance

## 4. Email Service — Client-Only

- [x] 4.1 Create `services/email/default.nix` with client-only role using mkClientTooling — himalaya CLI package, email-management skill, manifest.name = "email"
- [x] 4.2 Create `services/email/skills/SKILL.md` — email-management skill covering inbox triage, folder management, search, compose, reply, and workflow automation via himalaya

## 4b. Tana Service — Client-Only

- [x] 4b.1 Create `services/tana/default.nix` with client-only role using mkClientTooling — tana-export skill, manifest.name = "tana"
- [x] 4b.2 Create `services/tana/skills/SKILL-tana-export.md` — tana-export skill for Tana knowledge management export

## 5. OpenClaw Service Updates

- [x] 5.1 Update openclaw client role to add capabilities.extraPackages with: clawhub, imsg, gogcli, remindctl, blogwatcher, memo, defuddle (codegraph excluded — it's a general devtool, not openclaw-specific)
- [x] 5.2 Add lobster as global HM package in openclaw client perInstance (home.packages)
- [x] 5.3 Create `services/openclaw/skills/SKILL-workspace.md` — openclaw-workspace skill for project scaffolding, environment setup, workflow orchestration
- [x] 5.4 Wire openclaw-workspace skill into capabilities.skills list

## 6. Paperless Service Updates

- [x] 6.1 Add enex2paperless to paperless client role packages (via capabilities.extraPackages or cli)
- [x] 6.2 Create or port `services/paperless/skills/SKILL-evernote-convert.md` — generic evernote-convert skill: replace all hardcoded Mac-Studio folder paths with environment variables ($ENEX_INBOX_DIR, $ENEX_ARCHIVE_DIR, $ENEX_PROJECT_DIR). Skill should reference configurable directories for inbox, archive, and project rather than absolute paths. See paperless-client-updates spec for details.

## 7. Skills Routing

- [x] 7.1 Place tana-export skill at `services/tana/skills/SKILL-tana-export.md` (tana is its own client-only service)
- [x] 7.2 Verify sheets-cli skill remains in agentplot-kit (no action needed if already there)
- [x] 7.3 Ensure all service-bundled skills are referenced in their respective capabilities.skills lists

## 8. Flake Integration

- [x] 8.1 Add miniflux, obsidian, email, tana to `clan.modules` exports in flake.nix
- [x] 8.2 Add miniflux-cli to `packages.<system>` outputs in flake.nix
- [x] 8.3 Update openclaw and paperless clan.modules definitions if needed for new packages/skills

## 9. Framework Updates (agentplot-kit)

- [x] 9.1 Verify mkClientTooling supports client-only services (no server role) — test with obsidian
- [x] 9.2 Add `extraPackages` support to mkClientTooling for global HM package installs (in scope for this change)
- [x] 9.3 Source obsidian-cli from nixpkgs if available; fall back to app-bundled CLI

## 10. Tests

- [x] 10.1 Add composition test for client-only service (obsidian) — verify HM modules wire correctly without server role
- [x] 10.2 Add composition test for multi-package client (openclaw) — verify extraPackages appear in home.packages
- [x] 10.3 Add composition test for miniflux — verify server + client role composition matches linkding pattern
- [x] 10.4 Run `nix flake check` to validate all new service definitions
