# Template-set documentation pattern

The pattern behind principle 13. When this skill creates a template, or a set of templates,
it produces one documentation file per creation task, following the skeleton below. This backs
two jobs: give the template designer a plan to review and correct before anything is written,
and leave the project documented afterwards.

## When to produce it

- **Before the build, as a plan.** Draft the documentation from the instruction first, then let
  the designer read and correct it — which templates, which components, what is required, what is
  language-dependent. This is the intervention point. It matters most on programmatic writes
  through the API or REST, where no client guides the build and nothing stops a broken or
  unintended structure being saved (principle 11). Do not start a side-effectful write until the
  plan is signed off.
- **After the build, as documentation.** Update it to match what was actually created, then keep
  it beside the templates. A documentation that has drifted from the templates is worse than none.

## What to record, and how to get it right

- **The originating instruction.** Capture what drove the work — the prompt, a wireframe or
  mockup reference, a spec, or a ticket — verbatim or closely summarised. This is the "why" a
  later reader cannot recover from the forms alone.
- **Output mode and client.** Classic (HTML/file) or headless (JSON/CaaS); ContentCreator or
  SiteArchitect. These condition naming and structure (principles 4 and 7), so state them up top.
- **Templates by store type.** List them in the FirstSpirit Template Store order (below). For
  each, give the reference name, display name, description, its purpose, and what it references
  or is used in — the dependencies.
- **Components per form.** For each template's form, one row per component (see the table). Record
  the variable (reference name), the editor label, the input component and the datatype it
  yields, whether the value is **language-dependent**, whether it is **required** and how that is
  enforced, and notes (filter, default, the group or tab it sits in, rules).
- **Required is a rule, not a flag.** Enforce a required field with a not-empty validation rule
  at the restriction level the developer chooses — `INFO` (hint only), `RELEASE` (blocks release),
  or `SAVE` (blocks saving). Do not use the legacy `allowEmpty` attribute: it predates rules and
  is too blunt for real cases (it cannot express, for example, "required only in one language").
  Record both the requirement and the level — "Required / RELEASE" is a complete answer;
  "required" alone is not.
- **Language settings.** State whether each value is language-dependent (a value per project
  language) or language-independent (one value, shown for all languages). Note per-language
  validation or visibility (LANG / MASTER) where it applies.
- **Build order.** The order dependencies must be created in, since a component that points at
  another object needs that object first (principle 11): create inner-first, delete outer-first.

## Document skeleton

Copy this, fill it in, drop the sections that do not apply (mark them "none" rather than
deleting the heading, so a reader knows they were considered).

```markdown
# Template documentation — <project / feature name>

- **Date:** <YYYY-MM-DD>   **Author:** <name>
- **Output mode:** classic (HTML/file) | headless (JSON/CaaS)
- **Client:** ContentCreator | SiteArchitect
- **Status:** plan (awaiting sign-off) | built

## Originating instruction

<The prompt, wireframe/mockup reference, spec, or ticket that drove this. Verbatim or a close
summary. Link the wireframe or ticket if there is one.>

## Templates

### Page templates
| Reference name | Display name | Description | Purpose | References / used in |
|---|---|---|---|---|
| pt_landing | Landing page | Landing page with hero and flexible body | Marketing landing pages | uses st_hero, st_text |

### Section templates
| Reference name | Display name | Description | Purpose | References / used in |
|---|---|---|---|---|
| st_hero | Hero | Full-width hero with image and heading | Top of landing pages | used in pt_landing body |

### Format templates
_none_

### Link templates
_none_

### Scripts
_none_

### Database schemas
| Schema | Table template (uid) | Data source (uid) | Purpose | Relations (foreign keys) | Remote Data |
|---|---|---|---|---|---|
| Products | Products.products | products | one row per product | products → product_categories (n:1, via tt_category) | master here / imported from <project> / — |
| Products | Products.product_categories | product_categories | controlled vocabulary | — | — |

For each table template add a column table under *Components per form* (below) with two more
columns than a section form: **Column type** (String, Integer, Long, Double, Boolean, Date,
FirstSpirit editor, or *relation* for an `FS_DATASET`) and **Key / reference** (the unique key
column a database combobox stores, or `Schema.table` + cardinality for a dataset reference).
A key column is never language-dependent; state who guarantees its uniqueness in *Notes*.

### Workflows
_none_

## Components per form

### st_hero
| Variable (ref name) | Label (editor) | Input component | Datatype | Language-dependent | Required (enforcement) | Notes |
|---|---|---|---|---|---|---|
| st_headline | Headline | CMS_INPUT_TEXT | String | yes | required / RELEASE | not-empty validation |
| st_image | Image | FS_REFERENCE | Media | no | optional | FILTER = picture only |
| st_show_overlay | Dark overlay | CMS_INPUT_TOGGLE | boolean | no | optional | default off |

### Products.products (table template)
| Variable (ref name) | Label (editor) | Input component | Column type | Key / reference | Language-dependent | Required (enforcement) | Notes |
|---|---|---|---|---|---|---|---|
| tt_name | Name | CMS_INPUT_TEXT | String | — | yes (one column per language) | required / RELEASE | not-empty validation |
| tt_sku | SKU | CMS_INPUT_TEXT | String | key (unique) | no | required / SAVE | uniqueness guaranteed by the import script |
| tt_category | Category | FS_DATASET | relation | Products.product_categories, n:1 | no | required / RELEASE | maps onto the foreign key products → product_categories |
| tt_price | Price | CMS_INPUT_NUMBER | Double | — | no | optional | |

## Build order (for API / REST writes)

0. <database first when there is one — schema, table templates with their foreign keys, one data source per table template, vocabulary rows, then rows that reference them>
1. <inner objects first — e.g. section template st_hero, index tables, referenced media>
2. <objects that reference them — e.g. page template pt_landing>
3. <site-store / registration steps>

Delete in reverse order. Confirm any destructive or side-effectful write before running it.

## Open questions for the designer

- <Anything to confirm before build: required vs optional, language settings, which content
  areas allow which sections, restriction levels.>
```

## Notes

- This document is plain Markdown so it lives beside the templates and reads without tooling. If
  a styled, shareable page is wanted, hand the finished document to the `doc-builder` skill.
- Keep it per creation task, not per template — a set built together is documented together, so
  the dependencies and build order stay in one place.
- The component and datatype detail behind the table is in `components-and-tags.md`; naming rules
  for the reference names are in `naming-and-conventions.md`.
