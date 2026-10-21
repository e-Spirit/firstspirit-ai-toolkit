# Cutting an artifact into templates

How to turn an HTML example, wireframes, a design system or a verbal description into FirstSpirit
templates: which parts become which kind of template, and which questions are worth an answer. Everything
here is a **suggestion with a reason**, not a rule; a project's own conventions win, as long as the
difference is noted. Use the FirstSpirit terms of `common-language-to-fs-terms.md` in every question.

Facts about what a template kind is come from `components-and-tags.md`; component choice and datatypes from
`firstspirit-templating-reference`; naming from `naming-and-conventions.md`; languages from
`localisation.md`. This file only says how to apply them to an artifact.

## Order of work

1. **Read the artifact first.** Write a short reading in FirstSpirit words: the page types you see, the
   parts that repeat, what the header, footer and html head hold, which assets and frameworks it loads.
   The person corrects the reading once; do not ask questions the artifact already answers.
2. **Decide once, for the whole project** (section "Asked once"): languages, link types, rich-text formats.
3. **Work item by item.** One item per part (header, footer, navigation, html head, each repeated part).
   For each: state the default from the map below, ask only what is open, record the answer and its reason.
4. **First a page that shows the whole design, then extract.** Build one page template with the full markup
   inline and a page from it, and check logos, images and CSS against the artifact. Only then move the shared
   parts (header, footer, repeated sections) out into render templates, global content or section templates. The
   visible result comes first so a person can see that the design works before the structure is refined. A
   template and a page created from it are separate steps; each new section template is added to the page, with its
   content, right after it exists. Whether a page template can be changed to read global content while the existing
   page stays valid has not been tested over REST `[verify]`; if the page has to be recreated, say so.
5. **Create in dependency order.** A catalog restricted to a section template needs that template to exist
   first (see `firstspirit-templating-reference`).

## Default map: what is usually in an artifact

| Part of the artifact | Default | Ask only if open |
|---|---|---|
| Page layout that differs by use | one **page template** per distinct layout; a difference in styling only may be a selection in the page form instead of a second page template `[verify]` | How do the page types differ: design, number of content areas, usage? Is it styling only? |
| Variable middle of the page | a **content area** in the page template that takes **sections** | One content area or several? Any restriction on which section templates it allows? (A content area restricts which section templates are allowed, not how many sections it holds.) |
| Header | fixed in the page template, or a **render template** (a format template called with `$CMS_RENDER$`) if several page templates share it; its content can come from the **project settings** | Do editors configure it, and where should the content live? See "Header and footer: where the content lives" |
| Footer | same as the header | same |
| Navigation | built from the **site structure**, referenced from the page template and rendered by a format template | Levels shown? Separate footer navigation? |
| html head | in the page template (or a format template); anything that appears once belongs there | Are title and h1 the same or different, and what is the fallback? Which meta fields? |
| Assets: CSS, JS, icons | **media store** | Linked externally instead? Provide the links now or later |
| Framework | none assumed | Is a framework used for CSS, for JS, or is it a web app? |
| A part an editor fills in and repeats | a **section template**, with a snippet (`snippets.md`) | Which fields? Which component per field? Which field is the label and which the extract? |
| Items repeated inside a part (cards, accordion entries) | **nested items** in the section (a catalog restricted to an item section template) | Or a **dataset** in a data source, if the items are structured records used in several places? |
| Anything on every page with the same pattern | the same decision as header and footer | Does an editor change it? |
| Forms, search, third-party widgets | not modelled: keep as static markup | Keep static, drop, or model later? |

Recurring template code goes into a **format template**; content shared across pages goes into a
**global content area** (principles 8 and 9 in `SKILL.md`). Once-only content belongs in the page template
(principle 2), what may go where is constrained by content-area restrictions (principle 3), and structured
repeated content as data with its dependencies (principle 11).

## Header and footer: where the content lives

Both are common ways to build a header or footer; the choice is a preference with deciding factors.

- **Render template, content from the project settings.** The markup is a render template and the content
  fields are in the project settings. Simple and robust: nothing refers to a page that could be missing.
- **Global content area.** A page template of its own whose page is referred to by its reference name; the
  reference can fail if that page is missing. Its template renders the whole header or footer, and the page
  template only places it with `$CMS_VALUE(#global.gca("REFERENCE_NAME"))$` `[odfs]` (`global-content-areas.md`).

Ask these, in this order, and suggest accordingly:

1. **Does the content vary** with, for example, the place in the site tree? Then a global content area is
   the better option.
2. **Rights.** Global content can be managed with different rights than the project settings, which may
   hold settings that should not be changed without knowledge.
3. **Editing access.** A global content area can be edited on the page, but not separated from the page's
   own content there; access to the whole form may need a script in ContentCreator. Project settings are
   edited in their own form.
4. **Release.** Project settings normally do not go through a release workflow; a global content area is
   content and goes through the release the project uses.

These come from practice, not from the documentation; check the project's release setup before relying
on point 4.

## Forms: groups and order, decided before the template is created

Decide the form's structure when you write it, not afterwards. A form generated from the markup alone comes out in
file order with no groups, which is hard to use `[observed]` 2026-10-16.

- **Order** is the order an editor fills the fields in, not the order of the markup.
- **Groups** (`CMS_GROUP`): fields that belong together are one group, for example an image with its caption and
  style toggle. A form with many fields gets tabs.
- **Labels and descriptions** per principle 6 in `SKILL.md`; `CMS_LABEL` for in-place instructions.
- **Changing it later** (grouping or order of an existing template) must not rename a field, change an editor type
  or break a rule target. Whether groups and tabs can be added to an existing template over REST without recreating
  it has not been tested `[verify]`.

Review the same points: a form with ungrouped fields in markup order is a finding.

## Without an artifact

Ask in this order; each answer decides the next question, and each leaf ends in a suggestion.

```
How many page types?
  1  → how many content areas?
         1  → any special placement, or a restriction on allowed section templates?
         >1 → how do they differ: placement, restriction, other?
  x  → how do the page types differ: design, number of content areas, usage, other?
Is the header the same on every page?
  yes → can editors configure it?  no  → suggest a render template, fixed content
                                   yes → where does the content live? ask the deciding factors below:
                                         project settings (render template) or global content area
  no  → what makes it differ: page type, part of the site, other?
Is the footer the same on every page?     (same questions)
Is anything else repeated on every page?  (same questions)
html head: title and h1 the same or different? fallbacks? which meta fields? assets in the media store or linked?
Framework: CSS? JS? a web app?
```

## Asked once, for the whole project

- **Project languages** first. Read them from the project and print them back, so the right ones are
  selected for labels and content (`localisation.md`).
- **Link types** editors may use (internal page, external URL, media, mail), then per field only where the
  artifact shows a limit.
- **Rich-text formats**: take them from the formats the artifact actually uses (bold, lists, quotes, classes)
  and offer exactly those.
- **Required fields**: use rules, not `allowEmpty` (principle 6).

Ask these as one short question each with suggestions and an own-answer option, not once per field.

## Folders and names for what you create

Put the templates you create into folders by role (see `naming-and-conventions.md`, *Organising templates*),
for example one folder for section templates of a kind and one for render templates. Where several
templates serve specific use cases that their names do not reveal, agree one naming pattern early and
record it with the decisions.

## What to record

For each item: the FirstSpirit term it became, the evidence in the artifact, the answer and the reason, and
who confirmed it. A skipped question is recorded as "default", so it can be revisited.

## What this file does not decide

Enterprise-scale content strategy, language structure across many sites and the choice of tooling are
decided by people before this work starts. Read their documents; do not try to elicit them with questions.
Rights, environments and infrastructure are not asked here; keep landscape detail out of anything written
down beyond what the work needs.
