# The FirstSpirit object model

Every editorial object in a project lives in one of **six stores**, arranged as a
tree. Each tree node implements a specific Access-API interface. This file maps
the trees to their interfaces and covers the base type all nodes share.

> The diagram [assets/firstspirit-object-model.png](../assets/firstspirit-object-model.png)
> (DTA "FirstSpirit-Objects" poster) shows all six trees at a glance.

---

## The six stores and their trees

| Store | `Store.Type` | Tree (folder → … → leaf) → interfaces |
| --- | --- | --- |
| **Page content** | `PAGESTORE` | `PageFolder` → `Page` → `Body` → `Section` (also `SectionReference`, `Content2Section`) |
| **Site structure** | `SITESTORE` | `PageRefFolder` → `PageRef`, `DocumentGroup` |
| **Media** | `MEDIASTORE` | `MediaFolder` → `Media` (Picture / File) |
| **Data sources** | `CONTENTSTORE` | `ContentFolder` → `Content2` → (`Dataset` / `Entity` rows) |
| **Global settings** | `GLOBALSTORE` | `GCAFolder` → `GCAPage` → `GCABody` → `GCASection` (Global Content Area) |
| **Templates** | `TEMPLATESTORE` | `TemplateFolder` → `PageTemplate`, `SectionTemplate`, `FormatTemplate`, `LinkTemplate`; `Script`; `Schema` → `Query`, `TableTemplate`; `Workflow` |

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
String      getName();                   // reference name
String      getDisplayName(Language);    // editor-facing label

// Navigation
IDProvider  getParent();                 // null for store roots / deleted elements
Listable    getChildren();               // direct children
Listable<T> getChildren(Class<T> type, boolean recursive);   // filtered, optionally deep
Store       getStore();                  // the owning Store
Store.Type  getStore().getType();

// Type
ElementType getElementType();            // used by fs.type queries
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

Store elements are **local copies** — changes aren't on the server until `save()`.
The trailing boolean on `setLock`/`save` controls **recursion**: **pages are
typically locked and saved recursively** (`true`), most other elements
non-recursively (`false`). Don't pre-check the lock — attempt it and catch
`LockException` (see `firstspirit-scripting`).

## `Store.Type` values

`PAGESTORE`, `SITESTORE`, `MEDIASTORE`, `CONTENTSTORE`, `GLOBALSTORE`,
`TEMPLATESTORE` — passed to `StoreAgent.getStore(type, release)`.

## `IDProvider.UidType` values

The namespace a UID is unique in. Each UID-bearing element also exposes a static
`UID_TYPE` field (e.g. `PageFolder.UID_TYPE`).

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
| `TEMPLATESTORE` | page/section templates |
| `TEMPLATESTORE_SCHEMA` | `Schema` |
| `TEMPLATESTORE_LINKTEMPLATE` | `LinkTemplate` |
| `TEMPLATESTORE_FORMATTEMPLATE` | `FormatTemplate` |
| `TEMPLATESTORE_TABLEFORMATTEMPLATE` | table format template |
| `TEMPLATESTORE_STYLETEMPLATE` | style template |

Used with `StoreElementAgent.loadStoreElement(uid, uidType, release)` — see
[agents.md](agents.md).
