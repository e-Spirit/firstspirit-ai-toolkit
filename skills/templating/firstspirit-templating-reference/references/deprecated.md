# Deprecated & removed — wrong → right

What is out of date and what replaces it. This is **factual** (what the system deprecated and
when); treating a *current* template's use of these as a quality problem is the judgement side,
which lives in `firstspirit-template-design` (principle 12). For the diagnostic consumer, a hit
here is a signal to flag.

## Components

| Deprecated / removed | Status | Use instead |
|---|---|---|
| `FS_LIST` | deprecated v5.2R3; **removed in version 2020-07** (the ODFS migration guide's "from 2020-01" was the planned date; actual removal was 2020-07). Still present in **older on-prem releases** before 2020-07, so legacy templates on those servers do contain it; on 2020-07+ forms with it can no longer be edited and produce no output, with no return after migration even after a downgrade. | `FS_CATALOG` / `FS_INDEX` / `CMS_INPUT_SECTIONLIST` by type — see mapping below |
| `CMS_INPUT_PICTURE` | deprecated (survives only as a legacy inline example; no dedicated component page) | `FS_REFERENCE` with a `picture` filter (`<FILTER><ALLOW type="picture"/></FILTER>`) |
| `CMS_INPUT_FILE` | deprecated since 5.0.107, consolidated into the `FS_*` components | `FS_REFERENCE` with a `FILTER` allowing `type="file"` |
| `CMS_INPUT_PAGEREF` | deprecated since 5.0.107 | `FS_REFERENCE`, restricted by `FILTER` |
| `CMS_INPUT_LINKLIST` | deprecated since 5.0.107 | `FS_CATALOG` (a list of links in one component) |
| `CMS_INPUT_CONTENTLIST` | deprecated since 5.0.107 | `FS_INDEX` (lists from internal or external data) |
| `CMS_INPUT_OBJECTCHOOSER` | deprecated since 5.0.107 | `FS_DATASET` (one dataset) |
| `CMS_INPUT_TABLIST` | deprecated since 5.0.107 | `FS_INDEX` |
| `CMS_INPUT_CONTENTAREALIST` | deprecated since 5.0.107 | `FS_CATALOG` (it was a list of sections, the same target as `CMS_INPUT_LINKLIST`) |

The eight `CMS_INPUT_*` rows `[odfs]`: the *Deprecated List* of the FirstSpirit Access-API (ODFS, FirstSpirit 2026.11)
carries one editor-value interface per component, each "since 5.0.107" with the replacement named here (`PictureEditorValue`,
`FileEditorValue`, `PageRefEditorValue`, `LinkListEditorValue`, `ContentListEditorValue`, `ObjectChooserEditorValue`,
`TabListEditorValue`, `ContentAreaListValue`); the `FS_REFERENCE` page shows `CMS_INPUT_PAGEREF` rebuilt with a
`pageref` filter. `CMS_INPUT_PICTURE` has no component page of its own any more. `FS_REFERENCE` is the single
consolidation point for the old media, file and page-reference choosers; the inner `FILTER` tag shapes it, so one
component covers what used to be three.

### FS_LIST → successor, by type

`FS_LIST` had several types; the replacement depends on the type (verified from the migration guide):

| FS_LIST type / tag | Replace with |
|---|---|
| `DATABASE` | `FS_INDEX` |
| `INLINE` | `FS_CATALOG` |
| `PAGE` | `CMS_INPUT_SECTIONLIST` |
| `SERVICE` | `FS_INDEX` with a Data Access Plugin |
| `MEDIAMODE` tag | `FS_INDEX` using the `DatasetDataAccessPlugin` (shipped by default) |

## Deprecated usage patterns

These are *correct components used the wrong way* — factual gotchas, not style opinions.

**FS_INDEX rendered with a bare `$CMS_VALUE$`** — **wrong.** An `FS_INDEX` has no included
template, so `$CMS_VALUE(st_index)$` does not render it (the source migration doc's "no longer
supported" / "use of deprecated value generation method for an index editor" warning is correct on
this point). It is **not** like `FS_CATALOG` (which does carry a `<TEMPLATE>`). Reach the records
through `.values` instead — resolved and verified against the reference projects; see `datatypes.md`
(FS_INDEX access note).

```
$CMS_VALUE(st_index)$                          $-- WRONG: no template to render with --$
$CMS_VALUE(st_index.values.first.<field>)$     $-- right: navigate the record set --$
```

**Old Rules syntax** — the pre-5.2 rules syntax is superseded by the current `<RULE>` syntax
(introduced in 5.2). Use the forms in `rules/*.md`; do not copy older-style rules from legacy docs.

## Version-conditional (verify per project / version)

- **`useLanguages="YES"`**: the documentation carries a version-sensitive note on `useLanguages`
  ("will potentially no longer be evaluated in FirstSpirit 5.2R5 and higher", repeated across most
  input-component pages); verify against the project's version before relying on it. Related:
  `forbidPolyglotDataHierarchy` on `FS_CATALOG`.

## Client status

- **New features focus on ContentCreator.** SiteArchitect (the Java client) and
  `…javaClientUrl` access still work; prefer the ContentCreator path (`…webeditUrl`) where a
  choice exists, since new functions (the AI Suite, for example) are fully available there. Not a component removal —
  a direction-of-travel fact worth noting when reading older templates.

## How deprecation appears in a form (diagnostic aid)

- A component explicitly set to the **`deprecated`** state is drawn with its opening/closing tag
  **crossed out** in the GOM form.
- A component the server no longer knows (obsolete or not installed) is shown as an **unknown
  component** placeholder in the form.

## See also

- `datatypes.md` — the current components and what they return.
- `firstspirit-template-design` principle 12 and its `references/deprecated.md` — why surfacing deprecated
  components as current is the trap, what is in and out of scope (no migration planning), how a review reports a hit.
