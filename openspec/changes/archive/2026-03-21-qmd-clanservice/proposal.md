## Why

AgentPlot services need a local document RAG capability for searching personal knowledge bases (notes, docs, code). qmd provides state-of-the-art hybrid retrieval with custom finetuned query expansion, cross-encoder reranking, and strong signal bypass — significantly better than naive embedding search. Deploying it as a clanService enables all agent toolchains (Claude Code, agent-deck) to search indexed document collections via MCP.

## What Changes

- Add `services/qmd/` clanService with server and client roles
- Server role: systemd service running qmd in Streamable HTTP mode on swancloud-srv, sqlite-vec storage, borgbackup integration, Caddy reverse proxy with DNS (qmd.swancloud.net)
- Client role: MCP HTTP endpoint configuration with delegation to claude-code and agent-deck, following the linkding client pattern
- Add qmd as a flake input (upstream has flake.nix)
- Configure collections via interface options (attrsOf with path, pattern, exclude)

## Capabilities

### New Capabilities
- `qmd-server`: Server-side deployment of qmd — systemd service, Caddy reverse proxy, borgbackup, collection indexing configuration
- `qmd-client`: Client-side MCP endpoint configuration — HTTP transport delegation to claude-code profiles and agent-deck

### Modified Capabilities

_None — this is a new service with no existing specs to modify._

## Impact

- **Flake inputs**: New `qmd` input pointing to upstream flake
- **Services**: New `services/qmd/` directory with `default.nix`
- **Infrastructure**: swancloud-srv gets qmd systemd service, Caddy vhost, borgbackup paths, firewall rules
- **Agent tooling**: Darwin/VM machines gain MCP endpoint config for qmd's 4 read-only tools (search, list collections, get document, get chunk)
- **HM delegation**: Client role accumulates HM modules via `agentplot.hmModules.qmd-*` pattern
