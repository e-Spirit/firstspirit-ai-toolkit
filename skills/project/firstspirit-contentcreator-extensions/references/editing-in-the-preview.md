# Editing in the preview: `editorId(...)` parameters, InEdit, metadata, drag-and-drop, cropping

How a template makes the preview editable in ContentCreator (EasyEdit, InEdit, LiveEdit) and
highlighted in SiteArchitect (Content Highlighting). All **[odfs]** — *Template development ›
Content Highlighting and EasyEdit › Use in projects*, FirstSpirit 2026.5; Java types
**[jar]** (`fs-isolated-runtime` 5.2.261011). Not re-tested live **[verify]**.
Dynamic reload from JavaScript: `we-api-preview.md`. Where `editorId` belongs in a template
set, and why it is the default: `firstspirit-template-design/references/output-conventions.md`.

## The principle

An **editor identifier** is rendered into an HTML element by `editorId(...)`; the element can then
be highlighted (SiteArchitect) or edited (ContentCreator, LiveEdit). With no parameter the
current context (section, page) is used. One template change serves SiteArchitect and
ContentCreator alike. Put the call **inside the opening tag of a block element** (`<h3 …>`,
`<div …>`) or on `<img>`; an element-specific call such as the one on an image is allowed:

```
<h3$CMS_VALUE(editorId(editorName:"st_headline"))$>
<div$CMS_VALUE(editorId())$>
<img src="$CMS_REF(st_picture)$" $CMS_VALUE(editorId(editorName:"st_picture"))$ />
```

Highlighting needs content: an empty input component cannot be highlighted, so guard the
output with `$CMS_IF(!IDENTIFIER.isEmpty)$`. [odfs]

## Parameters

| Parameter | Meaning | Scope |
| --- | --- | --- |
| `editorName` | UID of the input component | both |
| `language` | Language the form opens in (`"FR"` or a language object such as `#global.getLanguage("FR")`); default is the current language | ContentCreator |
| `entity` | An entity object, for database content not in a content projection (for example from `contentSelect`) | both |
| `template` | A table template (object or UID string, `schema.gallery`) | both |
| `view` | A data source (`Content2` object or UID string) | both |
| `element` | Any `IDProvider`: a global content area, `#global.gca("…")`, a content area `#global.page.body("…")`, a medium, a page, `#nav.ref` | both |
| `target` | A FirstSpirit object as `element`, but also non-`IDProvider` objects; needed when the target cannot be derived from the generation context, for example **nested components** (the `FormDataList` item of an `FS_CATALOG` loop) or identifying a dataset | both |
| `previewRulesEvaluation` | `false` switches rule evaluation off **for the preview generation** of this element (default `true`). Use it when rule evaluation makes the preview slow. The cost: rule violations in that element no longer show in the page status in ContentCreator; forms still evaluate rules normally. Datasets from table templates never show rule violations in the preview anyway. | ContentCreator |
| `resolution` | Switches the image cropping on for that resolution (reference name), or several as a list `["A","B"]`; the list order is the order in the cropping dialog. `FS_REFERENCE` only. | ContentCreator |
| `reloadPreview` | `true` reloads the whole page after a change in a sub-area (default: only the area is swapped, which misses changes outside it). Has no effect if `reloadElement` is a valid HTML ID. | ContentCreator |
| `reloadElement` | ID of the HTML element to reload after editing, instead of the one carrying the identifier | ContentCreator |
| `json` | `true` returns a JSON object instead of an HTML fragment; needed for `NewListEntry` on `FS_CATALOG` / `FS_INDEX`; **JavaScript only**, in HTML output it produces invalid HTML (`customising-contentcreator.md`) | ContentCreator |
| `meta` | `true` opens the **metadata** form instead of the content form (InEdit; off by default) | ContentCreator |
| `externalReference` | Identifier of one external reference stored in an `FS_INDEX` that does **not** use the `DatasetDataAccessPlugin` (for example `FirstSpiritFragmentAccess`) | ContentCreator |

## Patterns by object

| Object | Template change |
| --- | --- |
| Input component | `editorId(editorName:"st_headline")` in the element that shows it |
| Multi-value component (`FS_CATALOG`) | In the `$CMS_FOR(_card, st_list)$` loop: `<li$CMS_VALUE(editorId(target:_card))$>` |
| `FS_INDEX` with `DatasetDataAccessPlugin` | `editorId(element:_formData, view:"mycontent2")` in the loop; `view` is the jump target |
| `FS_INDEX` without it | outer element `editorId(editorName:"fs_index")`, then per item `editorId(editorName:"fs_index", externalReference: objectId)` over `fs_index.identifiers` |
| Section / page | `<div$CMS_VALUE(editorId())$>` around the whole output |
| Content area | `editorId(element:#global.page.body("Content left"))` in the **page** template. It highlights in SiteArchitect; it has **no effect in ContentCreator** (individual sections can still be edited). |
| Global content area | `editorId(element:#global.gca("gca_common_header"))` in a `<div>` |
| Dataset, content projection | `editorId(view:"pressreleases", editorName:"cs_teaser")`: the dataset is found from the generation context |
| Dataset via `contentSelect` | add `entity:`: `editorId(entity:_medium, view:"gallerymedia", editorName:"cs_picture")` |
| Medium (metadata of the picture) | `$CMS_SET(el, st_picture.getMedia)$` then `editorId(element:el)` on the `<img>`; the section keeps its own icon |
| Navigation item (move by drag-and-drop) | in the navigation function's array element: `<li$CMS_VALUE(editorId(element:#nav.ref))$>` or the same on the `<a>` |

**Datasets in several places.** The link from a preview to a dataset is not unique when the same
dataset is output through several table templates (an overview with teasers and a detail page).
Only the table template that defines the input components can be matched automatically;
elsewhere pass `entity`, `view` and `editorName` by hand. The template's **Preview page**
(Properties tab) selects which page reference carries the dataset in the preview; only one can
be chosen, so it must work for every template that uses the data source. To edit datasets in
the preview, **"Use in ContentCreator"** must be ticked per table template. [odfs]

## Different behaviour in SiteArchitect and ContentCreator

`#global.is("WEBEDIT")` is true in a ContentCreator preview, so highlighting can be kept for one
client only:

```
$CMS_SET(isWebEdit, #global.is("WEBEDIT"))$
$CMS_IF(!isWebEdit)$ <div$CMS_VALUE(editorId())$> $CMS_END_IF$
```

## InEdit: supported components

`CMS_INPUT_CHECKBOX`, `CMS_INPUT_COMBOBOX`, `CMS_INPUT_DATE`, `CMS_INPUT_DOM`,
`CMS_INPUT_DOMTABLE`, `CMS_INPUT_LIST`, `CMS_INPUT_NUMBER`, `CMS_INPUT_RADIOBUTTON`,
`CMS_INPUT_TEXT`, `CMS_INPUT_TEXTAREA`, `CMS_INPUT_TOGGLE`, `FS_DATASET`, `FS_REFERENCE`.
The page names no other component for InEdit.

## Metadata

- **Prerequisite:** switch metadata maintenance on per object type in the project's
  ContentCreator settings (project properties), where each type also gets language-dependent
  display names for the menus. [odfs]
- **Menu:** with metadata on, the element-type menu ("PAGE", "FOLDER") edits the metadata of the
  page, the page reference and the Site Store folder. [odfs]
- **EasyEdit:** an "Edit metadata" icon appears in the section's tool bar, no parameter
  needed; the target is derived from the context. [odfs]
- **A medium:** `editorId(element:el)` on the `<img>` (above) adds a second icon for the
  medium's metadata. [odfs]
- **InEdit:** inline edit of **one metadata field**: `editorId(editorName:"md_copyright", meta:true)`.
  Without `element` the context object (a section heading means the section) receives the
  metadata; `element:#global.page` targets the page, `element:el` a medium (or medium folder).
  `editorName` is read as a metadata-template field only together with `meta:true`. [odfs]

## Drag-and-drop in the preview

- **Move menu items:** pages and menu items can be moved in the preview when the navigation
  elements carry `editorId(element:#nav.ref)` (above). [odfs]
- **New page:** with that markup the navigation elements are also **drop targets** for a page or
  page reference dragged from a report; releasing opens the dialog to insert the page into the
  navigation. "Finish" creates, by default, a page at that position with the same name and content as the dropped page; the editor can change the settings in the dialog or afterwards. [odfs]
- **Hit marker:** report entries can be shown as counters in the preview. A
  `de.espirit.firstspirit.webedit.DataAssociationHandler` [jar] relates report objects to preview
  objects (for example the built-in "SiteStoreAssociation" marks menu items, `SiteStoreFolder`,
  with the number of matching page references in a search report). Related types:
  `DataAssociationAgent` (`associate`, `associateIds`, `getId`, `getFromId`) and the aspect
  `client.plugin.dataaccess.aspects.DataAssociating` (`getAssociationType`, `setAssociation`)
  [jar]. The preview objects are identified through `editorId(...)`. The counters may not show where CSS or JavaScript builds the navigation. [odfs]

## Image cropping in the preview

`resolution:` on `editorId` (above) with an `FS_REFERENCE`:

```
<img src="$CMS_REF(st_picture, resolution:"TextBildTeaser")$"
     $CMS_VALUE(editorId(editorName:"st_picture", resolution:"TextBildTeaser"))$/>
```

Each resolution of an image has one of three variants, and cropping behaves per variant [odfs]:

| Variant in the target resolution | Crop starts from | Saving a crop | Saving without a crop box |
| --- | --- | --- | --- |
| None (scaled from "Original") | the "Original" area | cropped "Original" area is saved in the target resolution | — |
| Cropped (cut or rotated "Original") | the "Original" area | same | the crop is removed; the resolution becomes "None" again |
| Uploaded (a file saved in that resolution) | the uploaded graphic | the cropped area **replaces** the uploaded graphic; later crops start from that smaller area | — |

Resolution-specific upload or delete of a differing image is not possible here. Remote-project
images can be cropped; the result is saved in the target resolution of the remote project.
Automatic and AI-assisted cropping: `automatic-cropping.md`.

**Open the dialog from code.** `de.espirit.firstspirit.webedit.server.CropDialogOperation` [jar],
obtained through `OperationAgent` (`firstspirit-operations`): `setMedia(Media)`,
`setLanguage(Language)`, `setResolutions(List<Resolution>)`, `perform()`. With an empty list or
unknown resolutions all project resolutions are editable. A `File` medium or a picture without
image data is not opened; the exception goes to `fs-server.log`. [jar] [odfs] The ODFS example
is a script `cc_crop` bound to the `onDrop` of a hidden `FS_BUTTON` with
`<DROPTYPES><TYPE value="picture"/></DROPTYPES>`, reading the dropped media from `dropdata`
through `TransferAgent` and `ResolutionAgent.getResolutionByName(...)`; rendered with
`fsbutton(editorName:"pt_cropButton")`. [odfs]

## CSS: stay under z-index 1000

EasyEdit and InEdit frames and tool bars are HTML blocks laid over the element, positioned with
CSS and shown on hover, with `z-index` **1000 or higher**. They are guaranteed to work only if
the project's own `z-index` values are **below 1000**. [odfs]
