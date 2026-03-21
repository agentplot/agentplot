## Context

Agentplot has 5 services with client roles (linkding, ogham-mcp, subcog, gno, qmd). Each independently implements delegation to downstream HM modules (claude-code, agent-skills, agent-deck, openclaw). The delegation code is structurally identical: define enable flags → build MCP/skill config → wire into `programs.X` via `agentplot.hmModules`. Linkding has the most complete implementation (6 targets including claude-tools); the 4 new services have incomplete subsets (2-3 targets each) with inconsistent patterns (some use multi-client, some don't).

The agentplot-kit repo (`../agentplot-kit`) is the framework layer. It currently provides `modules/home-manager/claude-code.nix` (the claude-code HM module) and the clanService design docs, but no lib functions for service authors. The nix-agent-deck repo (`../nix-agent-deck`) provides the agent-deck HM module with `mcps` and `tools` options but no `skills` option.

Five downstream HM modules exist:
1. `programs.claude-code` (agentplot-kit) — skills (attrsOf (either lines path)), mcpServers (attrsOf jsonFormat.type), profiles (attrsOf profileModule)
2. `programs.agent-skills` (agent-skills-nix) — sources (attrsOf sourceType), skills.explicit (attrsOf with from/path/rename/packages/transform), targets (attrsOf with enable/dest)
3. `programs.agent-deck` (nix-agent-deck) — mcps (attrsOf (attrsOf anything)), tools (attrsOf (attrsOf anything))
4. `programs.openclaw` (nix-openclaw) — skills (listOf submodule with name/mode/body/source/description/homepage)
5. `programs.claude-tools` (claude-plugins-nix) — being dropped, overlaps with claude-code + agent-skills

Agent-deck also has a runtime skills system: `~/.agent-deck/skills/pool/` directory, `sources.toml`, per-project `skills.toml` + symlinks. No HM option exists for declarative pool population.

## Goals / Non-Goals

**Goals:**
- Create `mkClientTooling` in agentplot-kit that generates a complete client role from a capabilities declaration
- Implement a capabilities → targets model where adding new agent platforms requires zero service changes
- Standardize all 5 services on multi-client pattern with consistent enable flags
- Add agent-deck skill pool as a declarative target
- Add `programs.agent-deck.skillSources` to nix-agent-deck HM module
- Drop claude-tools target and claude-plugins-nix dependency
- Add user-focused README.md to each service directory

**Non-Goals:**
- Modifying any downstream HM module except nix-agent-deck (adding skillSources)
- Changing server roles — this is client-side only
- Changing Clan inventory schema — the `clients = attrsOf` shape is already how linkding works
- Adding new services — this refactors existing ones

## Decisions

### 1. `mkClientTooling` Function Signature and Location

**Decision**: `agentplot-kit.lib.mkClientTooling` is a function that takes a capabilities attrset and returns `{ interface; perInstance; }` — the complete client role. Lives at `lib/mkClientTooling.nix` in agentplot-kit, exposed via `lib` flake output.

```nix
agentplot-kit.lib.mkClientTooling {
  serviceName = "qmd";
  capabilities = {
    skills = [                         # list of paths, or null
      ./skills/SKILL.md
    ];                                 # multiple skills per service supported
    mcp = {                            # attrset or null
      type = "http";                   # "http" | "sse"
      urlTemplate = client: "https://${client.domain}/mcp";
    };
    cli = {                            # attrset or null
      package = ./packages/cli;
      wrapperName = client: client.name;
      envVars = client: {
        API_TOKEN_FILE = client.tokenPath;
        BASE_URL = client.base_url;
      };
    };
    secret = {                         # attrset or null
      name = "api-token";
      mode = "prompted";               # "prompted" | "generated"
      description = client: "API token for ${client.name}";
    };
  };
  extraClientOptions = { lib, ... }: {
    domain = lib.mkOption { type = lib.types.str; };
    default_tags = lib.mkOption { type = lib.types.listOf lib.types.str; default = []; };
  };
}
```

**Rationale**: Maximal ownership — the function generates everything including the interface options, perInstance, vars generators, HM modules, and agentplot.hmModules wiring. Services only declare what makes them unique. The `extraClientOptions` escape hatch handles service-specific fields (domain, collections, namespace, etc.).

**Alternative considered**: Minimal helper (just generates the submodule type + a wiring function). Rejected — too much boilerplate left in each service, defeating the extraction purpose.

### 2. Capabilities → Targets Model

**Decision**: Targets are a registry inside `mkClientTooling`. Each target declares which capabilities it requires and how to wire them. Enable flags are only generated for targets whose required capabilities are present.

```
Target Registry:
  claude-code-skill:   requires [skills]       → programs.claude-code.skills.X (per skill)
  claude-code-mcp:     requires [mcp]          → programs.claude-code.mcpServers.X
  claude-code-profile: requires [mcp]          → programs.claude-code.profiles.*.mcpServers.X
  agent-skills:        requires [skills]       → programs.agent-skills.{sources,explicit,targets} (per skill)
  agent-deck-mcp:      requires [mcp]          → programs.agent-deck.mcps.X
  agent-deck-skill:    requires [skills]       → programs.agent-deck.skillSources (per skill dir)
  openclaw-skill:      requires [skills]       → programs.openclaw.skills list (per skill)
```

When `capabilities.skills = null` or `[]`, none of the skill-consuming targets appear in the interface. When `capabilities.mcp = null`, none of the MCP targets appear. Services may declare multiple skills (e.g., a service with both a management skill and a query skill); each skill gets its own enable flag and is distributed independently to downstream targets.

**Rationale**: This is the extensibility point. Adding a new agent platform (e.g., Cursor, Aider) means adding one target definition with its requirements and wiring function. Every service that declared matching capabilities automatically gets the new target.

### 3. Multi-Client Pattern for All Services

**Decision**: All services use `options.clients = attrsOf clientSubmodule`. The generated interface always has this shape. Services that currently have flat options (gno, qmd, subcog) are refactored to use `clients`.

For memory servers, multi-client maps to namespace/collection isolation:
```nix
clients.personal = { name = "subcog"; namespace = "personal"; ... };
clients.work = { name = "subcog-work"; namespace = "work"; ... };
```

For document RAG servers, multi-client maps to different collection scopes:
```nix
clients.docs = { name = "qmd-docs"; domain = "qmd.swancloud.net"; ... };
clients.code = { name = "qmd-code"; domain = "qmd.swancloud.net"; ... };
```

**Rationale**: Consistency across all services. Multi-client is how linkding already works and it's the natural model for partitioned access. Even if someone only configures one client, the `clients.default = { ... }` shape is simple enough.

### 4. Agent-Deck Skill Pool via nix-agent-deck HM Module

**Decision**: Add `programs.agent-deck.skillSources` option to nix-agent-deck:

```nix
programs.agent-deck.skillSources = lib.mkOption {
  type = lib.types.attrsOf lib.types.path;
  default = {};
  description = "Skill directories to symlink into ~/.agent-deck/skills/pool/";
};
```

The HM module generates `home.file.".agent-deck/skills/pool/${name}".source = path` for each entry. Agent-deck's TUI then discovers these skills in the pool and allows per-project attachment.

`mkClientTooling` wires: `programs.agent-deck.skillSources.${skillName} = skillDir` for each skill when `agent-deck.skill.enabled = true`. Note: agent-deck requires each pool entry to be a **directory** containing a `SKILL.md` file, not the file itself. When `capabilities.skills` lists paths like `./skills/SKILL.md`, the symlink target must be the parent directory (`./skills/`).

**Rationale**: Declarative management of the skill pool is cleaner than raw `home.file` and makes the capability visible in the nix-agent-deck option documentation. The nix-agent-deck repo is in this workspace, so the change is straightforward.

### 5. Secret Management Standardization

**Decision**: `capabilities.secret` declares the secret shape. `mkClientTooling` generates per-client clan vars generators with the naming convention `agentplot-${serviceName}-${clientName}-${secretName}`.

Two modes:
- `mode = "prompted"`: Uses `prompts` with `type = "hidden"` for manual token entry
- `mode = "generated"`: Uses `runtimeInputs = [ pkgs.openssl ]` with auto-generation script

The secret path is available to capabilities via `client.tokenPath` (resolved in the perInstance closure from NixOS config).

**Rationale**: Every service needs a secret. Standardizing the naming and generation pattern eliminates per-service boilerplate and ensures consistent secret file ownership (`agentplot.user` / staff group on darwin).

### 6. Drop claude-tools Target

**Decision**: Remove `programs.claude-tools` delegation from all services. Remove `claude-plugins-nix` from agentplot's flake inputs.

**Rationale**: `claude-tools` (claude-plugins-nix) wraps Kamalnrf/claude-plugins for marketplace skill installation. This overlaps entirely with `programs.claude-code.skills` (direct skill writing) and `programs.agent-skills` (multi-platform distribution). The upstream is low-activity (last update Jan 2026). Removing it simplifies the target registry and removes a flake input.

### 7. Multiple Skills Per Service

**Decision**: `capabilities.skills` is a list of skill paths (or null). Each skill is identified by its directory name relative to the service. When a service has multiple skills, each gets independently distributed to all skill-consuming targets.

```nix
capabilities.skills = [
  ./skills/manage/SKILL.md   # management operations
  ./skills/query/SKILL.md    # read-only query skill
];
```

The skill directory structure determines the skill name. For agent-deck pool, each skill directory is symlinked independently. For claude-code/agent-skills/openclaw, each skill gets its own entry.

**Rationale**: Some services may want to expose different capabilities to different contexts — e.g., a full management skill for admin agents and a read-only query skill for general-purpose agents. The downstream targets (claude-code, agent-skills, agent-deck, openclaw) all support multiple entries natively.

### 8. Service README Pattern

**Decision**: Each `services/<name>/` directory gets a `README.md` with:
- What the service does (one paragraph)
- Upstream project link
- Roles overview (server: what it deploys; client: what it enables)
- Client capabilities (which agent targets are available)
- Example inventory configuration
- Key options reference

**Rationale**: Services should be self-documenting for users browsing the repository. The README is user-focused (not implementation notes), explaining how to configure the service in Clan inventory.

## Risks / Trade-offs

**[Risk] Breaking existing inventory configurations** → Mitigation: The `clients = attrsOf` shape and enable flag names stay the same as linkding's current pattern. Gno/qmd/subcog currently have flat options that become `clients.X.option` — this is a breaking change for those 4 services. Since they haven't been deployed yet (just committed today), this is acceptable.

**[Risk] `mkClientTooling` becomes too rigid** → Mitigation: The `extraClientOptions` escape hatch lets services add any option. The returned perInstance can be extended via `lib.mkMerge` if a service needs custom NixOS config beyond the standard delegation.

**[Risk] nix-agent-deck upstream may not accept the skillSources PR** → Mitigation: We maintain the nix-agent-deck fork. If upstream doesn't merge, we keep it in our fork. The feature is additive and non-breaking.

**[Trade-off] agentplot now depends on agentplot-kit for client role generation** → This is the intended architecture. agentplot-kit is the framework, agentplot is a consumer. The dependency already exists for the claude-code HM module.

**[Trade-off] More abstraction = harder to debug individual services** → Mitigated by clear error messages in `mkClientTooling` when capabilities are misconfigured, and by keeping the generated code structurally identical to the current hand-rolled version.
