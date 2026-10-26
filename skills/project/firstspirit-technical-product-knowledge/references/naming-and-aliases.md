# Naming & aliases — legacy/internal name → current name → where it lives

FirstSpirit carries a lot of **legacy and internal names** that no longer match
the current product name but still show up in licence files, class/API names,
module IDs, and older-but-still-online documentation. This reference maps them to
the **current product name** and **points to the right place** so old labels don't
mislead.

**Why the drift exists.** FirstSpirit used **major.minor**
versioning until the **5.2** release in **2015**, then abandoned that scheme for
the time-based `YYYY.N` line (a release ~every 4 weeks). Names, licence flags and
class names from the old era were never renamed, and documentation from that era
is still published — harmless for those who know, **confusing for Cloud customers**
(always-latest) who never see the old constructs. Use the **current product name**
in all output (see [product-overview.md](product-overview.md#naming--branding) for
the branding rule); use this table to decode what you find.

> **Multisite / CorporateContent / ContentTransport naming.** The release-notes
> **Categories** index (below) lists **Content Transport**, **Corporate Content**
> and **Multisite Management** as three distinct categories, so all three labels
> are in current use. Treat the Multisite Management row as an umbrella mapping.

> **Naming oracle — the Release Notes "Categories" index.** The FirstSpirit release
> notes publish a controlled list of ~99 current feature/area names (AI-powered tools,
> the four Assistants, Content Store, Content Transport, Corporate Content, Multisite
> Management, DQM Connect, Data Access Plug-In, FSDevTools, CXT, OCM, Collaboration,
> Health Center, …). When in doubt about the **current, official** spelling/label of a
> feature, check it there:
> `docs.crownpeak.com/firstspirit/releasenotes/5.2/release-notes-kategorien/index-2.html`
> (see [documentation-map.md](documentation-map.md)).

## Product & feature aliases

| Current name | Legacy / alias / internal name(s) | Where the old name still surfaces | Go to |
| --- | --- | --- | --- |
| **ContentCreator** | WebEdit, WebClient (former names; `webedit` still appears in ContentCreator URLs, e.g. `…/fs5webedit/…`); **LiveEdit** (an editing mode inside ContentCreator, not a separate product) | `WE_API` (JS API), `license.WEBEDIT` (licence flag), the `LiveEdit` release-notes category, old docs | [product-overview.md](product-overview.md) (clients) |
| **SiteArchitect** | JavaClient | `JC_API` (JS API), **Webstart / Java Web Start** (legacy launch), old docs | [product-overview.md](product-overview.md) (clients) |
| **Development Tools** (in ContentCreator) | (a micro client inside ContentCreator; **not** FSDevTools / `fs-cli`, the command-line SDK) | needs the **CXT-Platform** = FirstSpirit **Content Experience Tools (CXT)** | [product-overview.md](product-overview.md) (clients) |
| **Collaboration** (comment threads in ContentCreator) | — | module `fs-collaboration`; the `Collaboration` release-notes category | [extensions-and-modules.md](extensions-and-modules.md) → `firstspirit-collaboration` |
| **Multi Perspective Preview (MPP)** | — | `MPP_API` | [product-overview.md](product-overview.md) (clients) |
| **Multisite Management** (umbrella) | "CorporateContent" (module/doc title); "Multi-Site Management" | PDF/doc title | [extensions-and-modules.md](extensions-and-modules.md) |
| **Corporate Content** (package/subscription distribution) | Paket-Verwaltung / "package management"; "PackagePool" | `license.PACKAGEPOOL` (licence flag), the **PackageManager** service | [extensions-and-modules.md](extensions-and-modules.md) |
| **ContentTransport** | (its unit is a "Feature") | — | [extensions-and-modules.md](extensions-and-modules.md) |
| **CaaS Connect** | CaaS module **v2** (legacy, deprecated) | old module versions | `firstspirit-headless` |
| **Content as a Service (CaaS)** | — | — | `firstspirit-headless` |
| **Omnichannel Manager (OCM)** | ThirdPartyPreview (**TPP**); SNAP / `TPP_SNAP` (the JS bridge) | module `fs-tpp-*.fsm`, `TPP_SNAP` | `firstspirit-headless` |
| **AI Suite** | AI Assistant Suite | both names are in use | [extensions-and-modules.md](extensions-and-modules.md) |
| **Digital Quality Management (DQM)** | Digital Accessibility & Quality Management | both used | [extensions-and-modules.md](extensions-and-modules.md) |
| **Formcentric Webforms** | "Monday" | — | [extensions-and-modules.md](extensions-and-modules.md) |
| **External Synchronization** | FSDevTools / `fs-cli` (the tool) | tool name, GitHub repo | [extensions-and-modules.md](extensions-and-modules.md) |
| **API-Access** (licence feature) | — | `fs-license.conf` feature | [editions-and-licensing.md](editions-and-licensing.md) |
| **Self-hosted** (canonical hosting term) | **on-prem** / on-premises | older docs, sales | [hosting-and-deployment.md](hosting-and-deployment.md) — **new content uses "self-hosted"** |

## Company / brand names (not product names)

Use the **product name** (FirstSpirit, etc.); these company names appear in
history and URLs — mention only where necessary.

| Term | What it is | Where it surfaces |
| --- | --- | --- |
| **FirstSpirit** | The product name (use this) | — |
| **Crownpeak** | Company name; Crownpeak Technology GmbH is the copyright holder named on `firstspirit.com/policies/legal` | doc hosts (`docs.crownpeak.com`), legal pages, older material |
| **Rezolve** | Safest wording: "a Rezolve solution" (Rezolve Ai PLC owns the GmbH and the brand; don't state ownership in more detail) | site footers, corporate framing |
| **e-Spirit** | Former company name | host names (`*.e-spirit.com`, `*.e-spirit.cloud`, `*.e-spirit.hosting`), module IDs (`e-Spirit/…` repos) |

## Relic licence flags (self-hosted `fs-license.conf`)

Legacy flag names that gate current features — full list in
[editions-and-licensing.md](editions-and-licensing.md):

- `license.WEBEDIT` → **ContentCreator** editing
- `license.PACKAGEPOOL` → **Multisite Management** (ContentTransport / Corporate Content)
- `license.MODULES` → comma-separated module entitlements (names may be dated)
- API-Access feature → **External Synchronization** / external API clients

## Deprecated / removed (from the release notes, 2025–2026)

Decision-level "going away" facts — so a plan doesn't lean on something removed.
Versions are **orientation, not a matrix**; confirm on the live release notes.

- **Jetty web server → dropped.** Jetty is no longer available from **2026.2**
  (announced in the 2025.9 release notes). **Embedded Tomcat** (since 2023.9, default
  since 2024.12) is for tests only; production uses an external Tomcat (Tomcat 11
  from 2025.13). The
  `FirstSpirit Jetty Web Server` category is legacy. See
  [hosting-and-deployment.md](hosting-and-deployment.md).
- **Omnichannel Manager 2.x** — deprecated (2025-01); use the current OCM/TPP line.
- **FragmentCreator** — **discontinued.** Release notes 2025.1 `[odfs]`: placed in
  maintenance mode with 2025.1 (only security-relevant and critical errors fixed), from
  2025.3 available in the SaaS offering on request only, and with **2025.12** no longer
  supported and no longer available. Release notes 2025.12 `[odfs]` ("Discontinuation of
  the FragmentCreator"): the same applies to its modules CaaS Integration, Fragment DAP,
  Tagging Editor, Markdown Editor and CXT Dataservice; the *Deprecations* table lists
  FragmentCreator as deprecated 2025-01, removed 2025-12, with no rows of their own for
  the modules. The Markdown Editor module page carries the marker *Available up to
  FirstSpirit Version 2025.12* `[odfs]` (CXT documentation, 2026.11). It was a separate
  editor for omnichannel content **fragments**; don't propose it for new work.
  **These modules do not work with the 2026 releases:** the Markdown Editor 1.29.20 was
  built against an API class that the 2026 isolated runtime no longer exports. On a
  server where it is still installed, the SiteArchitect's GOM form view fails with a
  `NoClassDefFoundError` for every template, not only those using the component
  `[observed]` (2026-10-26, FirstSpirit 5.2.261119). Deactivating the module on the
  server resolved it at once, without a server or client restart `[observed]`. The
  mechanism and the diagnosis recipe are in `firstspirit-module-development`
  (`firstspirit-module-development/references/isolated-mode-and-packaging.md`, *When a
  module stops linking after a server update*).
- **WebSphere Application Server** support — deprecated (2019); long legacy.
- **Java floor moved** — Java 17 operation is no longer possible from **2026.5**
  (bytecode level 21; Java 21 is the reference version, Java 25 officially
  supported, release notes 2026.3). A runtime *decision input*, kept out of this skill as a matrix → point to the technical-
  requirements doc ([documentation-map.md](documentation-map.md)).
- **Not owned here (route out):** the standing **`CMS_INPUT_*`** template-component
  deprecations (→ `firstspirit-templating-reference`) and the **Access-API** method
  deprecations, incl. a fresh 2025.13 batch (→ `firstspirit-api-reference`). This
  skill only flags that they exist; those skills own the current replacements.

---

*Sources: docs.crownpeak.com/firstspirit and docs.e-spirit.com (documentation and release notes).*
