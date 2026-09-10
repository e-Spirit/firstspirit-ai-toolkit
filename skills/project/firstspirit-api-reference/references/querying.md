# Searching the repository — QueryAgent

The `QueryAgent` (Search API) answers text queries for project elements. You pass
a query string in the FirstSpirit query syntax and iterate the matching elements.

Package: `de.espirit.firstspirit.agency.QueryAgent`.

---

## Basic usage (BeanShell)

```
//!BeanShell
import de.espirit.firstspirit.agency.QueryAgent;

agent = context.requireSpecialist(QueryAgent.TYPE);
result = agent.answer("fs.uid = solar_concept_car", null);   // (query, QueryParameters)
for (hit : result.iterator()) {
    print(hit);
}
result.close();                                              // release resources
```

- `answer(String query, QueryParameters parameters)` — pass `null` for
  `parameters` (reserved for future use).
- The result is **lazy and blocking**: iterating starts a server search; each new
  iterator restarts it. **Close** the result when done.
- The deprecated `answer(String)` (single-arg) still exists — prefer the two-arg
  form.

## Query syntax (`fs.*` fields)

Queries combine field comparisons with `and` / `or`. Common fields:

| Query | Finds |
| --- | --- |
| `fs.uid = solar_concept_car` | element by UID |
| `"solar_concept_car MEDIASTORE_LEAF"` | a media / reference by name (quoted) |
| `"solar_concept_car MEDIASTORE_LEAF" or fs.uid = solar_concept_car` | either match (combine with `or`) |
| `fs.type = Dataset and fs.type = Page` | elements of a given `ElementType` (see `StoreElement.getElementType()`) |
| `fs.meta = 1` | elements that have meta data defined |
| `fs.width >= 468 and fs.height >= 60` | pictures of at least a size |
| `fs.width >= 1000 or fs.height >= 1000` | pictures outside a range |
| `fs.crc = 1309123022` | media by CRC value |
| `fs.workflow = *` | elements with a running workflow (value is `workflowId/stateId`) |
| `fs.workflowLock = 1` | elements locked by a workflow |

Component-based queries (use the input-component name):

| Query | Finds |
| --- | --- |
| `st_picture_zoomable = true` | elements where a toggle component is set |
| `meta.md_content = *` | elements with any value in the `md_content` meta component |
| `meta.md_content = ""` | elements with an empty `md_content` meta component |

- `meta.<name>` targets components in the **meta** (page/element metadata) form.
- Values with spaces must be quoted.
- Tip: in the SiteArchitect Java-client search field, drag-and-drop an element to
  see the query that matches it — a quick way to discover field names.

## When to use what

- **Know the UID?** → `StoreElementAgent.loadStoreElement(...)` (direct, no search)
  — see [agents.md](agents.md).
- **Need to find by content/attribute across the project?** → `QueryAgent`.
- **Walking a known subtree?** → `getChildren(type, recursive)` on the parent —
  see [object-model.md](object-model.md).
