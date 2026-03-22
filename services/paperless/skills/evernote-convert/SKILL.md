---
name: evernote-convert
description: Convert Evernote .enex exports to Paperless-ngx documents using enex2paperless. Use when importing Evernote notebooks, migrating from Evernote, or processing .enex export files into Paperless.
---

# Evernote to Paperless Conversion Skill

Convert Evernote `.enex` export files into Paperless-ngx documents using `enex2paperless`.

## Environment Variables

Configure directory paths via environment variables. These allow the same workflow to work on any machine.

| Variable | Purpose | Default |
|----------|---------|---------|
| `ENEX_INBOX_DIR` | Directory where .enex files are placed for processing | (must be set) |
| `ENEX_ARCHIVE_DIR` | Directory where processed .enex files are moved after conversion | (must be set) |
| `ENEX_PROJECT_DIR` | Optional project-specific export directory | (optional) |

## Conversion Workflow

### 1. Check Inbox for New Exports

```bash
# List .enex files waiting for processing
ls "${ENEX_INBOX_DIR}"/*.enex 2>/dev/null || echo "No .enex files in inbox"

# Count pending files
find "${ENEX_INBOX_DIR}" -name "*.enex" -type f | wc -l
```

### 2. Convert .enex to Paperless

```bash
# Convert a single .enex file
enex2paperless "${ENEX_INBOX_DIR}/notebook.enex" --output-dir /tmp/paperless-import/

# Convert all .enex files in inbox
for f in "${ENEX_INBOX_DIR}"/*.enex; do
  [ -f "$f" ] || continue
  echo "Converting: $(basename "$f")"
  enex2paperless "$f" --output-dir /tmp/paperless-import/
done

# Convert with tag mapping
enex2paperless "${ENEX_INBOX_DIR}/notebook.enex" \
  --output-dir /tmp/paperless-import/ \
  --tag-prefix "evernote:"
```

### 3. Import to Paperless-ngx

After conversion, documents can be imported to Paperless-ngx via its consume directory or API.

```bash
# Copy converted documents to Paperless consume directory
cp /tmp/paperless-import/* "${PAPERLESS_CONSUME_DIR:-/path/to/consume}/"

# Or upload via API (if paperless-cli is available)
paperless upload /tmp/paperless-import/*
```

### 4. Archive Processed Files

```bash
# Move processed .enex files to archive
for f in "${ENEX_INBOX_DIR}"/*.enex; do
  [ -f "$f" ] || continue
  mv "$f" "${ENEX_ARCHIVE_DIR}/$(date +%Y%m%d)-$(basename "$f")"
done
```

### 5. Log Results (Optional)

If `sheets-cli` is available, log conversion results:

```bash
# Log to tracking spreadsheet
sheets-cli append "Evernote Migration" \
  --values "$(date +%Y-%m-%d),$(basename "$f"),$(wc -l < /tmp/paperless-import/manifest.json),success"
```

## Batch Processing

```bash
# Full batch workflow: convert all, import, archive
for f in "${ENEX_INBOX_DIR}"/*.enex; do
  [ -f "$f" ] || continue
  BASENAME=$(basename "$f" .enex)
  TMPDIR=$(mktemp -d)

  echo "Processing: $BASENAME"
  enex2paperless "$f" --output-dir "$TMPDIR/"

  # Import to Paperless
  cp "$TMPDIR"/* "${PAPERLESS_CONSUME_DIR:-/path/to/consume}/" 2>/dev/null

  # Archive source
  mv "$f" "${ENEX_ARCHIVE_DIR}/$(date +%Y%m%d)-${BASENAME}.enex"

  rm -rf "$TMPDIR"
  echo "Done: $BASENAME"
done
```

## Project-Specific Exports

For project-scoped Evernote exports:

```bash
# Process project-specific exports
if [ -n "${ENEX_PROJECT_DIR}" ] && [ -d "${ENEX_PROJECT_DIR}" ]; then
  for f in "${ENEX_PROJECT_DIR}"/*.enex; do
    [ -f "$f" ] || continue
    enex2paperless "$f" --output-dir /tmp/paperless-import/ --tag-prefix "project:"
  done
fi
```
