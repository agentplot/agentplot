---
name: qmd-cli
description: Search, query, and manage a qmd document index via CLI. Use for hybrid document search, collection management, index status, and troubleshooting.
---

# qmd CLI — Document Search Engine

qmd is a local hybrid search engine for markdown documents with query expansion, vector search, and LLM reranking. The `qmd` CLI is available in your PATH.

## Search Commands

```bash
# Hybrid search with query expansion + reranking (best quality)
qmd query "how does the deployment pipeline work"

# Fast BM25 keyword search (no LLM inference)
qmd search "deployment pipeline"

# Vector similarity search (semantic, no reranking)
qmd vsearch "CI/CD workflow"
```

### Search Options

All search commands support:
- `-n 10` — number of results
- `--collection wiki` — restrict to a named collection
- `--all` — return all matches
- `--min-score 0.5` — minimum score threshold
- `--json`, `--csv`, `--md`, `--xml`, `--files` — output format

### Structured Query Format

`qmd query` supports multi-line structured queries:
```bash
qmd query "lex: deployment
vec: CI/CD automation
hyde: A document describing the deployment pipeline"
```

## Document Retrieval

```bash
# List collections or files
qmd ls
qmd ls wiki/docs

# Get a single document by path or docid
qmd get wiki/architecture.md

# Get multiple documents by glob pattern
qmd multi-get "wiki/**/*.md"
```

## Collection Management

```bash
# List all collections
qmd collection list

# Add a new collection
qmd collection add /path/to/docs --name wiki

# Show collection details
qmd collection show wiki

# Remove a collection
qmd collection remove wiki

# Rename a collection
qmd collection rename old-name new-name

# Set pre-update command (e.g., git pull)
qmd collection update-cmd wiki "git pull"

# Include/exclude from default queries
qmd collection include wiki
qmd collection exclude archive
```

## Context Management

Attach human-written summaries to improve search relevance:
```bash
qmd context add wiki/api "REST API for user management, auth, and billing"
qmd context list
qmd context rm wiki/api
```

## Index Management

```bash
# Re-index all collections
qmd update

# Re-index with git pull
qmd update --pull

# Refresh vector embeddings
qmd embed
```

## Diagnostics

```bash
# Index health, GPU status, VRAM, pending embeddings
qmd status

# Clear caches and vacuum database
qmd cleanup
```

## MCP Server

```bash
# Start MCP server (HTTP transport)
qmd mcp --http --port 8423

# Start MCP server as background daemon
qmd mcp --daemon

# Stop background MCP daemon
qmd mcp stop
```
