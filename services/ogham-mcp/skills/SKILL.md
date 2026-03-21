---
name: ogham-mcp
description: Persistent agent memory with hybrid search (semantic + full-text), knowledge graph, progressive compression, and cognitive decay. Use to store, retrieve, and manage long-term memory across sessions.
env:
  - OGHAM_MCP_URL
---

# ogham-mcp — Persistent Agent Memory

ogham-mcp provides long-term memory for agents via MCP. It is already configured as an MCP server — you interact with it through MCP tools, not CLI commands.

## Capabilities

- **Hybrid search**: Combines semantic (vector) and full-text search using Reciprocal Rank Fusion (RRF)
- **Knowledge graph**: Store and traverse entity relationships
- **Progressive compression**: Older memories are automatically summarized to save space
- **ACT-R cognitive decay**: Memories decay over time based on cognitive modeling, surfacing the most relevant ones
- **Partitions**: Memory can be scoped to partitions for isolation (e.g., work vs personal)

## Available MCP Tools

The ogham-mcp server exposes these tools via MCP:

### Memory Operations
- `store_memory` — Store a new memory with optional tags and metadata
- `search_memory` — Hybrid search across stored memories
- `get_memory` — Retrieve a specific memory by ID
- `delete_memory` — Remove a memory by ID
- `list_memories` — List recent memories with optional filtering

### Knowledge Graph
- `add_entity` — Add an entity to the knowledge graph
- `add_relation` — Create a relationship between entities
- `search_entities` — Search for entities by name or type
- `get_entity_relations` — Get all relations for an entity

## Usage Notes

- Memories are automatically embedded for semantic search — no manual embedding needed
- Use tags to categorize memories for filtered retrieval
- The knowledge graph complements flat memory with structured relationships
- Partition scoping is handled by the MCP configuration — no action needed per-request
