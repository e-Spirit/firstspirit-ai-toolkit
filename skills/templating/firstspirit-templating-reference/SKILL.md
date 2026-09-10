---
name: firstspirit-templating-reference
description: >-
  Concrete lookup reference for FirstSpirit template development: the template
  language ($CMS_VALUE$, $CMS_IF$, $CMS_FOR$, $CMS_REF$, $CMS_RENDER$, system
  objects, string operations), GOM form/input components (CMS_INPUT_*,
  FS_REFERENCE, FS_CATALOG, FS_INDEX, FS_DATASET) and the datatype each yields,
  Rules (validation, visibility, editability, value), identifier and casing
  rules, and deprecated→current components. Use whenever you need exact
  FirstSpirit template syntax, the right input component, what datatype a
  component produces, how to access it in the output channel, or whether
  something is deprecated — e.g. "syntax for CMS_FOR", "which input component
  for a single choice", "what datatype does FS_REFERENCE produce", "how do I
  output a date", "escape a value against XSS", "is FS_LIST still supported". It
  is also the content-interpretation companion to downstream analysis
  (that skill owns export structure; this one explains what is inside
  GomSource.xml / Ruleset.xml / ChannelSource files). Pair with
  firstspirit-template-design for design judgement and naming conventions, and
  firstspirit-scripting for BeanShell / Access-API.
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit templating reference

A fast, factual **lookup** reference for FirstSpirit template development — the "what/how".
It answers the concrete questions that come up mid-task: exact tag syntax, the right input
component, the datatype a component yields and how to read it, the applicable rule, and whether
something is deprecated.

This skill states **facts about the language**. Design judgement (what good looks like, naming
conventions/prefixes) lives in `firstspirit-template-design`; scripting (BeanShell, Access API)
in `firstspirit-scripting`; export structure in downstream analysis.

## How to use this skill

- **Look up, then stop.** Answer with the exact syntax, component, datatype, or rule and point
  into the reference file below — don't restate a whole catalogue inline.
- **Settle output mode and client when they change the answer.** Classic (HTML) vs. headless
  (JSON/CaaS) differs for some questions; so does SiteArchitect (the Java client, being phased
  out) vs. ContentCreator. Note which applies when it matters.
- **Defer design decisions.** When the real question is "which design is right" or "what should
  I name this", hand off to `firstspirit-template-design`.

## Most-common lookups

```
$CMS_VALUE(st_x)$                       output a field's value
$CMS_REF(st_x)$                         resolve a media/reference URL
$CMS_IF(...)$ … $CMS_END_IF$            conditional
$CMS_FOR(item, st_list)$ … $CMS_END_FOR$  iterate
$CMS_RENDER(template:"…")$              include another (format) template
```

- **Which component yields which datatype, and how to read it** → `references/datatypes.md`.
- **Is it deprecated / what replaces it** (e.g. `FS_LIST`, `CMS_INPUT_PICTURE`) →
  `references/deprecated.md`.
- **Reference-name (UID) and casing rules** → `references/identifiers-and-casing.md`.

## Interpreting a sync-export file

This skill explains what is **inside** an export's files; downstream analysis owns
the export **structure** (store folders, `StoreElement.xml`, UID/`templateid` semantics).

| Export file | Holds | Interpret with |
|---|---|---|
| `GomSource.xml` | the GOM form (input components) | `references/gom/`, `references/datatypes.md` |
| `Ruleset.xml` | validation / visibility / editability / value rules | `references/rules/` |
| `ChannelSource_<set>_<channel>.<ext>` | one output channel (template language) | `references/templates/` |
| `StoreElement.xml`, `FS_*.txt`, store/folder layout | element identity & structure | → downstream analysis |

## References

Loaded on demand — read the file that matches the question.

### Core lookups
| File | Covers |
|---|---|
| `references/datatypes.md` | GOM component → stored datatype → output access (the spine) |
| `references/deprecated.md` | deprecated/removed components & usage → current replacement |
| `references/identifiers-and-casing.md` | reference-name (UID) rule; where casing matters |

### GOM — forms & input components (`references/gom/`)
| File | Covers |
|---|---|
| `structure.md` | `CMS_MODULE` wrapper, common attributes, `LANGINFOS`/`ENTRIES` |
| `text-inputs.md` | `CMS_INPUT_TEXT` / `TEXTAREA` / `DOM` / `DOMTABLE`, `CMS_LABEL` |
| `selection-inputs.md` | `COMBOBOX` / `RADIOBUTTON` / `CHECKBOX` / `LIST`, `CMS_INCLUDE_OPTIONS` |
| `numeric-date-boolean.md` | `NUMBER` / `DATE` / `TOGGLE` |
| `references-links.md` | `FS_REFERENCE`, `CMS_INPUT_LINK`, `FS_DATASET`, `FS_BUTTON`, `IMAGEMAP` |
| `catalogs-indexes.md` | `FS_CATALOG` / `FS_INDEX` |
| `real-world.md` | production form shapes |

### Rules (`references/rules/`)
| File | Covers |
|---|---|
| `validation.md` | validation rules (`<VALIDATION>` fires when `<WITH>` is FALSE) |
| `visibility.md` | show/hide, client scoping (`WEB` / `NOT WEB`) |
| `editability.md` | editable / locked |
| `value-manipulation.md` | set / calculate values |
| `real-world.md` | production rule shapes |

### Template language (`references/templates/`)
| File | Covers |
|---|---|
| `variables-conditionals.md` | `$CMS_VALUE$` / `$CMS_SET$` / `$CMS_IF$` / `$CMS_SWITCH$` |
| `loops-lists.md` | `$CMS_FOR$` |
| `composition.md` | `$CMS_RENDER$` (include a format template / script / channel), `$CMS_TRIM$` |
| `system-objects.md` | `#global` / `#nav` / `#row` / page / section / dataset context |
| `string-operations.md` | string methods + output escaping / XSS safety |
| `dom-media.md` | DOM output; format templates in their DOM-styling role; `$CMS_REF$` media |
| `real-world.md` | production output shapes |

> `references/common-patterns.md` (Java Access API / BeanShell) is **transitional** — it is out
> of scope for templating and migrates to `firstspirit-scripting`. Use that skill for scripting.

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
