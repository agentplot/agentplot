---
name: subcog-diagnostics
description: Troubleshoot and diagnose the subcog memory server. Use when checking server health, reviewing memory statistics, investigating search quality, or debugging database connectivity.
---

# subcog Diagnostics

subcog is a persistent memory server for AI agents with hybrid search and knowledge graph. This skill covers diagnostics and troubleshooting — for day-to-day memory operations, use the subcog MCP tools directly.

## Health & Connectivity

Check that the subcog server is reachable and responding:

```bash
# Verify the server is up
curl -s https://${SUBCOG_DOMAIN}/health | jq .

# Check MCP endpoint
curl -s -X POST https://${SUBCOG_DOMAIN}/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","method":"tools/list","id":1}' | jq .
```

## Memory Statistics

Use MCP tools to inspect memory state:

- `get_memory_stats` — storage stats, memory counts, index health
- `list_namespaces` — verify namespace configuration
- `list_memories` with pagination — check total memory count
- `search_memories` with a known term — verify hybrid search quality

## Common Issues

### Memories not appearing in search
1. Check vector embeddings are generated (subcog embeds inline via all-MiniLM-L6-v2)
2. Verify the correct namespace is being searched
3. Large batch imports may delay indexing — check `get_memory_stats`

### Search returning unexpected results
1. Use `vector_search` and `keyword_search` separately to isolate the issue
2. Check if the memory was stored with the expected metadata
3. Try `similar_memories` to verify embedding quality

### Knowledge graph queries empty
1. Entities must be explicitly created via `create_entity`
2. Relations require both source and target entities to exist
3. Use `list_entities` to verify graph population
4. `traverse_graph` requires a valid starting entity and depth

### Namespace issues
1. Use `list_namespaces` to verify the namespace exists
2. Default namespace is "default" — check if memories are in a different namespace
3. Retention policies are per-namespace — check with `get_retention_policy`

## Database Connectivity

subcog connects to PostgreSQL at `10.0.0.1` (host bridge). If the server fails to start:

```bash
# Check PostgreSQL is running on the host
systemctl status postgresql

# Verify the subcog database exists
sudo -u postgres psql -c "\\l" | grep subcog

# Check pgvector extension
sudo -u postgres psql subcog -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"
```

## Maintenance

Use MCP tools for maintenance operations:

- `compact_database` — optimize storage and rebuild indexes
- `expire_memories` — manually trigger retention policy enforcement
- `merge_entities` — deduplicate knowledge graph nodes
