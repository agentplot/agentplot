---
name: subcog
description: Persistent agent memory with hybrid search (vector + keyword + graph), entity-centric knowledge graph, and namespace-scoped retention policies. Use when storing, retrieving, searching, or managing agent memories, entities, relationships, and knowledge across sessions.
---

# Subcog Memory Skill

Subcog provides persistent, structured memory for AI agents via MCP tools over HTTP. It supports hybrid search (vector similarity + keyword + graph traversal), entity-centric knowledge graphs, and namespace-scoped retention policies.

## Core Concepts

- **Memories**: Discrete pieces of information with content, metadata, and optional entity associations
- **Entities**: Named nodes in the knowledge graph (people, projects, concepts) with properties
- **Relations**: Typed edges between entities forming a knowledge graph
- **Namespaces**: Scoped containers for organizing memories with independent retention policies
- **Hybrid Search**: Combines vector similarity (all-MiniLM-L6-v2, 384d), keyword matching, and graph traversal

## MCP Tool Categories

### Memory Management

Store, retrieve, update, and delete memories:
- `create_memory` — Store a new memory with content, metadata, and optional entity links
- `get_memory` — Retrieve a specific memory by ID
- `update_memory` — Update memory content or metadata
- `delete_memory` — Remove a memory
- `list_memories` — List memories with pagination and filtering
- `batch_create_memories` — Store multiple memories in one operation

### Search & Retrieval

Find memories using hybrid search:
- `search_memories` — Hybrid search combining vector similarity, keyword, and graph context
- `vector_search` — Pure vector similarity search
- `keyword_search` — Full-text keyword search
- `graph_search` — Search by traversing entity relationships
- `search_by_entity` — Find all memories associated with an entity
- `search_by_namespace` — Search within a specific namespace
- `search_by_metadata` — Filter memories by metadata fields
- `similar_memories` — Find memories similar to a given memory

### Entity Management

Manage knowledge graph nodes:
- `create_entity` — Create a named entity with type and properties
- `get_entity` — Retrieve entity details
- `update_entity` — Update entity properties
- `delete_entity` — Remove an entity
- `list_entities` — List entities with type filtering
- `merge_entities` — Merge duplicate entities
- `search_entities` — Search entities by name or properties

### Relationship Management

Manage knowledge graph edges:
- `create_relation` — Create a typed relationship between entities
- `get_relations` — Get relationships for an entity
- `delete_relation` — Remove a relationship
- `list_relation_types` — List available relationship types
- `traverse_graph` — Walk the graph from an entity with depth control

### Namespace Management

Organize and scope memories:
- `create_namespace` — Create a namespace with retention policy
- `get_namespace` — Retrieve namespace details
- `update_namespace` — Update namespace settings or retention policy
- `delete_namespace` — Remove a namespace and its memories
- `list_namespaces` — List all namespaces

### Retention & Maintenance

Manage memory lifecycle:
- `set_retention_policy` — Configure retention rules for a namespace
- `get_retention_policy` — View current retention policy
- `expire_memories` — Manually trigger retention policy enforcement
- `get_memory_stats` — Get statistics about stored memories
- `compact_database` — Optimize storage and indexes

### Context & Sessions

Session-aware memory operations:
- `create_session_context` — Initialize a session context for memory operations
- `get_session_context` — Retrieve current session context
- `add_to_context` — Add memories to active session context
- `summarize_context` — Get a summary of session-relevant memories

## Usage Patterns

### Store a memory about a conversation
The MCP tools are called directly by the agent framework — no CLI commands needed. The agent interacts with subcog through tool calls automatically routed to the HTTP MCP endpoint.

### Typical workflow
1. Search for relevant context before responding
2. Store important information as memories during conversation
3. Create entities for people, projects, and concepts mentioned
4. Link memories to entities for graph-based retrieval
5. Use namespace scoping to separate different knowledge domains
