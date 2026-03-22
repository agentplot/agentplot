---
name: obsidian
description: Manage Obsidian vaults, notes, search, creation, linking, and vault operations via obsidian-cli. Use when working with Obsidian notes, searching vaults, creating or editing notes, managing tags, or navigating note links.
---

# Obsidian Vault Management Skill

Manage Obsidian vaults and notes using `obsidian-cli`.

## Environment

The following environment variables configure vault access:
- `OBSIDIAN_VAULTS` — colon-separated list of vault names
- `OBSIDIAN_VAULT_BASE_PATH` — base directory containing vaults (default: `~/Documents/Obsidian`)

## Common Operations

### Vault Operations

```bash
# List configured vaults
obsidian-cli vault list

# Open a vault
obsidian-cli vault open "Business"

# Get vault info
obsidian-cli vault info "Personal"
```

### Note Search

```bash
# Search notes by content across all vaults
obsidian-cli search "meeting notes"

# Search within a specific vault
obsidian-cli search "project plan" --vault "Business"

# Search by tag
obsidian-cli search --tag "todo"

# Search by path pattern
obsidian-cli search --path "Projects/**"

# List recent notes
obsidian-cli list --sort modified --limit 20
```

### Note Creation

```bash
# Create a new note
obsidian-cli create "Meeting Notes/2024-01-15" --vault "Business" --content "# Meeting Notes\n\n## Attendees\n"

# Create from template
obsidian-cli create "Daily/2024-01-15" --template "Templates/Daily Note"

# Create with tags
obsidian-cli create "Ideas/New Feature" --tags "idea,product" --content "# Feature Idea\n"
```

### Note Editing

```bash
# Read note content
obsidian-cli read "Projects/Alpha/README" --vault "Business"

# Append to a note
obsidian-cli append "Journal/2024-01" --content "\n## January 15\nNew entry content"

# Update frontmatter
obsidian-cli frontmatter set "Projects/Alpha/README" --key "status" --value "active"
```

### Link Management

```bash
# List backlinks for a note
obsidian-cli links backlinks "Projects/Alpha/README"

# List outgoing links
obsidian-cli links outgoing "Projects/Alpha/README"

# Find unlinked mentions
obsidian-cli links unlinked "Alpha Project"

# List orphan notes (no incoming or outgoing links)
obsidian-cli links orphans --vault "Business"
```

### Tag Management

```bash
# List all tags in a vault
obsidian-cli tags list --vault "Business"

# List notes with a specific tag
obsidian-cli tags notes "project" --vault "Business"

# Rename a tag across all notes
obsidian-cli tags rename "old-tag" "new-tag" --vault "Business"
```

## Output Formatting

```bash
# JSON output for scripting
obsidian-cli search "query" -o json

# List format (paths only)
obsidian-cli list --format paths

# Full content output
obsidian-cli read "note/path" --format raw
```
