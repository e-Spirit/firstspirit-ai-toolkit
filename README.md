# FirstSpirit AI Toolkit

Skills, agents, and MCP servers for building and managing [FirstSpirit CMS](https://www.crownpeak.com/products/crownpeak-dxp) projects with AI coding assistants.

## Install

### Claude Code

```bash
/plugin install firstspirit-ai-toolkit
```

Or via self-hosted marketplace:

```bash
/plugin marketplace add FirstSpirit-Solutions/firstspirit-ai-toolkit-marketplace
/plugin install firstspirit-ai-toolkit
```

### Codex App

```
plugin install firstspirit-ai-toolkit
```

### Gemini CLI

```bash
gemini extension add firstspirit-ai-toolkit
```

### Cursor

Install via the Cursor plugin marketplace or manually reference `.cursor-plugin/`.

## What's Included

### Skills

Skills are organised into FirstSpirit domain categories:

| Category | Skills |
|----------|--------|
| `content/` | Content store management, datasets |
| `templating/` | Page, section, and link templates |
| `project/` | Project setup and configuration |
| `deployment/` | Publishing and generation runs |
| `diagnostics/` | Troubleshooting and health checks |

### MCP Servers

| Server | Package | Purpose |
|--------|---------|---------|
| `firstspirit-api` | `@firstspirit-ai-toolkit/mcp-firstspirit-api` | FirstSpirit REST API tools |

Wire up the MCP server in your project:

```bash
claude mcp add firstspirit-api -- npx @firstspirit-ai-toolkit/mcp-firstspirit-api
```

Set environment variables:
- `FS_URL` — FirstSpirit server URL (e.g. `https://your-server.example.com`)
- `FS_API_KEY` — FirstSpirit API key

## Contributing

See [CLAUDE.md](CLAUDE.md) for contributor guidelines.

## Requirements

- `jq` (required for session-start hook): `brew install jq` / `apt install jq`
- `jq` and Node.js 18+ for contributors (version bump script, MCP servers)

## License

MIT © Guy Brown
