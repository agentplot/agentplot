---
name: miniflux
description: Manage Miniflux RSS feeds, entries, categories, and OPML import/export via the REST API. Use when subscribing to feeds, reading entries, organizing categories, or managing RSS subscriptions.
---

# Miniflux API Skill

Manage the Miniflux RSS reader via its REST API using `miniflux-cli`.

`miniflux-cli` wraps restish with the bundled OpenAPI spec, so all endpoints are auto-discovered as typed CLI commands. New API features work immediately without skill updates.

Authentication is pre-configured — just use the commands below.

## Discovering Available Operations

```bash
# List all operations
miniflux-cli --help

# Help for a specific operation
miniflux-cli <operation-id> --help
```

## Restish Syntax Rules

- **GET query parameters** use `--flag value` syntax (flags are kebab-case, auto-generated from the OpenAPI spec):
  `miniflux-cli list-entries --status "unread" --limit 10`
- **POST/PUT/PATCH body parameters** use `key:value` syntax:
  `miniflux-cli create-feed 'feed_url:"https://example.com/feed.xml"' 'category_id:1'`

**Shell quoting is critical:** Values containing colons (URLs, timestamps) must be double-quoted *for restish*, and those double quotes must survive shell expansion. Wrap each `key:"value"` argument in single quotes: `'feed_url:"https://example.com/feed.xml"'`.

Do NOT use `key:value` for GET query params — restish treats those as body args and will error with "accepts 0 arg(s)".

## Common Operations

### Feeds

```bash
# List all subscribed feeds
miniflux-cli list-feeds

# Subscribe to a new feed
miniflux-cli create-feed 'feed_url:"https://example.com/feed.xml"' 'category_id:1'

# Get feed details
miniflux-cli get-feed 42

# Update a feed
miniflux-cli update-feed 42 'title:"New Title"' 'category_id:2'

# Delete a feed subscription
miniflux-cli delete-feed 42

# Refresh a single feed
miniflux-cli refresh-feed 42

# Refresh all feeds
miniflux-cli refresh-all-feeds
```

### Entries

```bash
# List all entries (paginated)
miniflux-cli list-entries

# List unread entries
miniflux-cli list-entries --status "unread"

# List starred entries
miniflux-cli list-entries --starred true

# Search entries by content
miniflux-cli list-entries --search "kubernetes"

# List entries in a specific category
miniflux-cli list-entries --category-id 3

# List entries with pagination and ordering
miniflux-cli list-entries --limit 20 --offset 0 --order "published_at" --direction "desc"

# Get a specific entry
miniflux-cli get-entry 123

# List entries for a specific feed
miniflux-cli list-feed-entries 42 --status "unread"

# List entries in a category
miniflux-cli list-category-entries 3 --limit 10

# Mark entries as read
miniflux-cli update-entries-status 'entry_ids:[123,456,789]' 'status:"read"'

# Mark entries as unread
miniflux-cli update-entries-status 'entry_ids:[123]' 'status:"unread"'

# Toggle bookmark/star on an entry
miniflux-cli toggle-entry-bookmark 123
```

### Categories

```bash
# List all categories
miniflux-cli list-categories

# Create a category
miniflux-cli create-category 'title:"Technology"'

# Update a category
miniflux-cli update-category 5 'title:"Tech News"'

# Delete a category
miniflux-cli delete-category 5
```

### OPML Import/Export

```bash
# Export all feeds as OPML
miniflux-cli export-opml > feeds.opml

# Import OPML subscriptions
miniflux-cli import-opml < feeds.opml
```

### User Profile

```bash
# Get current user info
miniflux-cli get-current-user
```

## Output Formatting

Restish auto-detects output context:
- **Piped/scripted**: outputs raw JSON (agent-friendly)
- **Interactive terminal**: colorized human-readable output

Force specific formats:

```bash
# JSON output
miniflux-cli list-feeds -o json

# Filter specific fields
miniflux-cli list-entries --status "unread" -f 'body.entries.{id, title, published_at, feed.title}'

# Raw string (no quotes)
miniflux-cli get-entry 123 -f 'body.title' -r
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (2xx) |
| 1 | Unrecoverable error |
| 4 | Client error (4xx) |
| 5 | Server error (5xx) |

## Workflow Patterns

```bash
# Daily reading workflow: get unread entries sorted by newest
miniflux-cli list-entries --status "unread" --order "published_at" --direction "desc" --limit 50

# Find entries about a topic across all feeds
miniflux-cli list-entries --search "AI agents" -f 'body.entries.{id, title, feed.title, published_at}'

# Batch mark as read after review
miniflux-cli update-entries-status 'entry_ids:[101,102,103,104]' 'status:"read"'
```
