# FirstSpirit AI Toolkit

Skills, agents, and MCP servers for building and managing [FirstSpirit CMS](https://www.crownpeak.com/products/crownpeak-dxp) projects with AI coding assistants.

## Install

### Claude Code

```bash
/plugin install firstspirit-ai-toolkit
```

Or via self-hosted marketplace:

```bash
/plugin marketplace add e-Spirit/firstspirit-ai-toolkit-marketplace
/plugin install firstspirit-ai-toolkit
```

### GitHub Copilot

```bash
copilot plugin install firstspirit-ai-toolkit@awesome-copilot
```

Or browse and install via VS Code: open Extensions, search `@agentPlugins`, find **FirstSpirit AI Toolkit**, and click Install.

Once installed, the toolkit loads its skill index automatically at session start — only when the project looks like FirstSpirit (same detection as Claude Code). No per-project setup needed.

**No plugin install?** Add the following to your project's `.github/copilot-instructions.md` instead (create the file if it doesn't exist):

```
If this project involves FirstSpirit CMS, read `skills/using-firstspirit-toolkit/SKILL.md` for the available skills and when to use them. If it does not, ignore that file entirely.
```

### Codex App

```
plugin install firstspirit-ai-toolkit
```

### Antigravity CLI

Clone this repo (or add it as a submodule), then install from the local path:

```bash
git clone https://github.com/e-Spirit/firstspirit-ai-toolkit.git
agy plugin install ./firstspirit-ai-toolkit
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

### When the toolkit loads

On session start the toolkit loads its skill index only when the current project
looks like FirstSpirit — so it stays invisible on unrelated projects. It is
detected automatically from any of:

- a `.firstspirit` marker file (empty file is enough), or `fs-project.yaml`;
- an external-sync export tree (the `FS_References.txt` / `FS_Info.txt` sidecars);
- a `module.xml` / `module-isolated.xml` or a build file (`pom.xml`, `build.gradle`)
  that references FirstSpirit (`de.espirit…`, `fs-isolated-runtime`, `fs-access`).

Drop an empty `.firstspirit` in a repo the detector doesn't recognise to force it
on. Override either way with the `FIRSTSPIRIT_PROJECT` environment variable
(`1` = always load, `0` = never). On projects with no signal, the toolkit prints a
single line telling the assistant where to find the skill index if the work turns
out to be FirstSpirit.

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
