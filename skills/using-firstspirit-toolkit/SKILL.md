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
- **firstspirit-templating-reference** _(beta)_ — Use when you need the exact FirstSpirit template syntax, the right GOM input component, the datatype a component yields and how to read it in an output channel, a validation/visibility rule, a database-schema fact, or whether something is deprecated.
  Covers: `$CMS_*$` tags and system objects (`#global`, `#nav`, `#row`), string operations and escaping, the Navigation and PageGroup header functions, content projection, every `CMS_INPUT_*` / `FS_*` component with its datatype, database schemas (column types and which component maps onto which, foreign keys, the KEY column, queries, Remote Data, Entity vs Dataset), rules (`Ruleset.xml`), identifier and casing rules, deprecated → current components, how to read `GomSource.xml` / `ChannelSource` files.
- **firstspirit-template-design** _(beta)_ — Use when creating, generating, reviewing or auditing FirstSpirit templates and forms — it holds the design judgement (what a good template looks like, naming, editorial usability, headless/CaaS shape, content modelling), while firstspirit-templating-reference holds the syntax facts.
  Covers: 14 design principles with review checklist, input-component choice by editorial intent, naming and prefix conventions, headless/CaaS and ContentCreator specifics, multi-language handling, database schema modelling (relations vs columns, keys, build and delete order), a template-set documentation pattern used as the sign-off plan before programmatic writes.

### Project (`skills/project/`)
- **firstspirit-api-reference** _(beta)_ — Use when you need to know which Access API interface a store element has, how the stores nest, which agent yields a store or service, how to load an element by UID, or how to write an `fs` query — the object-model map for scripts and modules.
  Covers: The store and element hierarchy as text trees, `SpecialistsBroker` and the agents (`StoreAgent`, `QueryAgent`, `OperationAgent`, `BrokerAgent` …), `requestSpecialist` vs `requireSpecialist`, loading elements by UID and type, form-value access (`FormData`, `FormField`), the `fs` query language, lock/save/unlock and release rationale.
- **firstspirit-scripting** _(beta)_ — Use when writing, reviewing or debugging a FirstSpirit BeanShell script — which `context` object a script type gets, BeanShell syntax and its traps, logging, and safe Access-API patterns for reading and writing elements and datasets.
  Covers: Script types and their context hierarchy (`BaseContext`, `ProjectScriptContext`, `ClientScriptContext`, `GenerationContext` …) as a diagram, BeanShell language notes, logging and debugging, conventions, common patterns (elements, form data, datasets that persist only changed values, relation lists mutated in place), real-world script shapes.
- **firstspirit-rest-api** _(beta)_ — Use when performing CMS operations through the FirstSpirit REST API — creating or editing templates, managing pages and sections, writing form-field values, uploading media, running scripts, or searching content — and when a call answers 4xx/5xx and you need the meaning.
  Covers: Endpoint groups for content management, content templates (GOM/form creation and the section-id drift between module versions), content catalogue and search, Global Content Areas, media upload rules, language-path PATCH semantics, the error-code table (403, 409, 410, 413, 429) and the write-order (dependencies first) it forces.
- **firstspirit-operations** _(beta)_ — Use when a script or module must open a dialog, open an element's form or meta form, show a message, or trigger another client action through `OperationAgent` — and before writing any `perform(...)` call, because the parameter type is where these go wrong.
  Covers: Catalogue of the SiteArchitect and ContentCreator operations (`RequestOperation`, `OpenElementDataFormOperation`, `OpenElementMetaFormOperation`, `ShowFormDialogOperation`, `SelectOptionOperation`, `PreviewOperation`, `ClientScriptOperation` and more) with the exact `perform` parameter type, the configuration setters each one really has, which client it runs in, and the `ReflectError` / wrong-argument traps.
- **firstspirit-contentcreator-extensions** _(beta)_ — Use when JavaScript in a ContentCreator preview or action must talk to the client, when a BeanShell script or `Executable` must run JavaScript in the editor's browser, or when a module adds its own ContentCreator UI (toolbar button, status note, timeline marker, translation provider).
  Covers: The `WE_API` JavaScript API (`Common`, `Dialog`, `Preview`, `Report`, `FSID`), preview reload/rescan/repaint, report shortcodes and filters, `FS_INDEX` and status hotspots, the server→browser bridges `ClientScriptOperation` and `ClientResourceOperation`, a "does not work in ContentCreator" list, `MPP_API` and `JC_API` for SiteArchitect previews, the ContentCreator plug-in interfaces (`WebeditToolbarActionsItemsPlugin`, `WebeditInlineEditItemsPlugin`, `WebeditStatusNotePlugin`, `WebeditElementStatusProviderPlugin`, timeline providers, `TranslationPlugin`) with their `@WebAppComponent`.

### Deployment (`skills/deployment/`)
- **firstspirit-external-sync-export** _(beta)_ — Use when exporting or importing a FirstSpirit project with fs-cli (FSDevTools / external synchronisation) — installation, connection and authentication, the export and import commands and their options, and what the error messages mean.
  Covers: fs-cli setup, connection modes and credentials handling, `export` and `import` commands with filters and the resulting file layout, external-sync file names, troubleshooting of the common failures.

### Diagnostics (`skills/diagnostics/`)
- **firstspirit-verify-api-contracts** — Use when you need to know what a FirstSpirit API actually returns before writing a module or script against it — measuring signatures and live behaviour against a running server with `javap`, a compiled probe, the Access API, or a throwaway schedule-task script.

## Platform Tool Mappings

If you are running on a harness listed below, read the corresponding reference for how abstract operations map to that harness's real tool names:

- **Codex:** read `skills/using-firstspirit-toolkit/references/codex-tools.md`
- **Cursor:** read `skills/using-firstspirit-toolkit/references/cursor-tools.md`
- **Gemini CLI:** read `skills/using-firstspirit-toolkit/references/gemini-tools.md`
- **GitHub Copilot:** read `skills/using-firstspirit-toolkit/references/copilot-tools.md`

Claude Code users: native tool names match the skill descriptions directly.
