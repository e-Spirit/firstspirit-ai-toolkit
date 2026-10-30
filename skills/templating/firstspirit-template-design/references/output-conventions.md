# Output conventions for HTML templates

Three habits for HTML output channels that make a template testable and editable in ContentCreator without
later rework. They are practice from template development, not product rules; each says what to do unless the
project asks otherwise `[verify]`. Syntax of `$CMS_VALUE$` is in the
`firstspirit-templating-reference` skill (`templates/variables-conditionals.md`); the parameters of `editorId(...)` and
which element gets the call per component, dataset and content area are in the `firstspirit-contentcreator-extensions`
skill (its `editing-in-the-preview.md`).

## 1. Give every output a default, unless a condition surrounds it

A variable that can be empty or null belongs either inside an `$CMS_IF$` that handles the empty case, or in
`$CMS_VALUE(var, default:"")$`. A bare `$CMS_VALUE(var)$` outside a condition is the case to avoid: whether it
prints nothing, "null" or breaks the markup depends on the type. Use `default:""` when empty should print
nothing, or a meaningful default text where the page needs one. Remember that a field with `preset="COPY"`
counts as filled (`.isEmpty` is false), so a guard on emptiness does not catch it.

## 2. Set `editorId` on HTML output by default

Emit `editorId` for every HTML output channel unless the project says otherwise. It lets ContentCreator select
and edit in place, lets tests find the element, and avoids a dedicated change to every template later. Three
places, all in the first build, not added afterwards `[verify]`:

- **Section level.** The outer element of each section template carries `$CMS_VALUE(editorId())$` (no
  arguments: it resolves against the section). A section without it cannot be selected in ContentCreator.
- **Text fields.** The element that shows a `CMS_INPUT_TEXT`, `CMS_INPUT_TEXTAREA` or `CMS_INPUT_DOM` value
  carries `editorId` with the component variable (`editorId(editorName: st_title)`), so the value is edited
  in place.
- **Pictures.** An `FS_REFERENCE` limited to pictures always gets `editorId` with its name and, if the
  template uses one, the resolution (`editorId(editorName: prm_inputName, resolution: ...)`, a list of
  resolutions when several are rendered; example in `firstspirit-templating-reference`,
  `templates/real-world.md`). Without it the editor cannot crop in ContentCreator.

When no HTML element carries the value (a small template that outputs a bare value, or a section without a
surrounding element), do not skip it silently. Put a comment in the output channel that states the editorId is
missing and why, for example `<!-- editorId: no element to attach to for st_title -->`. A developer reviewing
the code then decides either to add an element that exists only in the preview, or that inline editing is not
needed there.

## 3. Inline editing or the whole form

Inline editing, `editorId` with a component variable, is the default for **text fields** (above). For every other
component type the developer decides and says so in the spec or the template documentation; do not add it by
default.

- **In place** suits values the editor sees on the page and changes on their own: a headline, a paragraph.
- **In the form** suits values that do not appear in the output as such (settings, selections, metadata,
  visibility switches), values that depend on each other, and structured fields such as catalogs and datasets.
- If the output has no element for a form-only value, a comment is enough; do not invent markup for the live site.

## 4. Readable output: indentation and line breaks

Render with line breaks and indentation, one tab per level (SiteArchitect shows a tab as four spaces), not on a single line.
Single-line output is hard to read in the preview, in a diff and in a test failure.

- **Empty lines** left by `$CMS_IF$` and `$CMS_FOR$` are an issue only when they matter; then wrap the block in
  `$CMS_TRIM(level:1)$` (consecutive blank rows become one) or `level:2` (blank rows removed). Levels 3 and 4
  also remove the indentation, and level 4 breaks JavaScript `[odfs]`; keep them for values, JSON or PDF, not for HTML.
- **Finicky formats** (Markdown tables, YAML, and others where a line break changes the meaning): let a
  `$-- ... --$` comment span the line break, so the break is part of the comment and never reaches the output.
  Open the comment where the line would end and close it at the start of the next line: `$CMS_IF(cond)$$--` newline `--$`.
  The comment can also hold an indent that should not appear, for example a tab inside a `$CMS_FOR$`. Example from a
  Markdown channel `[observed]` (the project's own templates, 2026-10-16):

  ```
  $CMS_IF(!headline.isEmpty)$$--
  --$## $CMS_VALUE(headline)$
  $CMS_END_IF$
  ```

  The same project documents a template's parameters in a leading `$-- ... --$` comment and wraps the body in
  `$CMS_TRIM(level:4)$`; level 4 collapses all whitespace and is right for Markdown, not for HTML or JavaScript.

How much of this is applied today is open: the choices are made by the developer and no gate checks them
`[verify]`.
