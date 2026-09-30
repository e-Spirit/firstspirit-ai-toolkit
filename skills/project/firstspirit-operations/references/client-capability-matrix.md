# Client capability matrix — SiteArchitect × ContentCreator

One table for "does this work in the client my script runs in". Verification key:
**[jar]** package/signature on `fs-isolated-runtime.jar` FS 5.2.240208 · **[javadoc]** Access
API Javadoc · **[odfs]** ODFS page · **[observed]** toolkit field test 2026-09-11, single
session — reproduce before relying on it · **[verify]** inferred, not yet checked.

Which client you are in: `context.is(Env.WEBEDIT)` / `Env.PREVIEW`
(`firstspirit-scripting/references/script-contexts.md`).

## Operations (`OperationAgent.getOperation(TYPE)` — `null` when unavailable)

| Operation | SiteArchitect | ContentCreator | Evidence |
| --- | --- | --- | --- |
| `RequestOperation` | yes | yes | ODFS "Message Boxes" shows both [odfs] |
| `OpenElementDataFormOperation` | yes | yes — the ContentCreator implementation is `WebeditOpenElementDataFormOperation` | [observed] (error text names the class) |
| `OpenElementMetaFormOperation` | yes | yes | `ui.operations` package [verify] |
| `OpenMergeDialogOperation` | yes | ? | [verify] |
| `ShowFormDialogOperation` | yes | ? — `setUiStyle(Store.Type)` suggests a client-neutral form dialog | [verify] |
| `PreviewOperation` | yes ("the original client") | ? | Javadoc wording [javadoc] [verify] |
| `ClientScriptOperation` | **no** | yes | "only available in ContentCreator" [odfs]; package `webedit.server` [jar] |
| `ClientResourceOperation` | **no** | yes | package `webedit.server` [jar] [verify] |
| `SelectOptionOperation` | **no** | yes | package `webedit.server` [jar] [verify] |
| `TranslationOperation` | **no** | yes | package `webedit.server` [jar] [verify] |
| `NewSectionOperation`, `CropDialogOperation`, `ComparisonDialogOperation` | **no** | yes | package `webedit.server` [jar] [verify] |

Rule of thumb until the `?` cells are filled: `de.espirit.firstspirit.ui.operations.*` is
meant for both clients; `de.espirit.firstspirit.webedit.server.*` is ContentCreator only.
Always test `getOperation(...)` for `null`.

## Behaviour that differs

| Feature | SiteArchitect | ContentCreator | Evidence |
| --- | --- | --- | --- |
| HTML in a `RequestOperation` message | renders | **escaped** — tags print literally | [observed] |
| HTML injected via `ClientScriptOperation` (into the DOM, or a `WE_API` `Dialog`) | n/a (ContentCreator only) | **renders as markup** — the 2026-09-14 re-run displayed a thumbnail grid this way | [observed, 2026-09-14] |
| `RequestOperation.Kind.WARN` vs `INFO` | different icons | **identical** (exclamation icon) | [odfs] |
| `context.showForm()` (`GuiScriptContext`) | menu / context-menu scripts | **not** in an `FS_BUTTON` (`ClientScriptContext`) — same in SiteArchitect | [observed] |
| Deep link to a **medium** via `ClientUrlAgent` | `ClientType.JAVACLIENT` builder: any `IDProvider` | `ClientType.WEBEDIT` builder: **page references, site-store folders, datasets only** | [odfs] |
| Navigate the preview to a **medium** | element preview | `WE_API.Common.jumpTo({id, store:"MEDIASTORE"})` does **not** resolve | [observed] |
| Preview JavaScript object | `top.JC_API` (`reload`, `execute`) | `top.WE_API` (`Common`, `Dialog`, `Preview`, `Report`) | [odfs] — `firstspirit-contentcreator-extensions/references/jc-api.md` |
| Partial preview reload | no (`JC_API.reload()` only) | `WE_API.Preview.reload(element)` with `editorId` | [odfs] |
| `top.MPP_API` | after `window.onBrowserInjection` | immediately; the three listeners are ContentCreator-only | [odfs] [javadoc] |
| Run server code from preview JS | `JC_API.execute` — sync and async | `WE_API.Common.execute` — async only | [javadoc] |
| Parameters of `execute` reaching the script | untested | **not delivered** in one observation | [observed] — `firstspirit-contentcreator-extensions/references/does-not-work-in-contentcreator.md` |

## What each side owns

- Operation signatures and setters: `references/operations-catalogue.md` (this skill).
- ContentCreator-specific behaviour, the "does not work" list, `WE_API` / `JC_API` / `MPP_API`:
  `firstspirit-contentcreator-extensions`.
- Which `context` you have and `Env`: `firstspirit-scripting/references/script-contexts.md`.
