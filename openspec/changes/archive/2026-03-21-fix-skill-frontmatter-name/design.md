## Context

The linkding clanService client role generates per-client skills by reading `skills/SKILL.md` as a template and applying `builtins.replaceStrings ["linkding-cli"] [cliName]`. This substitutes CLI command references in the body (e.g., `linkding-cli list-bookmarks` becomes `linkding-biz list-bookmarks`), but the frontmatter `name: linkding` is untouched because it doesn't contain the string `linkding-cli`.

The same pattern appears in both the primary `clientSkill` derivation (line 262) and the Phase 2 `agent-skills` transform (line 327).

## Goals / Non-Goals

**Goals:**
- Frontmatter `name:` field matches `cliName` for every client instance
- Fix applies to both the primary `clientSkill` and the Phase 2 `agent-skills` transform
- No changes to the SKILL.md template file itself

**Non-Goals:**
- Rewriting the skill as a structured attrset (over-engineering for this fix)
- Modifying other frontmatter fields (description, secrets, env) — these are shared across instances
- Introducing a general-purpose frontmatter rewriting mechanism

## Decisions

**Decision: Add a second replaceStrings pair for the frontmatter name field**

Add `"name: linkding"` → `"name: ${cliName}"` to the existing `replaceStrings` call, making it substitute both CLI references in the body and the name field in the frontmatter in a single pass.

*Alternatives considered:*
- *Structured attrset with metadata overrides*: Would require the skill installer to reconstruct SKILL.md from parts. More correct long-term but unnecessary complexity for a single-field fix.
- *Post-processing with a separate replaceStrings call*: Works but is redundant — the existing call can simply accept additional pairs.
- *Changing the template to use `linkding-cli` as the name*: Would make the template less readable and couples the name field to the CLI naming convention.

## Risks / Trade-offs

- **[Risk] The string `"name: linkding"` could appear elsewhere in the skill body** → Mitigated: the SKILL.md template only contains this exact string in the frontmatter line. The body uses `# Linkding API Skill` (different casing/format) and CLI command references use `linkding-cli`.
- **[Risk] Future frontmatter fields may need similar substitution** → Acceptable: if more fields need per-client values, a structured approach can be introduced then. YAGNI for now.
