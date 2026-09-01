# @firstspirit-ai-toolkit/mcp-firstspirit-api

MCP server that exposes FirstSpirit REST API operations as tools for AI coding assistants.

> **Status: Stub** — No tools are registered yet. This package establishes the
> pattern and wire-up mechanism.

## Wire-Up

In your project:

```bash
claude mcp add firstspirit-api -- npx @firstspirit-ai-toolkit/mcp-firstspirit-api
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `FS_URL` | Yes | FirstSpirit server URL, e.g. `https://your-server.example.com` |
| `FS_API_KEY` | Yes | FirstSpirit API key |

## Development

```bash
npm install
npm run build
npm start
```

## Adding Tools

1. Register the tool in `ListToolsRequestSchema` handler with its `inputSchema`.
2. Add a `case` block in `CallToolRequestSchema` handler to execute it.
3. Use `FS_URL` and `FS_API_KEY` for authenticated REST calls.

## Publishing

```bash
npm publish --access public
```
