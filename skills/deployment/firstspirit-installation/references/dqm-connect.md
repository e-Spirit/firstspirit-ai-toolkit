# DQM Connect

Source: *Administration and Configuration*, DQM Connect 2026.11 `[odfs]`, read 2026-10-13.
DQM itself is a separate SaaS subscription (`firstspirit-technical-product-knowledge`, `firstspirit-technical-product-knowledge/references/extensions-and-modules.md`).

## Cloud or on-prem

On **Cloud**, support installs and configures DQM Connect on request. On a local server only a server administrator can install modules `[odfs]`.

## Requirements `[odfs]`

The module file (`.fsm`, from customer support); a **DQM website ID and DQM API key** per endpoint, also from customer support; optional proxy URL from your network administrator.

## Steps, in order `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Install the module; **start the DQM Connect service and enable autostart** | ServerManager, Server, Server Properties, Modules | service running |
| 2 | Configure the **DQM Connector** service: DQM API URL and DQM Highlight URL (preset, usually unchanged); optional proxy URL; **New** endpoint = name (display only), website ID, API key | Modules, DQM Connect, DQM Connector, Configure | **Test Connection** passes |
| 3 | At least the **Default Configuration** must exist: it is used when a project has no endpoint selected | same | |
| 4 | Add the web component *DQM Integration Web App* to the ContentCreator web app and **roll out** all enhanced ContentCreator web apps. Project-local ContentCreator instances get the component under the project's web components | Server, Properties, Web applications; Project, Web components | |
| 5 | **Per project (project administrator):** add the *DQM Connect ProjectApp*, then *Configure* and pick the endpoint (= the website ID) | Project components | DQM available in ContentCreator |

One server can serve several websites: one endpoint per website ID, chosen per project `[odfs]`.
