---
name: openclaw-workspace
description: OpenClaw workspace management — project scaffolding, environment setup, workflow orchestration, and development tooling coordination. Use when setting up new projects, managing development environments, or orchestrating multi-tool workflows.
---

# OpenClaw Workspace Skill

Manage OpenClaw workspaces for project scaffolding, environment setup, and workflow orchestration.

## Overview

OpenClaw workspace management coordinates the full development ecosystem: project creation, environment configuration, workflow automation via lobster, and multi-tool orchestration.

## Workspace Operations

### Project Scaffolding

```bash
# Create a new project workspace
clawhub project create "my-project" --template default

# List available project templates
clawhub project templates

# Initialize workspace from existing directory
clawhub project init --name "existing-project"
```

### Environment Setup

```bash
# Set up development environment for a project
clawhub env setup "my-project"

# List configured environments
clawhub env list

# Switch active environment
clawhub env switch "my-project"
```

### Workflow Orchestration

Lobster handles workflow automation. Workflows are YAML files that define multi-step processes.

```bash
# List available workflows
lobster list

# Run a workflow
lobster run <workflow-name>

# Run with parameters
lobster run <workflow-name> --param key=value

# Show workflow definition
lobster show <workflow-name>
```

## Available CLI Tools

The following tools are available when the OpenClaw client role is enabled:

| Tool | Purpose |
|------|---------|
| `lobster` | Workflow automation and orchestration |
| `clawhub` | Project and workspace management |
| `imsg` | iMessage integration for notifications |
| `gogcli` | GOG Galaxy CLI for game library management |
| `remindctl` | Reminders integration |
| `blogwatcher` | Blog/feed monitoring and alerts |
| `memo` | Quick note capture and retrieval |
| `defuddle` | Web page content extraction (clean markdown) |

## Workflow Patterns

### New Project Setup

1. Create project with `clawhub project create`
2. Configure environment with `clawhub env setup`
3. Set up automation workflows with `lobster`

### Daily Workflow

1. Check active projects: `clawhub project list --active`
2. Run daily workflows: `lobster run daily`
3. Review notifications and captures
