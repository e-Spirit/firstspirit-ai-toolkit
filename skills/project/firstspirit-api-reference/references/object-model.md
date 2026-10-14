# The FirstSpirit object model

Every editorial object in a project lives in one of **six stores**, arranged as a
tree. Each tree node implements a specific Access-API interface. This file maps
the trees to their interfaces and covers the base type all nodes share.

> [assets/firstspirit-object-model.md](../assets/firstspirit-object-model.md) shows all six
> trees at a glance as text (one expansion per tree plus a parent/child index per interface).

---

## The six stores and their trees

| Store | `Store.Type` | Tree (folder → … → leaf) → interfaces |
| --- | --- | --- |
| **Page content** | `PAGESTORE` | `PageFolder` → `Page` → `Body` → `Section` (also `SectionReference`, `Content2Section`) |
| **Site structure** | `SITESTORE` | `PageRefFolder` → `PageRef`, `DocumentGroup` |
| **Media** | `MEDIASTORE` | `MediaFolder` → `Media` (Picture / File) |
| **Data sources** | `CONTENTSTORE` | `ContentFolder` → `Content2` — the rows are **not** tree children: `content2.getDatasets(...)` → `Dataset`, whose `getEntity()` is a `de.espirit.or.schema.Entity` (a `Map<String,Object>`, not a store element) `[jar]` |
| **Global settings** | `GLOBALSTORE` | `GlobalContentArea` (itself a `GCAFolder`) → `GCAFolder` → `GCAPage` → `GCABody` → `GCASection`; the root also holds `ProjectProperties` and `URLProperties` `[jar]` |
| **Templates** | `TEMPLATESTORE` | fixed containers under the root `[jar]`: `PageTemplates` / `SectionTemplates` / `LinkTemplates` → `TemplateFolder` → `PageTemplate` / `SectionTemplate` / `LinkTemplate`; `FormatTemplates` → `FormatTemplateFolder` → `FormatTemplate` (not a `Template`, so never in a `TemplateFolder<T extends Template>`); `Scripts` → `ScriptFolder` → `Script`; `Schemes` → `SchemaFolder` → `Schema` → `Query`, `TableTemplate`; `Workflows` → `WorkflowFolder` → `Workflow` |

Packages: `de.espirit.firstspirit.access.store.pagestore` / `.sitestore` /
`.mediastore` / `.contentstore` / `.globalstore` / `.templatestore`.

## `StoreElement` → `IDProvider` — the common base

Every tree node is a `StoreElement`, and (almost) every one is an `IDProvider`.
These methods therefore work on *any* element:

```
// Identity
long        getId();                     // internal numeric id
boolean     hasUid();                    // call BEFORE getUid()/getUidType()
String      getUid();                    // unique identifier (throws if !hasUid)
UidType     getUidType();                // the namespace of the uid
String      getName();                   // element name — @Deprecated on Page/PageRef/Media since 4.1.10, use getUid() [javadoc]
String      getReferenceName();          // @Nullable — the name $CMS_REF(...)$ uses; null if the element cannot be referenced [javadoc]
String      getDisplayName(Language);    // editor-facing label

// Navigation
IDProvider  getParent();                 // null for store roots / deleted elements
Listable    getChildren();               // direct children
Listable<T> getChildren(Class<T> type, boolean recursive);   // filtered, optionally deep
Store       getStore();                  // the owning Store
Store.Type  getStore().getType();

// Type
String      getElementType();            // used by fs.type queries

// References — see references/references.md
ReferenceEntry[] getOutgoingReferences(); // @NotNull — what this element points at
ReferenceEntry[] getIncomingReferences(); // @NotNull — what points at this element
boolean          hasIncomingReferences(); // cheaper than getIncomingReferences().length > 0
```

> **Iterate `getChildren(...)` with an iterator**, never by materialising a full
> list — recursive child sets can be huge (see `firstspirit-scripting`
> conventions).

## Modifying an element — lock / save / revert

Writes require an exclusive lock; always release in `finally` (full pattern in
`firstspirit-scripting/references/common-patterns.md`):

```
element.setLock(true, false);            // (lock, recursive)
try {
    // ... mutate ...  e.g. element.setFormData(fd);
    element.save("comment", false);      // persist; the boolean controls recursion
} finally {
    element.setLock(false, false);
}

element.revert(revision, recursive, ignoreRevertTypes);   // roll back to a Revision
```

Field and property changes are **local** until `save()`. Structural PageStore operations
(`createPage`, `createPageFolder`, `createSection`, `moveChild`, `delete()`, restore) take effect on the server
immediately `[observed]`.
The trailing boolean on `setLock`/`save` controls **recursion**: **pages are
typically locked and saved recursively** (`true`), most other elements
non-recursively (`false`). Don't pre-check the lock — attempt it and catch
`LockException` (see `firstspirit-scripting`).

**Why production Java nests two `try` blocks.** `setLock(true)` itself throws
`LockException` and `ElementDeletedException` `[jar]`. If the lock attempt failed, the
element is locked by someone else or gone, and calling `setLock(false)` in a `finally`
that covers the lock attempt would try to unlock what you never locked. So the unlock
`finally` wraps only the work *after* a successful lock, and the exceptions are caught
outside:

```
try {
    element.setLock(true, false);
    try {
        // ... mutate ...
        element.save("comment", false);
    } finally {
        element.setLock(false, false);        // reached only if the lock succeeded
    }
} catch (LockException | ElementDeletedException e) {
    // report; do not retry blindly
}
```

Both exceptions are checked (`de.espirit.common.CheckedException`) `[jar]`. A bare
`save("comment")` on a locked element with no data change still creates a **new revision**,
which is the documented way to force a regeneration of that element downstream `[observed]`.

## `Store.Type` values

`PAGESTORE`, `SITESTORE`, `MEDIASTORE`, `CONTENTSTORE`, `GLOBALSTORE`,
`TEMPLATESTORE` — passed to `StoreAgent.getStore(type, release)`.

## `IDProvider.UidType` values

The namespace a UID is unique in. Most UID-bearing interfaces also expose a static
`UID_TYPE` field (e.g. `PageFolder.UID_TYPE`, `Media.UID_TYPE`); `GCAFolder`, `ContentFolder`
and `Dataset` do not `[jar]` — use the table below for those.

| UidType | Applies to |
| --- | --- |
| `PAGESTORE` | `Page`, `PageFolder` |
| `SITESTORE_LEAF` | `PageRef`, `DocumentGroup` |
| `SITESTORE_FOLDER` | `SiteStoreFolder` |
| `MEDIASTORE_LEAF` | `Media` |
| `MEDIASTORE_FOLDER` | `MediaFolder` |
| `CONTENTSTORE` | `Content2` |
| `CONTENTSTORE_DATA` | dataset rows |
| `GLOBALSTORE` | global-store elements |
| `TEMPLATESTORE` | `PageTemplate`, `SectionTemplate`, `MasterTemplate`, **`Schema`**, `Script`, `Workflow` `[jar]` |
| `TEMPLATESTORE_SCHEMA` | `TableTemplate`, `Query` — **not** `Schema` (that is `TEMPLATESTORE`; `loadStoreElement(uid, TEMPLATESTORE_SCHEMA, …)` never finds a schema) `[jar]` |
| `TEMPLATESTORE_LINKTEMPLATE` | `LinkTemplate` |
| `TEMPLATESTORE_FORMATTEMPLATE` | `FormatTemplate` |
| `TEMPLATESTORE_TABLEFORMATTEMPLATE` | table format template |
| `TEMPLATESTORE_STYLETEMPLATE` | style template |

Used with `StoreElementAgent.loadStoreElement(uid, uidType, release)` — see
[agents.md](agents.md).
