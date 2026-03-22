---
name: ogham-mcp-diagnostics
description: Troubleshoot and diagnose the ogham-mcp memory server. Use when checking server health, investigating search quality, reviewing memory statistics, or debugging connectivity issues.
---

# ogham-mcp Diagnostics

ogham-mcp is a persistent agent memory server accessed via MCP tools. This skill covers diagnostics and troubleshooting — for day-to-day memory operations, use the ogham-mcp MCP tools directly.

## Health & Connectivity

Check that the ogham-mcp server is reachable and responding:

```bash
# Verify the server is up (HTTP health endpoint)
curl -s https://${OGHAM_DOMAIN}/health | jq .

# Check SSE endpoint connectivity
curl -s -N https://${OGHAM_DOMAIN}/sse -H "Accept: text/event-stream" --max-time 5
```

## Memory Statistics

Use MCP tools to inspect memory state:

- `list_memories` with no filters — check total memory count and recent entries
- `search_memory` with a known term — verify search is returning expected results
- `search_entities` — confirm knowledge graph is populated

## Common Issues

### Memories not appearing in search
1. Check embedding provider is configured and API key is valid
2. Verify PostgreSQL connectivity: memories require pgvector for semantic search
3. New memories need embedding — there may be a processing delay

### High latency on search
1. Check if pgvector indexes are built (first search after restart may be slow)
2. Verify embedding provider latency (external API calls to OpenAI/Mistral/Voyage)
3. Check database size — large memory stores may need index tuning

### Knowledge graph queries returning empty
1. Entities must be explicitly created via `add_entity`
2. Relations require both source and target entities to exist
3. Check entity names — search is case-sensitive

## Database Connectivity

The ogham-mcp server connects to PostgreSQL at `10.0.0.1` (host bridge). If the server fails to start:

```bash
# Check PostgreSQL is running on the host
systemctl status postgresql

# Verify the ogham database exists
sudo -u postgres psql -c "\\l" | grep ogham

# Check pgvector extension
sudo -u postgres psql ogham -c "SELECT extname FROM pg_extension WHERE extname = 'vector';"
```
