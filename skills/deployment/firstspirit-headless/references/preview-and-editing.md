# Preview and on-page editing — OCM / TPP / SNAP

How an **external (headless) frontend** — a PWA/SPA rendering from CaaS — is
loaded *inside* ContentCreator's preview and gains click-to-edit / on-page
editing.

**The naming, straightened out:**
- **OCM** = **Omnichannel Manager** — the FirstSpirit *product/module* that
  provides real-time preview editing of headless applications in ContentCreator.
  Docs: <https://docs.crownpeak.com/firstspirit/ocm/> (documented v3.0). Its own
  docs point at the TPP/SNAP reference as the API.
- **TPP** = **ThirdPartyPreview** — the *mechanism*.
- **SNAP** = the *JavaScript bridge library* (`fs-tpp-api/snap.js`), exposing the
  global **`TPP_SNAP`** object. This is the actual developer API.
- **`live.js`** — OCM 3.0's frontend entry-point library
  (`https://<FS-HOST>/fs5webedit/live/live.js`) that establishes the connection;
  `TPP_SNAP` / `fs-tpp-api` is the API surface underneath it.

So: **OCM is the capability, TPP the mechanism, `TPP_SNAP` (via `snap.js` /
`live.js`) the API you write against.**

Sources:
[TPP/SNAP API](https://docs.e-spirit.com/tpp/snap/) (~v2.4.9) ·
[OCM](https://docs.crownpeak.com/firstspirit/ocm/) (v3.0).

> **Not headless?** For a page rendered by FirstSpirit's *own* integrated preview
> use the ODFS JS APIs (`WE_API`/`JC_API`/`MPP_API`) — see the last section; they
> are **not** the headless path. And building the actual Next.js preview wiring is
> the FirstSpirit PWA reference implementation (JavaScript Content API) (`PreviewProvider`, resolve route, preview-id builders).
> This file is the platform-level API reference.

---

## Architecture

The external frontend is loaded in ContentCreator; `snap.js` performs a
**handshake**, then communicates with ContentCreator via **`postMessage`**. Only
active inside ContentCreator (preview) — on the live site `TPP_SNAP` is absent /
disconnected, so decoration and editing are inert.

Detect the preview context with `TPP_SNAP.isConnected` (`Promise<boolean>`).

Script inclusion (the handshake origin secures it):
```html
<script src="path/to/fs-tpp-api/snap.js"
        data-firstspirit-origin="http://firstspirit:8000"></script>
<!-- load your app scripts AFTER this so window.TPP_SNAP exists -->
```

---

## `TPP_SNAP` API surface (static methods)

**Connection / mode**
- `isConnected` → `Promise<boolean>` · `isLegacyCC` → boolean
- `enableCaasMode(previewCollectionUrl, apiKey, options?)` — makes SNAP wait for
  updated content to land in the CaaS `preview.content` collection before firing
  rerender handlers (needs CaaS Platform v3.0.3+ and CaaS Connect v3.4.0+).

**Events** (register with the `on…` methods)
- `onInit(success, isLegacyCC)` — after the handshake completes.
- `onContentChange($node, previewId, content)` — content changed; `content` is a
  string, object, or `null` (deletion). **Return a defined value (e.g. `false`)
  to mark it handled and skip the fallback full rerender**; return nothing to let
  SNAP fall back to `onRerenderView`.
- `onRerenderView()` — full-view refresh fallback.
- `onNavigationChange(previewId)` — site structure/navigation changed.
- `onRequestPreviewElement(previewId)` — the editor asked to navigate to an
  element; your app should route to it.

**Preview element / navigation**
- `getPreviewElement()` → `Promise<string>` · `setPreviewElement(previewId)`
- `findPreviewNodes(previewId)` → `Promise<HTMLElement[]>` · `previewUrl()`

**Rendering / content**
- `renderElement(previewId)` · `triggerChange(previewId, content)` ·
  `triggerRerenderView()` · `getElementStatus(previewId, refresh)` → `Status`

**Dialogs**
- `showEditDialog(previewId)` · `showMetaDataDialog(previewId)` ·
  `showTranslationDialog(previewId, source, target)` ·
  `cropImage(previewId, resolution, result)` ·
  `showMessage(message, kind, title?)` · `showQuestion(message, title?)` →
  `Promise<boolean>`

**Creation / structural**
- `createPage(path, uid, template, options?)` · `createSection(previewId, options?)`
  · `createDataset(template, options?)` · `moveSection(source, target, options?)`
  · `deleteElement(previewId, showConfirmDialog)` · `toggleBookmark(previewId)`

**Workflows / execute**
- `startWorkflow(previewId, workflow)` · `processWorkflow(previewId, transition)`
- `execute(identifier, params, result)` → `Promise<any>` — run a FirstSpirit
  script/executable. Identifier form `script:<UID>` / `class:<FQCN>`
  (**(UNVERIFIED)** — prefix convention inferred from the sibling `JC_API`).

**Language**
- `getPreviewLanguage()` · `languages()` → `Promise<string[]>` · `locales()`

**Buttons** (custom decoration buttons)
- `registerButton(button, index)` · `overrideDefaultButton(name, overrides)`.
  Default buttons: `edit`, `translate`, `metadata`, `add-sibling-section`,
  `add-child-section`, `workflows`, `delete`, `crop-image`, `bookmark`.

**MPP** (Multi Perspective Preview wrappers — the headless way to reach MPP)
- `mppAddParameterizedListener` / `mppAddParameterListener` /
  `mppAddTimeParameterListener` · `mppGetParameter(name)` / `mppGetTimeParameter()`
  / `mppIsParameterized()` · `mppSetParameter(name, value)` /
  `mppSetTimeParameter(date)`

---

## Decoration attributes (click-to-edit)

- **`data-preview-id`** — binds a DOM node to FirstSpirit content; SNAP
  auto-decorates it with borders + action buttons.
- **`data-on-tpp-change`** — inline change-handler string for that node.
- **`data-tpp-context-image-resolution`** — resolution used for crop actions.
- Script-tag: **`data-firstspirit-origin`** (handshake security).

**`data-preview-id` value forms.** SNAP docs and OCM 3.0 docs describe them
slightly differently — verify against the version in play:
- Element preview id (page/section/dataset): UUID `+ .language`, e.g.
  `8326527a-...b660249.de_DE`.
- Inline editing of an input component: `#INPUT_COMPONENT_NAME`.
- Nested (FS_CATALOG/FS_INDEX): `#PARENT_COMPONENT_NAME` + index form `#0`.
- OCM 3.0 slash forms:
  `{sectionPreviewId}/{editorName}[/{catalogCardIndex}[/{catalogCardEditorName}]]`
  — e.g. `...de_DE/st_catalog/0` (card index may be a UUID instead of an ordinal).
- Custom: `custom:action:path:name`.

> The FirstSpirit PWA reference implementation (JavaScript Content API) is prescriptive here (always build ids with
> `buildPreviewId` / `buildCatalogItemPreviewId`, locale as `en_GB` not `EN`,
> catalog separator `/`). Defer to it for the consumer rules.

---

## Common flows

```javascript
// init + CaaS mode
TPP_SNAP.onInit(async (success) => {
  if (!success) return;
  TPP_SNAP.enableCaasMode("https://caas-host/<tenant>/<uuid>.preview.content", "<api-key>");
});

// content change → in-place update, else full rerender
TPP_SNAP.onContentChange(($node, previewId, content) => {
  if ($node.matches('.content') && content !== null) { $node.innerHTML = content; return false; }
});
TPP_SNAP.onRerenderView(() => app.rerender());

// editor navigates to an element
TPP_SNAP.onRequestPreviewElement(async (previewId) => {
  const path = previewIdToPath(previewId);
  if (path) return route(path);
});

// structural + workflow + dialogs
TPP_SNAP.createSection(previewId, { template: 'sectionTemplateUid', name: 'Section', index: 0 });
TPP_SNAP.startWorkflow(previewId, workflowUid);
TPP_SNAP.showMessage("Saved", "info", "Confirmation");
```

Rerender flow: an edit → `onContentChange` (with new `content`) → if the handler
returns a value that node updates in place, otherwise SNAP falls back to
`onRerenderView`. `enableCaasMode` makes SNAP wait for the fresh CaaS document
first, so the app re-fetches current data rather than stale content.

### Supporting objects
- **`Status`** (`getElementStatus`): `{ previewId, elementType
  (PageRef|Page|Section|GCAPage|GCASection|Dataset|SectionReference|Media|Body),
  custom, workflows, permissions { canChange, canDelete, canMetaChange,
  canAppendLeaf } }`.
- **`ButtonScope`** (button callbacks): `{ $node, $button, previewId, status,
  language }`; callback set: `isVisible`, `isEnabled`, `getIcon`, `getLabel`,
  `getItems`, `beforeExecute`, `execute`, `afterExecute`.

---

## OCM button data-attributes (declarative)

OCM 3.0 also exposes button behaviour declaratively via data-attributes and
standard executables:
- `data-button-script-onclick` / `data-button-script-ondrop` — script/executable
  to run (e.g. `class:NewSection`).
- `data-button-script-params` — JSON init params for the script context.
- Standard executables: **`NewSection`** (create a section), **`NewListEntry`**
  (create a catalog entry). Example:
  ```html
  <div data-button-script-onclick="class:NewSection"
       data-button-script-ondrop="class:NewSection"
       data-button-script-params='{"page":"e86e62b0-...de_DE","body":"main"}'>Create Section</div>
  ```

---

## Adjacent: ODFS JavaScript APIs — *not* the headless path

The ODFS "JavaScript APIs" index
(<https://docs.e-spirit.com/odfs/template-develo/javascript-apis/index.html>)
documents three APIs for HTML shown inside **FirstSpirit's own integrated
previews** (SiteArchitect's embedded browser, ContentCreator). Listed here so you
reach for TPP/SNAP instead of these in a headless project:

- **`top.WE_API`** (ContentCreator) — `Common`, `Dialog`, `Preview`
  (`reload()`, `reload(element)`, element reload listener, `repaint()`,
  `rescan(element)`, `getWindow()`), `Report`. Controls ContentCreator's own UI.
  **Headless: not applicable.** *(Some ODFS method pages 404'd at research time;
  `WE_API.Common` method names not retrieved — **(UNVERIFIED)**.)*
- **`top.JC_API`** (SiteArchitect embedded preview) — `reload()`,
  `execute("script:<UID>" | "class:<FQCN>")`, `execute(exec, params, callback)`.
  **Headless: not applicable.**
- **`top.MPP_API`** (Multi Perspective Preview) — `isParameterized()`,
  `get/setTimeParameter`, `get/setParameter(name[, value])`; does not expose the
  viewport. **Headless: partial** — MPP time/role parameters reach a headless
  frontend via the **`TPP_SNAP.mpp*`** wrappers above, not `MPP_API` directly.

Preview URL configuration, PreviewRenderingPlugin selection, the preview
ProjectApp, and OCM 2.x migration are parked →
[for-later-configuration-and-install.md](for-later-configuration-and-install.md).
