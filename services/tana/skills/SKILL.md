---
name: tana
description: Export and manage Tana knowledge base content — nodes, supertags, views, and workspace data. Use when exporting Tana content, migrating data from Tana, or working with Tana's knowledge graph structure.
---

# Tana Export Skill

Export and work with content from the Tana knowledge management tool.

## Overview

Tana organizes knowledge as a graph of nodes with supertags (structured types). This skill covers exporting and processing Tana content for use in other systems.

## Export Operations

### Full Workspace Export

```bash
# Export entire workspace as JSON
tana-export workspace --format json --output ./tana-export/

# Export workspace as markdown
tana-export workspace --format markdown --output ./tana-export/

# Export with date filtering
tana-export workspace --since "2024-01-01" --format json --output ./tana-export/
```

### Supertag-Based Export

```bash
# Export all nodes with a specific supertag
tana-export supertag "Meeting Notes" --format markdown --output ./meetings/

# Export tasks/todos
tana-export supertag "Task" --format json --output ./tasks/

# Export with field selection
tana-export supertag "Project" --fields "title,status,deadline,owner" --format csv
```

### Node Export

```bash
# Export a specific node and its children
tana-export node "<node-id>" --format markdown --depth 3

# Export search results
tana-export search "quarterly review" --format markdown
```

## Processing Exported Data

### Convert to Obsidian

```bash
# Convert Tana JSON export to Obsidian-compatible markdown
tana-export convert --from tana-json --to obsidian \
  --input ./tana-export/ \
  --output ./obsidian-vault/Import/

# Preserve supertag structure as frontmatter
tana-export convert --from tana-json --to obsidian \
  --input ./tana-export/ \
  --output ./obsidian-vault/Import/ \
  --supertags-as frontmatter
```

### Generate Reports

```bash
# Summarize exported content
tana-export summary --input ./tana-export/ --format markdown

# List all supertags and node counts
tana-export stats --input ./tana-export/
```

## Data Model

| Tana Concept | Description |
|-------------|-------------|
| **Node** | Basic unit of content (text, reference, etc.) |
| **Supertag** | Structured type applied to nodes (like a schema) |
| **Field** | Named property on a supertag |
| **View** | Saved query/filter over nodes |
| **Reference** | Link between nodes |
