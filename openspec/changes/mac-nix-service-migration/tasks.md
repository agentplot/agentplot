## 1. Miniflux Service — Server Role

- [ ] 1.1 Create `services/miniflux/default.nix` with server role: OCI container (miniflux/miniflux), external PostgreSQL at 10.0.0.1:5432, Caddy TLS reverse proxy, borgbackup state dirs, firewall port 443
- [ ] 1.2 Add kanidm OIDC support to miniflux server role using `agentplot.oidc.clients.miniflux` interface (optional, matching linkding pattern)
- [ ] 1.3 Add clan vars generator `miniflux-db-password` with openssl random hex generation

## 2. Miniflux Service — Client Role

- [ ] 2.1 Create `services/miniflux/packages/miniflux-cli/default.nix` — restish wrapper with bundled Miniflux v2 OpenAPI spec and X-Auth-Token header authentication
- [ ] 2.2 Create `services/miniflux/skills/SKILL.md` — miniflux agent skill covering feed management, entry reading, category organization, OPML import/export via restish
- [ ] 2.3 Add client role to `services/miniflux/default.nix` using mkClientTooling with cli, skills, secret (prompted api-token), and extraClientOptions (base_url)

## 3. Obsidian Service — Client-Only

- [ ] 3.1 Create `services/obsidian/default.nix` with client-only role using mkClientTooling — obsidian-cli package, extraClientOptions for vaults (list of strings), vaultBasePath (string), syncthing.enable (bool)
- [ ] 3.2 Create `services/obsidian/skills/SKILL.md` — obsidian agent skill covering vault operations, note search, creation, linking, and management via obsidian-cli
- [ ] 3.3 Create `services/obsidian/skills/SKILL-para.md` — obsidian-para skill for PARA-based note organization with vault routing rules referencing client vault config
- [ ] 3.4 Wire syncthing folder declarations in perInstance HM module when syncthing.enable is true

## 4. Email Service — Client-Only

- [ ] 4.1 Create `services/email/default.nix` with client-only role using mkClientTooling — himalaya CLI package, email-management skill, manifest.name = "email"
- [ ] 4.2 Create `services/email/skills/SKILL.md` — email-management skill covering inbox triage, folder management, search, compose, reply, and workflow automation via himalaya

## 5. OpenClaw Service Updates

- [ ] 5.1 Update openclaw client role to add capabilities.extraPackages with: clawhub, ppls, imsg, gogcli, remindctl, blogwatcher, memo, defuddle, codegraph
- [ ] 5.2 Add lobster as global HM package in openclaw client perInstance (home.packages)
- [ ] 5.3 Create `services/openclaw/skills/SKILL-workspace.md` — openclaw-workspace skill for project scaffolding, environment setup, workflow orchestration
- [ ] 5.4 Wire openclaw-workspace skill into capabilities.skills list

## 6. Paperless Service Updates

- [ ] 6.1 Add enex2paperless to paperless client role packages (via capabilities.extraPackages or cli)
- [ ] 6.2 Create or port `services/paperless/skills/SKILL-evernote-convert.md` — generic evernote-convert skill (remove Mac-Studio-specific folder references)

## 7. Skills Routing

- [ ] 7.1 Move tana-export skill to `services/obsidian/skills/SKILL-tana-export.md` (knowledge-management adjacent)
- [ ] 7.2 Verify sheets-cli skill remains in agentplot-kit (no action needed if already there)
- [ ] 7.3 Ensure all service-bundled skills are referenced in their respective capabilities.skills lists

## 8. Flake Integration

- [ ] 8.1 Add miniflux, obsidian, email to `clan.modules` exports in flake.nix
- [ ] 8.2 Add miniflux-cli to `packages.<system>` outputs in flake.nix
- [ ] 8.3 Update openclaw and paperless clan.modules definitions if needed for new packages/skills

## 9. Framework Dependencies (agentplot-kit)

- [ ] 9.1 Verify mkClientTooling supports client-only services (no server role) — test with obsidian
- [ ] 9.2 Check if mkClientTooling supports extraPackages; if not, file agentplot-kit change for global HM package support
- [ ] 9.3 Determine obsidian-cli package source (llm-agents.nix overlay or standalone derivation)

## 10. Tests

- [ ] 10.1 Add composition test for client-only service (obsidian) — verify HM modules wire correctly without server role
- [ ] 10.2 Add composition test for multi-package client (openclaw) — verify extraPackages appear in home.packages
- [ ] 10.3 Add composition test for miniflux — verify server + client role composition matches linkding pattern
- [ ] 10.4 Run `nix flake check` to validate all new service definitions
