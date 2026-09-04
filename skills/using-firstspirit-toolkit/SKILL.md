---
name: using-firstspirit-toolkit
description: "Use when starting any session that involves FirstSpirit CMS work — establishes what skills are available and when to invoke them."
---

# FirstSpirit AI Toolkit

You have the FirstSpirit AI Toolkit loaded. Before responding or taking action on any FirstSpirit task, check whether a more specific skill applies.

## Rule

If there is even a small chance a skill applies to your task, you MUST invoke it before acting. Check for skills before clarifying questions, before exploring the codebase, before writing code.

## Available Skills

### Templating (`skills/templating/`)
- **firstspirit-templating-reference** — Use when you need exact FirstSpirit template syntax, the right GOM input component, what datatype a component produces, how to access it in an output channel, or whether something is deprecated.

### Project (`skills/project/`)
- **firstspirit-api-reference** — Use when you need to know which interface a store element has, how the stores nest, which agent yields a store or service, how to load an element by UID, or how to write an `fs` query.
- **firstspirit-rest-api** — Use when performing CMS operations via the FirstSpirit REST API — creating/editing templates, managing pages and sections, writing form field values, uploading media, or searching content.
- **firstspirit-scripting** — Use when writing, reviewing, or debugging a FirstSpirit BeanShell script — covers script types and their `context` objects, BeanShell syntax, logging, and safe Access-API patterns.

### Deployment (`skills/deployment/`)
- **firstspirit-external-sync-export** — Use when exporting or importing a FirstSpirit project via fs-cli (FSDevTools / external synchronisation) — covers installation, connection, authentication, export/import commands, and troubleshooting.

## Platform Tool Mappings

If you are running on a harness listed below, read the corresponding reference for how abstract operations map to that harness's real tool names:

- **Codex:** read `skills/using-firstspirit-toolkit/references/codex-tools.md`
- **Cursor:** read `skills/using-firstspirit-toolkit/references/cursor-tools.md`
- **Gemini CLI:** read `skills/using-firstspirit-toolkit/references/gemini-tools.md`

Claude Code users: native tool names match the skill descriptions directly.
