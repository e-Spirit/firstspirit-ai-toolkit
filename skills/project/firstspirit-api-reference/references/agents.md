# SpecialistsBroker and agents

You never `new` a FirstSpirit store or service — you **request it from the
`SpecialistsBroker`**. In a script the `context` *is* a broker; in a module you
receive one. Agents are the typed entry points to stores, services, and
operations.

Package: `de.espirit.firstspirit.agency`.

---

## Getting an agent

```
// context (script) or any SpecialistsBroker
Agent a = broker.requireSpecialist(SomeAgent.TYPE);   // throws if unavailable
Agent a = broker.requestSpecialist(SomeAgent.TYPE);   // returns null if unavailable
```

- `requireSpecialist` — use when the agent must be there; fails fast otherwise.
- `requestSpecialist` — use when absence is acceptable (branch on `null`).

Every agent exposes a `static final SpecialistType TYPE` used as the key.

## Reaching the stores

```
import de.espirit.firstspirit.agency.StoreAgent;
import de.espirit.firstspirit.access.store.Store;

storeAgent = broker.requireSpecialist(StoreAgent.TYPE);
Store pageStore = storeAgent.getStore(Store.Type.PAGESTORE, false);   // false = current, true = release
```

## Loading a single element by reference

```
import de.espirit.firstspirit.agency.StoreElementAgent;
import de.espirit.firstspirit.access.store.IDProvider;

elemAgent = broker.requireSpecialist(StoreElementAgent.TYPE);
IDProvider e = elemAgent.loadStoreElement("my_uid", IDProvider.UidType.PAGESTORE, false);
// also: elemAgent.loadReference("<reference descriptor>", false);
```

## Agent catalogue

The agents you reach for most (all via `requireSpecialist(X.TYPE)`):

| Agent | Gives you |
| --- | --- |
| `StoreAgent` | Store roots by `Store.Type` (+ release flag) |
| `StoreElementAgent` | `loadStoreElement(uid, uidType, release)`, `loadReference(...)` |
| `QueryAgent` | Repository search via `fs.*` query syntax — see [querying.md](querying.md) |
| `ProjectAgent` | The current `Project`, its languages, resolutions, config |
| `LanguageAgent` | Project `Language`s, the master language, language lookup |
| `OperationAgent` | GUI/editorial **operations** (open element, show dialogs, request messages) via `OperationType` |
| `WorkflowAgent` | Run / continue workflows on objects headlessly (no UI) |
| `UserAgent` | Information about the current user |
| `ResolutionAgent` | Access project image resolutions |
| `FeatureInstallAgent` / feature agents | Entry point to the ContentTransport API (feature transport between projects) |
| `TransferAgent` | Drag-and-drop / clipboard transfer handling |
| `ImageAgent` | Load/transform images from media |
| `RenderingAgent` | Render a template/element to a string from code |
| `UrlAgent` / `UrlCreatorAgent` | Generated URLs for elements/media |
| `PreviewUrlAgent` / `ClientUrlAgent` | Preview URLs; client (SiteArchitect/ContentCreator) URLs |
| `SnippetAgent` | The editor snippet (label/thumbnail) for an element |
| `FormsAgent` | Access to form definitions / `FormData` handling |
| `RuleValidationAgent` / `ValidationAgent` | Run rule/element validation from code |
| `ModuleAdminAgent` | Install/configure modules and components (admin) |
| `ScheduleTaskAgent` | Start/inspect schedule tasks |
| `ScriptAgent` | Execute a project script by identifier from code |
| `ServerInformationAgent` | Server version / build info |
| `MaintenanceModeAgent`, `RunLevelAgent` | Server state (admin) |
| `BrokerAgent` | Obtain a *project-scoped* broker from a non-project context (e.g. server schedule) |

> Not the full set — the `de.espirit.firstspirit.agency` package has more (see
> the FirstSpirit ODFS documentation). These cover the vast majority of script/module needs.

## Cross-context tip: getting a project broker on the server

Server-level contexts (e.g. a server schedule entry) aren't tied to a project.
Get a project-scoped broker via the `BrokerAgent`:

```
brokerAgent = context.requireSpecialist(BrokerAgent.TYPE);
projectBroker = brokerAgent.getBrokerByProjectName("MyProject");
storeAgent = projectBroker.requireSpecialist(StoreAgent.TYPE);
```
