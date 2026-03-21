## ADDED Requirements

### Requirement: nix-agent-deck HM module declares skillSources option
The `programs.agent-deck` HM module SHALL expose a `skillSources` option of type `attrsOf path` that declares skill directories to populate in `~/.agent-deck/skills/pool/`.

#### Scenario: Single skill source declared
- **WHEN** `programs.agent-deck.skillSources.linkding = ./skills` is set
- **THEN** HM activation SHALL create a symlink at `~/.agent-deck/skills/pool/linkding` pointing to the skill directory

#### Scenario: Multiple skill sources from different services
- **WHEN** `programs.agent-deck.skillSources` contains entries for "linkding", "ogham", and "qmd"
- **THEN** three symlinks SHALL exist in `~/.agent-deck/skills/pool/`, one for each service

#### Scenario: No skill sources declared
- **WHEN** `programs.agent-deck.skillSources` is empty (default)
- **THEN** no pool symlinks SHALL be created and the existing pool directory SHALL not be affected

### Requirement: mkClientTooling wires agent-deck skill pool
When `capabilities.skills` is provided and `agent-deck.skill.enabled = true` on a client, `mkClientTooling` SHALL set `programs.agent-deck.skillSources.${clientName}` to the skill directory path.

#### Scenario: Service with skill capability enables agent-deck skill
- **WHEN** a service declares `capabilities.skills = ./skills/SKILL.md` and a client enables `agent-deck.skill.enabled = true`
- **THEN** the generated HM module SHALL include `programs.agent-deck.skillSources.${clientName} = skillDir`
