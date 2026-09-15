---
name: firstspirit-scripting
description: >-
  Concrete lookup reference for FirstSpirit scripting with BeanShell: the script
  types and their bound `context` objects (menu, context-menu, workflow,
  Content2/dataset, FS_BUTTON, template/generation, schedule, PermissionService),
  BeanShell language essentials, logging and debugging, and the safe Access-API
  patterns (lock/save/unlock, iteration, store navigation, form data,
  transitions). Use this skill whenever you write, review, or debug a FirstSpirit
  script — for example "which context object do I get in a workflow script",
  "how do I lock and save an element in BeanShell", "how do I log from a script",
  "how do I read a form field", "how do I call a script from a template with
  $CMS_RENDER$", or "how do I open a dialog / an element's data form from a client
  script" (operations via OperationAgent). Also use it whenever the user asks to write a BeanShell (or
  "Bean Shell") script, even without naming FirstSpirit, and for `.bsh` script
  files — outside FirstSpirit, BeanShell is almost never used. Pair with
  the FirstSpirit ODFS documentation for deep API lookup and firstspirit-templating-reference for
  template-language syntax.
metadata:
  source-commit: 3bec7d0
  published: 2026-09-15
  toolkit-version: 0.2.0
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit scripting reference

Fast, factual lookup for **FirstSpirit scripting with BeanShell**. Where
the FirstSpirit ODFS documentation is the broad knowledge base (full API, docs, tutorials),
`firstspirit-templating-reference` covers template-language *output* syntax, and
`firstspirit-api-reference` catalogues the Access-API *object model* (stores,
elements, agents), this skill answers the concrete questions that come up while
writing or reviewing a script: which `context` object you get, the BeanShell
syntax and conventions, how to log, and the safe patterns for reading and
modifying content.

> **Companion skill:** for the objects you manipulate *inside* a script — store
> element interfaces, `IDProvider`/`FormData`, the `SpecialistsBroker` agents,
> `QueryAgent` syntax — use `firstspirit-api-reference`. This skill owns the
> *script* layer (contexts, BeanShell, logging); that one owns the *object* layer.

## Before you script — check first

BeanShell scripts are a **lightweight** way to add behaviour. Before writing one:

1. **Does FirstSpirit already do this?** A standard feature or existing template
   function is always preferable to a script.
2. **Is this long-term, load-bearing behaviour?** If yes, implement it as a
   **module** (executable / plugin), not a script. Scripts are best for
   automation of editorial steps, migrations, and gluing external systems.

## How to use this skill

- **Look up, don't lecture.** Answer the specific question with the exact context
  object, method, or pattern — then stop. Point into `references/` for the full
  catalogue rather than restating it inline.
- **Settle the script *type* first — it decides the `context`.** The variable
  `context` is always bound, but its concrete interface (and therefore which
  methods exist) depends on *where* the script runs. See
  [references/script-contexts.md](references/script-contexts.md).
- **Settle client and mode when it matters.** Some behaviour differs between
  SiteArchitect and ContentCreator, and between preview and release generation.
  Note which applies when it changes the answer.
- **Defer design/API depth.** For full Access-API signatures, hand off to
  the FirstSpirit ODFS documentation; for form (GOM) and template-output syntax, use
  `firstspirit-templating-reference`.

## Quick answers

- **Script header:** first line `//!BeanShell` (case-insensitive). Put all
  `import` statements directly under it.
- **The bound variable is `context`** — its type depends on the script type (see
  contexts table). In a *template/generation* script the generation context is
  bound as `gc` and the return value is set via `result.setValue(...)`.
- **Logging:** `context.logInfo/logDebug/logWarning/logError(msg)` — never `print()`
  in production scripts (`print()` is for the BeanShell console).
- **Modify content:** always `setLock(true,false)` → change → `save(...)` →
  `setLock(false,false)` in a `try/finally`. See
  [references/common-patterns.md](references/common-patterns.md).

## References

Loaded on demand — read the file that matches the question.

| File | Covers | Read when |
| --- | --- | --- |
| [references/script-contexts.md](references/script-contexts.md) | Every script type, where it runs, and the concrete `context` interface it binds — `GuiScriptContext`, `WorkflowScriptContext`, `Content2ScriptContext`, `ClientScriptContext` (FS_BUTTON), `GenerationScriptContext`, `ScheduleContext`, `PermissionServiceScriptContext` — with their key methods | You need to know which object `context` is, or which methods are available in a given script type |
| [references/beanshell-language.md](references/beanshell-language.md) | BeanShell basics: `//!BeanShell` header, dynamic typing, imports, the convenience methods (`print`, `show`, `getMethods`, `javap`), and the BeanShell console | You need the language syntax, an import rule, or a console/debug helper |
| [references/logging-and-debugging.md](references/logging-and-debugging.md) | The four log levels, `print()` vs logging, extended logging, and how to find/trace errors | You need to emit log output or debug a failing script |
| [references/common-patterns.md](references/common-patterns.md) | Copy-paste Access-API patterns: lock/save/unlock, safe iteration, store navigation via `SpecialistsBroker`/`UserService`, reading `FormData`, FS_BUTTON variables, `$CMS_RENDER(script:…)$` (`gc`/`result`), workflow `doTransition`, schedule variables, `Executable` classes | You need working code for a concrete scripting task |
| [references/real-world.md](references/real-world.md) | Fuller task-shaped examples (DTA-derived): the IDE-to-script workflow, change a field value, create page+section, dynamic form dialog (`FormsAgent` + `ShowFormDialogOperation`), read a data source (iterate + `de.espirit.or` query), trigger a schedule | You want an end-to-end worked example, not just a snippet |
| [references/conventions.md](references/conventions.md) | Code style (blocks, indentation, comments) and the Dos & Don'ts (imports in header, correct locking, iterators over lists, log instead of print, script-vs-module) | You are writing or reviewing a script for maintainability |

---

*Sources: FirstSpirit online documentation (Template development → Scripting) and
the FirstSpirit Access API, as bundled in the FirstSpirit ODFS documentation.*

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
