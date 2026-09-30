# Does not work in ContentCreator — type-compatible, semantically invalid

The calls below **compile, parse and run without error** — the parameter types are right, the
constants are valid — and then do nothing useful in ContentCreator. Neither a BeanShell parse
check nor a `javap` signature check can catch them; only this list can. Source: the toolkit
field test of 2026-09-11 on an internal FirstSpirit Cloud instance (ContentCreator; instance
and project are recorded in the skill's working docs, not here) unless tagged otherwise.
Everything **[observed]** is a single-session observation — reproduce before treating it as law.

| Call | Looks right because | What actually happens | Do instead |
| --- | --- | --- | --- |
| `top.WE_API.Common.jumpTo({"id": <mediaId>, "store": "MEDIASTORE"})` | `MEDIASTORE` is a valid `Store.Type`; the Javadoc even uses it as its example | The ContentCreator preview is **page-reference-centric**: navigating to a raw medium does not resolve — nothing is shown. [observed] | Jump to the `PageRef` (or dataset via `pageref` / `content2` / `template`) that displays the medium; open the medium's forms with `OpenElementMetaFormOperation` (`firstspirit-operations/references/operations-catalogue.md`). |
| `ClientUrlAgent.getBuilder(ClientType.WEBEDIT).element(medium).createUrl()` | `element(IDProvider)` accepts any element | ODFS: the ContentCreator URL builder "should be used only to create addresses pointing towards page references, site store folders and datasets. Any other use … is not supported." [odfs — Plug-In Development › Working With Store Elements] | Build the deep link to the `PageRef` / `SiteStoreFolder` / dataset; for a medium use the SiteArchitect builder (`ClientType.JAVACLIENT`) or open a form. |
| `OpenElementDataFormOperation.perform(medium)` | "open the element's form" reads as one operation | `perform` takes `pagestore.DataProvider`; a `Media` is not one → `bsh.ReflectError: Method perform(…MediaImpl) not found in class '…WebeditOpenElementDataFormOperation'` [observed] [jar] | `OpenElementMetaFormOperation.perform(IDProvider)` — and note it has **no `setLanguage`**. Full trap table: `firstspirit-operations` SKILL.md. |
| `top.WE_API.Common.execute("script:x", {"key": "value"}, cb)` — reading `key` in the script | ODFS: parameters "will be supplied to the script or the executable" | The script saw **no custom key**: `context.getProperties()` held only the standard set (`nodeName`, `currentTreeNode`, `currentStoreElement`, `storeName`, `sessionId`, `userName`, `nodeId`, `userId`, `userGroups`, `userService`) and `this.namespace.getVariableNames()` only the script's own locals. [observed — one FS version, one project; **reproduce before relying on it**] | Until reproduced: pass state through the element (`context` gives you the current preview element) or have the script read what it needs itself; keep the callback for the *result* direction, which did work. If you do reproduce it, record the FS version here. |
| HTML markup in a `RequestOperation` message (`perform("<b>…</b>")`) | Renders as HTML in SiteArchitect | **Escaped** in ContentCreator — the tags print literally. [observed] The escaping is specific to the message box: HTML pushed through **`ClientScriptOperation` renders as markup** (re-run 2026-09-14 showed a thumbnail grid that way). [observed] | Plain text in `RequestOperation`; for rich output use a `WE_API` `Dialog` (`references/we-api-dialog.md`) via `ClientScriptOperation`. |
| `RequestOperation.setKind(WARN)` vs `INFO` | Two different kinds | Render identically in ContentCreator (both the exclamation icon). [odfs — "Message Boxes"] | Put the severity in the title text if it matters. |
| `context.showForm()` from an `FS_BUTTON` script | The dialog pattern in the scripting docs uses it | `FS_BUTTON` binds `ClientScriptContext`; `showForm` is a `GuiScriptContext` method — not available. [observed] | `RequestOperation` (both clients) or `ShowFormDialogOperation` — `firstspirit-operations/references/operations-catalogue.md`; `firstspirit-scripting/references/script-contexts.md` for the context table. |

## What the report could not test

- `WE_API.Preview.reload(element)` on an element **without** an editor identifier — the ODFS
  rule says the whole page reloads; not yet observed.
- `WE_API` `Dialog.setContent(element)` [javadoc] with an element created in the **preview
  iframe's** document rather than `top.document` — see `references/we-api-dialog.md`.
- Whether `ClientScriptOperation.perform` returns `null` in SiteArchitect or `getOperation`
  already does — `references/client-script-operation.md`.

The full SiteArchitect × ContentCreator feature matrix lives with the operations skill:
`firstspirit-operations/references/client-capability-matrix.md`.
