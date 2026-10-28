# Server-side release from a script or module

A workflow's release step, a BeanShell script or a module can release elements on the server
through the Access API, and choose **what else** is released with the element. This file is the
model: the default and the specific release, what each option pulls in, the order that makes a
dependent release work, and **language-dependent release**. Tags: **[odfs]** *Advanced topics ›
Server-side release* and its subpages (FirstSpirit 2026.5); **[jar]** `javap` on
`fs-isolated-runtime-5.2.261011.jar` and `fs-isolated-runtime.jar` (5.2.240208) 2026-10-23.
Nothing here was run on a server **[verify]**. The ODFS workflow demo that does this in a script
is `serverrelease`: `references/official-examples.md`. A workflow's release step: `references/workflow-model.md`.

Release flag and `CAN_RELEASE` right of a workflow: `references/workflow-model.md`; granting the right: `firstspirit-configuration`; the interfaces: `firstspirit-api-reference`.

## Two ways, and the one to use

| | Call | Status |
| --- | --- | --- |
| Current API | `OperationAgent.getOperation(ReleaseOperation.TYPE)`, `de.espirit.firstspirit.store.operations.ReleaseOperation` | **use this** |
| Old API | `de.espirit.firstspirit.access.AccessUtil.release(...)`, four overloads | **deprecated** on both jars [jar]; the ODFS page says no longer developed [odfs] |

How to obtain an operation: `firstspirit-operations/references/operations-catalogue.md`.

`ReleaseOperation` [jar] is fluent; each setter returns the operation:

| Member | Meaning |
| --- | --- |
| `checkOnly(boolean)` | `true` runs the release as a test and **moves nothing to the release state**; use it to find errors first |
| `ensureAccessibility(boolean)` | release never-released nodes of the parent chain |
| `recursive(boolean)` | release the child elements too |
| `dependentReleaseType(IDProvider.DependentReleaseType)` | `NO_DEPENDENT_RELEASE` (default), `DEPENDENT_RELEASE_NEW_ONLY`, `DEPENDENT_RELEASE_NEW_AND_CHANGED` |
| `withComment(String)` | release comment |
| `languages(Language...)` | **5.2.261011 only**: release only these languages; none = all languages (see below) |
| `perform(IDProvider...)`, `perform(Collection<IDProvider>)` | run; `throws Exception`; returns `ReleaseOperation.ReleaseResult` |

`ReleaseResult` [jar]: `isSuccessful()`, `getReleasedElements()`, `getReleaseFailedElements()`,
`getProblematicElements()` (a map from `ReleaseProblem` to the elements). The old `AccessUtil`
methods return a `ServerActionHandle<? extends ReleaseProgress, Boolean>` instead
(`getProgress`, `getResult`, `isRunning`, `cancelAction`, `checkAndThrow` [jar]); the handle
carries the release status and log. [odfs] [jar]
The `AccessUtil.release(...)` parameters correspond one to one: `(toRelease, checkOnly)` for the
default release, `(start, checkOnly, ensureAccessibility, recursive, dependentType)` for the
specific one, each with an optional trailing `String` comment overload. [jar]

## Default release

The element **plus the options that the type's default implies**; they differ by type and **cannot
be changed**. [odfs] Examples from the page: a page in the page store is released with its
sections and with parent elements that were never released; a page reference in the site store
is released alone. `checkOnly` runs the same release as a test. [odfs]

## Specific release: the four options

Combine them freely; a wide release may release more than anyone wanted, so run it with
`checkOnly(true)` first. [odfs]

| Option | What it adds | Limit |
| --- | --- | --- |
| `ensureAccessibility` (parent chain) | Walks from the start node to the store root and releases the nodes that were **never released**. Nodes released before are **not** released again, even if changed (for example a folder that gained a page reference). | Current store, unless combined with a dependent release |
| `recursive` | Every child of the start node. Example: folder "Folder 1" releases "Ref 1", "Folder 2" and "Ref 2". | Children of the start node only, in the current store; never the children of dependent objects in another store |
| `DEPENDENT_RELEASE_NEW_ONLY` | Objects the start node **references**, if never released (a medium used in an image component) | Outgoing references, one direction (below) |
| `DEPENDENT_RELEASE_NEW_AND_CHANGED` | Same, plus referenced objects that were changed since their last release | same |

**`ensureAccessibility=false` still keeps the object reachable.** The element is added to the
**release child list** of its parent node:
- parent changed (was released before): the element is reachable in the release state, the parent
  itself stays unreleased;
- parent **new** (never released): the element is **not reachable** in the release state, and
  references to it can be invalid there. [odfs]

The ODFS use case: an editor may release a page reference but has no right to release the folder
above it; the reference should enter the release state, other new changes in the folder should
not. The child list does that, and the folder is released later by whoever may. [odfs]

### Combinations

| Combination | Result |
| --- | --- |
| parent chain + recursive | Limited to **one store** (no dependencies followed). If a child references an object that was never released (a new page, a new medium), the release **errors**; references to objects that were released before resolve to their last released version and succeed. |
| parent chain + dependent | The dependent release applies to the start node **and** to the never-released parent chain; and the chain walk is repeated for every dependent object, so a new folder above a referenced medium is released too, and a never-released parent of a referenced page as well. A parent that was released before (merely changed) is not released, and its dependents are not followed. |
| dependent without the others | Only outgoing references of the start node, not its children (the example: "Folder 1" releases the one medium its own form references) |
| all three | Widest; see the warning above |

### Order: the reference direction is one way

Dependent release follows **outgoing references in one direction only**, to avoid cycles. It
takes the objects of the page and media stores that content, structure (site store) or data
objects reference. The reverse direction does not work. [odfs]

| Release started in | References followed |
| --- | --- |
| Site store | to the data (content) store and the media store; the ODFS example also releases the page that a page reference points to |
| Page store | to the media store |
| Page store | **not** to the site store |
| Media store | **not** to the site store or the page store |
| Objects of a **remote project** | **not** followed |

So the **start node decides the reach**: a release that must cover everything that belongs
together starts at the top of that direction (the site store) and uses the dependent option;
started in the media store it pulls in no object of another store. The page calls this "the order to maintain"
when all dependent objects are to be included. [odfs]

Not followed even though the reference graph shows them: [odfs]
- a page's `FS_REFERENCE` to a **page reference** (only the page is released);
- a medium hard-coded in a template, for example `$CMS_REF(media:"XXX")$`;
- in a `CMS_INPUT_LINK`/`CMS_INPUT_DOM`/`CMS_INPUT_DOMTABLE`: the referenced **medium** is released,
  the referenced **page reference** is not;
- a medium **referenced inside a parsed CSS file** (file parsing "yes").

**Cycles.** Two pages whose sections reference each other's sections, none released yet, cannot be
released automatically. Remove one section reference, release the page it pointed to, restore the
reference, release the other page. [odfs]

## Language-dependent release

*Advanced topics › Server-side release › Language-Dependent Release* [odfs]. Available by default;
needs 2025.1 or later and is **not backward
compatible with earlier versions**.

**What it changes.** An element can be released **for chosen languages**: when the English content
is ready and the other languages are not, release only English.

**How the versions work.** Versioning is unchanged: every change creates a "Current" version, every
release a "Release" version. What is new is that a Release version is **labelled with the
languages it released**, so there is no longer one common release version. When a page is
generated, each language is rendered from **the latest Release version labelled with that
language**. Worked example from the page:

| Version | Event | Label |
| --- | --- | --- |
| V1 | create | Current |
| V2 | change | Current |
| V3 | release EN | Release "EN" |
| V4 | change | Current (not a release) |
| V5 | release DE | Release "DE" |

After V5 the English output comes from V3, the German output from V5. If an element is released in
two languages one after the other **without a change in between**, the two release versions are
merged into one labelled with both. [odfs]

**Setting up.** Switch it on per project in the ServerManager, project settings; it is **on by
default**. Before using it in an **existing project**, save once each schema that is meant for
language-dependent release; FirstSpirit logs an error if the database column it needs is missing,
so that nothing is released wrongly. [odfs]

**Limits.** [odfs]
- Only **language-dependent media** release per language. Changing a language-independent medium in
  one language puts the new version into **every** language at the next generation.
- Applies to **data** only; hierarchies (the structure) are **excluded**.
- Started from a workflow, only **one workflow runs per element at a time**: the next language can
  be released only after the first release has finished.

**API.** `ReleaseOperation.languages(Language...)` limits the release to those languages;
without it, all languages as before. The method is on the 5.2.261011 jar and **absent from
5.2.240208** [jar]: a module that must run on both cannot call it directly.

```
op = operations.getOperation(ReleaseOperation.TYPE);   // OperationAgent
result = op.checkOnly(true).ensureAccessibility(true).recursive(false)
           .dependentReleaseType(IDProvider.DependentReleaseType.NO_DEPENDENT_RELEASE)
           .languages(english).perform(pageRef);        // languages(...) 5.2.261011 only
```

The snippet is assembled from the `javap`-verified signatures; it was not executed **[verify]**.

## Checklist for a release script

1. `checkOnly(true)` first, read `getProblematicElements()`.
2. Decide the four options on purpose; "everything on" is rarely what the editor expects.
3. Start a dependent release at the top of the reference direction (site store), not at a medium.
4. The user running the script needs the right to release every element involved
   (`firstspirit-configuration/references/permissions.md`); the check-only run shows missing rights.
5. In several languages: say which, and expect the next release to wait for the first.
