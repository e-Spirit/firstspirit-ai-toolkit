# Deprecated and removed components

Reference list of FirstSpirit input components that should no longer be used in new templates, with the replacement for each. This backs principle 12 in SKILL.md. Source: the ODFS deprecated list (FirstSpirit Access-API) and the FS_LIST migration guide. Verify against the current ODFS on each release, since deprecation and removal status can change.

**Source of truth.** Within the portfolio, the firstspirit-templating-reference skill's `deprecated.md` owns the deprecated→current mappings (tracked against the documentation). This list is the design-facing view backing principle 12; where the two differ, templating-reference wins on the facts.

The key point: a deprecated component stays in the ODFS and usually keeps working, so a documentation search will surface it as if it were a live option. Existing in the docs is not the same as being current. Always check this list, and the ODFS deprecated list, before adopting a component you have not used recently.

## Scope: preventing, not migrating

The job of this file is to keep deprecated and removed components out of new templates and projects. That is principle 12's check, and it is fully in scope.

Migrating existing removed components is out of scope for this skill. It is specialist work: a multi-step migration across several server versions, which is not possible in cloud services and needs a dedicated, experienced FirstSpirit expert. Depending on the component it can mean content loss or losing the ability to edit and save. When a review finds a removed component in an existing project, flag it and hand it to a FirstSpirit expert. Do not plan or attempt the migration here.

In practice this is rarely a live concern. These components are very old. FS_LIST was the last one that genuinely needed attention, and that was at least five years ago. The list is kept complete for reference, but it should not affect new projects.

## Deprecated versus removed

The two states are not the same, and the difference matters for a migration plan.

- **Deprecated:** still documented, still works, but should not be used in new templates.
- **Removed:** no longer usable. Migrating existing use is specialist work and out of scope for this skill (see Scope above). Flag it for a FirstSpirit expert.

The replacements below come from the ODFS Access-API deprecated list and the FS_LIST migration guide. Exact removal dates are not all in one place, and for new work the date does not matter: the rule is simply not to use any of these. Removal timing only matters when someone is dealing with an existing project, which is the specialist hand-off case above.

## The `CMS_INPUT_*` group (deprecated since 5.0.107)

These older components were consolidated into the `FS_*` components. The deprecation is long-standing, so treat them as off-limits for new templates.

| Deprecated component | Replacement | Note |
|---|---|---|
| `CMS_INPUT_PICTURE` | `FS_REFERENCE` | Use a `FILTER` with `ALLOW type="picture"`. |
| `CMS_INPUT_FILE` | `FS_REFERENCE` | Use a `FILTER` with `ALLOW type="file"`. |
| `CMS_INPUT_PAGEREF` | `FS_REFERENCE` | Any reference, restricted by `FILTER`. |
| `CMS_INPUT_LINKLIST` | `FS_CATALOG` | List of links maintained in one component. |
| `CMS_INPUT_CONTENTLIST` | `FS_INDEX` | Lists from internal or external data. |
| `CMS_INPUT_OBJECTCHOOSER` | `FS_DATASET` | Select a single dataset. |
| `CMS_INPUT_TABLIST` | `FS_INDEX` | |
| `CMS_INPUT_CONTENTAREALIST` | `FS_CATALOG` | Was a list of sections, so it consolidates into `FS_CATALOG`, the same target as `CMS_INPUT_LINKLIST`. |

`FS_REFERENCE` is the single consolidation point for the old media, file and page-reference choosers. Its behaviour is shaped by the inner `FILTER` tag, so the same component covers what used to be three.

## `FS_LIST` (deprecated 5.2R3, removed 2020-07)

`FS_LIST` is a separate case. It was removed, not just deprecated, so any remaining use must be migrated. The replacement depends on the FS_LIST type.

| FS_LIST type | Replacement |
|---|---|
| `INLINE` | `FS_CATALOG` |
| `DATABASE` | `FS_INDEX` |
| `PAGE` | `CMS_INPUT_SECTIONLIST` |
| with `MEDIAMODE` | `FS_INDEX` using the `DatasetDataAccessPlugin` (shipped by default) |

## Using this in a review

When reviewing a template, check every input component against this list. For each deprecated or removed component found:

1. Name it and its state (deprecated or removed).
2. Give the replacement from the tables above, so the right component is used in any new work.
3. If it is a removed component in an existing project, flag it for a FirstSpirit expert. Do not propose a migration here (see Scope).

This is also where the two FirstSpirit skills divide cleanly. A documentation or API reference tells you a component exists and how its parameters work, including the deprecated ones, because the docs keep them. This file is the layer that says which ones not to use and what to use instead.
