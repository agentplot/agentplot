## 1. Miniflux Service — Server Role

- [x] 1.1 Create `services/miniflux/default.nix` with server role: native NixOS services.miniflux, external PostgreSQL at 10.0.0.1:5432, Caddy TLS reverse proxy, firewall port 443
- [x] 1.2 Add kanidm OIDC support to miniflux server role using `agentplot.oidc.clients.miniflux` interface (optional, matching linkding pattern)
- [x] 1.3 Add clan vars generator `miniflux-db-password` with openssl random hex generation

## 2. Miniflux Service — Client Role

- [x] 2.1 Create `services/miniflux/packages/miniflux-cli/default.nix` — restish wrapper with bundled Miniflux v2 OpenAPI spec and X-Auth-Token header authentication
- [x] 2.2 Create `services/miniflux/skills/SKILL.md` — miniflux agent skill covering feed management, entry reading, category organization, OPML import/export via restish
- [x] 2.3 Add client role to `services/miniflux/default.nix` using mkClientTooling with cli, skills, secret (prompted api-token), and extraClientOptions (base_url)

## 3. Obsidian Service — Client-Only

- [x] 3.1 Create `services/obsidian/default.nix` with client-only role using mkClientTooling — obsidian-cli package (optional, nixpkgs fallback), extraClientOptions for vaults (list of strings), vaultBasePath (string), syncthing.enable (bool)
- [x] 3.2 Create `services/obsidian/skills/SKILL.md` — obsidian agent skill covering vault operations, note search, creation, linking, and management via obsidian-cli
- [x] 3.3 Create `services/obsidian/skills/para/SKILL.md` — obsidian-para skill for PARA-based note organization with vault routing rules referencing client vault config
- [x] 3.4 Expose syncthing.enable and vault paths in interface (extraClientOptions) for consumer-level syncthing and backup wiring — no folder declarations in perInstance

## 4. Himalaya Service — Client-Only

- [ ] 4.1 Rename `services/email/` to `services/himalaya/`, update manifest.name to "himalaya"
- [ ] 4.2 Port email account interface from `__mac-nix/modules/home/loomos/email-accounts.nix` into extraClientOptions — multi-account IMAP/SMTP config (email, displayName, default, backend host/port/login/passwordKey, smtp host/port/login/encryption/passwordKey)
- [ ] 4.3 Port himalaya config generation from `__mac-nix/modules/home/loomos/himalaya.nix` into perInstance HM module — generate ~/.config/himalaya/config.toml with TOML account blocks, secretspec integration, himalaya-get-secret wrapper
- [ ] 4.4 Update `services/himalaya/skills/SKILL.md` — email-management skill referencing himalaya CLI (not generic "email")

## 4b. Tana Service — Client-Only

- [x] 4b.1 Create `services/tana/default.nix` with client-only role using mkClientTooling — tana-export skill, manifest.name = "tana"
- [x] 4b.2 Create `services/tana/skills/SKILL.md` — tana-export skill for Tana knowledge management export

## 5. OpenClaw Service — Server + Node + Client

- [ ] 5.1 Port openclaw server role from `swancloud/clanServices/openclaw/default.nix` into `services/openclaw/default.nix` — gateway, channels (telegram/discord/bluebubbles), agents, providers, plugins, bindings, clan vars generators, openclaw system user, Caddy TLS
- [ ] 5.2 Port openclaw node role from swancloud — remote gateway connection with NixOS and Darwin modules
- [x] 5.3 Add client role using mkClientTooling with capabilities.extraPackages (lobster, clawhub, imsg, gogcli, remindctl, blogwatcher, memo, defuddle) and capabilities.skills (workspace skill)
- [x] 5.4 Create `services/openclaw/skills/SKILL.md` — openclaw-workspace skill for project scaffolding, environment setup, workflow orchestration

## 6. Paperless Service — Server + Client

- [ ] 6.1 Port paperless server role from `swancloud/clanServices/paperless/default.nix` into `services/paperless/default.nix` — NixOS services.paperless, clan vars generators (db-password, admin-password, secret-key), OIDC, Caddy reverse proxy, borgbackup state
- [ ] 6.2 Replace fabricated paperless-cli with original from agentplot-kit (commit 4e178ad^) — restish wrapper fetching live OpenAPI from `$PAPERLESS_BASE_URL/api/schema/?format=json`
- [ ] 6.3 Replace fabricated paperless skill with original from agentplot-kit (commit 4e178ad^) — full API surface covering documents, mail rules, tags, correspondents, document types, storage paths, workflows
- [x] 6.4 Add enex2paperless to paperless client role packages (via capabilities.extraPackages)
- [x] 6.5 Create `services/paperless/skills/evernote-convert/SKILL.md` — generic evernote-convert skill with environment variables ($ENEX_INBOX_DIR, $ENEX_ARCHIVE_DIR, $ENEX_PROJECT_DIR)

## 7. Skills Routing

- [x] 7.1 Place tana-export skill at `services/tana/skills/SKILL.md` (tana is its own client-only service)
- [x] 7.2 Verify sheets-cli skill remains in agentplot-kit (no action needed if already there)
- [ ] 7.3 Ensure all service-bundled skills are referenced in their respective capabilities.skills lists

## 8. Flake Integration

- [ ] 8.1 Add miniflux, obsidian, himalaya, tana, openclaw, paperless to `clan.modules` exports in flake.nix
- [x] 8.2 Add miniflux-cli and paperless-cli to `packages.<system>` outputs in flake.nix
- [ ] 8.3 Wire openclaw and paperless server roles with correct flake input dependencies (nix-openclaw, microvm if needed)

## 9. Framework Updates (agentplot-kit)

- [x] 9.1 Verify mkClientTooling supports client-only services (no server role) — test with obsidian
- [x] 9.2 Add `extraPackages` support to mkClientTooling for global HM package installs
- [x] 9.3 Source obsidian-cli from nixpkgs if available; fall back to app-bundled CLI

## 10. Tests

- [x] 10.1 Add composition test for client-only service (obsidian) — verify HM modules wire correctly without server role
- [x] 10.2 Add composition test for multi-package client (openclaw) — verify extraPackages appear in home.packages
- [x] 10.3 Add composition test for miniflux — verify server + client role composition matches linkding pattern
- [ ] 10.4 Run `nix flake check` to validate all new service definitions (re-run after all changes)
