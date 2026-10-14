# Setup and configuration — license, model, activation, MCP

The order matters: **license → model connection → activation per assistant → prompts**.
Step-by-step pages: `docs.crownpeak.com/ai-suite/configuring-the-ai-suite/` `[odfs]`.

## Who does what (Cloud vs on-premises)

| Step | On-premises | FirstSpirit Cloud |
|---|---|---|
| License (feature `AI`) | Part of the server license | Part of the subscription |
| Model and endpoint connection | Server admin, ServerManager | The FirstSpirit team, after an initial discussion |
| Server-wide activation and assistant settings | Server admin, ServerManager | The FirstSpirit team, on request |
| MCP server connections | Server admin, ServerManager | Contact your FirstSpirit representative |
| Project components (Analyze, Image), metadata field | Project admin | Project admin |
| Content Assistant availability per project | Project admin | Project admin |
| Shared and project prompts | Server or project admin, in ContentCreator (*Actions > Open AI Configuration*) or ServerManager | Same, in ContentCreator |
| System and global prompts | Server admin only | Not editable by customers |

## License

Server side, `GenerativeAIAgent` checks the license feature **`AI`**. When it is
missing, every connector it returns is an "unlicensed" stand-in: `isAvailable()` is `false`,
and every request throws a `LicenseException` naming the feature `AI` `[core]`.
One license covers the whole suite, including the Code Assistant, the AI Content Review and
Collaboration's agents `[odfs]`.

## Modules, services and components

| Thing | Kind | Where | Purpose |
|---|---|---|---|
| OpenAI connector | Module (installed automatically) | Server | Default `GenerativeAIConnectorPlugin`; OpenAI and Azure endpoints |
| *OpenAI Endpoint Configuration* | Service of the OpenAI connector | Server | API key, API URL, model, API-key header, *Test Connection* |
| *FirstSpirit AI Configuration* | Service | Server | Choose the connector plugin (*Plugins*: the standard plugin); system, global and shared prompts |
| *FirstSpirit AI Configuration ProjectApp* | Project component | Project | Shared and project prompts |
| *CXT ContentCreator: Feature Configuration Service* / *…ProjectApp* | Service / project component (Tailored UI, module *FirstSpirit CXT ContentCreator*) | Server / project | Feature **Report: Content Assistant**: which users or groups get it |
| *FirstSpirit Analyze Assistant Service* | Service | Server | Parallel requests per analysis, 1–16, default 8 |
| `FirstSpirit-AIAnalyze-ProjectApp` | Project component | Project | Enables the Analyze Assistant in that project |
| *FS Image Assistant - GPT Alt Text Config* | Service | Server | Global vs individual model (plugin + model); system or custom prompt |
| *FS Image Assistant - Configuration* | Project component | Project | Enables the Image Assistant; optional project-level prompt override |
| *FirstSpirit MCP Connector* → *MCP Connector Configuration* | Module → service | Server | External MCP servers (name, URL, API key, *Test*) |

**Bundled modules.** The older docs say on-premises
installations must install the *FirstSpirit AnalyzeAI* module by hand and that the Cloud has it
preinstalled `[odfs]`. Check the module list before telling an admin to install anything
`[verify]`.

## Connecting a model

1. ServerManager › *Server › Properties › Modules*, tick *Show Services*, search for "AI".
2. *FirstSpirit AI Configuration* › *Configure* › *Plugins*: choose the standard plugin. This
   sets the server's default connector. If none is configured, a request for the default
   connector throws `NoSuchElementException` `[core]`.
3. *OpenAI Endpoint Configuration* › *Configure*:
   - **API Key** and **API URL**.
   - **Model** (optional).
   - **API Key Request Header** (optional): the docs say it is pre-filled with `api-key` for
     `azure.com` endpoints and empty for `openai.com`, where a default authorization header is
     used. The docs call it "Authentication"; the usual OpenAI header is `Authorization`
     `[verify]`.
   - **Test Connection**.

Native vendors: **OpenAI** (default) and **Azure AI**. For any other or self-hosted model,
implement a `GenerativeAIConnectorPlugin` as a module (`plugins-and-mcp.md`). The model
matters: test the same prompts on the candidate model before rolling out to editors `[odfs]`.

## Server-wide activation (on-premises)

- **Content Assistant:** *CXT ContentCreator: Feature Configuration Service* › search
  *Report: Content Assistant* › *Edit* › *Feature availability*: users or groups. This makes it
  active in all projects.
- **Analyze Assistant:** set the parallel requests in *FirstSpirit Analyze Assistant Service*.
  More requests means faster results and a higher load on the model endpoint (rate limits).
- **Image Assistant:** *FS Image Assistant - GPT Alt Text Config*:
  - *Use global model* uses the AI connection. *Use individual model* takes a plugin and a
    model name.
  - Then choose *Use system prompt* or *Define custom prompt*.
  - Custom alt-text prompts are created in the AI Configuration and tagged
    `ImageAssistantAltText`.
- **Code Assistant:** no switch is documented. It is active with a valid license.

## Project activation (all environments)

- **Content Assistant:** *Project components › CXT ContentCreator: Feature Configuration
  ProjectApp* › *Report: Content Assistant* › *Feature availability*.
- **Analyze Assistant:** add `FirstSpirit-AIAnalyze-ProjectApp`.
- **Image Assistant:** add *FS Image Assistant - Configuration* (optionally override the
  prompt). Then add the alt-text field to the project's **metadata template**:

  ```xml
  <CMS_INPUT_TEXTAREA name="fsai_altText">
     <LANGINFOS>
        <LANGINFO lang="*" label="Alternative Text (AI)"/>
     </LANGINFOS>
  </CMS_INPUT_TEXTAREA>
  ```

  The name is fixed; the label is free. Output templates read the alt text from the
  media's metadata like any other metadata field. For how, see `firstspirit-templating-reference`.
- **AI Configuration ProjectApp:** the older docs say it is added automatically `[odfs]`.

## MCP Connector (on-premises)

1. ServerManager › *Server › Properties › Modules › FirstSpirit MCP Connector* › *MCP
   Connector Configuration* › *Configure* › *Create*.
2. Enter a name, the server URL and an API key if needed, click *Test* ("Connection
   successful"), then *Create*.
3. In the prompt configuration, enable the server's functions per operation (*Functions*
   section of *Edit operation*).

- **Client-side:** FirstSpirit connects **out** to the MCP server, so firewall rules are
  outbound.
- **Read-only functions only:** only functions annotated read-only, or not annotated at all,
  are offered.
- It is built on `GenerativeAIFunctionServerPlugin`. Write your own for systems without a
  remote MCP server (`plugins-and-mcp.md`).

## Troubleshooting

| Symptom | Likely cause | Check |
|---|---|---|
| A script throws `LicenseException` for the feature `AI` | License feature `AI` missing `[core]` | Server license |
| `isAvailable()` is `false` | No API key on the endpoint, or unlicensed `[javadoc]` `[core]` | *OpenAI Endpoint Configuration* › *Test Connection* |
| `NoSuchElementException` when the default connector is requested | No plugin chosen in *FirstSpirit AI Configuration* `[core]` | *Plugins* selection |
| `getConnector("…")` throws `NoSuchElementException` | Wrong plugin name; it expects the plugin's public component name `[javadoc]` | Module list › component names |
| Azure endpoint answers 401 | Header not `api-key`, or wrong deployment URL `[verify]` | *API Key Request Header* |
| No speech bubble in a text field | Feature *Report: Content Assistant* not granted to the user's group (server or project); section switched off; no operation tagged `ContentAssistant` | Feature configuration; the section's off switch; tags |
| Analyze Assistant icon missing | `FirstSpirit-AIAnalyze-ProjectApp` not added | Project components |
| Analyze Assistant fails on a page | Content projection with several datasets (unsupported) | Page content |
| Alt text not saved | `fsai_altText` missing from the metadata template | Metadata template |
| Alt text not generated | Format not JPEG/PNG/WebP; image component missing; Azure image token limits | Image type; project components; Azure deployment |
| An operation is missing in one assistant | Tag not set for that assistant, or hidden via *Visibility* | AI Configuration |
| MCP function not offered | Function annotated as writing (not read-only) | The MCP server's annotations |
| The model ignores an MCP function | Function calls are at the model's discretion | Name the call in the prompt |
