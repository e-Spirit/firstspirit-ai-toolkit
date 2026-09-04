---
name: firstspirit-api-reference
description: >-
  Concrete lookup reference for the FirstSpirit Java Access API object model: the
  store trees and their interfaces (StoreElement/IDProvider, Page, Body, Section,
  Content2, Dataset, PageRef, Media, PageTemplate/SectionTemplate/…), UID types
  and Store types, the SpecialistsBroker and its agents (StoreAgent, QueryAgent,
  LanguageAgent, ProjectAgent, OperationAgent, …), value objects (FormData,
  Language, TemplateSet, Entity), and the QueryAgent search syntax. Use this skill
  whenever you need to know which interface an object has, how the stores nest,
  which agent yields a store or service, how to load an element by UID, or how to
  write an fs query — for example "what interface is a section", "how do I get the
  PageStore", "which UidType for a media", or "fs query to find an element by
  uid". Pair with firstspirit-scripting (how to run code + the script contexts)
  and firstspirit-module-development (how to package it); the FirstSpirit ODFS documentation has
  the full 146-package API for anything not distilled here.
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit Access API reference

Fast, factual lookup for the **FirstSpirit Java Access API object model** — the
"nouns" you read and manipulate from scripts (`firstspirit-scripting`) and modules
(`firstspirit-module-development`). Where those skills cover *how you run code*,
this skill answers *what objects exist, how they relate, and how you reach them*.

This is the API layer taught in **DTA (Developer Training Advanced)**, distilled
from the FirstSpirit Access API. For the exhaustive 146-package Javadoc, defer to
the FirstSpirit ODFS documentation.

## Public API only

Scripts and modules access FirstSpirit through the **public API**
(`de.espirit.firstspirit.access.*`, `de.espirit.firstspirit.agency.*`, …). Classes
and methods **not** in the public API carry no support guarantee — they may change
or vanish without notice. Only use documented, public types.

FirstSpirit exposes **one public Access API** (Java) — the historical "Access API
vs Developer API" split no longer applies. Per the ODFS *API documentation* page,
deprecated elements are marked `@Deprecated` (and listed in the release notes),
then removed **no earlier than six additional releases**; `@ApiStatus.Experimental`
marks provisional additions that may change as early as the next release. Check the
release notes when changing versions. Source:
`docs.e-spirit.com/odfs/template-develo/firstspirit-api/api-documentati/`.

## How to use this skill

- **Look up, don't lecture.** Give the interface, method, UID type, agent, or
  query — then stop. Point into `references/` for the full catalogue.
- **State vs release matters.** Most store access takes a `boolean release`
  (`false` = current/edit state, `true` = released state). Name which you mean.
- **Reach objects through agents, never `new`.** Obtain stores and services from
  the `SpecialistsBroker` via `requireSpecialist(...)`. See
  [references/agents.md](references/agents.md).
- **Defer.** Script contexts / BeanShell → `firstspirit-scripting`. Module
  packaging & component types → `firstspirit-module-development`. Template
  language & GOM → `firstspirit-templating-reference`.

## Quick answers

- **Every store node is an `IDProvider`** (extends `StoreElement`): `getId()`,
  `getUid()`/`getUidType()`/`hasUid()`, `getName()`, `getParent()`,
  `getChildren(...)`, `getStore()`, plus `setLock`/`save`/`revert`.
- **Get a store:** `broker.requireSpecialist(StoreAgent.TYPE).getStore(Store.Type.PAGESTORE, false)`.
- **Load by UID:** `broker.requireSpecialist(StoreElementAgent.TYPE).loadStoreElement("uid", IDProvider.UidType.PAGESTORE, false)`.
- **Search:** `broker.requireSpecialist(QueryAgent.TYPE).answer("fs.uid = my_uid", null)`.
- **The six stores:** Page content (PageStore), Site structure (SiteStore), Media
  (MediaStore), Data sources (ContentStore), Global settings (GlobalStore),
  Templates (TemplateStore). See the object-model diagram in
  [references/object-model.md](references/object-model.md).

## References

Loaded on demand — read the file that matches the question.

| File | Covers | Read when |
| --- | --- | --- |
| [references/object-model.md](references/object-model.md) | The six store trees → their interfaces (the DTA "FirstSpirit-Objects" map), `StoreElement`/`IDProvider` common methods, `Store.Type`, `IDProvider.UidType`, lock/save/revert | You need to know an element's interface, how the trees nest, or the right UID/Store type |
| [references/stores.md](references/stores.md) | Per store: root element, the key element interfaces and their most-used methods (Page/Body/Section, Content2/Dataset, PageRef/DocumentGroup, Media, the Template interfaces, GCA) | You need methods on a specific element type |
| [references/agents.md](references/agents.md) | `SpecialistsBroker` (`requireSpecialist`/`requestSpecialist`) and the agent catalogue — StoreAgent, StoreElementAgent, QueryAgent, LanguageAgent, ProjectAgent, OperationAgent, ImageAgent, RenderingAgent, Url/PreviewUrlAgent, ModuleAdminAgent, … | You need to reach a store/service/operation and don't know which agent |
| [references/values-and-data.md](references/values-and-data.md) | Value objects: `FormData`/`FormField`, `Language`/master language, `TemplateSet`, Content-Store `Dataset`/`Entity`/`EntityType`, editor values | You need to read/write field values, languages, or dataset content |
| [references/querying.md](references/querying.md) | `QueryAgent` usage and the FirstSpirit query (`fs.*`) syntax with worked examples | You need to search the repository from code |

Visual: [assets/firstspirit-object-model.png](assets/firstspirit-object-model.png)
— the DTA object-model poster (store trees mapped to interfaces).

---

*Sources: FirstSpirit Access API (`fs-api/`, bundled in the FirstSpirit ODFS documentation) and
the DTA "FirstSpirit Objects" / "FirstSpirit Contexts" training posters.*

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
