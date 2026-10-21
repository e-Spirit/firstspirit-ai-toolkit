# Snippets: what the editor sees in lists

A snippet is the editor's teaser of **one object**, a section, page or dataset, built from the content it holds: a
label, an extract and a thumbnail shown in search, the project history, reports, selection dialogs, the `FS_CATALOG` entry list and,
in FragmentCreator, the fragment list. Every section of a template gets its own text, because the snippet reads that
section's fields. Without one the editor sees the technical name and the folder path, and cannot tell ten sections of
one template apart: a catalog of cards without snippets lists every entry under the template name, "Experience Card"
four times `[observed]` 2026-10-16 (DevCon test run, ContentCreator). A snippet is part of the template, not decoration:
an editor-facing template without one is unfinished. It is not the template's preview image (`preview-image.md`), which
is shown when the template itself is chosen. Facts and expression syntax
are in the `firstspirit-templating-reference` skill (its `templates/snippets.md`); this file is the design view.

## Which templates need one

- **Every section template, page template and table template an editor meets**, including the item template of an
  `FS_CATALOG` (the entries are listed by their snippet).
- **Link templates**: label and extract (and a thumbnail for page links); the snippet is also the tooltip in rich text.
- **Media**: through the metadata template.
- **Not needed** for hidden or technical templates that no editor opens; check that they are hidden instead.

## What to put in each part

Pick the content that tells objects of this template apart and say what the object is at a glance; keep it short.

| Part | Rule | Example shape |
|---|---|---|
| Label | the field that is the object's title or name; the one an editor would search for | `card_title`; a guarded expression if the title is optional |
| Extract | the field that adds meaning to the label: the first text, a key and an order, a URL | `card_text`, or `truncate(card_text, 65)` |
| Thumbnail | an image field, **only where the form has one**; never a blanket expression | `card_image` |

- Guard every optional or reference input with an empty check, and check the type of an `FS_REFERENCE` before reading
  a property (the syntax is in the reference).
- Apply `xmlEscape()` to logic results used in label or extract; `truncate()` long extracts.
- A **partly** missing snippet is a finding only where the form has a field that could fill it; a thumbnail for a
  template with no image field is correct.
- Use the preview on the Snippet tab to check the result before the template is used.
- Structure (object type, hierarchy position) is secondary in this display, so the label must carry the identity.

## In the build

- Write the snippet when the form is written (it names fields of the form), not afterwards; the three expressions go
  in the spec or the template documentation next to the form.
- **Snippets cannot be created over REST** `[observed]` 2026-10-16: a person creates them in the template store in
  SiteArchitect or in Template Development in ContentCreator. Write down name, template and the three expressions, say
  that they were not created, and hand them over (`firstspirit-rest-api`).
- In a review, a missing snippet on an editor-facing template is a finding.
