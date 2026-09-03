# FirstSpirit AI Toolkit — Repository Design Spec

**Date:** 2026-09-01  
**Status:** Approved  
**Author:** Guy Brown (guy.brown@rezolve.com)

---

## Overview

`firstspirit-ai-toolkit` is an agentic skills and tooling library for working with FirstSpirit CMS across AI coding assistants. It follows the structure and conventions established by [Superpowers](https://github.com/obra/superpowers) and is compatible with the same plugin/extension ecosystems.

The repo ships skills (organised by FirstSpirit domain), MCP server stubs, platform manifests, and the hook infrastructure needed to auto-inject the bootstrap skill at session start.

---

## Goals

- Provide a structured, extensible home for FirstSpirit-specific AI skills
- Support Claude Code, Codex App, Gemini CLI, and Cursor IDE at launch
- Include MCP server stubs so FirstSpirit REST API integration has a clear home
- Be publishable to npm and installable via each harness's plugin command
- Be immediately usable as a contribution target before any FirstSpirit skills are authored

---

## Non-Goals

- FirstSpirit skill content itself (added separately)
- MCP server implementation (stubs only at this stage)
- Support for harnesses beyond the four listed (Kimi, Devin, OpenCode, Pi, Hermes — deferred)
- Any runtime dependencies (no npm packages required at the skills layer)

---

## Package Identity

| Field | Value |
|-------|-------|
| npm package name | `firstspirit-ai-toolkit` |
| npm scope (MCP servers) | `@firstspirit-ai-toolkit/` |
| Version | `0.1.0` |
| License | MIT |
| Author | Guy Brown \<guy.brown@rezolve.com\> |

---

## Directory Structure

```
firstspirit-ai-toolkit/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .codex-plugin/
│   └── plugin.json
├── .cursor-plugin/
│   └── plugin.json
├── .github/
│   ├── workflows/
│   │   └── ci.yml
│   └── pull_request_template.md
├── assets/
│   └── app-icon.png              # Placeholder — replace with real branding
├── docs/
│   ├── specs/
│   │   └── 2026-09-01-firstspirit-ai-toolkit-design.md  # This file
│   ├── porting-to-a-new-harness.md
│   └── writing-skills.md
├── hooks/
│   ├── hooks.json                # Claude Code SessionStart hook
│   ├── hooks-cursor.json         # Cursor SessionStart hook (referenced by .cursor-plugin/plugin.json)
│   ├── run-hook.cmd              # Hook dispatcher
│   └── session-start             # Shell script: detects harness, emits JSON
├── mcp-servers/
│   ├── README.md
│   └── firstspirit-api/
│       ├── package.json
│       ├── tsconfig.json
│       ├── src/
│       │   └── index.ts
│       └── README.md
├── scripts/
│   ├── bump-version.sh
│   └── lint-skills.sh
├── skills/
│   ├── using-firstspirit-toolkit/
│   │   ├── SKILL.md
│   │   └── references/
│   │       ├── codex-tools.md
│   │       ├── cursor-tools.md
│   │       └── gemini-tools.md
│   ├── content/
│   │   └── manage-content/
│   │       └── SKILL.md
│   ├── templating/
│   │   └── design-templates/
│   │       └── SKILL.md
│   ├── project/
│   │   └── setup-project/
│   │       └── SKILL.md
│   ├── deployment/
│   │   └── publish-content/
│   │       └── SKILL.md
│   └── diagnostics/
│       └── diagnose-project/
│           └── SKILL.md
├── .gitattributes
├── .gitignore
├── .pre-commit-config.yaml
├── .version-bump.json
├── AGENTS.md
├── CLAUDE.md
├── CODE_OF_CONDUCT.md
├── GEMINI.md
├── LICENSE
├── README.md
├── RELEASE-NOTES.md
├── gemini-extension.json
└── package.json
```

---

## Skills Architecture

### Namespace Convention

Skills are organised into category subdirectories under `skills/`. All plugin manifests point to `./skills/` and harnesses recurse into subdirectories for discovery.

| Category | Purpose |
|----------|---------|
| `using-firstspirit-toolkit/` | Bootstrap skill — auto-injected at session start via hooks |
| `content/` | Content management, content stores, dataset operations |
| `templating/` | Template design, section/page templates, rendering |
| `project/` | Project setup, configuration, user management |
| `deployment/` | Publishing, release, deployment workflows |
| `diagnostics/` | Troubleshooting, health checks, log analysis |

### SKILL.md Format

Every skill follows the Superpowers SKILL.md contract:

```markdown
---
name: skill-name-with-hyphens
description: "Use when [specific triggering conditions]."
---

# Skill Title
...body...
```

Rules:
- Frontmatter max 1024 characters
- `name`: letters, numbers, hyphens only
- `description`: starts with "Use when" — triggering conditions only, never a workflow summary
- One skill per directory, directory name matches `name` field

### Bootstrap Skill

`skills/using-firstspirit-toolkit/SKILL.md` is the activation mechanism. It is injected into every new AI session via the hook system and tells the agent:
- What this toolkit is
- What skill categories exist and when to use them
- Platform-specific tool name mappings (via `references/`)

The `references/` subdirectory contains harness-specific tool mapping files so the bootstrap skill can guide agents on how abstract operations ("create a todo", "dispatch a subagent") map to actual tool names in each harness.

---

## MCP Servers Architecture

MCP servers live under `mcp-servers/`. Each server is a self-contained npm package under the `@firstspirit-ai-toolkit/` scope.

### firstspirit-api (stub)

Package: `@firstspirit-ai-toolkit/mcp-firstspirit-api`

Intended to expose FirstSpirit REST API operations as MCP tools — content reading/writing, project navigation, template access. At launch, ships only the MCP SDK boilerplate entry point.

**Wire-up:** Projects consuming this server add it via:
```bash
claude mcp add firstspirit-api -- npx @firstspirit-ai-toolkit/mcp-firstspirit-api
```

Configuration (base URL, API key) passed via environment variables documented in the server's own README.

---

## Platform Manifests

### Claude Code (.claude-plugin/plugin.json)

```json
{
  "name": "firstspirit-ai-toolkit",
  "description": "Skills and tools for building and managing FirstSpirit CMS projects with AI",
  "version": "0.1.0",
  "author": { "name": "Guy Brown", "email": "guy.brown@rezolve.com" },
  "homepage": "https://github.com/e-Spirit/firstspirit-ai-toolkit",
  "license": "MIT",
  "keywords": ["firstspirit", "cms", "skills", "agentic"]
}
```

### Codex App (.codex-plugin/plugin.json)

Full manifest including `skills: "./skills/"`, brand color, display name, `defaultPrompt`, capabilities array, and `sessionStart` hook reference.

### Cursor (.cursor-plugin/)

`plugin.json` references `skills: "./skills/"` and `hooks: "./hooks/hooks-cursor.json"`. Cursor uses a different hook JSON shape from Claude Code — both are maintained separately.

### Gemini CLI (gemini-extension.json + GEMINI.md)

`gemini-extension.json` at root with `contextFileName: "GEMINI.md"`. `GEMINI.md` file-references the bootstrap skill and gemini-tools.md — Gemini has no hook system so this is the injection mechanism.

---

## Hook System

The `SessionStart` hook injects the bootstrap skill into every new session.

### Claude Code (hooks/hooks.json)

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
        "shell": "bash",
        "async": false
      }]
    }]
  }
}
```

### Cursor (hooks/hooks-cursor.json)

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [{ "command": "./hooks/run-hook.cmd session-start" }]
  }
}
```

### session-start script

Reads `skills/using-firstspirit-toolkit/SKILL.md` and emits platform-specific JSON:
- Claude Code: `{ "hookSpecificOutput": { "hookEventName": "SessionStart", "additionalContext": "..." } }`
- Cursor: `{ "additional_context": "..." }`
- Unknown: `{ "additionalContext": "..." }`

Harness is detected via env vars: `CLAUDE_PLUGIN_ROOT` → Claude Code, `CURSOR_PLUGIN_ROOT` → Cursor.

---

## Version Management

`.version-bump.json` declares every file that must stay version-synced. `scripts/bump-version.sh` updates all declared files atomically.

### Tracked files

| File | Field |
|------|-------|
| `package.json` | `version` |
| `.claude-plugin/plugin.json` | `version` |
| `.claude-plugin/marketplace.json` | `plugins.0.version` |
| `.codex-plugin/plugin.json` | `version` |
| `.cursor-plugin/plugin.json` | `version` |
| `gemini-extension.json` | `version` |

### Usage

```bash
./scripts/bump-version.sh 0.2.0   # Bump all to 0.2.0
./scripts/bump-version.sh --check  # Report all versions, detect drift
```

---

## CI

`.github/workflows/ci.yml` runs on every PR:

1. `./scripts/bump-version.sh --check` — fails if any manifest version drifts
2. `./scripts/lint-skills.sh` — fails if any SKILL.md is missing `name` or `description`, or if `description` doesn't start with "Use when"

---

## Agent Instruction Files

| File | Purpose |
|------|---------|
| `CLAUDE.md` | Contributor guidelines for Claude Code users working on this repo |
| `AGENTS.md` | Same content — picked up by Codex CLI and agents-convention tools |
| `GEMINI.md` | File-references bootstrap skill + gemini-tools.md (skill injection for Gemini) |

`CLAUDE.md` and `AGENTS.md` describe: how to add a skill, how to add an MCP server, how to run the version bump script, and how to run CI checks locally.

---

## Publishing

### npm

```bash
npm publish --access public
```

Publishes the root package. MCP server sub-packages are published independently from their own directories.

### Claude Code Marketplace

Plugin becomes installable via:
```
/plugin install firstspirit-ai-toolkit
```

once submitted to the Anthropic marketplace, or via self-hosted marketplace using `.claude-plugin/marketplace.json`.

### Codex

```
plugin install firstspirit-ai-toolkit
```

### Gemini CLI

```bash
gemini extension add /path/to/firstspirit-ai-toolkit
# or from npm:
gemini extension add firstspirit-ai-toolkit
```

---

## Open Questions

None — all structural decisions resolved during design review.
