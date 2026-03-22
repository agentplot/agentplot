## MODIFIED Requirements

### Requirement: Paperless client role includes enex2paperless package
The paperless client role SHALL include `enex2paperless` in its package set (via `capabilities.extraPackages` or `capabilities.cli`), making the Evernote-to-Paperless conversion tool available when the paperless client role is enabled.

#### Scenario: enex2paperless available in PATH
- **WHEN** the paperless client role is enabled
- **THEN** the `enex2paperless` binary SHALL be available in the user's PATH

### Requirement: Paperless client role bundles generic evernote-convert skill
The paperless client role SHALL include an evernote-convert skill at `services/paperless/skills/SKILL-evernote-convert.md`. The skill SHALL be generic — it MUST NOT contain hardcoded machine-specific folder paths (e.g., Mac-Studio-specific paths). Instead, all directory references SHALL use environment variables or parameterized paths.

#### Scenario: Skill uses parameterized paths
- **WHEN** the evernote-convert skill is loaded
- **THEN** the skill content SHALL reference configurable directories (inbox, archive, project) via environment variables (e.g., `$ENEX_INBOX_DIR`, `$ENEX_ARCHIVE_DIR`) rather than absolute hardcoded paths

#### Scenario: Skill covers full conversion workflow
- **WHEN** the evernote-convert skill is active
- **THEN** the skill SHALL describe: importing .enex files from a configurable inbox directory, running enex2paperless for conversion, logging results via sheets-cli (if available), and moving processed files to a configurable archive directory

#### Scenario: Skill delegated to claude-code
- **WHEN** a paperless client enables `claude-code.skill.enabled = true`
- **THEN** `programs.claude-code.skills` SHALL contain an evernote-convert skill entry with substituted client name

### Requirement: evernote-convert skill is environment-driven
The evernote-convert skill SHALL document the following environment variables for path configuration, with sensible defaults:
- `ENEX_INBOX_DIR` — directory where .enex files are placed for processing
- `ENEX_ARCHIVE_DIR` — directory where processed .enex files are moved after conversion
- `ENEX_PROJECT_DIR` — optional project-specific export directory

These variables allow the same skill to work on any machine without modification.
