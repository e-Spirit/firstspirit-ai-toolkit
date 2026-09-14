# References — what points where

Every `StoreElement` can report what it **points at** (outgoing) and what **points at it**
(incoming), as `ReferenceEntry` objects. "Which media does this page use?", "is anything still
linking to this element?", "which references are broken?" are all answered here.

Verification key: **[jar]** = `javap` on `fs-isolated-runtime.jar` FS 5.2.240208 (2026-09-14);
**[javadoc]** = FirstSpirit Access API Javadoc (the the FirstSpirit ODFS documentation `fs-api/` pages);
**[observed]** = seen working on a live project (toolkit field test 2026-09-11) but not re-run
by us; **[verify]** = not yet confirmed.

## On `StoreElement` — the entry points [jar]

```
ReferenceEntry[]     elm.getOutgoingReferences();           // @NotNull — what this element points at   (since 3.1.172)
ReferenceEntry[]     elm.getIncomingReferences();           // @NotNull — what points at this element   (since 3.1.172)
boolean              elm.hasIncomingReferences();           // cheaper than getIncomingReferences().length > 0 (since 4.0)
Set<ReferenceEntry>  elm.getReferences();                   // @Nullable! current outgoing refs as a Set (since 4.0.17)
Set<ReferenceEntry>  elm.getReferences(Language... langs);  // @Experimental, @NotNull — [javadoc] only; NOT on the 5.2.240208 jar
```

Two things bite:

- **`getReferences()` may return `null`; the array methods never do.** Prefer
  `getOutgoingReferences()` unless you specifically want the `Set`. [javadoc]
- **Namesake trap.** `de.espirit.firstspirit.access.store.Data` has its own
  `Reference[] getReferences()` — **deprecated since 5.2.21** and a different return type
  (`Reference`, not `ReferenceEntry`). If auto-complete offers `Reference[]`, you are on the
  wrong interface. [javadoc]

The Javadoc's own advice: to ask "is this element referenced anywhere?" call
`hasIncomingReferences()`, not the array length. [javadoc]

## `ReferenceEntry` — `de.espirit.firstspirit.access` [jar]

Note the package: **`de.espirit.firstspirit.access.ReferenceEntry`** — not `…access.store`,
not `…access.editor.reference`.

| Method | Returns | Note |
| --- | --- | --- |
| `getReferencedElement()` | `IDProvider` **`@Nullable`** | the target as a store element — `null` if not visible in this session, deleted, **broken**, or the target is not an `IDProvider` [javadoc] |
| `getReferencedObject()` | `Object` **`@Nullable`** | the target as whatever it is; same `null` cases [javadoc] |
| `getReferenceString()` | `String` | the textual reference, e.g. `media:logo` — say *what* a broken reference wanted [javadoc] |
| `getDisplayText()` | `String` | editor-facing label |
| `getStoreType()` | `Store.Type` | which store the target lives in — the usual coarse filter |
| `getType()` / `isType(int)` | `int` / `boolean` | typed classification via the constants below — the finer filter |
| `isBroken()` | `boolean` | **internal** targets only: `media:logo` with no such medium is broken; an **external URL is never checked** and returns `false` even if invalid [javadoc] |
| `isRemote()` / `getRemote()` | `boolean` / `String` | target lives in a remote project (`RemoteProjectConfiguration`) [javadoc] |
| `getUsages()` | `ReferenceEntry[]` | where this reference is used — for a broken one, the elements still carrying it [javadoc] |
| `getRelease()` | `boolean` | reference taken from the release state |
| `getId()` / `getProjectId()` | `long` | target ids |
| `refresh()` | `void` | re-resolve |
| `getCategory()` | `String` | |

`ReferenceEntry` is `Serializable` and `Comparable<ReferenceEntry>`. [jar]

### Type constants [jar]

`PAGE_STORE_REFERENCE` · `SITE_STORE_REFERENCE` · `SITE_STORE_FOLDER_REFERENCE` ·
`MEDIA_STORE_REFERENCE` · `TEMPLATE_STORE_REFERENCE` · `RENDER_TEMPLATE_REFERENCE` ·
`SCRIPT_REFERENCE` · `GLOBAL_STORE_REFERENCE` · `CONTENT_STORE_REFERENCE` ·
`CONTENT_REFERENCE` · `STORE_ELEMENT_REFERENCE` · `RELATED_PROJECT_REFERENCE` ·
`EXTERNAL_REFERENCE`

`entry.isType(ReferenceEntry.MEDIA_STORE_REFERENCE)` and
`entry.getStoreType() == Store.Type.MEDIASTORE` both select media. `isType` is the finer
sieve — `SITE_STORE_FOLDER_REFERENCE` and `SITE_STORE_REFERENCE` share `Store.Type.SITESTORE`
but are distinct types.

## Recipe — all media a page uses, including its sections [observed]

Outgoing references of the **page itself** cover page-level fields; each **section** carries
its own. Walk both, keep media, skip broken ones, de-duplicate by id:

```
//!BeanShell
import de.espirit.firstspirit.access.ReferenceEntry;
import de.espirit.firstspirit.access.store.pagestore.Page;
import de.espirit.firstspirit.access.store.pagestore.Section;
import de.espirit.firstspirit.access.store.mediastore.Media;

page = (Page) context.getElement();               // menu / context-menu / FS_BUTTON on a page
seen = new java.util.LinkedHashMap();             // id -> Media, insertion-ordered

collect(elm) {
    for (entry : elm.getOutgoingReferences()) {   // @NotNull — safe to iterate
        if (!entry.isType(ReferenceEntry.MEDIA_STORE_REFERENCE)) continue;
        if (entry.isBroken()) continue;           // report entry.getReferenceString() if you want to list them
        target = entry.getReferencedElement();    // @Nullable even when not broken — check it
        if (target instanceof Media) seen.put(target.getId(), target);
    }
}

collect(page);
for (section : page.getChildren(Section.class, true).iterator()) {
    collect(section);
}
// seen.values() -> the distinct Media the page and its sections reference
```

The composition is the field tester's (task 4 listed 6 images across page and sections on a
live project); every call in it is **[jar]**-verified. Iterate `getChildren(...)` with the
iterator, never a materialised list — see
`firstspirit-scripting/references/common-patterns.md`.

## Incoming — "can I delete this?" [jar]

```
//!BeanShell
if (elm.hasIncomingReferences()) {                // the cheap check first
    for (entry : elm.getIncomingReferences()) {
        // entry.getReferenceString(), entry.isRemote(), entry.getStoreType() ...
    }
}
```

Remote-project references (`isRemote()`) show up here when another project points at this
element. **[verify]:** which end `getReferencedElement()` returns on an *incoming* entry — the
Javadoc says only "the referenced node"; confirm on a live project before relying on it.

## Related

- The element types you get back (`Media`, `Page`, …): [references/stores.md](references/stores.md).
- The inverse direction — resolving a **reference descriptor string** to an element —
  is `StoreElementAgent.loadReference(...)`: [references/agents.md](references/agents.md).
