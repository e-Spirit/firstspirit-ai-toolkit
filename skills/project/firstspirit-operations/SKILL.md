---
name: firstspirit-operations
description: >-
  Catalogue of FirstSpirit client operations obtained through OperationAgent: RequestOperation dialogs, OpenElementDataFormOperation / OpenElementMetaFormOperation, OpenMergeDialogOperation, PreviewOperation, ShowFormDialogOperation, SelectOptionOperation, ClientScriptOperation and more — each with the EXACT perform(...) parameter type, the configuration setters it really has, and the client (SiteArchitect / ContentCreator) it runs in. Use whenever a script or module needs to open a dialog, open an element's form, show a message or trigger a client action — e.g. "show a yes/no question from an FS_BUTTON", "open the data form of a page from a script", "why does perform(media) throw ReflectError", "which operation opens the meta form". First rule: check the perform parameter type before writing the call — a plausible operation name is not enough. Pair with firstspirit-scripting (your context object) and firstspirit-api-reference (the element types you pass in).
metadata:
  source-commit: "239a7e2"
  published: "2026-09-30"
  toolkit-version: "0.3.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit operations (`OperationAgent`)

> **First pass (2026-09-14) — SME review pending.** Signatures marked **[jar]** in the
> catalogue are verified by `javap` against `fs-isolated-runtime.jar` (FS 5.2.240208);
> **[javadoc]** = FirstSpirit Access API Javadoc; **[observed]** = toolkit field test
> 2026-09-11, single session; **[verify]** = not yet confirmed. Client-availability cells
> are `[verify]` until checked on a live install.

Client operations are how a script or plugin drives the **UI** of SiteArchitect or
ContentCreator — dialogs, opening an element's form, previews, client-side actions.
They are the layer the reference skills only name in passing.

## The one rule

**Verify the `perform(...)` parameter type before you write the call.** Operation names are
plausible and read well; their `perform` signatures are strict and differ in ways the name
does not reveal. BeanShell resolves the overload at runtime, so a wrong type is not a compile
error — it is a `bsh.ReflectError: Method perform(…) not found` at click time.

The canonical trap:

| Operation | `perform` takes | Accepts a `Media`? | Has `setLanguage`? |
| --- | --- | --- | --- |
| `OpenElementDataFormOperation` | `pagestore.DataProvider` | **No** — page-store data elements only | **yes** |
| `OpenElementMetaFormOperation` | `store.IDProvider` | **yes** — any element with meta data | **no** |

Swapping the operation without checking fails one line earlier on `setLanguage`. Both facts
are visible only in the signature — which is why this skill lists them.

## How you obtain an operation

Always through the agent, never as a specialist:

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
import de.espirit.firstspirit.ui.operations.RequestOperation;

ops = context.requireSpecialist(OperationAgent.TYPE);   // context is a SpecialistsBroker
req = ops.getOperation(RequestOperation.TYPE);           // null if unavailable in this client
```

`context.requireSpecialist(<Operation>.TYPE)` — as one ODFS page writes it — does **not**
work: operations are not specialists. (That same page names a class that does not exist,
`OpenElementDataFormDialogOperation`; see the negatives table in
`firstspirit-scripting/references/common-patterns.md`.)

`getOperation` returns `null` when the operation is not available in the current client — a
server-side or generation context has no UI. Which context you are in decides what you can
use: see `firstspirit-scripting/references/script-contexts.md`.

## The catalogue

`references/operations-catalogue.md` — per operation: package · `TYPE` · **exact `perform`
signature** · configuration setters · return value · known traps. Jar-verified now:
`RequestOperation`, `OpenElementDataFormOperation`, `OpenElementMetaFormOperation`,
`ShowFormDialogOperation`, `PreviewOperation`, and the ContentCreator-only
`ClientScriptOperation`, `ClientResourceOperation`, `SelectOptionOperation`,
`TranslationOperation`, `NewSectionOperation`, `CropDialogOperation`, `ComparisonDialogOperation`.

A second shape to know besides the `DataProvider`/`IDProvider` trap: several operations take
**no `perform` argument** — you configure with setters, then call `perform()`
(`PreviewOperation`, `SelectOptionOperation`, `TranslationOperation`). Read the row.

## Which client — the matrix

`references/client-capability-matrix.md` — operation × SiteArchitect × ContentCreator, plus
the behaviour that differs (HTML escaped in ContentCreator message boxes, `WARN` = `INFO`
icon, media deep links and `jumpTo` to a medium, `showForm` availability). Rule of thumb:
`ui.operations.*` is for both clients, `webedit.server.*` is ContentCreator only, and
`getOperation` returns `null` where an operation is unavailable — test for it.

## Not covered here

- What a `DataProvider`, `IDProvider`, `Media` or `FormData` *is*:
  `firstspirit-api-reference/references/object-model.md`.
- ContentCreator-only client extensions — the `WE_API` JavaScript API and
  `ClientScriptOperation` (sync vs async, the callback rule) — are owned by
  `firstspirit-contentcreator-extensions` (`firstspirit-contentcreator-extensions/references/client-script-operation.md`).
  This catalogue keeps signatures only.

<!-- feedback-footer:v1 -->
## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
