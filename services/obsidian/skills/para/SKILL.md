---
name: obsidian-para
description: PARA-based note organization for Obsidian vaults with vault routing rules. Use when organizing notes into Projects, Areas, Resources, or Archives, or when deciding which vault a note belongs in.
---

# Obsidian PARA Organization Skill

Organize Obsidian notes using the PARA method (Projects, Areas, Resources, Archives) with vault-aware routing.

## PARA Categories

| Category | Purpose | Example |
|----------|---------|---------|
| **Projects** | Active work with a deadline or deliverable | "Q1 Launch", "Website Redesign" |
| **Areas** | Ongoing responsibilities without end dates | "Health", "Finance", "Team Management" |
| **Resources** | Reference material for future use | "Design Patterns", "API Documentation" |
| **Archives** | Completed or inactive items from above | "2023 Q4 Review", "Old Project X" |

## Vault Routing Rules

Notes are routed to the appropriate vault based on context. The configured vaults (`OBSIDIAN_VAULTS`) determine which vaults are available.

### Routing Decision Tree

1. **Is it work/business related?** → Route to the business vault
2. **Is it personal/creative?** → Route to the personal vault
3. **Does it span multiple contexts?** → Create in the primary context vault, link from others

### Within Each Vault

```
<Vault>/
  Projects/        # Active, time-bound work
  Areas/           # Ongoing responsibilities
  Resources/       # Reference material
  Archives/        # Completed/inactive items
  Templates/       # Note templates
  Daily/           # Daily notes (if applicable)
```

## Operations

### Classify and File a Note

```bash
# Move a note to the correct PARA category
obsidian-cli move "Inbox/Untitled" "Projects/Website Redesign/Requirements" --vault "Business"

# Archive a completed project
obsidian-cli move "Projects/Q4 Review" "Archives/2024/Q4 Review" --vault "Business"
```

### Create with PARA Structure

```bash
# Create a new project
obsidian-cli create "Projects/New Initiative/README" --vault "Business" \
  --template "Templates/Project" \
  --tags "project,active"

# Create an area note
obsidian-cli create "Areas/Health/Exercise Log" --vault "Personal" \
  --tags "area,health"

# Create a resource
obsidian-cli create "Resources/API Patterns/REST Best Practices" --vault "Business" \
  --tags "resource,api"
```

### Review and Maintain

```bash
# List all active projects
obsidian-cli list --path "Projects/**" --vault "Business" --sort modified

# Find stale projects (not modified in 30 days)
obsidian-cli list --path "Projects/**" --vault "Business" --older-than 30d

# List items in inbox needing classification
obsidian-cli list --path "Inbox/**" --sort created
```

## Weekly Review Workflow

1. Process inbox items into PARA categories
2. Review active projects for progress
3. Archive completed projects
4. Update area notes with current status
5. Prune unused resources
