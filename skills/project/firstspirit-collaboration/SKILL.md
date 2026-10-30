---
name: firstspirit-collaboration
description: >-
  Lookup reference for the FirstSpirit Collaboration Java API
  (com.crownpeak.firstspirit.modules.collaboration, @Experimental), the comment threads on
  editors in ContentCreator: the entry point CollaborationAgents.create(broker), the
  per-project ConversationAgent, MessageAgent and IdentifierAgent, the DTOs (Conversation,
  Message, Participant, ConversationPath and its Builder), the enums (ConversationType,
  MessageType, ParticipantType SYSTEM/FS_USER/AI_AGENT), and how a conversation is anchored
  to a PageRef, Section, Dataset or a specific editor or catalog card. Use whenever you
  create, read, update or archive a Collaboration comment from code: "post a comment on a
  page from a script", "add a message to an existing thread", "list the comments on a
  dataset", "build a ConversationPath", "post as an AI agent". Pair with
  firstspirit-api-reference (broker, IDProvider) and firstspirit-scripting or
  firstspirit-module-development (running the code).
metadata:
  source-commit: "1e54562"
  published: "2026-10-30"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit Collaboration API reference

Fast, factual lookup for the **FirstSpirit Collaboration Java API** — the
"Collaboration" feature that attaches **comment threads (conversations of
messages) to editors** in ContentCreator. This skill is the code-facing view:
how to create, read, update, and archive those conversations and messages from a
script or module.

Package root: `com.crownpeak.firstspirit.modules.collaboration`. The whole API is
annotated **`@Experimental`** — see [the caveat](#experimental-api).

> Collaboration threads are where review findings and AI-generated remarks land for
> editors; this skill is the API for writing and reading them from code.

## Companion skills — this skill owns only the Collaboration layer

- **The broker and the elements you comment on** — `SpecialistsBroker`,
  `IDProvider`, `PageRef`, `Section`, `Dataset`, `FormField`, `Language`, and the
  **GID** of a store element (via `GidAgent`) — belong to
  `firstspirit-api-reference`. This skill takes those as given and builds
  conversations on top of them.
- **How you run the code** — the bound `context`/broker in a BeanShell script →
  `firstspirit-scripting`; packaging it as a module (Executable, Service,
  ContentCreator integration) → `firstspirit-module-development`.
- **Not REST.** The FirstSpirit REST API (`firstspirit-rest-api`) has **no
  Collaboration endpoints** — this Java API is the only programmatic route. See
  [references/concepts-and-setup.md](references/concepts-and-setup.md).
- **What the feature is for editors, and how to install/activate it** →
  [references/concepts-and-setup.md](references/concepts-and-setup.md) and the
  [installation guide](https://docs.crownpeak.com/firstspirit/collaboration/installation-guide/).

## How to use this skill

- **Look up, don't lecture.** Give the agent method, DTO, or path-builder call —
  then stop. Point into `references/` for the full catalogue.
- **Get the agents from the broker, per project.** There is no `new`. Start from
  `CollaborationAgents.create(broker)`, then ask it for the agent you need by
  **project id**. See [Quick answers](#quick-answers).
- **A conversation is anchored by a `ConversationPath`.** You never hand-build
  one — you get a `ConversationPath.Builder` from the `IdentifierAgent` for a
  concrete `IDProvider` (a `PageRef` or a `Dataset`), then narrow it to a section,
  editor, or catalog card. See [references/api-model.md](references/api-model.md).
- **Two id systems.** Store elements are addressed by their **GID** (`UUID`);
  conversations and messages have their own **`UUID`** ids. Don't confuse the two.
- **Copies, not live objects.** `getConversations`, `getById`, `getMessages`
  return **copies** of the persisted objects. To persist an edit you must call
  the matching `update(...)` — mutating the copy alone changes nothing.

## Quick answers

- **Entry point:** `CollaborationAgents agents = CollaborationAgents.create(broker);`
  then `agents.getConversationAgent(projectId)`, `agents.getMessageAgent(projectId)`,
  `agents.getIdentifierAgent(projectId)` — `projectId` is a `long`.
- **Post a comment on an element:** build a `ConversationPath`, then
  `conversationAgent.create(path, "text")` → returns the new `Conversation`.
- **Build the path:** `identifierAgent.createPathBuilder(idProvider)` →
  `.language("EN")` → optionally `.section(...)` / `.editor("st_headline")` /
  `.catalogCard(card)` → `.build()`. The `idProvider` must be a **`PageRef`** or a
  **`Dataset`**.
- **Reply in a thread:** `messageAgent.addMessage(conversationId, "text")` →
  returns the new `Message`.
- **Read a thread:** `messageAgent.getMessages(conversationId)` → `List<Message>`.
- **List an element's comments:** `conversationAgent.getConversations(elementGid,
  "EN", false)` — `false` = current, `true` = archived only. Get `elementGid`
  with `broker.requireSpecialist(GidAgent.TYPE).getGid(idProvider)`.
- **Archive:** `conv.setArchived(true); conversationAgent.update(conv);`
- **Who posted:** `message.getAuthor()` → `Participant`, whose
  `getType()` is `SYSTEM`, `FS_USER`, or `AI_AGENT`.
- **Authorship is fixed:** messages you post through this API are **always
  authored as the current user** (`FS_USER`) — you can't set the author. Give a
  bot its own service account. `AI_AGENT` replies come from AI-Suite agents
  (`@name` in ContentCreator), not from `MessageAgent`.

## References

Loaded on demand — read the file that matches the question.

| File | Covers | Read when |
| --- | --- | --- |
| [references/api-model.md](references/api-model.md) | The full class catalogue: `CollaborationAgents` and the three agents (`ConversationAgent`, `MessageAgent`, `IdentifierAgent`), the DTOs (`Conversation`, `Message`, `Participant`, `ConversationPath` + `Builder`), and the enums (`ConversationType`, `MessageType`, `ParticipantType`) — with method signatures and semantics | You need an exact signature, return type, nullability, or what a method does |
| [references/common-patterns.md](references/common-patterns.md) | Copy-paste tasks: get the agents, comment on a page / section / editor / catalog-card / dataset, reply, list & read threads, archive, edit & soft-delete a message, and post a system/AI-agent comment | You need working code for a concrete Collaboration task |
| [references/concepts-and-setup.md](references/concepts-and-setup.md) | What Collaboration is for editors, the conversation/message/participant model, **who authors a message**, GID vs UUID, current vs archived, **ContentCreator-only / not-headless / not-REST scope**, **AI agents (AI Suite, `@name`)**, editor-facing behaviour & limits, the `@Experimental` contract, and the prerequisites/installation/activation summary | You need the conceptual model, the delivery scope, how AI agents fit, or what must be installed and activated |

## Experimental API

Every public type in this API carries `@Experimental`. Treat it as **not yet
stable**: signatures, types, and behaviour may change between FirstSpirit
releases without the usual deprecation cycle. This skill follows the Javadoc and
the product documentation; the names are verified against the API jar, and
statements tagged `[verify]` are not yet confirmed on a live installation.
Requires **FirstSpirit 2025.5+**
and the **FirstSpirit Collaboration** module installed and activated per project
(see [references/concepts-and-setup.md](references/concepts-and-setup.md)). Pin
the FS version you built against and re-check after upgrades.

---

*Sources: the FirstSpirit Collaboration API Javadoc
(`com.crownpeak.firstspirit.modules.collaboration`; the class catalogue in
`references/api-model.md` is transcribed from it), and the FirstSpirit
Collaboration documentation —
[installation guide](https://docs.crownpeak.com/firstspirit/collaboration/installation-guide/),
[API guide](https://docs.crownpeak.com/firstspirit/collaboration/collaboration-api-guide/index-2.html),
[configuring AI agents](https://docs.crownpeak.com/firstspirit/collaboration/configuring-ai-agents/),
[user guide](https://docs.crownpeak.com/firstspirit/collaboration/user-guide/).
Statements tagged `[verify]` are not yet confirmed against a live install.*

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
