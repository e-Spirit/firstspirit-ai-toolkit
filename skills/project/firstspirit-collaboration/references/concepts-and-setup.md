# Collaboration — concepts, setup, and activation

The conceptual model behind the API, and what must be in place before any of it
works. For the code, see [common-patterns.md](common-patterns.md); for
signatures, [api-model.md](api-model.md).

## What Collaboration is

FirstSpirit Collaboration adds **comment threads to editorial content**. An
editor working in **ContentCreator** can attach a comment to a page, a section,
or a specific input component, and others can reply — a lightweight review and
discussion channel that lives *on the content*, in context, rather than in email
or a separate tool.

The Java API in this skill is the programmatic face of that feature: it lets code
(a module, a script, an AI integration, an analysis skill) create and read those
same threads. That is why this skill is the **delivery path** the portfolio's
analysis skills use — a content-hygiene or diagnostic finding becomes a comment on
the exact element it concerns, waiting for the editor in ContentCreator.

## The model in three objects

- **Conversation** — a thread. It has a **type** (today always `COMMENT`), an
  **anchor** (a `ConversationPath`), a **language**, and an **archived** flag.
- **Message** — one entry in a thread. It has an **author** (`Participant`),
  **content**, timestamps, a **type** (today always `CHAT_MESSAGE`), and a
  soft-**deleted** flag.
- **Participant** — the author of a message. Its **type** is `SYSTEM`,
  `FS_USER`, or `AI_AGENT` — so the model explicitly anticipates humans, the
  system, and AI agents commenting side by side.

Creating a conversation (`ConversationAgent.create`) always creates its first
message; further entries are added with `MessageAgent.addMessage`.

## Who authors a message

**Messages you create through the Java API are posted as the current user** — the
authenticated session the broker belongs to (an `FS_USER`). You do **not** pass an
author, and you cannot post as a different user. Consequences:

- A script or module that posts findings comments as **whatever FirstSpirit
  account it runs under** — so give the "hygiene bot" its own service account if
  you want its comments to read as a distinct author.
- **`AI_AGENT`** participants are **not** produced by this API. They come from
  **AI-Suite agents** configured in ContentCreator and invoked by an editor typing
  `@<agentname>` in a thread (see [AI agents](#ai-agents-are-configured-not-called-from-this-api)).
- **`SYSTEM`** is the system participant (system-generated messages); the exact
  triggers aren't documented — treat the enum as read-only classification, not
  something you set.

Editing follows the same identity: an editor can edit **only their own** comments;
administrators can edit any (per the user guide). Expect the API to enforce the
same, i.e. `update(...)` is bounded by who the session is.

## Where a conversation is anchored — the `ConversationPath`

A conversation belongs to **exactly one element**: a **`PageRef`** (Site Store)
or a **`Dataset`** (Content Store). From a `PageRef` anchor it can be narrowed
further:

```
PageRef  ─┬─ (whole page)
          ├─ Section
          └─ Editor (by name / FormField)
                 └─ Catalog card (inside an FS_CATALOG)

Dataset  ─── (the record)
```

You never construct a path by hand — you get a `ConversationPath.Builder` from
the `IdentifierAgent` for a concrete element, then narrow and `build()`. The
builder rejects an element that is neither a `PageRef` nor a `Dataset`, and
rejects setting both a `pageRef` and a `dataset`.

## Two id systems — GID vs UUID

- **GID** — the `UUID` that identifies a **store element** (`PageRef`, `Section`,
  `Dataset`). This is what `ConversationAgent.getConversations(elementGid, …)`
  filters on, and what a `ConversationPath` stores internally
  (`getPageRef()`/`getDataset()`/`getSection()` all return GIDs). Get it — and
  resolve it back — with the **`GidAgent`**
  (`de.espirit.firstspirit.common.GidAgent`):
  `getGid(idProvider)` for element → GID, `findIDProvider(gid, release)` for
  GID → element, and `findDataset(gid, release)` for a dataset GID (datasets do
  **not** resolve via `findIDProvider`). It is *not* a `getGid()` on the element
  itself.
- **Conversation / Message `UUID`** — the id of the *thread* or the *message*
  itself, returned by `Conversation.getId()` / `Message.getId()` and used with
  `getById` / `getMessages` / `addMessage`.
- **Project id, twice over** — `CollaborationAgents.get*Agent(long projectId)`
  takes the numeric **`long`** project id; `Conversation.getProjectId()` returns
  a **`UUID`**. Different representations of the project — don't cross them.

## State: current vs archived

Conversations are either **current** or **archived**. `getConversations(gid,
lang, archived)` returns one or the other, never both — pass `false` for current,
`true` for archived, and query twice if you need the full set. Archive by
`setArchived(true)` + `update(...)`. Messages are never hard-deleted through this
API — `setDeleted(true)` marks them, and `isDeleted()` lets you filter.

## ContentCreator-only — not headless, not REST

Collaboration is a **ContentCreator** feature. Two scoping facts matter for the
portfolio:

- **Not available for headless projects** (per the user guide). Comments live in
  ContentCreator; a headless project has no place to show them. So this delivery
  path only reaches ContentCreator editors.
- **No REST endpoints.** The FirstSpirit REST API (`/rest/v1`,
  `firstspirit-rest-api`) exposes pages, sections, datasets, media, templates,
  scripts, search — but **nothing** for conversations or messages. Delivery goes
  through **this Java API** (a module, or a script with broker access). The
  install guide deploys a separate *microapp* web app for the feature's own UI
  (and the API supports real-time updates over WebSockets), but that is internal
  to the module, not a documented public REST surface — don't build against it.

(If a public Collaboration REST endpoint or headless support appears later,
revisit this.)

## AI agents are configured, not called from this API

The `AI_AGENT` participant type is fulfilled by **AI-Suite agents**, configured
and invoked entirely outside the Collaboration Java API:

- **Requires** a FirstSpirit **AI Suite** subscription; **only project admins**
  can create agents.
- Configured in **ContentCreator's prompt configuration** as an operation (name,
  prompt, feature access), with an optional `Collaboration:` prefix.
- An editor invokes one by typing **`@<agentname>`** in a conversation (the
  built-in one is `@FirstSpiritAI`); the agent's reply appears as an `AI_AGENT`
  message.
- The agent prompt can pull context via placeholders:
  `$AI.COMMENTS.THREAD$` (thread history), `$AI.CONTENT.EDITOR$` (current input
  component's form data), `$AI.CONTENT.PAGE$` (whole page form data),
  `$AI.USER.REQUEST$` (the user's chat message), `$FS.PROJECT.ID$`,
  `$FS.PROJECT.NAME$`.

So: to add AI behaviour you configure an agent in the AI Suite — you do not post
`AI_AGENT` messages through `MessageAgent`. Full detail:
[configuring AI agents](https://docs.crownpeak.com/firstspirit/collaboration/configuring-ai-agents/).

## Editor-facing behaviour (what the API is backing)

From the user guide — useful when your code's comments must fit what editors see:

- **Where:** editors open Collaboration from the **report area** icon; comment
  markers appear in the preview next to annotated elements. Comments attach to a
  single input component or the whole page.
- **Language-dependent:** the default view shows unresolved comments in the
  **current project language**; filters switch language, show resolved, or show
  all project comments. This is the `language` argument on the API.
- **Resolve ≈ archive:** editors "resolve" a conversation to mark it complete and
  can filter "resolved" ones. This appears to correspond to the API's
  **`archived`** flag (`isArchived()` / `setArchived(...)` / the `archived`
  argument) — **treat as an inference to confirm** `[verify]`.
- **Not in this API:** the UI also offers **emoji reactions** and has **no user
  tagging** — neither is represented in the DTOs here, so don't promise them from
  code.
- **Other limits (user guide):** dataset comments are limited to preview pages and
  media comments to preview references; comments are **excluded from transports**
  (they don't travel with a project export/deployment).

## The `@Experimental` contract

Every public type is annotated `@Experimental`. This is a real signal, not
boilerplate: the API may change shape between releases without the normal
deprecation path. Practically:

- Pin the FirstSpirit version you build/test against.
- Re-verify after every FS upgrade.
- Don't build irreversible automation on it without a fallback.

## Prerequisites, installation, activation

> **Source of truth:** the FirstSpirit
> [Collaboration installation guide](https://docs.crownpeak.com/firstspirit/collaboration/installation-guide/).
> The summary below is for orientation; follow the guide for the authoritative,
> current steps. **Cloud-hosted setups differ from local servers** — the guide
> distinguishes them.

**Prerequisites (as documented at the time of writing):**

- FirstSpirit **2025.5 or higher**.
- The **FirstSpirit Collaboration** module (current version).
- **Tomcat 10.1.11+** and **PostgreSQL 12.0+**.
- A configured **CXT platform** with the required Tomcat properties, and a single
  external web server.
- A downgrade is not generally guaranteed — plan the version carefully.

**Installation (local server, in brief):**

1. **FirstSpirit service config** — create
   `[FirstSpirit]/conf/modules/fs-collaboration.fs-collaboration-service/` with a
   properties file holding the database credentials, schema, driver, and JDBC URL.
2. **Tomcat** — copy the PostgreSQL driver JAR into `[Tomcat]/lib/`, and add
   `fs-collaboration-microapp.properties` under `[Tomcat]/lib/config/`.
3. **Database** — create the schema named in the config and grant the configured
   user read/write.
4. **Web apps** — installation deploys the microapp web app
   (`fs-multisite-microapp`) and adds the ContentCreator integration component;
   the **ContentCreator web app must be (re)deployed manually** by an admin.

**Activation per project:** add the **"FirstSpirit Collaboration | ProjectApp"**
project component to each project via ServerManager. Without this the feature —
and the API — is inactive for that project.

Until the module is installed *and* the ProjectApp is activated, all API calls
either fail or find nothing; a "no conversations / errors" result on a fresh
project usually means activation is missing, not that the code is wrong.
