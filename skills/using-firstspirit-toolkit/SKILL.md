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

### Templating (`skills/templating/`)
- **firstspirit-templating-reference** — Use when you need exact FirstSpirit template syntax, the right GOM input component, what datatype a component produces, how to access it in an output channel, or whether something is deprecated.

### Project (`skills/project/`)
- **firstspirit-api-reference** — Use when you need to know which interface a store element has, how the stores nest, which agent yields a store or service, how to load an element by UID, or how to write an `fs` query.
- **firstspirit-rest-api** — Use when performing CMS operations via the FirstSpirit REST API — creating/editing templates, managing pages and sections, writing form field values, uploading media, or searching content.
- **firstspirit-scripting** — Use when writing, reviewing, or debugging a FirstSpirit BeanShell script — covers script types and their `context` objects, BeanShell syntax, logging, and safe Access-API patterns.

### Deployment (`skills/deployment/`)
- **firstspirit-external-sync-export** — Use when exporting or importing a FirstSpirit project via fs-cli (FSDevTools / external synchronisation) — covers installation, connection, authentication, export/import commands, and troubleshooting.

### Diagnostics (`skills/diagnostics/`)
- **firstspirit-verify-api-contracts** — Use when you need to know what a FirstSpirit API actually returns before writing a module or script against it — measuring signatures and live behaviour against a running server with `javap`, a compiled probe, the Access API, or a throwaway schedule-task script.

## Platform Tool Mappings

If you are running on a harness listed below, read the corresponding reference for how abstract operations map to that harness's real tool names:

- **Codex:** read `skills/using-firstspirit-toolkit/references/codex-tools.md`
- **Cursor:** read `skills/using-firstspirit-toolkit/references/cursor-tools.md`
- **Gemini CLI:** read `skills/using-firstspirit-toolkit/references/gemini-tools.md`
- **GitHub Copilot:** read `skills/using-firstspirit-toolkit/references/copilot-tools.md`

Claude Code users: native tool names match the skill descriptions directly.
