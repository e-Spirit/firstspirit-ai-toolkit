---
name: firstspirit-template-design
description: >-
  Design principles and review guidance for FirstSpirit template development. Use whenever creating, generating, reviewing or auditing FirstSpirit templates: page, section, format and link templates, input components and forms (GOM), CMS tags and output, headless and CaaS projects, content modelling and datasets, naming and coding conventions, reuse, editorial usability, localisation and multi-language handling, and documenting a created template set. Trigger it for any FirstSpirit template task (ContentCreator, SiteArchitect, ODFS, CaaS, AI Suite), even when the request does not say "design principles" — e.g. "build a section template", "review this FirstSpirit template", "which input component should I use", "document the templates you generate", "check our templates against our conventions". Component, tag, datatype and naming reference in references/. Write precisely and in FirstSpirit vocabulary when the deliverable is written content (a report or documentation).
metadata:
  source-commit: "91d76a9"
  published: "2026-10-07"
  toolkit-version: "0.4.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit template design

Design judgement for FirstSpirit template development, for two jobs: building templates well, and reviewing templates against a consistent standard. The principles below state what to aim for and how to tell whether a template meets it. The detail behind them (component catalogue, tag syntax, datatype mapping, naming tables) lives in `references/`, loaded when a specific question comes up.

## How to use this skill

- **Generating.** Apply the principles as you design a template. Reach into `references/` for the concrete syntax, the right input component, or the correct prefix.
- **Reviewing.** Read each principle's "good looks like" line as a check against the template in front of you. Name what is missing or wrong, and point to the convention it breaks.

A template can be technically correct and still be a poor design. These principles are about the design, not the syntax. When a principle and a project's own house rules disagree, the project's rules win; note the difference rather than silently overriding it.

## Know the output mode and client first

Several principles below change depending on two things. Settle both before applying the rest.

- **Output mode.** Classic projects generate HTML or similar files. Headless projects deliver JSON, usually through CaaS, where FirstSpirit renders the JSON in a fixed setup and nests components into each other. The output mode changes naming (principle 7) and template structure (principle 4).
- **Client.** Much of the older material this skill draws on uses the SiteArchitect, the Java fat client, which is being phased out. Templates can also be built in the ContentCreator, where the setup differs. Treat SiteArchitect-specific steps with that in mind.

## Principles

### 1. Keep content and presentation separate

The page template holds the fixed layout and everything shown on every page of this type, including the navigation reference from the site structure. Section templates hold everything an editor supplies. The split is the whole point of the model: editors work on content, developers own presentation.

Good looks like: nothing an editor needs to change is hard-coded in the page template, and nothing structural is left for an editor to get wrong in a section.

### 2. Put once-only content in the page template

Sections repeat on a page without limit, so anything that should appear exactly once belongs in the page template, not a section. The page title is the standard example.

Good looks like: single-occurrence elements live in the page template; sections carry only what can sensibly recur.

### 3. Constrain what can go where

A content area can be restricted to the section templates that make sense in it. Use that. Allowing every section everywhere pushes layout decisions onto editors and invites broken pages.

Good looks like: each content area allows only the sections it should, so an editor cannot place a section where it does not belong.

### 4. Match template structure to how it is consumed

How content is consumed shapes how templates should nest. In a classic HTML project, structure serves the rendered page. In a headless project delivered through CaaS, FirstSpirit renders the JSON in a fixed setup and nests components into each other, so deep nesting becomes awkward for the frontend. For a project that targets CaaS, keep nesting flatter and shape it around what frontend developers need to consume.

Good looks like: in headless projects, component nesting is shallow and predictable for the frontend; in classic projects, structure follows the page.

### 5. Choose the input component for the editor's task, not the data

Start from how the editor thinks about the field and what makes their job clear and safe, then pick the component whose behaviour and resulting datatype fit. Toggle, combo box, radio buttons and a checkbox can all express a choice; they are not interchangeable for the editor or for the dependency they create. Filter selectable objects (for example with the `FILTER` tag on `FS_REFERENCE`) so only valid options appear.

Good looks like: the component matches the editorial intent, yields the right datatype and dependency, and offers only valid choices. See `references/components-and-tags.md` for the catalogue and the datatype mapping.

### 6. Make the form clear, guiding and safe for the editor

The form is the editor's workspace, so design it for them. Label each component clearly: the label is the field name the editor reads. Use the component description as help; it shows on mouseover as a tip. In AI Suite projects, the description is also used to carry prompts or instructions for an assistant, so treat it as a working field, not decoration. Keep a long form navigable. Use `CMS_GROUP` to gather fields that belong together, and tabs to give the editor a concise overview, so they can see where their content goes. This matters most in complex, content-heavy templates. Group an image's fields together, for example the reference, a caption and a styling toggle, or put all metadata in one tab that a different person or an assistant fills. Use an in-form label (`CMS_LABEL`) where the editor needs an instruction in place.

Then use default values, dynamic forms and validation so the form shows only what is relevant and an editor cannot easily produce broken output. Rules do four jobs: validate a field, show or hide it, make it editable or locked, and set or calculate its value. Their targets are single fields or whole groups, so a rule can reveal an entire tab from a toggle (show the image tab only when the editor turns an image on) or restrict a tab to the editors who should maintain it, such as a metadata tab tied to a group-membership check (`IN_GROUP`).

Rules are an editor-layer mechanism. They shape the form in ContentCreator and SiteArchitect, but they do not apply to content set by a script or the API, which can bypass validation. So use rules to guide and structure the editor, not as a security control or a guarantee for sensitive data. Expect the same in AI Suite: if an assistant fills the form through the API, a rule will not constrain it, so the constraint belongs in the prompt, not in a rule applied afterwards.

Three design points matter more than the syntax. First, choose the restriction level deliberately. `INFO`, the default, shows the message as a hint under the field with no further consequence. `RELEASE` blocks release of the page the violation sits in, however deeply nested, while still letting the editor save and fix it later. `SAVE` blocks saving altogether, so use it sparingly and only where it truly matters, or the form becomes painful to work in. Mark a field required with a not-empty validation at the level you have chosen; do not reach for the legacy `allowEmpty` attribute, which predates rules and cannot express a conditional or per-language requirement. Second, hide what does not apply rather than leaving it editable, so the form stays small and the editor is not faced with dead controls, and constrain catalog or index sizes with rules where the layout needs a minimum or a maximum. Third, mind the validation inversion: a validation fires when its condition evaluates to false, so a "must not be empty" check is written by negating the empty test, and getting this backwards passes exactly when it should fail, and fails quietly.

The rule patterns themselves live in the firstspirit-templating-reference skill's rules references (validation, visibility, editability, value manipulation, and the real-world combinations). Reach there for the XML; keep the design decision here.

Good looks like: fields are clearly labelled and grouped so the editor can see where their content goes, descriptions help the editor (and carry assistant instructions in AI Suite projects), the restriction level fits the workflow, required fields are validated, irrelevant fields are hidden rather than disabled, sensible defaults are pre-filled, and rules are used to guide the editor rather than to secure data or constrain API or assistant input.

### 7. Name for traceability, and fix naming debt at once

Prefixes let you read a variable's origin and purpose from its name. They serve two practical ends: they make debugging easier, and they stop you fetching a value from the wrong context by accident. For example, if a page template and a section nested in it both have a `headline`, an empty section value can silently resolve to the page's value; distinct prefixes prevent that. Keep reference names lower case, English, underscore-separated and short, and correct a wrong reference name immediately. Reference names are developer-facing and stable; display names follow business and editorial-language demands.

Output mode changes this. The prefix convention matters most when the output is HTML or similar. In a pure headless project the variable names surface in the JSON and frontend developers prefer clean keys, so the convention is not always applied. Decide per project, by agreement with the frontend team.

Good looks like: in classic projects, variables carry the correct prefix and reference names follow the convention; in headless projects, naming keeps the JSON clean while keeping contexts unambiguous. See `references/naming-and-conventions.md`.

### 8. Reuse instead of repeat

Factor recurring template code into a format template. Prefer template code over a script. Use the global content area for content shared across pages, and read shared values rather than copying them.

Good looks like: no copy-pasted template logic, shared code lives in a format template, and cross-page content comes from the global content area rather than being duplicated.

### 9. Centralise what should stay consistent

Settings that several templates depend on, such as a date format, belong in project settings, maintained once. Repeating them per template guarantees they drift.

Good looks like: shared formats and configuration are read from project settings, not redefined in each template.

### 10. Write display names and descriptions for the editor

Display names and template descriptions are how an editor picks the right template or section, so write them for the editor, not only for developers. Give each template a meaningful, unique, language-independent description and a clear display name, and give site store folders proper display names.

Good looks like: an editor can choose the right template from its name and description alone, and the site map is readable.

### 11. Model structured and repeated content as data, and respect its dependencies

Content that is structured, repeated across pages, or queryable belongs in the content store as datasets, output through content projection, not rebuilt as page-bound sections. Follow the schema naming conventions (tables plural, rows singular). How a projection is wired and paginated (entries per page, generated page group, the PageGroup function) is a fact question for the firstspirit-templating-reference skill's templates references (content-projection, page-group).

Model the relations deliberately. A parent that owns an ordered list of children carries an `FS_INDEX` over the child table (1:n, editor order kept). A child that belongs to one parent and must be found by it in a query, in content projection or in CaaS carries an `FS_DATASET` linked to a foreign key of the schema (n:1). Do not do both for the same relation. Controlled values that several tables or projects share (a category, a status, an owner) are a small table with a `key` column and translated names, not an `<ENTRIES>` list repeated in each form; a database-backed combobox with `<KEY>` then stores that key. Components may reference a table in any schema of the project, but a query joins only tables of its own schema, so keep tables that must be joined in one schema and split schemas by who maintains and consumes them (Remote Data needs the shared schema in the source project's standard layer). A key must be unique and rules cannot see other rows: uniqueness is enforced by whatever writes the rows (editor discipline, seed script, REST client), and the documentation names it. Use one ordering mechanism per relation, the index order or an `order` column, never both. Decide `useLanguages` per column: a key is never translated, a display name usually is, and a language-dependent component needs one physical column per language, which also means a newly added project language gets no data until its columns exist. Do not make a column mandatory in the schema editor (*Allow empty value* off): the dataset then cannot be saved and the editor sees the database's error, not a hint. Express "required" as a not-empty rule on the form, as for any other field (principle 6). Decide per dataset reference whether it maps onto a foreign-key relation (the database knows the link, queries and aggregation can use it) or onto a column (editorial only); an `FS_INDEX` never maps onto a relation. The facts behind this (column types, what each component stores, foreign keys, queries, Remote Data) are in the firstspirit-templating-reference skill's `gom/database-schema.md`.

Structured content nests, and the nested pieces have dependencies: a component that points at another object needs that object to exist first. An `FS_CATALOG` restricted to a section template cannot be saved until that template exists. A person building the template in the client is guided to create the inner object as they go, so this stays invisible, but it bites on programmatic writes through the API or REST, where nothing stops a broken reference being saved. There the order must be deliberate: create dependencies before the things that point to them, delete in the reverse order, and confirm a destructive or side-effectful write before running it. The write mechanics live in the firstspirit-rest-api skill; the dependency thinking lives here.

For database content the chain is: schema, then its table templates (with foreign keys between them), then one data source per table template, then rows. Rows of a vocabulary table come before the rows that reference them; when the child holds the `FS_DATASET`, the parent row exists first; when the parent holds the `FS_INDEX`, the child rows exist first. Delete in reverse, and for a table template that means the data source first, then the template. A table template cannot be deleted while its data source exists (the delete reports the incoming reference and skips it). Never force the delete past that check: it leaves the data source pointing at nothing, the data source itself is broken from then on, and re-creating a template with the same name does not repair it. Where a dangling reference elsewhere only fails at generation or in the preview, this one is hard to fix at all. A foreign key marked *Aggregation* deletes and releases the linked datasets with their owner. In code, a row has two faces: the `Entity` is the raw record, the `Dataset` is the Content Store element that wraps it with its table template, form data and per-language release state. Change values through the dataset's form data and save the dataset; writing the entity directly bypasses the form mapping.

Good looks like: structured or reusable content is modelled once in the content store and projected where needed; and every reference resolves to an object that already exists, created inner-first and removed outer-first, with destructive API or REST writes confirmed.

### 12. Avoid deprecated and removed components

Do not build new templates on components that have been deprecated or removed. The trap, especially in doc-driven or headless work, is that deprecated components stay in the ODFS and keep working, so a documentation search surfaces them as if they were a live choice. The component existing in the docs is not the same as it being current.

There are two cases. `FS_LIST` was deprecated in 5.2R3 and removed in FirstSpirit 2020-07, and its replacement depends on the FS_LIST type. A larger group of older `CMS_INPUT_*` components (`PICTURE`, `FILE`, `PAGEREF`, `LINKLIST`, `CONTENTLIST`, `OBJECTCHOOSER`, `TABLIST`, and others) has been deprecated since 5.0.107 and consolidated into the `FS_*` components. For example, image selection is `FS_REFERENCE` with a `picture` filter, not `CMS_INPUT_PICTURE`. Treat the ODFS deprecated list as the authority, and check it before adopting any component you have not used recently.

The full list, with the replacement for each component, is in `references/deprecated.md`. Note the scope: this principle is about keeping new templates clean. Migrating a removed component in an existing project is specialist, multi-step, cross-version work that sits outside this skill, so the review flags it for a FirstSpirit expert rather than planning it here. In practice this is rare, since the affected components are very old.

Good looks like: no deprecated or removed components in new templates. Where an existing project still contains one, it is flagged for a FirstSpirit expert, not migrated as part of the review.

### 13. Document the template set as you build it

When you create a template, or a set of templates, produce a documentation alongside it. Capture the instruction that drove the work — the prompt, a wireframe, a spec or a ticket — and then the template set itself: which templates, organised by store type (page, section, format and link templates, scripts, database schemas, workflows), and for each form the components, their variables, whether each value is language-dependent, and whether it is required and how that is enforced.

This does two jobs. It gives the template designer a point to intervene: the documentation is a plan they can read, correct and sign off before anything is written, which matters most on programmatic API or REST writes where no client guides the build (principle 11). And it leaves the project documented — a record of what was built and why, that a later developer or editor can read instead of reverse-engineering the forms.

Produce it before the build where the designer needs to approve, and keep it in step with the result afterwards; a documentation that has drifted from the templates is worse than none. Remember that a required field is enforced with a not-empty validation rule at a restriction level the developer chooses (principle 6) — not with the legacy `allowEmpty` attribute — so record both the requirement and the level that enforces it.

The pattern to fill in — the store-type inventory, the per-component table (variable, label, component, datatype, language, required), and the build order — is in `references/template-documentation.md`.

Good looks like: every generated template set ships with a documentation that states the originating instruction, lists the templates by store type, and for each form records the components with their variables, language settings and requirement status; the designer has had a chance to correct it before any write; and the documentation matches the templates that exist.

### 14. Decide language per component, and keep the two language dimensions apart

FirstSpirit has two separate language dimensions, and conflating them is the usual mistake. One is the editor-facing language of labels, display names and descriptions; the other is `useLanguages`, whether the content itself is translated or held once for all languages. Settle each deliberately.

Editor-facing text can be given per project language, with a default (fallback) language marked `*`; unspecified languages fall back to it, so only the default has to be filled in. Reference names stay single and English regardless (principle 7).

For content, decide `useLanguages` per component. Link templates are never translated (`useLanguages="no"`). Format templates are language-neutral, unless one is used as a render template whose output branches on `#global.language`. For input components the rule of thumb is to assume the content is translated unless the context makes clear it is not — dates, names, visual settings (image position, colour, theme) and access flags are the common language-neutral cases. It is a pattern, not a hard rule.

Catalog and index are the subtle case. The rule is at most one language-dependent level per nesting chain: `useLanguages="yes"` stores deviating values per language, and you may set it at a single level of a nested catalog only. Where you set it decides what varies — a language-dependent *field* inside a language-neutral catalog gives the same entries with translated values (the common setup), whereas a language-dependent *catalog* gives each language its own independent set of entries. Two or more language-dependent levels is the polyglot hierarchy FirstSpirit no longer honours: `forbidPolyglotDataHierarchy="yes"` (default since 5.2R5) silently flattens the inner level to language-independent, so it collapses rather than erroring. Turning that setting on in a legacy project that already has nested language-dependent content can lose data, which is an expert migration, not new-template design (principle 12).

Good looks like: editor-facing languages and content language-dependence are decided separately; every translatable field is `useLanguages="yes"` and every clearly language-neutral field is `"no"`; links and format templates are language-neutral except for explicit `#global.language` render logic; and each catalog carries a single language-dependent level, placed to give either a translated shared list or a per-language list as intended, never nested language dependence. See `references/localisation.md`.

## References

- `references/naming-and-conventions.md`: reference and display names, variable prefixes and when they apply, database schema naming, reuse do's.
- `references/components-and-tags.md`: stores, page and section templates, input component catalogue, datatype mapping, CMS tags, header functions.
- `references/deprecated.md`: deprecated and removed input components and their replacements, with the deprecation or removal version where known.
- `references/template-documentation.md`: the fill-in pattern for documenting a created template set — originating instruction, templates by store type, per-component table, build order.
- `references/localisation.md`: the two language dimensions (editor-facing vs `useLanguages`), language-dependence by template and component type, and the catalog/index shared-structure behaviour.

For anything not covered here or in the references, the authoritative source is the ODFS (Online Documentation FirstSpirit). The reference detail is drawn from older material that predates headless projects and reflects the SiteArchitect, so verify headless, CaaS, ContentCreator and AI Suite specifics against current documentation. This skill is a design reference, not a replacement for the FirstSpirit developer courses.

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
