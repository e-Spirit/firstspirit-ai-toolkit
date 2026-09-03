# FirstSpirit AI Toolkit — Contributor Guide

This repo contains skills, MCP server stubs, and platform manifests for building
FirstSpirit CMS projects with AI coding assistants.

## Adding a Skill

1. Choose the right category under `skills/`: `content/`, `templating/`, `project/`,
   `deployment/`, or `diagnostics/`.
2. Create a new directory named after your skill (letters, numbers, hyphens only).
3. Add a `SKILL.md` file with this frontmatter:

```yaml
---
name: your-skill-name
description: "What the skill covers and when it applies."
---
```

4. The `description` field must be present and make clear when the skill applies.
   Opening with `"Use when …"` is a good, greppable pattern but is **not** required
   — a topic-first description (e.g. "Concrete lookup reference for …") is fine.
   CI checks that a description exists, not its wording.
5. Add your skill's instructions in the Markdown body.
6. Update `skills/using-firstspirit-toolkit/SKILL.md` to mention your new skill in
   the relevant category section.
7. Run `./scripts/lint-skills.sh` to verify.

## Adding an MCP Server

1. Create a new directory under `mcp-servers/` named after the server.
2. Initialise an npm package: `npm init -y` then set `"name"` to
   `@firstspirit-ai-toolkit/mcp-<server-name>`.
3. Add the MCP SDK: `npm install @modelcontextprotocol/sdk`.
4. Create `src/index.ts` with your server entry point.
5. Document wire-up in the server's own `README.md` and in the root `mcp-servers/README.md`.

## Version Management

All platform manifest versions must stay in sync. To bump:

```bash
./scripts/bump-version.sh 0.2.0
```

To verify consistency (also runs in CI):

```bash
./scripts/bump-version.sh --check
```

Requires `jq` to be installed (`brew install jq` / `apt install jq`).

## Running CI Checks Locally

```bash
./scripts/lint-skills.sh          # validate all SKILL.md files
./scripts/bump-version.sh --check # check version consistency
```

## Publishing

```bash
npm publish --access public
```

MCP server sub-packages are published independently from their own directories.
