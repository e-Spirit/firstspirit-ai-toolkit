# AI Suite: connecting a model

Source: *Connecting a model and vendor* (AI Suite documentation) `[odfs]`, read 2026-10-13.
The skill `firstspirit-ai-suite` owns the detail (assistants, prompts, plugins, MCP); its `firstspirit-ai-suite/references/setup-and-configuration.md` has the same steps with the `[core]` readings. This page gives only the install order.

## Cloud or on-prem

Server-level configuration needs server administrator access on a local server. On **Cloud** the FirstSpirit team configures the model connection after an initial discussion `[odfs]`. Whether an assistant is on for a project or user is the customer's, on both.

## Steps, in order `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Nothing to install: the **OpenAI connector module comes with FirstSpirit** | Modules list (tick *Show Services*, search "AI") | *OpenAI Endpoint Configuration* is listed |
| 2 | Choose the connector: *FirstSpirit AI Configuration*, *Configure*, *Plugins*: the standard plugin | ServerManager, Server, Properties, Modules | |
| 3 | Fill *OpenAI Endpoint Configuration*: **API Key**, **API URL**; optional model name and *API Key Request Header* (pre-filled `api-key` for `azure.com` endpoints) | same | **Test Connection** succeeds |
| 4 | Another model or a self-hosted one: a module with a `GenerativeAIConnectorPlugin` (`firstspirit-ai-suite`, `plugins-and-mcp.md`), then step 2 | | |
| 5 | Enable each assistant on server or project level (`firstspirit-ai-suite`, `setup-and-configuration.md`) | | an editor sees the assistant |

Vendors: **OpenAI** (default) and **Azure AI**. Test the intended prompts on the model before rolling out; results differ by model `[odfs]`.
Permissions for who may use an assistant are group based: `firstspirit-configuration`.
