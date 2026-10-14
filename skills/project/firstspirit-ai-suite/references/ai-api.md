# The AI API — calling the model from scripts and modules

Packages: `de.espirit.firstspirit.ai` (agents, connectors, functions, plugins),
`de.espirit.firstspirit.ai.dto` (requests, messages, schemas) and
`de.espirit.firstspirit.ai.admin` (editing the prompt configuration).

- Every type and method below is `[jar]`, checked with `javap` against the 5.2.261011
  runtime. The package is **absent** from 5.2.240208.
- *Since* versions come from the online Javadoc
  (`docs.e-spirit.com/odfs/access/de/espirit/firstspirit/ai/package-summary.html`) `[javadoc]`.
- Script mechanics (`context`, BeanShell vs. executables, where a script runs) belong to
  `firstspirit-scripting`. The samples are Java. BeanShell accepts the same calls, but not the
  lambdas, so write those as loops or anonymous classes there.

## Version table — check this first

| Since | What arrived |
|---|---|
| 5.2.240708 | `GenerativeAIAgent`, `GenerativeAIConnector` (`request`, `openStream`, `isAvailable`), `GenerativeAIConnectorPlugin`, `Request`, `Message` (text and image URL), `Response`, `TokenUsage`, `ResponseStream` |
| 5.2.240903 | `PromptConfigurationAgent` (read system prompts, operations, options), `SystemPrompt`, `PromptOperation`, `PromptOption`, `PromptOptionItem`, `PromptConfigurationPlugin`, `PromptConfigurationTestPlugin` |
| 5.2.241209 | `ai.admin`: `PromptConfigurationAdminAgent` and the `Configurable*` types (write the prompt configuration) |
| 5.2.250908 | Function calling: `GenerativeAIAgentConnector.createFunctionRequest()`, `GenerativeAIFunctionRequest`, `Function`, `FunctionParameter`, `FunctionCall`, `Tool`, `ToolCall`; `Request.Builder.addTool` |
| 5.2.251104 | Function servers (`GenerativeAIFunctionServer*`, `GenerativeAIAgent.getFunctionServers()`), `AllowedTool` / `AllowedServerFunction`, `Request.Builder.addAllowedTool`, `JsonSchema`, `ConfigurablePromptOperation.setAllowedTools` |
| 5.2.251303 | Structured output: `request(Request, Class)`, `ResponseFormatJsonSchema`, `StrictMode`, `JsonSchema.Builder.type(Class)`, `Function.Builder.strictMode` |

On an older server the class is missing (`NoClassDefFoundError` in a module,
`ClassNotFoundException` or an "unknown class" error in BeanShell).

## The agents

| Agent | Get it with | Use |
|---|---|---|
| `GenerativeAIAgent` | `broker.requireSpecialist(GenerativeAIAgent.TYPE)` | Requests on the server's **default connector**, or `getConnector(name)` for a specific one; function requests; function-server listing |
| `PromptConfigurationAgent` | `broker.requireSpecialist(PromptConfigurationAgent.TYPE)` | Read the effective system prompts, operations and options (all levels merged) |
| `PromptConfigurationAdminAgent` | `broker.requireSpecialist(PromptConfigurationAdminAgent.TYPE)` | Edit the service, shared or a project configuration (needs admin rights) |

`GenerativeAIAgent` and `PromptConfigurationAdminAgent` are server-level specialists, so
they work from a server broker as well. `PromptConfigurationAgent` is also project-related:
from a project context you get that project's merged view `[core]`.

`GenerativeAIAgent` **is** a connector (`GenerativeAIAgent` → `GenerativeAIAgentConnector` →
`GenerativeAIConnector`). The default connector comes from the *FirstSpirit AI Configuration*
plugin selection. `getConnector(name)` takes the plugin's name (its public component name);
an unknown name throws `NoSuchElementException` `[javadoc]`. Check `isAvailable()` before
you send.

## 1. One prompt, one answer

```java
import de.espirit.firstspirit.ai.GenerativeAIAgent;

GenerativeAIAgent ai = broker.requireSpecialist(GenerativeAIAgent.TYPE);
if (!ai.isAvailable()) {
    throw new IllegalStateException("AI not available: license or endpoint API key missing");
}
Optional<String> idea = ai.request("Suggest three headlines for an article about solar roofs.");
```

`request(String)` sends one user message and returns the first variant's text.
`isAvailable()` depends on the API key in the endpoint configuration `[javadoc]`. Without
the license it is `false`, and a request throws `LicenseException` `[core]`.

## 2. A full request: system prompt, messages, attributes

```java
import de.espirit.firstspirit.ai.dto.*;

Request request = Request.builder()
        .addMessage(Message.create(Message.SYSTEM, "You write concise teaser texts."))
        .addMessage(Message.create(Message.USER, "Write a teaser for: " + body))
        .variantCount(2)                       // may be unsupported by the service; billed per token
        .create();
Response response = ai.request(request);
List<Message> variants = response.getVariants();
response.getTokenUsage().ifPresent(u -> log("tokens: " + u.getTotal()));
```

- **Roles:** `Message.USER`, `SYSTEM`, `ASSISTANT` and `TOOL` are the strings `"user"`,
  `"system"`, `"assistant"` and `"tool"`. A connector is encouraged to support the first three
  `[javadoc]`.
- **Images:**
  ```java
  Message.builder().role(Message.USER).addText("Describe this image.").addImageUrl(url).create()
  ```
  The URL must be reachable for the vendor, or be a data URL `[verify]`.
- **`attribute(name, value)`** passes connector-specific settings `[javadoc]`. A demo project
  sets the model per request with `attribute("model", "<model>")`; whether the bundled OpenAI
  connector honours it is not documented `[verify]`.
- `Response.getText()` is the first variant only.

## 3. Run an operation the admins configured

Let admins own the prompt text, and look it up by **tag** (or ID) instead of hard-coding it:

```java
import de.espirit.firstspirit.ai.PromptConfigurationAgent;

PromptConfigurationAgent prompts = broker.requireSpecialist(PromptConfigurationAgent.TYPE);
SystemPrompt system = prompts.getSystemPrompt("MyAssistant: System").orElseThrow();
PromptOperation op = prompts.getOperations(Set.of("MyAssistant"))      // all given tags must match
        .filter(o -> o.getName().equals("Teaser"))
        .findFirst().orElseThrow();

StringBuilder user = new StringBuilder(op.getPrompt());
prompts.getOptions(op).forEach(option ->                                // options linked to the operation
        user.append('\n').append(option.getItems().get(0).getPrompt())); // first item = the default
user.append("\n\n").append(inputText);                                   // the input goes last

Request request = Request.builder()
        .addMessage(Message.create(Message.SYSTEM, system.getPrompt()))
        .addMessage(Message.create(Message.USER, user.toString()))
        .create();
```

- **Prefer IDs for stability.** An operation's ID is shown in its edit window;
  `getOperation(UUID)` and `getOption(UUID)` look it up. Names are what admins rename.
- **How the built-in assistants combine option items** (`[lang] = German`) with the operation
  prompt is their module's business; the *Test Prompt* dialog likewise sends whatever the
  selected `PromptConfigurationTestPlugin` builds `[core]`. Appending the item prompts, as above, matches the
  documented `[param] = value` contract, but it is not proven to be what the Content Assistant
  sends `[verify]`.
- An item with an empty prompt (the `[None]` pattern) contributes nothing; skip it.
- `isTextRequired()` tells you whether the operation expects input text.
- **Also respect the operation's enabled functions:** pass `op.getAllowedTools()` to
  `addAllowedTool` and use a function request (§5).

## 4. Structured output (5.2.251303)

Simple POJO, mapped for you:

```java
public static class Teaser { public String headline; public String text; public List<String> keywords; }

Optional<Teaser> teaser = ai.request(Request.create("Teaser for: " + body), Teaser.class);
```

The Javadoc limits this to "simple objects and use-cases" `[javadoc]`. For anything richer,
give the schema yourself:

```java
JsonSchema schema = JsonSchema.builder().json("""
        {"type":"object","properties":{"headline":{"type":"string"}},
         "required":["headline"],"additionalProperties":false}""").create();
Request request = Request.builder()
        .addMessage(Message.create(Message.USER, "Teaser for: " + body))
        .responseFormat(ResponseFormatJsonSchema.builder().schema(schema).strictMode(StrictMode.ENABLED).create())
        .create();
String json = ai.request(request).getText().orElseThrow();
```

- **`StrictMode`:** `DEFAULT`, `ENABLED`, `DISABLED`. Strict schemas need every property
  required and `additionalProperties: false` (OpenAI's rule) `[javadoc]` `[verify]`.
- `JsonSchema.builder().type(Teaser.class)` generates the schema from a class.
- **Before 5.2.251303,** ask for JSON in the prompt and parse it yourself. Don't reach for
  internal JSON factories: scripts that do so break on upgrade.

## 5. Function calling (5.2.250908)

Your code offers functions; the model decides whether to call them. `request` runs the whole
call loop for you:

```java
import de.espirit.firstspirit.ai.*;

GenerativeAIFunctionRequest fr = ai.createFunctionRequest();
Function findPage = Function.builder()
        .name("find_page_title")
        .description("Returns the display name of a page in the current project, by page UID.")
        .addParameter(FunctionParameter.builder()
                .name("uid").type("string").description("The page UID").required(true).create())
        .create();
fr.addFunction(findPage, args -> args.getString("uid").map(this::titleOf).orElse("not found"));

Optional<String> answer = fr.request("Write a link text for the page with UID 'products'.");
```

- **`addFunction`** throws `IllegalArgumentException` on a duplicate function name
  `[javadoc]`.
- **`perform` returns a `Serializable`.** The model expects a string; the API converts other
  objects to JSON where it can `[javadoc]`.
- **Arguments:** read them with `getString`, `getNumber`, `getBoolean` or `get`, each returning an
  `Optional`.
- **Token usage:** the `TokenUsage` of the final response covers the whole chain. Use
  `EvaluatedResponse.getTokenUsage()` when you step manually `[javadoc]`.
- **Stepwise control:** `evaluate(request)` makes one round trip and returns `EvaluatedResponse`.
  1. Inspect `getFunctionCallHandles()`.
  2. Call `perform()` on the handles you approve.
  3. Continue with `createRequest()`. Skipped calls are left out.

  Stepwise evaluation is **not supported** when client functions and server functions (MCP)
  are mixed `[javadoc]`.
- **Server functions** (MCP Connector, other function-server plugins):
  - Allow them on the request with `addAllowedTool(AllowedServerFunction.builder()
    .pluginName(p).serverName(s).functionName(f).create())`. A `null` part means "no
    restriction".
  - List what exists with `ai.getFunctionServers()` (`GenerativeAIFunctionServerInfo`: plugin
    name and title, server name, functions).
- **Streaming with functions:** `openStream` (auto loop) or `evaluateStream` (stepwise).
- **A pattern to avoid:** scripts in a template-store folder become functions.
  The script comment is the description, and its form fields with descriptions are the
  parameters. It is powerful, but each "function" then runs arbitrary script code with the
  caller's rights. Allow-list the folder and review those scripts like code.

## 6. Streaming

```java
try (ResponseStream stream = ai.openStream(request)) {
    while (stream.hasNext()) {
        stream.next().getText().ifPresent(out::append);   // each Response is a fragment
    }
}
```

`openStream` streams only if the connector implements it. The Javadoc strongly encourages
connector plugins to do so `[javadoc]`. `ResponseStream` is `Closeable`, so always close it.
It also offers `stream()`.

## 7. Editing the prompt configuration (admin API, 5.2.241209)

```java
import de.espirit.firstspirit.ai.admin.*;

PromptConfigurationAdminAgent admin = broker.requireSpecialist(PromptConfigurationAdminAgent.TYPE);
ProjectPromptConfiguration cfg = admin.getProjectConfiguration(projectId);   // project admin

ConfigurablePromptOperation op = cfg.getOperations().create();               // not yet in the list
op.setName("Teaser");
op.setPrompt("You write teaser texts. You will receive an input text at the end of this message. …");
op.setTags(Set.of("MyAssistant"));
op.setTextRequired(true);
cfg.getOperations().add(op);
cfg.save();                                                                   // IOException, SecurityException
```

- **Three configurations:**
  - `getServiceConfiguration()`: server admin. The only one with `getSystemPrompts()`, a
    `SystemPromptList` with `get(name)` and `create()`.
  - `getSharedConfiguration()`: project admin.
  - `getProjectConfiguration(long projectId)`: project admin.
- **Inherited entries are read-only except for their tags.** Check `isInherited()` and
  `getSourceType()` (`PROJECT`, `SHARED`, `SERVICE`) before calling setters `[javadoc]`.
- **Tags:**
  - `setTags(Set)` makes exactly these active and disables the other inherited ones.
  - `setTags(Map<String, Boolean>)` sets the given ones and inherits the rest.
  - `setTag(name, state)` sets a single tag.
  - `getTagStates()` shows local vs inherited state.
- **Presets:** `getPresetMode()` returns `NONE`, `PRESET` or `MODIFIED`; `restorePreset()`
  reverts.
- **`apply(PromptOperation)`** copies a whole definition, such as one built with
  `PromptOperation.builder()`.
- **Use cases:** seeding a project's operations from a module installer, migrating prompts
  between servers, audits. Remember that **shared** edits hit every project.

## Things that go wrong

| Symptom | Cause |
|---|---|
| `LicenseException` for the feature `AI` | License feature `AI` missing `[core]` |
| `NoSuchElementException` when the default connector is requested | No plugin selected in *FirstSpirit AI Configuration* `[core]` |
| Empty `Optional` from `request(String)` | The model returned no text, for example only tool calls or a content filter `[verify]` |
| `SecurityException` on `save()` | Missing server or project admin rights `[javadoc]` |
| An operation is not found by tag | `getOperations(Set)` needs **all** tags; check the spelling and the level |
| Works in ServerManager, not in a project script | The project-level view has a project operation or override; read it with that project's broker |
