---
name: firstspirit-smartsearch
description: >-
  Build, index, query and run SmartSearch (formerly "haupia"), the Solr-based site search
  of the FirstSpirit portfolio, and its two companions: smartsearch.js for website search
  pages and the SmartSearch Connect module (FSM) that pushes released FirstSpirit content
  into the index. Use for Prepared Searches, Data Generators (Web, XML, API, External),
  Groovy enhancers and Prepared Search scripts, field suffixes (_keyword, _token, _pnt,
  _stored_only…), the search REST API (execute, facets, pagination, autocomplete, fq,
  grouping, highlighting, didYouMean, spatial, tags), API gateway vs server, the generic
  indexing API, hot injection, the Configuration Management API, smartsearch.js (Page,
  Facet, PageRenderer), Connect setup (service, ProjectApp, SmaSeJSON,
  noindex, full or partial generation, eventing, media, datasets, V1/V2 field names, CaaS
  headless), and on-prem operations (ZooKeeper, Solr, application.yml, LDAP/OIDC, SSL,
  5.11 systemd, updates). Not for licensing positioning.
metadata:
  source-commit: "1e54562"
  published: "2026-10-30"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# SmartSearch

SmartSearch is a search service on Apache Solr. It collects documents into an index,
shapes queries against that index, and answers them over REST. Three parts, one model:

| Part | What it is | Who uses it |
|---|---|---|
| **SmartSearch server** (index and search) | Spring Boot server with ZooKeeper and Solr, a web cockpit and REST APIs | Search admins, backend developers, operators |
| **smartsearch.js** | Browser library that calls the search API and renders results, facets, pagination, autocomplete | Frontend developers |
| **SmartSearch Connect** | FirstSpirit module that writes released pages, datasets and media straight into the index | FirstSpirit developers and admins |

Facts are from the product documentation `[odfs]` unless a line is tagged otherwise:
SmartSearch 5.12.1 (release notes to 5.13.0), Connect 1.15.2, smartsearch.js 1.4.1 (sources in `## Sources`).

## The mental model (read this before answering)

1. **Data Generator → index → Prepared Search → client.** A *Data Generator* fills the index
   (it crawls a website, reads XML, or receives documents over an API). A *Prepared Search* is
   a named, saved query configuration over one or more Data Generators: which fields are
   searched, weighted, highlighted and returned, which facets exist, an optional Groovy
   script. Clients only ever call a Prepared Search by name. Nothing queries Solr directly.
2. **Every document needs `id`, `title`, `content`, `link`.** `id` is reserved and set by
   SmartSearch; the field-name **suffix** decides the Solr type (`color_keyword` becomes a
   facet, `category_token` groups, `city_pnt` is a geo point). The suffix catalogue is in
   `references/indexing.md`.
3. **Two ways in, by purpose.** End-user search goes to the **API gateway** (cloud) or the
   server's `/rest/api/v1/prepared_search/…`. Everything that writes (indexing, hot injection,
   Data Generator control, configuration) goes to the **server** with credentials. The gateway
   is search-only, and it is the only part that stays up in a disaster-recovery scenario.
4. **Three ways to write into the index from FirstSpirit.** Pick before building:
   - **SmartSearch Connect** (recommended for FirstSpirit content): pushes JSON on release and
     on full generation into an `API` Data Generator. No crawling.
   - **Web Data Generator**: crawls the generated website. No module, but only what is
     published and linked is found.
   - **Generic API** from your own code (a FirstSpirit script, a module, an external app):
     `PUT/POST/DELETE /rest/api/v1/smartsearchconnect/{dataGenerator}/…`.
   Details and the decision table: `references/concepts-and-architecture.md`.
5. **Changes are not instant.** Index writes reach search after a commit interval: about 30 s
   for Connect, "minutes" for the generic API, up to 15 min for crawls and hot injection.
   Say this when someone reports "my change is not in the search".

## Pick the reference

| You need… | Read |
|---|---|
| Components, cloud vs on-prem, gateway vs server, cockpit areas, permissions, which indexing path to choose | [references/concepts-and-architecture.md](references/concepts-and-architecture.md) |
| Querying: execute, auth, facets, pagination, autocomplete, sorting, `fq`, highlighting, grouping, did-you-mean, tags, spatial, Prepared Search Groovy | [references/search-api.md](references/search-api.md) |
| Filling the index: Data Generator types, crawler rules, XML format, field suffixes, enhancers, generic API, hot injection and deletion, external DG API, start/stop, Configuration API, import/export | [references/indexing.md](references/indexing.md) |
| A search page in the browser with smartsearch.js: classes, methods, options, templates, CSS classes, known doc bugs | [references/smartsearch-js.md](references/smartsearch-js.md) |
| SmartSearch Connect: service and ProjectApp, SmaSeJSON, excluding pages and datasets, full and partial generation, eventing, media, datasets, V1/V2 field names, headless with CaaS, limits | [references/smartsearch-connect.md](references/smartsearch-connect.md) |
| Running SmartSearch on-prem: install order, ports, `application.yml`, LDAP, OIDC, SSL, proxy, 5.11 systemd change, updates and migrations, monitoring, logging, troubleshooting | [references/operations.md](references/operations.md) |

## Rules when answering

- **Ask cloud or self-hosted first** when it changes the answer: smartsearch.js needs the API
  gateway (cloud) according to the main documentation, Prepared Search accessibility
  (*Restricted / Public / Authenticated*) exists only in cloud mode, and on-prem operators own
  ZooKeeper and Solr.
- **Never put cockpit or server credentials in browser code.** A browser calls only the
  gateway with a *Public* Prepared Search. smartsearch.js cannot send a token at all, and the
  gateway's CORS settings let no `Authorization` header through from another origin, so
  *Authenticated* searches need a same-origin or server-side caller. `fq` and other
  URL parameters can be changed by the user, so security filters belong in the Prepared
  Search's Groovy script, not in a URL.
- **Name the field suffix.** Most "facet does not appear", "cannot sort", "grouping returns
  nothing" questions are a missing or wrong suffix (`_keyword`, `_sort`, `_token`). Since 5.12
  a value that does not match its suffix type is dropped with a warning instead of failing the
  document.
- **FirstSpirit content: prefer Connect over crawling**, and the V2 field naming
  (`FS_<component>___<child>`) over V1. Connect does not support projects with fragments.
- **Adaptable Results travel only with matching documents.** The documentation says they do
  not transfer; the source shows they point at document ids derived from the DG name and the
  document id or URL, so they hit on another instance only when the same DG holds the same
  documents (`references/indexing.md`).
- **Check versions.** 5.0 needs Java 21, ZooKeeper 3.9, Solr 9.7 and a new environment; 5.11
  removes `./server.jar start` (systemd with `java -jar`); 5.12 adds OIDC. Connect 1.15.0
  adds OAuth against an OIDC server. smartsearch.js has had no documented release since 1.4.1
  (23.08.2022; the repository's 1.4.2 changes only the build) and still documents IE11.

## Where other skills take over

- **Positioning, licensing (usage-based, own credentials), which customers it suits**:
  `firstspirit-technical-product-knowledge/references/extensions-and-modules.md` (*SmartSearch*).
- **CaaS, CaaS Connect, URL factories, CaaS document URLs** for the headless use case:
  `firstspirit-headless/references/caas-connect.md`.
- **Metadata and table templates, input components, rules** (for the noindex toggle):
  `firstspirit-template-design`; template syntax (`$CMS_VALUE$`, `json()`):
  `firstspirit-templating-reference`.
- **Scripts and executables** in FirstSpirit jobs (where `#! executable-class` runs):
  `firstspirit-scripting/references/script-contexts.md`.
- **FirstSpirit Cloud service boundaries** (which modules the cloud runs, who configures
  services): `firstspirit-cloud/references/cloud-constraints.md`.
- **FirstSpirit server operations** (module install, encryption, jobs):
  `firstspirit-operations`.

## Sources

SmartSearch documentation, admin manual, migration guide, external Data Generator REST API
and release notes (`docs.e-spirit.com/delivery_modules/smart_search/`, 5.12.1); SmartSearch
Connect documentation, server administrator page and release notes
(`docs.e-spirit.com/module/smartsearch-connect/`, 1.15.2); smartsearch.js developer
documentation, release notes and the TypeDoc API pages (`docs.e-spirit.com/module/smartsearch.js/`,
1.4.1). All read 2026-10-02. Evidence tags: `[odfs]` documentation · `[javadoc]` the
smartsearch.js TypeDoc pages · `[core]` read in the product source (SmartSearch server 5.12.2,
SmartSearch Connect 1.15.2, smartsearch.js 1.4.2).

<!-- feedback-footer:v1 -->
## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
