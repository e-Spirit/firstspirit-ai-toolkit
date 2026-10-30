# Omnichannel Manager (OCM 3.0) and the older TPP module

Sources `[odfs]`, read 2026-10-13: *OCM 3.0* documentation; *Omnichannel Manager* (the TPP module) 2.4.9, 21.05.2026.
The front end side (`live.js`, `data-preview-id`, `TPP_SNAP`): `firstspirit-headless` (`firstspirit-headless/references/preview-and-editing.md`).

## Which one to install

**New installs use OCM 3.0.** The TPP function is **part of ContentCreator** and there is **no module to install** `[odfs]`. The 2.x documentation is for the old module `fs-tpp-api-*.fsm`, which is deprecated but may still run in older projects.

| | OCM 2.x (module) | OCM 3.0 `[odfs]` |
|---|---|---|
| Server | module `fs-tpp-api-[version].fsm` plus web component *FirstSpirit ThirdPartyPreview WebApp* on the ContentCreator web app; FirstSpirit 5.2R16, Java 8 | nothing; the web component of 2.x **can be deleted** on migration |
| Front end library | `snap.js` delivered with the module or from npm (`fs-tpp-api`); keep the version compatible | `https://<host>/fs5webedit/live/live.js`, served by the ContentCreator itself |
| CaaS | depends on CaaS Connect (CaaS mode) | no dependency; templates render the preview by default |
| Standard functions | `overrideDefaultButton` | hide, extend or exchange them with TailoredUI |
| PageRef previewIds | edit action also on page references | use the page's id, as is standard |

## Steps for OCM 3.0 `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Enter the preview application's URL **with protocol** in *External Preview URL*. Empty means ContentCreator's own preview | Project properties, ContentCreator settings | the app shows in the preview area |
| 2 | The application must allow running in an iFrame (X-Frame-Options); use the same protocol as ContentCreator or `//` links, or expect a harmless console warning | the frontend host | |
| 3 | Include `live.js` from the ContentCreator's host and mark HTML elements with `data-preview-id` | the front end | an editable frame on mouse-over |
| 4 | Project component **CXT ContentCreator: Preview Configuration ProjectApp**: choose a *PreviewRenderingPlugin*; for CaaS projects the **CaaS Connect Preview Rendering Plugin**. Optional: more preview applications per folder (name, URL, folder) | Project properties, Project components | |
| 5 | Delete in ContentCreator needs the **delete workflow** set under *Options* (`firstspirit-installation` `basicworkflows.md` step 2.6; `firstspirit-workflow-development` on what it does) | Project properties, Options | |

**Step 4 is the one that is missed.** Without a plugin the preview content is made by the FirstSpirit templates; in a project without templates (CaaS Connect, zero templating) that gives **empty strings** for `renderElement` and `onContentChange` `[odfs]`. The plugin comes from the CaaS Connect Web App component (`caas-connect.md`, step 3).

## Limits `[odfs]`

- Historical versions are not shown for external applications that use CaaS (multi-perspective preview, project history).
- In 2.x, menu entries that TPP cannot support are hidden; drag and drop of desktop files into the app is not available.
- Workflows work in TPP/OCM; they apply to structure or content pages only. The status provider and workflow list need a section tied to the FirstSpirit object (see `firstspirit-workflow-development` `not-offered.md`, *Empty or grey status*).

## Updating a 2.x module that is still in use `[odfs]`

*Omnichannel Manager release notes* 2.4.9 (21.05.2026), read 2026-10-13; the entries that matter for an install. OCM 3.0 has no release notes of its own because it ships with ContentCreator (the FirstSpirit release notes carry it) `[verify]`.

- **2.4.9 (breaking):** the **CaaS Connect web component** (available from CaaS Connect 3.94.3) must be installed on the FirstSpirit server. When updating, **install or update CaaS Connect first, then the new TPP version.** The release also fixes a class-loading conflict (`NoSuchMethodError`) when TPP and CaaS Connect were installed side by side: TPP no longer bundles its own copy of the CaaS Connect service.
- **2.4.8:** web component declared Jakarta-compatible (needed for Tomcat 10 and later).
- **2.3.5:** support for the old CaaS Zero module removed. **2.3.4:** works with CaaS Platform 8 or later. **1.2.27:** works with CaaS Connect above 3.0.
- **2.0.0 (breaking):** the old library `fs-tpp-api.js` was removed; use the SNAP API (`snap.js`, the npm package's entry point).
- **1.2.29:** editing boxes resize with their element and need a browser with `ResizeObserver`. **1.2.15:** no `blob:` source needed in a Content Security Policy any more.

## Migrating 2.x to 3.0 `[odfs]`

Delete the *ThirdPartyPreview WebApp* component, load `live.js` instead of `snap.js`, set a PreviewRenderingPlugin if the project relied on CaaS-based preview, move to TailoredUI for standard-function changes, and change PageRef previewIds. Whether the old module can stay installed side by side while a project migrates is `[verify]`.
