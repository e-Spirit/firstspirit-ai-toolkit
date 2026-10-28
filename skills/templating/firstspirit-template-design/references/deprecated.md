# Deprecated and removed components

The design view behind principle 12 in SKILL.md: why deprecated components are a trap, what is in and out of scope, and how a review reports a hit. The components themselves, their status and the replacement for each are one table in the `firstspirit-templating-reference` skill (`references/deprecated.md`), tracked against the ODFS deprecated list and the FS_LIST migration guide.

**Ownership.** Facts (which component, deprecated or removed since when, what replaces it) live in templating-reference and only there since 2026-10-23; this file holds the judgement. Where a sentence here seems to state a fact, the reference wins.

The key point: a deprecated component stays in the ODFS and usually keeps working, so a documentation search will surface it as if it were a live option. Existing in the docs is not the same as being current. Always check this list, and the ODFS deprecated list, before adopting a component you have not used recently.

## Scope: preventing, not migrating

The job of this file is to keep deprecated and removed components out of new templates and projects. That is principle 12's check, and it is fully in scope.

Migrating existing removed components is out of scope for this skill. It is specialist work: a multi-step migration across several server versions that needs a dedicated, experienced FirstSpirit expert. On FirstSpirit Cloud, where every server runs the current version, a removed component cannot be migrated at all, because it no longer exists in that version; the removal of a component is announced ahead and migrated over several releases, with migration guides and dedicated communication, which is possible there. Once a component is removed, forms that contain it can no longer be edited and the expected output is no longer generated, and the change cannot be undone, not even by a server downgrade `[odfs]` (FS_LIST migration guide, FirstSpirit 2026.11). Do not rely on a chat answer that a removed component can still be used or migrated by a quick edit; check the ODFS and ask Technical Support. When a review finds a removed component in an existing project, flag it and hand it to a FirstSpirit expert. Do not plan or attempt the migration here.

In practice this is rarely a live concern. These components are very old. FS_LIST was the last one that genuinely needed attention, and that was at least five years ago. The list is kept complete for reference, but it should not affect new projects.

## Deprecated versus removed

The two states are not the same, and the difference matters for a migration plan.

- **Deprecated:** still documented, still works, but should not be used in new templates.
- **Removed:** no longer usable. Migrating existing use is specialist work and out of scope for this skill (see Scope above). Flag it for a FirstSpirit expert.

The replacements in the reference come from the ODFS Access-API deprecated list and the FS_LIST migration guide. Exact removal dates are not all in one place, and for new work the date does not matter: the rule is simply not to use any of these. Removal timing only matters when someone is dealing with an existing project, which is the specialist hand-off case above.

## The list

The components, their status and the replacement for each, including the `FS_LIST` successor by type, are one table
in the `firstspirit-templating-reference` skill (`references/deprecated.md`, with the deprecated usage patterns and the
version-conditional items). This file no longer repeats it; read it from there when reviewing.

## Using this in a review

When reviewing a template, check every input component against this list. For each deprecated or removed component found:

1. Name it and its state (deprecated or removed).
2. Give the replacement from the reference table, so the right component is used in any new work.
3. If it is a removed component in an existing project, flag it for a FirstSpirit expert. Do not propose a migration here (see Scope).

This is also where the two FirstSpirit skills divide cleanly. A documentation or API reference tells you a component exists and how its parameters work, including the deprecated ones, because the docs keep them. This file is the layer that says which ones not to use and what to use instead.
