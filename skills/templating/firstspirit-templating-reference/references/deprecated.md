# Deprecated & removed — wrong → right

What is out of date and what replaces it. This is **factual** (what the system deprecated and
when); treating a *current* template's use of these as a quality problem is the judgement side,
which lives in the template-design guidelines (not part of this toolkit). For the diagnostic consumer, a hit
here is a signal to flag.

## Components

| Deprecated / removed | Status | Use instead |
|---|---|---|
| `FS_LIST` | deprecated v5.2R3; **removed in version 2020-07** (the ODFS migration guide's "from 2020-01" was the planned date; actual removal was 2020-07 — SME). Still present in **older on-prem releases** before 2020-07, so legacy templates on those servers do contain it; on 2020-07+ forms with it can no longer be edited and produce no output, with no return after migration even after a downgrade. | `FS_CATALOG` / `FS_INDEX` / `CMS_INPUT_SECTIONLIST` by type — see mapping below |
| `CMS_INPUT_PICTURE` | deprecated (survives only as a legacy inline example; no dedicated component page) | `FS_REFERENCE` with a `picture` filter (`<FILTER><ALLOW type="picture"/></FILTER>`) |

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

- **`useLanguages="YES"`** carries an upstream note that it "will potentially no longer be
  evaluated in FirstSpirit 5.2R5 and higher" (repeated across most input-component pages). This
  is an aged, speculative warning — treat language-dependent content as version-sensitive and
  verify against the project's actual version rather than trusting the note. Related:
  `forbidPolyglotDataHierarchy` on `FS_CATALOG`.

## Client status

- **SiteArchitect (the Java fat client) is being phased out** in favour of ContentCreator.
  SiteArchitect-only surfaces and `…javaClientUrl` access still work but are on the way out;
  prefer the ContentCreator path (`…webeditUrl`) where a choice exists. Not a component removal —
  a direction-of-travel fact worth noting when reading older templates.

## How deprecation appears in a form (diagnostic aid)

- A component explicitly set to the **`deprecated`** state is drawn with its opening/closing tag
  **crossed out** in the GOM form.
- A component the server no longer knows (obsolete or not installed) is shown as an **unknown
  component** placeholder in the form.

## See also

- `datatypes.md` — the current components and what they return.
- the template-design guideline on deprecated components (not part of this toolkit) — why surfacing deprecated components as current is
  the trap, and how it scores against quality.
