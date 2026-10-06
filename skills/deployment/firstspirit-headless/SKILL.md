---
name: firstspirit-headless
description: >-
  Reference for the FirstSpirit headless delivery platform: how content leaves
  FirstSpirit and how a frontend reads and previews it. Covers CaaS Platform (REST and
  GraphQL on the MongoDB-backed repository: filtering, aggregations, reference
  resolution, change streams, API keys and secure tokens), CaaS Connect (the toJson
  document shape, preview vs release collections, media URLs), the Navigation Service
  (site structure as JSON, seoRouteMap/idMap, route resolution) and OCM / TPP / SNAP
  (TPP_SNAP and live.js for click-to-edit). Use it for any question about the headless
  stack itself: "how do I filter a CaaS collection", "how do I build a CaaS
  aggregation", "what does a CaaS document look like", "how does CaaS Connect deliver
  content", "resolve a URL with the Navigation Service", "OCM vs TPP vs SNAP", "wire
  click-to-edit with TPP_SNAP", "how does a frontend authenticate to CaaS". Template
  structure for headless: firstspirit-template-design.
metadata:
  source-commit: "8b27f9a"
  published: "2026-10-06"
  toolkit-version: "0.4.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit headless delivery platform

Factual lookup for the **FirstSpirit (Crownpeak) headless stack** — the pieces
that get content out of FirstSpirit and onto a decoupled frontend, and let editors
preview and edit that frontend inside ContentCreator.

The stack, in the order content flows:

```
FirstSpirit  ──[CaaS Connect]──▶  CaaS Platform  ──REST/GraphQL──▶  frontend
 (authoring)   serialises toJson    (JSON store)                      (renders)
      │                                                                   ▲
      └──[Navigation Service]──▶ site structure as JSON ───route lookup──┘
      └──[OCM / TPP / SNAP]────▶ on-page click-to-edit in ContentCreator ─┘
```

## What this skill is *not*

Point at these; do not restate them.

- **Designing templates for headless** — how to shape, nest, and name templates so
  the delivered JSON is good for a frontend (output mode, flat nesting, clean JSON
  keys, content modelling) — is **`firstspirit-template-design`**. That material
  is template strategy/structure/conventions and stays there. This skill takes the
  JSON as produced and covers the *platform* that carries it.
- **Building the frontend** — a Next.js/React app consuming CaaS, Navigation
  Service and TPP (client code, preview-id builders, image handling, preview vs
  release wiring) — is **the FirstSpirit PWA reference implementation (JavaScript Content API)**.
- **The FirstSpirit REST API** (`/rest/v1/`, editing content in FirstSpirit
  itself) is **`firstspirit-rest-api`** — a different API from CaaS's REST read
  interface.
- **Collaboration comments** (delivering findings to editors) is
  **the Collaboration module documentation** — and note it is **unavailable for headless
  projects**, so headless delivery of flagged findings is an open question there.
- **Install / configuration / admin** is parked →
  [references/for-later-configuration-and-install.md](references/for-later-configuration-and-install.md).

## How to use this skill

- **Look up, don't lecture.** Give the endpoint, JSON field, API method, or
  attribute — then stop. Point into `references/` for the full catalogue.
- **Name preview vs release.** Almost everything here exists twice — separate CaaS
  collections (`*.preview.*` / `*.release.*`), separate navigations, a preview-only
  editing bridge. Say which state you mean.
- **The JSON is `toJson`, not templated.** CaaS Connect produces a fixed,
  standardised JSON shape; you change the delivered data by changing the *model*
  (GOM form), not an output channel. See [caas-connect.md](references/caas-connect.md).
- **First pass.** This skill was distilled from documentation with **no live
  install**; items tagged **(UNVERIFIED)** need an SME. See
  the skill's review log.

## Quick answers

- **Read a CaaS collection, filtered:**
  `GET https://REST-HOST:PORT/<db>/<collection>?filter={fs_language:"EN"}&page=1&pagesize=20`
  (Mongo-style `filter`; `pagesize` default 20 / max 100). →
  [caas-platform.md](references/caas-platform.md)
- **Group / count / compute across documents:** a MongoDB aggregation
  pipeline, either stored in collection metadata (`aggrs`, called via
  `GET /<db>/<collection>/_aggrs/<uri>?avars={…}`, RESTHeart form, unverified
  on a current CaaS) or inside a GraphQL app's query mapping (`stages`,
  documented). No mapReduce, no variables in db/collection names, 30 s cap. →
  [caas-platform.md](references/caas-platform.md)
- **Authenticate a browser frontend to CaaS:** mint a short-lived secure token
  from an API key — `GET /_logic/securetoken?tenant=<db>&ttl=<s>` with
  `Authorization: Bearer <api-key>` — then read with `?securetoken=…`. Read-only =
  a key whose `methods` are just `GET`/`HEAD`.
- **CaaS document id:** FirstSpirit **GID + locale**, e.g. `<gid>.en_GB`.
  Collections encode state: `<project-GID>.preview.content` /
  `.release.content` (+ `.files` for media). → [caas-connect.md](references/caas-connect.md)
- **Real-time updates:** WebSocket change stream
  `wss://<host>/<db>/<collection>/_streams/crud?securetoken=…` (no SSE/webhooks).
- **Resolve a URL → page (Navigation Service, `format=caas`):**
  `seoRouteMap[path]` → `idMap[elementId]` → `caasDocumentId` → fetch from CaaS;
  or `GET /navigation/{navigationId}/by-seo-route/{seoRoute}`. →
  [navigation-service.md](references/navigation-service.md)
- **OCM vs TPP vs SNAP:** OCM = the product (Omnichannel Manager, real-time
  headless preview editing); TPP = ThirdPartyPreview, the mechanism; `TPP_SNAP`
  (via `snap.js` / `live.js`) = the JS API. Click-to-edit binds DOM nodes with
  `data-preview-id`. → [preview-and-editing.md](references/preview-and-editing.md)
- **Don't use `WE_API`/`JC_API` in a headless frontend** — those drive
  FirstSpirit's *own* previews. Use `TPP_SNAP`. →
  [preview-and-editing.md](references/preview-and-editing.md)

## References

Loaded on demand — read the file that matches the question.

| File | Covers | Read when |
| --- | --- | --- |
| [caas-platform.md](references/caas-platform.md) | The CaaS repository: storage hierarchy, REST read API (filter/pagination/resolveRef/HAL), aggregations, GraphQL, WebSocket change streams, API keys & secure tokens, operational limits | You're reading/querying CaaS or securing frontend access |
| [caas-connect.md](references/caas-connect.md) | The delivery module: the `toJson` document shape (fields, FormData, sections, references, media/rendition URLs), preview vs release, sync, and the "JSON isn't templated" constraint | You need to know what the delivered JSON looks like or how it's produced |
| [navigation-service.md](references/navigation-service.md) | Site structure as JSON: the REST endpoints, default vs `caas` format (`idMap`/`seoRouteMap`/`structure`), route resolution, customData, security | You're resolving routes or consuming navigation |
| [preview-and-editing.md](references/preview-and-editing.md) | OCM/TPP/SNAP: the `TPP_SNAP` API (methods, events, dialogs), `data-preview-id` decoration, common flows, OCM button attributes, and the non-headless ODFS JS APIs | You're wiring click-to-edit / on-page editing into a headless frontend |
| [for-later-configuration-and-install.md](references/for-later-configuration-and-install.md) | Parked install/config/admin material (holding pen for a future config skill) | You need setup pointers — but note it is unvalidated |

---

*First pass, distilled 2026-07-31 from the CaaS Platform, CaaS Connect, Navigation
Service, TPP/SNAP, OCM, and ODFS JavaScript-API documentation. No live install was
available — see the skill's review log.*

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
