# Accessing the API from a standalone app

Inside a running script or module component you already have a
`context`/`SpecialistsBroker`. When you run Java **outside** the server — a
standalone importer, a test harness, an IDE launcher (a common way to prototype before
packaging into a module) — you must open a connection yourself.

Package: `de.espirit.firstspirit.access.ConnectionManager`, `Connection`.

---

## Connect, get a project broker, disconnect

```java
import de.espirit.firstspirit.access.Connection;
import de.espirit.firstspirit.access.ConnectionManager;
import de.espirit.firstspirit.agency.BrokerAgent;
import de.espirit.firstspirit.agency.SpecialistsBroker;
import de.espirit.firstspirit.agency.StoreElementAgent;

Connection connection = ConnectionManager.getConnection(
        host, port, ConnectionManager.HTTP_MODE, login, password);
try {
    connection.connect();

    // The connection's broker has NO project binding:
    SpecialistsBroker broker = connection.getBroker();

    // Get a PROJECT-scoped broker via BrokerAgent, then use project agents:
    BrokerAgent brokerAgent = broker.requireSpecialist(BrokerAgent.TYPE);
    broker = brokerAgent.getBrokerByProjectName(projectName);

    StoreElementAgent elems = broker.requireSpecialist(StoreElementAgent.TYPE);
    // ... work with the API (see firstspirit-api-reference) ...

} finally {
    connection.close();                    // always release the session
}
```

Key points:

- **Connection mode:** `ConnectionManager.HTTP_MODE` (also SOCKET/HTTPS variants).
- **`connection.getBroker()` is project-less** — trying to get a
  `StoreElementAgent`/`StoreAgent` from it throws. Always resolve a project broker
  with `BrokerAgent.getBrokerByProjectName(...)` (or `getBroker(id)`).
- **Close the connection** in a `finally` — sessions are limited
  (`MaximumNumberOfSessionsExceededException` if leaked).
- A proxy can be set with `ConnectionManager.setProxy(...)` (not official API).

## Create content (lock + create + save)

The same lock discipline as scripting applies. Loading templates/folders by UID
and creating under a lock:

```java
StoreElementAgent agent = broker.requireSpecialist(StoreElementAgent.TYPE);

PageFolder folder  = (PageFolder)  agent.loadStoreElement(folderUid,   PageFolder.UID_TYPE,   false);
Template   pageTpl = (Template)    agent.loadStoreElement(pageTplUid,  PageTemplate.UID_TYPE, false);

Page page = folder.createPage("new_page_uid", pageTpl, true);   // create (folder must be lockable)

SectionTemplate secTpl = (SectionTemplate) agent.loadStoreElement(secTplUid, SectionTemplate.UID_TYPE, false);
page.getBodyByName("Content center").createSection("My section", secTpl);
// then: lock/save the affected elements (see firstspirit-api-reference: lock/save)
```

- Element types expose static UID types (`PageFolder.UID_TYPE`,
  `PageTemplate.UID_TYPE`, …) for `loadStoreElement`.
- `getBodyByName(...)` reaches a page's body by its template-defined name.
- For the full object model and the lock/save pattern, see
  `firstspirit-api-reference`.

## Standalone → module

A proven approach builds the logic as a standalone app first (fast to iterate in an IDE),
then wraps it as a module component. Once inside a module you **drop the ConnectionManager
code** — the server hands you a broker/context directly. Keep connection handling
at the entry point so the core logic works unchanged in both settings.
