# MCP Servers

Each subdirectory is a self-contained MCP server published under the
`@firstspirit-ai-toolkit/` npm scope.

## Servers

| Server | Package | Status |
|--------|---------|--------|
| `firstspirit-api` | `@firstspirit-ai-toolkit/mcp-firstspirit-api` | Stub |

## Adding a New Server

1. Create a directory: `mcp-servers/<server-name>/`
2. Initialise: `cd mcp-servers/<server-name> && npm init -y`
3. Set `"name"` to `@firstspirit-ai-toolkit/mcp-<server-name>` in `package.json`
4. Install the SDK: `npm install @modelcontextprotocol/sdk`
5. Create `src/index.ts` using the boilerplate in `firstspirit-api/src/index.ts`
6. Add the server to the table above
7. Document wire-up in the server's own `README.md`

## Wire-Up (Consumer Projects)

```bash
claude mcp add <server-name> -- npx @firstspirit-ai-toolkit/mcp-<server-name>
```
