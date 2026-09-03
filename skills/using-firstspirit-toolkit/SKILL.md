---
name: using-firstspirit-toolkit
description: "Use when starting any session that involves FirstSpirit CMS work — establishes what skills are available and when to invoke them."
---

# FirstSpirit AI Toolkit

## First: is this FirstSpirit work?

This toolkit is loaded at session start. Depending on the assistant, it may load
only inside a FirstSpirit project, or in **every** project — so before you use any
of it, decide whether the current task actually involves FirstSpirit CMS.

- **Not FirstSpirit work?** Ignore this file and the skills below entirely. Do not
  mention them, and do not let them influence your answer — respond as if the
  toolkit were not loaded.
- **FirstSpirit work?** Apply the rule below before acting.

## Rule

When the task involves FirstSpirit, check whether one of the skills below fits before you act, and invoke the most specific match rather than working from general knowledge — FirstSpirit's APIs and conventions are easy to get subtly wrong from memory. You do not need to invoke a skill before asking a clarifying question or reading the code to understand the task; do it before you write or change FirstSpirit code, templates, or configuration.

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
