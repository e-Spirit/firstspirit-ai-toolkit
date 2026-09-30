# Naming and coding conventions

Look-up reference for FirstSpirit naming and coding conventions. The principles in SKILL.md explain why these matter; this file holds the detail. Source: the two FirstSpirit coding-conventions documents and an older FirstSpirit overview handout, with corrections from current practice noted inline.

## Reference names versus display names and descriptions

- **Reference names** are developer-facing and exist for maintainability. They are what most of this file governs.
- **Display names and descriptions** are editor-facing. An editor uses them to select the right template or section, so write them for the editor. Display names also follow business and editorial-language demands and are set per project.
- Correct a wrong or misspelled reference name immediately, even at real cost. Naming debt left in place spreads.

## Reference names for folders and objects

Applies to folders and objects in the content store, site store, template store and media store:

- Lower case
- English
- Words separated with underscores
- Indexes separated with underscores
- Preferably short

Examples: `news`, `product_categories`, `press_archive`, `whoiswho_changed_1`, `whoiswho_changed_2`.

A template's own reference name follows these rules too — no type prefix. The prefix tables under *Variable naming and prefixes* below govern **variables**, grouped by the template type the variable is defined in. (Many projects do prefix template uids by type, `pt_`/`st_`/…; that is a project convention, not part of this standard.)

Site store: every folder should have a proper display name, visible in the site map, whether or not the site map is already in use.

## Template descriptions

Every template has a language-independent description in addition to its display and reference name. The description helps an editor choose the right template. Unless specified otherwise:

- English, or consistently the developers' language
- Significant and unique
- Words separated with blanks

## Variable naming and prefixes

General rules:

- English
- Accurate prefix, separated with an underscore (see tables below)
- No special characters, no blanks, no hyphens
- Words separated with camel case or underscores

Examples: `pt_title`, `st_picture`, `ss_showNavigation`, `gv_absoluteUrlPrefix`.

### Why prefixes, and when they apply

Prefixes serve two practical ends:

1. **Debugging.** You can read a variable's origin and purpose from its name.
2. **Avoiding accidental cross-context resolution.** If a page template and a section nested within it both define `headline`, an empty section value can silently resolve to the page's value. Distinct prefixes prevent that.

**Output mode caveat.** The prefix convention matters most when the output is HTML or similar. In a pure headless project the variable names surface in the JSON, and frontend developers prefer clean keys, so the convention is not always applied. Decide per project, by agreement with the frontend team, and keep the contexts unambiguous by other means if prefixes are dropped.

### Prefixes by template type

| Template type | Prefix |
|---|---|
| Page template | `pt_` |
| Section template | `st_` |
| Link template | `lt_` |
| Format template (and table style templates) | `ft_` |
| Project settings | `ps_` |
| Metadata template | `md_` |
| Page template of a global content area (GCA) | `gc_` |
| Table template | `tt_` |
| Script | `sc_` |

### Prefixes for other variables

| Variable type | Prefix | Notes |
|---|---|---|
| Site store variable | `ss_` | Define at site store root level. |
| Result of a header function call | `fr_` | Add a secondary template prefix for where it was calculated, e.g. `fr_st_sidebarMenu`, `fr_pt_mainNavigation`. |
| Temporary variable set with `CMS_SET` | `set_` | Add a secondary template prefix, e.g. `set_st_teaserbox`, `set_pt_productHighlight`. |
| Parsed data in the media store | `ms_` | e.g. `ms_color`. |
| Loop variable in `CMS_FOR` | `for_` | Add a secondary template prefix for where the loop runs. |
| Global value (set then overridden, not read-only) | `gv_` | Use `gv_` for site store variables that are overridden during deployment. |
| Deployment value (defined only for a deployment target) | `dv_` | |

## Input component names, labels and descriptions

- The `name` attribute follows the variable rules above. In headless projects this name surfaces in the JSON, so apply the output-mode caveat above.
- **Labels** are editor-facing: the label is the field name the editor reads.
- **Descriptions** show on mouseover as a tip for the editor. In AI Suite projects, the description is also used to carry prompts or instructions for an assistant, so treat it as a working field.

## Database schema naming

- **Tables:** English, plural, lower case, words separated with underscores.
- **Rows:** English, singular, lower case, words separated with underscores.

## Reuse, do's

- Maintain recurring template code in a format template where possible.
- Prefer template code over a script.
