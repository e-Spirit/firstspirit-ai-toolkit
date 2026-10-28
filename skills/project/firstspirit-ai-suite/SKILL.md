---
name: firstspirit-ai-suite
description: >-
  Set up, configure, prompt, script and extend the FirstSpirit AI Suite (formerly "AI
  Assistant Suite") in ContentCreator. Use for the Content, Analyze, Image or Code Assistant
  (what they do, where, limits); connecting a model (OpenAI or Azure endpoint, API key
  header, custom or self-hosted model); activating assistants per server or project
  (services, project components, the fsai_altText metadata field); prompt configuration
  (system, global, shared, project prompts; operations, options, tags, functions;
  [parameter] syntax; testing); calling AI from a script or module (GenerativeAIAgent,
  PromptConfigurationAgent, Request/Message, structured output, function calling,
  streaming, admin API); or plugins (GenerativeAIConnectorPlugin,
  GenerativeAIFunctionServerPlugin, PromptConfigurationPlugin, MCP Connector). Also for
  "LicenseException on an AI request" or "isAvailable() is false". Not for Collaboration's
  AI agents, licensing positioning or module packaging basics.
metadata:
  source-commit: "e293e30"
  published: "2026-10-28"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit AI Suite

The AI Suite puts LLM-backed assistants into ContentCreator and exposes the same machinery
to scripts and modules through a public API (`de.espirit.firstspirit.ai`). Everything —
the four assistants, the AI Content Review workflow, Collaboration's AI agents and your own
scripts — runs on **one model connection** and **one prompt configuration**. Get those two
right and the rest follows.

> Beta. Written from the product documentation and the API sources; statements tagged
> `[verify]` are not yet confirmed and are the open ones.

## The mental model (read this before answering)

1. **License → model connection → activation → prompts.** In that order. The license feature
   is `AI`; without it every request fails with a `LicenseException` and connectors report
   `isAvailable() == false` `[core]`. Without a configured endpoint (API key) nothing runs
   either. Activation is per assistant (server-wide or per project). Prompts are optional:
   presets ship and work out of the box.
2. **An operation is the unit of work.** Every assistant action ("Shorten", "SEO", the alt-text
   prompt, a custom script's task) is a *prompt operation*. Options fill `[parameter]`
   placeholders in an operation; **tags** decide which assistant (or script) shows it;
   **functions** (MCP or plugin) are tools the model *may* call. Details:
   `references/prompt-configuration.md`.
3. **Four prompt levels, one direction of inheritance.** System (server, every request) →
   global (server, read-only below) → shared (server or project admin, all projects) →
   project. Lower levels see everything above.
4. **Cloud vs on-premises.** In the FirstSpirit Cloud, the FirstSpirit team configures the model
   connection, server-wide activation and MCP servers. Customers do the project-level steps and prompts in
   ContentCreator. On-premises the server admin does all of it in ServerManager.
5. **Editors stay in control.** No assistant writes without an accept click (Analyze Assistant
   bulk-apply cannot be undone in one step — only element by element via the project history).
   Content goes from the FirstSpirit backend to the configured model; every change lands in the
   project history `[odfs]`.

## Pick the reference

| You need… | Read |
|---|---|
| What each assistant does, where it appears, presets, limits | [references/assistants.md](references/assistants.md) |
| License, model/vendor connection, server and project activation, MCP server setup, Cloud split, "why doesn't it show up" | [references/setup-and-configuration.md](references/setup-and-configuration.md) |
| Prompt levels, operations, options, tags, functions, writing and testing prompts | [references/prompt-configuration.md](references/prompt-configuration.md) |
| Calling AI from a script or module: agents, requests, configured operations, structured output, function calling, streaming, admin API, version table | [references/ai-api.md](references/ai-api.md) |
| Writing a connector, function server, prompt-preset or test plugin; how the MCP Connector fits | [references/plugins-and-mcp.md](references/plugins-and-mcp.md) |

## Rules when answering

- **Check the version first for API questions.** The package does not exist before
  FirstSpirit 5.2.2407. Function calling arrives in 5.2.2509, function servers in 5.2.2511,
  structured output in 5.2.2513. The `[jar]` tags in this skill are checked against 5.2.261011
  (R2610). The *Since* table is in `references/ai-api.md`.
- **Use only the public API.** `de.espirit.firstspirit.ai`, `.ai.dto`, `.ai.admin`. Scripts seen
  in the wild reach into internal factories, for example for JSON mapping. Since 5.2.2513 the
  public `request(Request, Class)` and `JsonSchema.builder().type(Class)` replace that.
- **A custom script needs its own system prompt and tag.** Create a custom system prompt
  (e.g. "MyAssistant: System") and tag your operations with a custom assistant name, then look
  both up by name and tag at runtime. Don't hard-code prompt text that admins should own.
- **Never put an API key in a script or template.** The key lives in the endpoint service
  configuration. A browser-side call to a vendor API bypasses the license, the prompt governance
  and the project history.
- **Functions are suggestions to the model.** To force a call, say so in the prompt.
- **Docs naming varies.** The newer docs say "AI Suite", the older ones "AI Assistant Suite" or
  "AI-powered tools". It is the same product. The tags in the configuration are
  `ContentAssistant`, `AnalyzeAssistant` and `ImageAssistantAltText` `[odfs]`.

## Where other skills take over

- **Positioning, licensing tiers, which customers it suits**:
  `firstspirit-technical-product-knowledge/references/extensions-and-modules.md` (*AI Suite*).
- **Collaboration's `@FirstSpiritAI` and custom agents** (license, `@name`, `AI_AGENT`
  participants): `firstspirit-collaboration/references/concepts-and-setup.md` (*AI agents are
  configured, not called from this API*). A custom agent is a prompt operation configured here.
- **Writing form descriptions the assistants read as prompts**: `firstspirit-template-design`.
- **Script mechanics** (`context`, BeanShell, executables, where scripts run):
  `firstspirit-scripting`.
- **Packaging a plugin as a module** (`module-isolated.xml`, public components, FSM build):
  `firstspirit-module-development`.
- **Cloud service boundaries**: `firstspirit-cloud`.

## Sources

FirstSpirit AI Suite docs (beta, `docs.crownpeak.com/ai-suite/`, read 2026-10-02), the older
ContentCreator AI-tools docs (`docs.e-spirit.com/contentcreator/ai-powered-tool/`), the online
Javadoc of `de.espirit.firstspirit.ai` (version history), `javap` against the 5.2.261011 runtime
jar, and read-only FirstSpirit Core source for license and discovery behaviour. Evidence tags:
`[jar]` javap-verified · `[javadoc]` · `[odfs]` documentation · `[core]` read in product source
· `[verify]` not yet checked.

<!-- feedback-footer:v1 -->
## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
