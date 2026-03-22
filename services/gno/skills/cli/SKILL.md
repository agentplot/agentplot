---
name: gno-cli
description: Search, query, and manage a gno document knowledge base via CLI. Use for document search, hybrid queries, index status, health checks, and collection troubleshooting.
---

# gno CLI — Document Knowledge Base

gno is a local-first knowledge engine with hybrid search, RAG Q&A, and wiki-link graph support. The `gno` CLI is available in your PATH.

## Search Commands

```bash
# Hybrid search (BM25 + vector + reranking) — best quality
gno query "how does authentication work"

# Fast keyword-only BM25 search (no LLM inference)
gno search "authentication middleware"

# Vector similarity search (semantic, no reranking)
gno vsearch "user session management"

# AI-powered answer grounded in search results
gno ask "what logging framework does this project use"
```

### Search Options

All search commands support:
- `-n 10` — number of results
- `--collection wiki` — restrict to a named collection
- `--all` — return all matches
- `--min-score 0.5` — minimum relevance threshold
- `--json`, `--csv`, `--md`, `--xml`, `--files` — output format

## Document Retrieval

```bash
# List indexed documents
gno ls
gno ls wiki

# Get a specific document by path or docid
gno get docs/architecture.md

# Find semantically similar documents
gno similar docs/auth.md

# Show outgoing wiki-links
gno links docs/auth.md

# Show backlinks (documents linking to target)
gno backlinks docs/auth.md

# Export knowledge graph
gno graph
```

## Index Management

```bash
# Full index (sync + embed)
gno index

# Sync files from disk without embedding
gno update

# Generate/refresh embeddings only
gno embed

# Manage document tags
gno tags
```

## Diagnostics & Health

```bash
# Check system health (GPU, models, database)
gno doctor

# Index status and collection info
gno status

# Remove orphaned data
gno cleanup

# Vector index maintenance
gno vec
```

## Model Management

```bash
# List available models
gno models list

# Pull a model
gno models pull <model-name>

# Switch active model
gno models use <model-name>
```
