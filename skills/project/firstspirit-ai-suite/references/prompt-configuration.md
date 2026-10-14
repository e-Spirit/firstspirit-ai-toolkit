# Prompt configuration — levels, operations, options, tags, functions

Source: *Prompt administration* and *Writing prompts*
(`docs.crownpeak.com/ai-suite/prompt-administration/`) `[odfs]`. The older ServerManager
procedure is in `docs.e-spirit.com/contentcreator/ai-powered-tool/fs-ai/firstspirit-ai/`.
The API view of the same objects is in `ai-api.md`.

## The parts

| Part | What it is | Key properties |
|---|---|---|
| **System prompt** | Runs with every operation execution; makes input interpretation and output consistent; invisible to editors | Name (unique, used to look it up from code), prompt; type *Preset*, *Preset (Modified)*, *Custom* |
| **Operation** | One task: a name editors see, a prompt they don't | ID (UUID), name, prompt, tags, *Text required*, options, allowed functions |
| **Option** | A set of predefined values for one or more `[parameter]`s in an operation prompt | ID, name, ordered items (name and prompt) |
| **Tag** | Which assistant, script or module action shows an operation | Standard tags such as `ContentAssistant`, `AnalyzeAssistant`, `ImageAssistantAltText`; custom tags for your own scripts |
| **Function** | A tool from a function server (MCP or plugin) that the operation may call | Enabled per operation; `(none)` / `(all)` / a selection |

## Levels and rights

| Level | Scope | Who edits |
|---|---|---|
| System | Every execution | Server admin, on-premises only |
| Global | All projects; read-only at project level (tags can still be adjusted) | Server admin, on-premises only |
| Shared | All projects; editable at project level | Server admin or project admin |
| Project | One project | Project admin |

- Each level shows its own entries plus all the levels above it. An option can only be assigned
  to operations on its own level or below. A project option can't go on a global operation.
- Entries are deleted only on the level that created them. Editing a **shared** operation
  changes it **server-wide**.
- Project operations can be **shared**, which promotes them server-wide. Modified global presets
  can be **restored**.
- Unmodified presets are updated automatically by FirstSpirit (matched by ID). A modified
  preset no longer receives updates `[javadoc]` (`PromptConfigurationPlugin`). Weigh that
  before editing a preset: the docs advise against editing preset system prompts.

**Where to edit:**

- **ContentCreator:** *Actions › Open AI Configuration*, for server and project admins; the tabs
  shown depend on rights.
- **ServerManager:** service *FirstSpirit AI Configuration* (server admin) or project component
  *FirstSpirit AI Configuration ProjectApp* (project admin). The older docs list its tabs as System
  Prompt, Operations, Options, Tags, Function Calling, and Global, Shared and Project Prompts
  `[odfs]`.

## Writing an operation prompt

- **Input is appended.** The assistant adds the editor's text after your prompt. In the old
  docs the hidden lead-in is "Use the rest of this prompt as input:" `[odfs]`. Write "You will
  receive an input text at the end of this message" and don't add your own input marker. When
  calling from code, you build the message yourself (`ai-api.md`).
- **Structure that works:**
  - A specific role.
  - Where the input is.
  - Numbered sub-tasks, with the order made binding.
  - The working language ("in the language of the input text").
  - An explicit output contract ("Output only the rewritten text").
- **Tick *Text required*** when the prompt operates on input text.
- Write the prompt for the **connected model**, and re-test after a model change.

## Options and parameters

- In the operation prompt, a parameter is written in **square brackets**: `[lang]`, `[tone]`.
- Each option item's prompt has the form **`[lang] = German`**. The parameter name must match the
  operation exactly. The item *name* is what editors see; it need not equal the value.
- Link option and operation from either side: *Edit option › Operations* or *Edit operation ›
  Options*.
- **Content Assistant behaviour:**
  - The **first item is preselected**; there is no empty choice and editors can't reset it.
    Make the first item a sensible default.
  - An option with **exactly one item is hidden**, but it is still applied. Use this to reuse
    a prompt block, such as house tone of voice, across operations without copying text
    (tutorial *Applying a consistent tone of voice*).
  - If all of an operation's options have one item, the selection step disappears.
  - To allow "no effect", add an item **without a prompt** (e.g. `[None]`) as the first entry.
- **Duplicating an operation that has options** (older docs): choose *Duplicate* (copy the
  options too) or *Reference* (share the existing ones) `[odfs]`.

## Tags and visibility

- An operation shows in an assistant only when it carries that assistant's tag. In the list,
  pick an assistant to get the *Visibility* column, which can be switched per entry.
- **Custom tag = custom consumer.** Create a tag such as `MyCustomAssistant` (*Additional AI
  Assistants* field, or the *Tags* tab in ServerManager). Assign operations to it, then select
  by tag in code (`getOperations(Set.of("MyCustomAssistant"))` returns operations that carry
  **all** given tags) `[javadoc]`.
- Moving an entry changes its position in **every** assistant it is tagged for.

## Functions (MCP or plugin)

- Enable functions per operation in *Edit operation › Functions*. Each configured server is
  listed with `(none)`, `(all)` or a selection. *Custom entries* lists functions whose server
  configuration was removed.
- **The model decides** whether to call a function. To force a call, say so: "Always retrieve
  all comments for the given page ID". The function's name is optional. Say what to do with the
  result.
- Follow the MCP server's own usage notes; forcing a call is not right for every operation.
- In code, enabled functions are `AllowedServerFunction` entries on the operation
  (`getAllowedTools()`, 5.2.2511) `[jar]`.

## Testing an operation

*Edit operation* › *Test Prompt* › *Test Settings*:

1. Choose a **test plugin**. *ContentAssistant: TestPlugin* in the new docs;
   `ContentAssistantPromptConfigurationTestPlugin` in the older ones. The plugin chooses the
   sample text and builds the request the same way its assistant does.
2. Pick option values, edit the sample text, and watch the streamed result.
3. Iterate on the prompt in the same window.

A test plugin is a `PromptConfigurationTestPlugin`. Write one for your custom assistant so admins
can test its operations with the same request your script sends (`plugins-and-mcp.md`).

## Reference patterns (from the tutorials)

- **House style on Review or Shorten:** add company rules to a copy of the preset instead of
  replacing it, such as spelling of the brand, banned words or sentence length (tutorial
  *Customizing prompts*).
- **Tone of voice everywhere:**
  1. Create a one-item option "Tone of Voice" holding the house rules.
  2. Assign it to every text operation.
  3. Add a `[None]` first item if editors may opt out.
- **Localised or brand prompts per project:** put them at the project level; keep generic
  ones shared.
- **The Analyze Assistant's SEO and Tone of Voice presets** can be specialised the same way
  (tutorial *Customizing prompts*).

Do not paste the preset prompt texts into answers; point to the tutorial page, which shows
each preset next to a customised version.
