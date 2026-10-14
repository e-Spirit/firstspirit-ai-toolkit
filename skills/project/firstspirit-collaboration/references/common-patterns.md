# Collaboration API — common patterns

Copy-paste patterns for the Collaboration API. Written in Java; they run
unchanged in a BeanShell script (where you already have a `context` giving you a
`SpecialistsBroker`) and in a module component. For signatures and semantics see
[api-model.md](api-model.md).

**Prerequisites for all of them:** the Collaboration module must be installed on
the server and its **ProjectApp** activated for the project, on FirstSpirit
2025.5+. The Collaboration classes must be on the classpath of the code that runs
(module dependency, or available to the script). See
[concepts-and-setup.md](concepts-and-setup.md).

Imports used below:

```java
import com.crownpeak.firstspirit.modules.collaboration.agency.CollaborationAgents;
import com.crownpeak.firstspirit.modules.collaboration.agency.ConversationAgent;
import com.crownpeak.firstspirit.modules.collaboration.agency.MessageAgent;
import com.crownpeak.firstspirit.modules.collaboration.agency.IdentifierAgent;
import com.crownpeak.firstspirit.modules.collaboration.dto.conversation.*;
import de.espirit.firstspirit.access.store.IDProvider;
import de.espirit.firstspirit.access.store.sitestore.PageRef;
import de.espirit.firstspirit.access.store.pagestore.Section;
import de.espirit.firstspirit.access.store.contentstore.Dataset;
import de.espirit.firstspirit.agency.ProjectAgent;   // for the long project id
import de.espirit.firstspirit.common.GidAgent;        // element GID <-> IDProvider
import java.util.List;
import java.util.UUID;
```

---

## 1. Get the agents (do this first)

```java
// broker: a SpecialistsBroker — from a BeanShell script's context
// (context / context.getSpecialistsBroker()), or from a Connection in a module.
CollaborationAgents agents = CollaborationAgents.create(broker);

long projectId = broker.requireSpecialist(ProjectAgent.TYPE).getProject().getId(); // or a known long id
ConversationAgent conversationAgent = agents.getConversationAgent(projectId);
MessageAgent       messageAgent      = agents.getMessageAgent(projectId);
IdentifierAgent    identifierAgent   = agents.getIdentifierAgent(projectId);
```

The `projectId` argument is a **`long`** (the FirstSpirit project id). Not to be
confused with `Conversation.getProjectId()`, which returns a `UUID`.

---

## 2. Post a comment on a whole page (PageRef)

```java
PageRef pageRef = ...; // e.g. loaded from the SiteStore via firstspirit-api-reference patterns

ConversationPath path = identifierAgent.createPathBuilder(pageRef)
        .language("EN")
        .build();

Conversation conversation = conversationAgent.create(path, "Please review this page before release.");
UUID conversationId = conversation.getId();
```

`create(path, content)` makes the conversation **and** its first message in one
call.

---

## 3. Scope the comment more precisely

Same start (`createPathBuilder(pageRef)`), then narrow before `build()`:

```java
// On a specific section of the page:
ConversationPath onSection = identifierAgent.createPathBuilder(pageRef)
        .language("EN")
        .section(section)                 // Section<?>
        .build();

// On a specific editor (input component) by name:
ConversationPath onEditor = identifierAgent.createPathBuilder(pageRef)
        .language("EN")
        .section(section)
        .editor("st_headline")            // the editor's name
        .build();

// On an editor via its FormField instead of a name:
ConversationPath onField = identifierAgent.createPathBuilder(pageRef)
        .language("EN")
        .editor(formField)                // FormField<?>
        .build();

// On a card inside an FS_CATALOG:
ConversationPath onCard = identifierAgent.createPathBuilder(pageRef)
        .language("EN")
        .editor("st_teasers")             // the catalog editor
        .catalogCard(card)                // Catalog.Card
        .build();
```

Then `conversationAgent.create(onEditor, "...")` as in pattern 2.

---

## 4. Comment on a dataset (Content Store)

```java
Dataset dataset = ...;

ConversationPath path = identifierAgent.createPathBuilder(dataset)   // Dataset, not PageRef
        .language("EN")
        .build();

Conversation conversation = conversationAgent.create(path, "This record's price is out of date.");
```

A path is anchored to **either** a `PageRef` **or** a `Dataset` — never both, and
`createPathBuilder` rejects any other `IDProvider` type.

---

## 5. Reply to an existing thread

```java
Message reply = messageAgent.addMessage(conversationId, "Fixed the headline, please re-check.");
```

---

## 6. List the comments on an element

```java
// The store element's GID comes from the GidAgent, not from the element directly:
UUID elementGid = broker.requireSpecialist(GidAgent.TYPE).getGid(idProvider);

// current (non-archived) conversations for this element in EN:
List<Conversation> open = conversationAgent.getConversations(elementGid, "EN", false);

// archived ones:
List<Conversation> archived = conversationAgent.getConversations(elementGid, "EN", true);
```

`getConversations` filters by element GID **and** language **and** archived flag.
There is no "both current and archived in one call" — query twice if you need
both.

---

## 7. Read a whole thread

```java
Conversation conversation = conversationAgent.getById(conversationId);
if (conversation == null) {
    // no such conversation
    return;
}

for (Message m : messageAgent.getMessages(conversationId)) {
    if (m.isDeleted()) continue;                    // skip soft-deleted
    Participant author = m.getAuthor();
    context.logInfo("[" + author.getType() + "] " + author.getDisplayName()
        + " @" + m.getTimestamp() + ": " + m.getContent());
}
```

`getById` returns `null` for an unknown id — always null-check it.

---

## 8. Archive / unarchive a conversation

```java
Conversation conversation = conversationAgent.getById(conversationId);
conversation.setArchived(true);              // mutates the local copy only
conversationAgent.update(conversation);      // persists it
```

The object from `getById` / `getConversations` is a **copy** — the `setArchived`
does nothing until you `update(...)`.

---

## 9. Edit a message

```java
List<Message> messages = messageAgent.getMessages(conversationId);
Message m = messages.get(0);
m.setContent("Corrected text.");
messageAgent.update(m);                      // persist the edit
```

Same copy-then-update rule. After an update, `getLastModifiedTimestamp()`
becomes non-null.

---

## 10. Soft-delete a message

```java
Message m = ...;                             // from getMessages(...)
m.setDeleted(true);
messageAgent.update(m);
```

This is a **soft** delete — the message object persists with
`isDeleted() == true`; filter it out when displaying (pattern 7). Do not treat it
as a hard removal.

---

## 11. Distinguish who is talking

`Message.getAuthor().getType()` tells you the participant kind:

```java
switch (message.getAuthor().getType()) {
    case FS_USER:  /* a FirstSpirit editor */          break;
    case AI_AGENT: /* an AI agent */                   break;
    case SYSTEM:   /* the system */                    break;
    default:       /* be forward-compatible */         break;
}
```

**Messages you post through this API are always authored as the current user**
(`FS_USER`) — the session the broker belongs to. You cannot set the author. So:

- Run your posting code under a **dedicated service account** if you want its
  comments to read as a distinct author.
- `AI_AGENT` messages are **not** posted through `MessageAgent` — they come from
  AI-Suite agents invoked with `@<agentname>` in ContentCreator. `SYSTEM` is
  system-generated. See
  [concepts-and-setup.md](concepts-and-setup.md#who-authors-a-message).
- Read `getType()` for classification, but don't try to *write* a non-user author.

---

## 12. Resolve a conversation back to its element

A `ConversationPath` stores **GIDs**, not live elements
(`getPageRef()`/`getDataset()`/`getSection()` each return a `UUID` or `null`). To
get back to the store element, use the same `GidAgent` in reverse. **Datasets do
not resolve via `findIDProvider` — use `findDataset`.**

```java
GidAgent gid = broker.requireSpecialist(GidAgent.TYPE);
ConversationPath path = conversation.getPath();

if (path.getPageRef() != null) {
    IDProvider pageRef = gid.findIDProvider(path.getPageRef(), false);  // false = current state
    // ... optionally path.getSection() -> gid.findIDProvider(...)
} else if (path.getDataset() != null) {
    Dataset ds = gid.findDataset(path.getDataset(), false);             // NOT findIDProvider
}
```

Both return `null` if nothing matches (e.g. the element was deleted).

---

## End-to-end: post a hygiene finding on a specific editor

```java
CollaborationAgents agents = CollaborationAgents.create(broker);
long projectId = broker.requireSpecialist(ProjectAgent.TYPE).getProject().getId();

IdentifierAgent   identifierAgent   = agents.getIdentifierAgent(projectId);
ConversationAgent conversationAgent = agents.getConversationAgent(projectId);

ConversationPath path = identifierAgent.createPathBuilder(pageRef)
        .language("EN")
        .section(section)
        .editor("st_link")
        .build();

Conversation c = conversationAgent.create(path,
        "Broken link detected: the target page no longer exists. Please update or remove.");

// later, a follow-up:
agents.getMessageAgent(projectId).addMessage(c.getId(), "Still unresolved as of the last scan.");
```
