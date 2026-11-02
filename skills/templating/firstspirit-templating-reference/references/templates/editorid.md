# `editorId(...)`: the edit marker in an output channel

`editorId(...)` is an instruction function of the template language. It writes an *editor identifier* into an HTML
element so that the element can be highlighted in SiteArchitect (Content Highlighting) and edited in ContentCreator
(EasyEdit, InEdit, LiveEdit). One call serves both clients. `[odfs]` FirstSpirit 2026.5, *Template syntax → Functions →
in instructions → editorId*.

This page holds the call form only. What each parameter does and which element gets the call for a catalog item, a
dataset, a content area, a navigation item or a picture is in the `firstspirit-contentcreator-extensions` skill (its
`editing-in-the-preview.md`); the rule to set it on every section, text field and picture by default, and what to do
when no element exists, is in the `firstspirit-template-design` skill (its `output-conventions.md`).

## Call form

```
<div$CMS_VALUE(editorId())$>                                          section or page: no argument, the current context
<h3$CMS_VALUE(editorId(editorName:"st_headline"))$>                    one input component, by its name as a string
<img src="$CMS_REF(st_picture)$" alt="" $CMS_VALUE(editorId(editorName:"st_picture"))$ />
```

- The call goes **inside the opening tag** of the element that shows the value: block elements such as `<h1>`…`<h6>`,
  `<p>`, `<div>`, or element-specific on `<img>` `[odfs]`.
- `editorName` takes the **name** of the input component as a string (`"st_headline"`). A bare variable passes the
  field's value, not its name; pass a variable only where it holds the name, as a render template's parameter does
  (`real-world.md`, `editorId(editorName: prm_inputName, …)`).
- Without any parameter the current context is used, the section or the page `[odfs]`.
- Parameter names: `editorName`, `language`, `entity`, `template`, `view`, `element`, `target`, `previewRulesEvaluation`,
  `resolution`, `reloadPreview`, `reloadElement`, `json`, `meta`, `externalReference` `[odfs]`. Meaning, scope
  (SiteArchitect and ContentCreator, or ContentCreator only) and examples: `firstspirit-contentcreator-extensions`,
  `editing-in-the-preview.md`.

## Empty elements

Do not leave the element that carries the identifier empty: no frame may be drawn. Output a substitute such as a
non-breaking space when the field is empty `[odfs]`:

```
<h3$CMS_VALUE(editorId(editorName:"st_headline"))$>
  $CMS_IF(!st_headline.isEmpty)$$CMS_VALUE(st_headline.convert2)$$CMS_ELSE$&nbsp;$CMS_END_IF$
</h3>
```

The companion rule on the *Use in projects* page, to wrap the output of a component in `$CMS_IF(!IDENTIFIER.isEmpty)$`
because an empty component cannot be highlighted, applies to the value, not to the element: keep the element, guard
the value.

## Related

- `editorId()` without arguments inside a shared format template resolves against the caller's section
  (`composition.md`).
- `fsbutton(...)` for an `FS_BUTTON` in the preview: `datatypes.md` (FS_BUTTON row); the form definition is in `gom/references-links.md`. The preview ids a headless
  frontend decorates its markup with (`data-preview-id`): `firstspirit-headless`, `preview-and-editing.md`.
