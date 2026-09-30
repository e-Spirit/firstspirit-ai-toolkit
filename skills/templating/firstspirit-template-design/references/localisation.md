# Localisation and multi-language

The detail behind principle 14. FirstSpirit has **two separate language dimensions**, and the
common mistake is to conflate them. Settle each on its own.

1. **Editor-facing language** — the language of labels, display names and descriptions the
   editor reads in the form. This is about the interface, not the content.
2. **Content language-dependence** — `useLanguages`, whether a value is translated (stored per
   project language) or held once for all languages. This is about the content itself.

## Editor-facing language (labels, display names)

Labels, display names and descriptions can be given per project language. A typical default is
**en + de**. The default (fallback) language is marked with `*`. Any language left unspecified
falls back to the default, so in a two-language setup **only the default needs to be filled in
explicitly**; add the second language only where the wording should actually differ. Reference
names stay single, English and language-independent (principle 7) — this is only about the
editor-facing text.

## Content language-dependence (`useLanguages`)

- **`useLanguages="yes"`** (the default): deviating values are stored per language — the value
  is translatable.
- **`useLanguages="no"`**: one value is stored for all languages — language-neutral.

### By template and component type

- **Link templates — always `useLanguages="no"`.** Links are not translated.
- **Format templates — language-neutral.** They have no form input. The one exception is a format
  template used as a *render* template whose output channel branches on `#global.language` (the
  current preview or generation language); that is the only place language enters a format
  template, and only when it carries language-based output logic.
- **Input components — assume translated unless the context says otherwise.** The rule of thumb
  is that content will be translated, so default to `useLanguages="yes"`. Set it to `"no"` when
  the value is clearly language-neutral. This is a pattern, not a hard rule. Common
  language-neutral cases:
  - **dates**;
  - **names** — of people, authors and similar;
  - **visual settings** — typically comboboxes, toggles and checkboxes: image position, "add
    description", colour, theme and similar;
  - **access** — typically permission components: access, publish, allow and similar.

## Catalog and index (`FS_CATALOG`, `FS_INDEX`)

These are the subtle case. The same rule applies to both, and to any nesting of them.

**The rule: at most one language-dependent level per nesting chain.** `useLanguages="yes"` makes
a component store deviating values per language — a *language-dependent level*. On the path from
an outer catalog, through the section template inside its entries, through a catalog nested in
that, down to the input components at the leaves, you may have **at most one** such level. Zero
means monolingual; one is fine; two or more is the "polyglot data hierarchy" that FirstSpirit no
longer honours.

**Where you put the one level decides what varies per language.** This is the part to get right,
because a language-dependent *catalog* and translated *content* are different choices, not the
same one:

| Outer catalog | Inner catalog | Input component | Result |
|:---:|:---:|:---:|---|
| no  | no  | no  | Monolingual — one value for all languages. |
| no  | no  | **yes** | Same entries in every language; the field **values** translate. The common setup for teaser-like lists. |
| no  | **yes** | no | The inner catalog holds a **different set of entries** per language. |
| **yes** | no | no | The **whole catalog** differs per language — different number, order and content of entries. |
| \>1 "yes" | | | Not honoured — the inner language dependence is silently ignored (see below). |

So to translate the *same* list — three teasers in every language, their text translated — set
the catalog `useLanguages="no"` and make the translatable **fields** language-dependent. Do
**not** make the catalog itself language-dependent for that; a language-dependent catalog gives
each language its own independent set of entries, which is only what you want when the languages
genuinely need different lists.

**The modern default enforces the rule by flattening, not by erroring.** With
`forbidPolyglotDataHierarchy="yes"` (the default in new projects since 5.2R5), a
language-dependent input component nested inside a language-dependent catalog is interpreted as
language-independent automatically — its own `useLanguages="yes"` is ignored, silently. A
two-level configuration does not fail to save; it quietly collapses to one level. So design for a
single level on purpose rather than leaning on the flatten. The old behaviour
(`forbidPolyglotDataHierarchy="no"`) did honour multiple levels, and that is exactly the polyglot
hierarchy that caused broken translation, poor editor usability, and content that could not be
output or edited.

**Migration is out of scope, and can lose data.** Turning `forbidPolyglotDataHierarchy` on in a
legacy project that already holds nested language-dependent content can cause data loss. That is
a versioned migration for a FirstSpirit expert, not new-template design — the same scope line as
deprecated-component migration (principle 12). For new templates, design for the modern default:
one language-dependent level, placed where the content actually needs to vary.

ODFS reference:
`https://docs.e-spirit.com/odfs/template-develo/forms/input-component/catalog/` (the language
dependency section). Verify against the current ODFS, as defaults change by version.

## Recording it

The template-set documentation (principle 13, `template-documentation.md`) records
language-dependence per component in its "Language-dependent" column, and per-language
validation or visibility (LANG / MASTER) belongs with the rule notes. Capture the editor-facing
language set (e.g. en*, de) once in the document header, not per field.
