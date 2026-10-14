# Collaboration API — class catalogue

Package `com.crownpeak.firstspirit.modules.collaboration`. Two sub-packages:

- `.agency` — the agents (entry point + the three per-project agents).
- `.dto.conversation` — the data model (`Conversation`, `Message`, `Participant`,
  `ConversationPath` + `Builder`, and the enums).

This is transcribed from the FirstSpirit Collaboration API Javadoc (the module's
`javadoc-collaboration` bundle) — that is the authoritative source; consult it for
anything not listed here.

Everything below is **`@Experimental`** (see SKILL.md). Fully-qualified
FirstSpirit types are shortened after first mention: `IDProvider`,
`PageRef`, `Section`, `Dataset`, `FormField`, `Language`, `Catalog.Card`,
`SpecialistsBroker`.

---

## Agents (`.agency`)

### `CollaborationAgents` — the entry point

The one type you construct a handle to; from it you reach the three working
agents, each scoped to a **project id** (`long`).

| Member | Signature | Notes |
| --- | --- | --- |
| `create` | `static CollaborationAgents create(SpecialistsBroker broker)` | Factory. `broker` is a standard FirstSpirit `SpecialistsBroker` (from a script `context`, a module component, etc.). Returns a new instance. |
| `getConversationAgent` | `ConversationAgent getConversationAgent(long projectId)` | Conversation CRUD for that project. |
| `getMessageAgent` | `MessageAgent getMessageAgent(long projectId)` | Message CRUD within a conversation. |
| `getIdentifierAgent` | `IdentifierAgent getIdentifierAgent(long projectId)` | Builds `ConversationPath`s for that project. |

All returns are `@NotNull`.

> **Related interface `CollaborationAgent`** appears in the type hierarchy as the
> common super-interface of the three agents. It is not part of the documented
> method surface you call directly — you always go through `CollaborationAgents`.

### `ConversationAgent` — manage conversations

| Method | Signature | Notes |
| --- | --- | --- |
| `create` | `Conversation create(ConversationPath path, String content)` | Creates a new conversation at `path` with an initial message `content`. Returns the created `Conversation`. |
| `getById` | `@Nullable Conversation getById(UUID conversationId)` | The conversation for that id, or `null` if none. Returned object is a **copy**. |
| `getConversations` | `List<Conversation> getConversations(UUID elementGid, String language, boolean archived)` | All conversations on the `IDProvider` with GID `elementGid`, for `language`. `archived`: `true` = only archived, `false` = only current. Returns **copies**. |
| `update` | `Conversation update(Conversation conversation)` | Persists a modified conversation (replaces the persisted instance). Use after e.g. `setArchived(...)`. |

`language` here is a **language abbreviation** string (e.g. `"EN"`, `"DE"`).

### `MessageAgent` — manage messages within a conversation

| Method | Signature | Notes |
| --- | --- | --- |
| `getMessages` | `List<Message> getMessages(UUID conversationId)` | All messages of the conversation, as **copies**. |
| `addMessage` | `Message addMessage(UUID conversationId, String content)` | Appends a new message; returns the stored `Message`. |
| `update` | `Message update(Message message)` | Persists a modified message (e.g. after `setContent(...)` or `setDeleted(...)`). |

### `IdentifierAgent` — build a conversation path

| Method | Signature | Notes |
| --- | --- | --- |
| `createPathBuilder` | `ConversationPath.Builder createPathBuilder(IDProvider idProvider)` | Starts a path builder from an element. **`idProvider` must be a `PageRef` or a `Dataset`** — any other type throws `IllegalArgumentException`. |

---

## Data model (`.dto.conversation`)

### `ConversationPath` — where a conversation lives

Immutable (`final`). Identifies the location of a conversation in a project. A
conversation belongs to **exactly one `IDProvider`: either a `PageRef` or a
`Dataset`** — so exactly one of `getPageRef()` / `getDataset()` is non-null; the
other is `null`. Build one via `IdentifierAgent.createPathBuilder(...)` — never
by hand.

| Accessor | Returns | Meaning |
| --- | --- | --- |
| `getPageRef()` | `@Nullable UUID` | GID of the `PageRef`, if the path is scoped to one; else `null`. |
| `getDataset()` | `@Nullable UUID` | GID of the `Dataset`, if scoped to one; else `null`. |
| `getSection()` | `@Nullable UUID` | GID of the `Section` within the page, if the path is narrowed to a section; else `null`. Only meaningful with a `PageRef`. |
| `getEditorPath()` | `List<String>` | The editor location. For a simple editor: a single editor name. For nested input components (e.g. `FS_CATALOG`): the full path, with catalog cards referenced **by id**. Empty if the conversation is on the element as a whole. |
| `getLanguage()` | `String` | The language abbreviation. |
| `equals` / `hashCode` | | Value equality. |

The path stores **GIDs**, not live elements. Get an element's GID, or resolve a
GID back to an element, with the **`GidAgent`**
(`de.espirit.firstspirit.common.GidAgent`, the type the Javadoc's "See Also"
points at):
`broker.requireSpecialist(GidAgent.TYPE)` → `getGid(IDProvider)` (element → GID),
`findIDProvider(UUID, boolean release)` (GID → element), and for datasets
`findDataset(UUID, boolean release)` (a dataset does **not** resolve via
`findIDProvider`). See [common-patterns.md](common-patterns.md) patterns 6 and 12.

### `ConversationPath.Builder`

Obtained from `IdentifierAgent.createPathBuilder(idProvider)`. Fluent — every
setter returns `this`. `build()` validates and throws
`IllegalArgumentException` on an invalid combination.

| Method | Signature | Notes |
| --- | --- | --- |
| `pageRef` | `Builder pageRef(PageRef pageRef)` | Anchor to a `PageRef`. **Provide either `pageRef(...)` or `dataset(...)`, never both.** |
| `dataset` | `Builder dataset(Dataset dataset)` | Anchor to a `Dataset`. Mutually exclusive with `pageRef(...)`. |
| `section` | `Builder section(Section<?> section)` | Narrow a page-anchored path to a `Section`. |
| `editor` | `Builder editor(String editorName)` | Add an editor path segment by name (e.g. `"st_headline"`). |
| `editor` | `Builder editor(FormField<?> formField)` | Add the editor segment from a `FormField` instance. |
| `catalogCard` | `Builder catalogCard(Catalog.Card card)` | Add an editor segment for a card inside an `FS_CATALOG`. |
| `language` | `Builder language(String abbreviation)` | Set language by abbreviation (e.g. `"EN"`). |
| `language` | `Builder language(Language language)` | Set language from a `Language` instance. |
| `build` | `ConversationPath build()` | Build the path. Throws `IllegalArgumentException` if the builder is in an invalid state (e.g. neither/both of pageRef & dataset). |

Typical starting point: `createPathBuilder(pageRefOrDataset)` already knows the
element, so in practice you often only add `language(...)` and, optionally,
`section(...)` / `editor(...)` / `catalogCard(...)` before `build()`.

### `Conversation`

A comment thread. Retrieve its messages via `MessageAgent`.

| Accessor / mutator | Signature | Meaning |
| --- | --- | --- |
| `getId()` | `UUID` | Unique id of the conversation (use with `MessageAgent`, `getById`). |
| `getProjectId()` | `UUID` | Id of the FirstSpirit project the conversation belongs to. **Note: a `UUID`, distinct from the `long` project id passed to `CollaborationAgents`.** |
| `getType()` | `ConversationType` | Currently always `COMMENT`. |
| `getPath()` | `ConversationPath` | Where the conversation is anchored. |
| `isArchived()` | `boolean` | Whether it is archived. |
| `setArchived(boolean)` | `void` | Set archived state — then persist with `ConversationAgent.update(...)`. |

### `Message`

One message in a conversation.

| Accessor / mutator | Signature | Meaning |
| --- | --- | --- |
| `getId()` | `UUID` | Unique message id. |
| `getType()` | `MessageType` | Currently always `CHAT_MESSAGE`. |
| `getAuthor()` | `Participant` | Who wrote it. |
| `getContent()` | `String` | The message text. |
| `setContent(String)` | `void` | Edit the text — then persist with `MessageAgent.update(...)`. |
| `getTimestamp()` | `long` | Creation timestamp (epoch millis). |
| `getLastModifiedTimestamp()` | `@Nullable Long` | Last-modified timestamp, or `null` if never modified. |
| `isDeleted()` | `boolean` | Whether the message is (soft-)deleted. |
| `setDeleted(boolean)` | `void` | Set deletion state — then persist with `MessageAgent.update(...)`. Soft delete: the message object remains. |

### `Participant`

Someone who can read and write messages.

| Accessor | Signature | Meaning |
| --- | --- | --- |
| `getId()` | `UUID` | Unique participant id. |
| `getType()` | `ParticipantType` | `SYSTEM`, `FS_USER`, or `AI_AGENT`. |
| `getName()` | `String` | The participant's name (login/identifier). |
| `getDisplayName()` | `String` | Human-readable display name. |

---

## Enums

| Enum | Constants | Meaning |
| --- | --- | --- |
| `ConversationType` | `COMMENT` | A comment chain on a FirstSpirit editor. (Only value today.) |
| `MessageType` | `CHAT_MESSAGE` | A chat message on a conversation thread. (Only value today.) |
| `ParticipantType` | `SYSTEM`, `FS_USER`, `AI_AGENT` | The author kind: the system, a FirstSpirit user, or an AI agent. |

Each enum has the standard `values()` / `valueOf(String)`. Because each has a
single content value today (except `ParticipantType`), don't hard-code
assumptions that survive future additions — switch on the constant you handle and
have a default.

---

## Nullability at a glance

- **Always non-null:** the agents and their non-`getById` returns, `Conversation`
  and `Message` fields except where noted, all `Participant` fields,
  `ConversationPath.getEditorPath()`/`getLanguage()`.
- **Nullable:** `ConversationAgent.getById(...)` (no such conversation);
  `ConversationPath.getPageRef()` / `getDataset()` (exactly one is null by
  design); `ConversationPath.getSection()` (null unless section-scoped);
  `Message.getLastModifiedTimestamp()` (null if never modified).

## `IllegalArgumentException` sources

- `IdentifierAgent.createPathBuilder(idProvider)` — `idProvider` is neither a
  `PageRef` nor a `Dataset`.
- `ConversationPath.Builder.build()` — invalid state (e.g. neither or both of
  `pageRef`/`dataset` set).
