# Extending the AI Suite — plugins and the MCP Connector

Four plugin interfaces. Each extends `de.espirit.firstspirit.client.plugin.Plugin`, which has
`setUp(BaseContext)` and `tearDown()` `[jar]`, and each is found by the server among the
**public components** of installed modules. For example,
`ModuleAgent.getComponents(GenerativeAIConnectorPlugin.class)` and the same call for
`GenerativeAIFunctionServerPlugin` `[core]`. How to declare and package a public component, and
how to give it a ServerManager configuration dialog, is covered by `firstspirit-module-development`
(`firstspirit-module-development/references/component-types.md`,
`firstspirit-module-development/references/module-descriptor.md`).

| Plugin | Since | Implement when… | Contract (methods) |
|---|---|---|---|
| `GenerativeAIConnectorPlugin` | 5.2.240708 | You need a model other than OpenAI or Azure: a self-hosted model, a gateway, another vendor | `isAvailable()`, `request(Request)`, `openStream(Request)` (has a default; override it) |
| `GenerativeAIFunctionServerPlugin` | 5.2.251104 | Operations should read from a system that has no remote MCP server | `init(GenerativeAIFunctionServerHost)` → `register` / `unregister` servers |
| `PromptConfigurationPlugin` | 5.2.240903 | Your module ships preset operations, options, system prompts and tags | `getTags()`, `getSystemPrompts()`, `getOperations()`, `getOptions()` |
| `PromptConfigurationTestPlugin` | 5.2.240903 | Admins should test your operations the way your code sends them | `getPreferredTags()`, `getDefaultText()`, `createRequest(PromptOperationContext)` |

## Connector plugin — a custom or self-hosted model

```java
public class MyModelConnector implements GenerativeAIConnectorPlugin {
    private String apiKey;                       // read from your module's configuration in setUp
    @Override public void setUp(BaseContext context) { apiKey = readConfiguredKey(context); }
    @Override public void tearDown() { }

    @Override public boolean isAvailable() { return apiKey != null; }

    @Override public Response request(Request request) throws IOException {
        // map request.getMessages() (roles user/system/assistant/tool, text and image parts),
        // request.getTools(), request.getResponseFormat(), request.getVariantCount(),
        // request.getAttributes() onto the vendor call …
        return Response.builder()
                .addVariant(Message.create(Message.ASSISTANT, text))
                .tokenUsage(TokenUsage.create(promptTokens, completionTokens, promptTokens + completionTokens))
                .create();
    }

    @Override public ResponseStream openStream(Request request) throws IOException {
        return new IteratorResponseStream(chunks.iterator());   // one Response per fragment
    }
}
```

- **Select it** in *FirstSpirit AI Configuration › Plugins* to make it the server default.
  Scripts can also address it with `GenerativeAIAgent.getConnector(name)`, which takes the
  plugin's name (its public component name) `[javadoc]`.
- **Function calling is run for you.** `GenerativeAIFunctionRequest` adds the `Function` tools to
  the request, reads the `ToolCall`s from the returned messages (`Message.getToolCalls()`), runs
  the functions and sends the results back as `Message.TOOL` messages with `toolCallId` `[core]`.
  - Your connector only has to translate tools to the vendor format, and tool calls back with
    `Message.builder().addToolCall(FunctionCall.builder().id(…).name(…).arguments(json).create())`.
  - When a request carries a function result, map the `TOOL` role and its `getToolCallId()`.
- **Structured output:** honour `getResponseFormat()` (`ResponseFormatJsonSchema` and its
  `StrictMode`). Otherwise `request(Request, Class)` on top of your connector cannot work.
- **Streaming:** implement `openStream`. The Javadoc strongly encourages it, and the assistants
  stream their results `[javadoc]`.
- **Attributes:** `getAttribute*` reads caller-supplied settings such as a model override. Document
  the attribute names your connector understands.
- **Secrets:** keep the API key in the module's configuration (a service or `<configurable>`),
  never in prompts or project content.

## Function-server plugin — your own "MCP server" inside FirstSpirit

```java
public class WikiFunctions implements GenerativeAIFunctionServerPlugin {
    private GenerativeAIFunctionServerHost host;
    private GenerativeAIFunctionServer server;

    @Override public void setUp(BaseContext context) { }
    @Override public void init(GenerativeAIFunctionServerHost host) {
        this.host = host;
        this.server = new WikiServer();          // getName() = "wiki"
        host.register(server);                   // may also be done later, asynchronously
    }
    @Override public void tearDown() { if (host != null) host.unregister(server); }
}
```

- **`GenerativeAIFunctionServer`** (`Closeable`) has `getName()`, `getFunctions()` (a list of
  `Function`) and `perform(GenerativeAIFunctionServerCall)`. `perform` gets `getFunction()` and
  `getArguments()` and returns a `Serializable`, which is sent to the model as a string or JSON
  `[javadoc]`.
- **The server name identifies the server** and prefixes its function ids. Registering two
  servers with the same name throws `IllegalArgumentException` `[javadoc]`.
- The host may be used until `tearDown()`. Register and unregister when the backing system comes
  and goes `[javadoc]`.
- **Once registered,** the functions appear in the prompt configuration's *Functions* section,
  per operation, and in `GenerativeAIAgent.getFunctionServers()`. Scripts allow them with
  `AllowedServerFunction` (`ai-api.md` §5).
- **Read-only by design:** the MCP Connector shows only read-only or unannotated functions. Apply
  the same rule to your own server: anything that writes needs its own approval step outside the
  model's discretion.

## The MCP Connector

The bundled *FirstSpirit MCP Connector* module is a `GenerativeAIFunctionServerPlugin`. Each
configured remote MCP server becomes a function server.

- **It is a client.** FirstSpirit calls the external MCP server; it does **not** expose
  FirstSpirit as an MCP server.
- Configuration and the read-only rule are in `setup-and-configuration.md`. It is on-premises
  only; Cloud customers go through their FirstSpirit representative.
- Typical use: centrally managed tone-of-voice rules, a product database or a wiki that
  operations consult while writing.

## Prompt-preset plugin — ship operations with your module

```java
public class MyPresets implements PromptConfigurationPlugin {
    static final UUID TEASER = UUID.fromString("…fixed, generated once…");
    @Override public Set<String> getTags() { return Set.of("MyAssistant"); }
    @Override public List<SystemPrompt> getSystemPrompts() {
        return List.of(SystemPrompt.create("MyAssistant: System", "You write for <brand> …"));
    }
    @Override public List<PromptOperation> getOperations() {
        return List.of(PromptOperation.builder()
                .name("Teaser").prompt("… You will receive an input text at the end of this message.")
                .tags(Set.of("MyAssistant")).textRequired(true).create(TEASER));
    }
    @Override public List<PromptOption> getOptions() { return List.of(); }
    @Override public void setUp(BaseContext context) { }
    @Override public void tearDown() { }
}
```

- **IDs must be stable.** FirstSpirit updates unmodified presets by ID. Once an admin edits a
  preset, it stops receiving updates. A preset you remove may stay visible in configurations
  `[javadoc]`.
- **System prompt names share one namespace** across plugins. Prefix them with your module or
  assistant name `[javadoc]`.
- `getTags()` returns standard tags. They show as checkboxes instead of free text in the editor.

## Test plugin — make the *Test Prompt* button match your code

`createRequest(PromptOperationContext ctx)` receives the following:

- `getText()`: the sample or edited input.
- `getOperation()`.
- `getOptions()`: a `Map<PromptOption, PromptOptionItem>` of the chosen items.
- `getSystemPrompt(name)`.

Build exactly the `Request` your script or module would send. Then a passing test means
something. `getPreferredTags()` preselects the plugin for operations with your tag.
`getDefaultText()` fills the sample input. The *Test Prompt* dialog sends exactly the
`Request` the chosen plugin builds `[core]`.
