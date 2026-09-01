---
name: using-firstspirit-toolkit
description: "Use when starting any session that involves FirstSpirit CMS work — establishes what skills are available and when to invoke them."
---

# FirstSpirit AI Toolkit

You have the FirstSpirit AI Toolkit loaded. Before responding or taking action on any FirstSpirit task, check whether a more specific skill applies.

## Rule

If there is even a small chance a skill applies to your task, you MUST invoke it before acting. Check for skills before clarifying questions, before exploring the codebase, before writing code.

## Available Skills

### Content (`skills/content/`)
- **manage-content** — Use when reading, writing, querying, or restructuring content in FirstSpirit content stores or datasets.

### Templating (`skills/templating/`)
- **design-templates** — Use when creating or modifying FirstSpirit page templates, section templates, or link templates.

### Project (`skills/project/`)
- **setup-project** — Use when configuring a new FirstSpirit project, modifying project settings, or managing users and groups.

### Deployment (`skills/deployment/`)
- **publish-content** — Use when triggering generation runs, publishing content to delivery, or managing release workflows.

### Diagnostics (`skills/diagnostics/`)
- **diagnose-project** — Use when troubleshooting FirstSpirit project issues, checking project health, or analysing logs.

## Platform Tool Mappings

If you are running on a harness listed below, read the corresponding reference for how abstract operations map to that harness's real tool names:

- **Codex:** read `skills/using-firstspirit-toolkit/references/codex-tools.md`
- **Cursor:** read `skills/using-firstspirit-toolkit/references/cursor-tools.md`
- **Gemini CLI:** read `skills/using-firstspirit-toolkit/references/gemini-tools.md`

Claude Code users: native tool names match the skill descriptions directly.
