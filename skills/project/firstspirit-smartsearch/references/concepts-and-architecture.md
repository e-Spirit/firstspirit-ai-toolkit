# Concepts and architecture

What the parts are, where requests go, who may do what, and which indexing path to pick.
Source: SmartSearch documentation 5.12.1 (*Introduction*, *SmartSearch cockpit*, *Usage of
SmartSearch APIs*) and admin manual `[odfs]`, unless a line says otherwise.

## Components

| Component | Role | Port |
|---|---|---|
| **ZooKeeper** 3.9 | Stores SmartSearch configuration (Prepared Searches, Data Generators, users, ACLs) together with the Solr configuration | 2181 client, 2888/3888 between instances |
| **Solr** 9.7, cloud mode | Holds the index; one collection per client plus a `_signals` collection | 8983 |
| **SmartSearch server** | Spring Boot app: collects and normalises data, rewrites queries, serves REST and the cockpit | 8181 (cockpit and REST) |
| **API gateway** (cloud only) | Public, search-only entry point in front of the servers | — |

- ZooKeeper and Solr are **not delivered**; on-prem operators install them in the stated
  versions (`operations.md`).
- Outside traffic is HTTPS; traffic between the components is HTTP.
- Several SmartSearch servers elect a **leader**. REST behaves the same on every instance, the
  **cockpit runs only on the leader**; other instances forward to it via ZooKeeper.
- The product was called **haupia** (renamed in 2.4.0). The name survives in configuration
  keys (`haupia.*`), query parameters (`haupia_pageNumber`) and Java packages
  (`de.arithnea.haupia…`) in logs.

## The objects you configure

| Object | What it does | Where |
|---|---|---|
| **Data Generator** (DG) | Fills the index from one source. Types: **Web** (crawler), **XML** (data or seed XML over HTTP), **External** (receives documents over a legacy REST API; deprecated in favour of the generic API), **API** (created automatically by SmartSearch Connect or the generic API; cannot be created by hand, started or stopped) | Cockpit → *Data → Data Generators* |
| **Enhancer** | Per-DG processing step before indexing. General and finishing enhancers are built in; configured ones are **Groovy script enhancers** (and a German-only names/nouns extractor) | DG → *Enhancer* tab |
| **Prepared Search** (PS) | Named query configuration over one or more DGs: searched / output / highlighted fields, partial match, emphasis, hits per page, highlight length, sort, spellcheck threshold, *Must Match*, Groovy script, facets | *Configuration → Prepared Search* |
| **Facet** | Filter dimension of a PS on a `_keyword` field: value weights (0–9.99, 0–2 recommended), minimum count, multi-select, *Exclude own filter* | PS → *Facets* tab |
| **Adaptable Result** | Per PS and search term: **elevate** or **exclude** individual documents; documents that left the index become "orphaned" entries | *Analysis → Adaptable Results* |
| **Stopwords, synonyms, substitutions** | Per language (26 languages). Stopword changes need a DG re-run. Do not define stopwords and synonyms for the same term | *Configuration* |
| **Statistics** | Top search terms per PS and period, filterable by `tag`; refreshed every 15 minutes; CSV export | *Analysis → Statistics* |

The PS *Preview* tab runs searches against unsaved settings, including facets, weights,
Groovy scripts and Adaptable Results. Use it before touching a client.

Full configuration reference (field options, crawler settings, XML format): `indexing.md`
and `search-api.md`.

## Cloud vs self-hosted

| | Cloud service | Self-hosted |
|---|---|---|
| Search calls from end users | **API gateway**: `https://<gateway-host>/v1/prepared_search/{name}/execute` | Server: `https://<server>:8181/rest/api/v1/prepared_search/{name}/execute` |
| Gateway auth | None by default; per PS *Public* or *Authenticated* (Basic since 5.5.0, OIDC bearer since 5.12) | — (server always needs credentials) |
| PS accessibility | *Restricted* (cockpit only), *Public*, *Authenticated* | Not shown |
| Writes, DG control, configuration | Server (cockpit instance) with credentials | Server with credentials |
| Disaster recovery | Only gateway search stays available; indexing and cockpit are down until recovery | Your own setup |
| smartsearch.js | Supported (main docs: "requires the API gateway") | Not directly: the library sends no `Authorization` header and has no option for one `[core]`, and the server always needs credentials. Only via your own proxy that adds them (`smartsearch-js.md`) |
| ZooKeeper, Solr, server operations | Operated for you | `operations.md` |

The documentation recommends the gateway for **all** end-user search so that search survives
a disaster-recovery scenario. Hot injection and hot deletion are **not** on the gateway.

## Permissions

- Users belong to **groups**; groups carry **permissions per cockpit area**: *Reading*,
  *Edit*, *Delete*, plus *Execute* for **Data Generator** and **Search**.
- Built-in groups `ADMIN` and `USER` cannot be deleted; the **master admin** (created from
  `application.yml` on first start) cannot be deactivated or deleted.
- REST calls use the same users: `Authorization: Basic base64(user:password)`, or with OIDC a
  bearer token. What an API call needs:
  - Search an *Authenticated* PS through the gateway in OIDC mode: *Execute* on *Search*,
    otherwise `403`.
  - Hot injection and deletion: *Execute* on *Data Generator*.
  - SmartSearch Connect's technical user: every right needed to create Data Generators and
    Prepared Searches (Connect server administrator page).
- **Admin-only** functions: *Reload Collection* (forces an immediate commit for all DGs),
  *Import/Export*.
- With **LDAP** or **OIDC**, users (LDAP: also groups) are read-only in the cockpit; permissions
  are still managed there (`operations.md`).

## Which way into the index?

| Situation | Use | Why |
|---|---|---|
| FirstSpirit-managed website or headless project | **SmartSearch Connect** (`smartsearch-connect.md`) | Pushes on release (eventing) and on full generation; datasets and media included; no crawl of the live site |
| Any reachable website, no module possible | **Web Data Generator** | Only published, linked (or sitemapped) pages; HTML markers and `rel="nofollow"` control scope |
| Feed files exist (product exports) | **XML Data Generator** | Data XML or seed XML over HTTP(S) |
| Own application or FirstSpirit script pushes documents one by one or in batches | **Generic API** (`indexing.md`) | Creates its own `API` DG and PS on first use |
| Urgent single URL or document must appear or disappear now | **Hot injection / hot deletion** on a Web or XML DG | Server only; use sparingly (deletion re-indexes) |
| Existing integration on the old external DG | External DG REST API (begin / add / commit) | Legacy; new projects use the generic API |

Several DGs can feed one PS: for example Connect for pages and datasets plus a Web DG for a
non-FirstSpirit microsite. Facet on `fsType` (Connect) or on your own `_keyword` field to let
users separate the sources.
