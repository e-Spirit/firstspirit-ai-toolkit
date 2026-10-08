# Changing what the SiteArchitect preview sends: a web-app filter

When a template set's preview comes back as a download, or as something the embedded browser does
not render, and the cause is the **response type of the preview web app**, a module can change it
with a **servlet filter** shipped as a `web-app` component. This file records what decides the
preview response and the shape of that module. Packaging in general is in
[component-types.md](component-types.md) (*ContentCreator / web components*) and
[multi-project-layout.md](multi-project-layout.md) (`@WebAppComponent`).

> **Status.** The facts about the preview URL and the content type are `[observed]`. That a filter
> in a module web-app component **wraps the preview servlet** is `[verify]`: the module builds and
> its descriptor is correct, but it has not yet been deployed and tested on a server.

---

## What decides the preview type

| Observation | Source |
| --- | --- |
| A store element preview request has the form `…/preview/<project>/<mode>/<language>/<state>/<templateSetId>/<elementId>/<free parameters>`. The ID after the state is the **template set (presentation channel) ID**: the same element previewed in two template sets differs only there. | `[observed]` |
| The preview type follows the **template set's target file extension**. A template set with extension `md` is sent as `binary/octet-stream`, which the embedded browser downloads. The same output with extension `html` renders. | `[observed]` |
| That extension also names the generated file, so changing it to fix the preview changes the deliverable. Copying the output into another channel is a debugging aid, not a fix. | `[observed]` |
| Server property `mime.types.additional` (`mimetype:extension`, separated by `;`) maps extensions for the **Media Store**. It does **not** change the type the preview sends for a page reference. | `[odfs]` Server properties → Misc; `[observed]` for the preview |
| The preview-specific `#global` properties contain nothing that sets a response type or header. | `[odfs]` |
| A `UrlFactory` is a **generation** hotspot. It cannot decide a preview response: a page reference has no registered URL before it is generated, and one page can be generated under different creators at different times. | `[odfs]` plus reasoning, not tested |

`text/plain` renders in the embedded browser as raw text. A `text/markdown` response is the type most
browsers also download instead of rendering `[verify]`, so a retype should aim for `text/plain` or, for a readable
preview, render to HTML in the filter.

## Recognising the channel in the filter

Read the template set ID from the request path, then decide by the **extension of that template set**
instead of hard-coding the ID, because IDs differ per stage:

- `TemplateSet.getId()` and `TemplateSet.getExtension()` `[jar]` (5.2.251108).
- From the template side, `#global.project.templateSets` lists the same objects `[observed]`.
- Whether a web-app filter can obtain a project broker in the preview web app, and how, is `[verify]`.
  Until it is settled, a fallback is an init parameter with the IDs per stage.

Keep the path parsing in a plain class with no servlet or FirstSpirit types so a unit test can cover it
(see [cloud-fsm-build.md](cloud-fsm-build.md): the build needs one passing test).

## The module shape

```java
@WebAppComponent(name = "MyPreview_WebApp", displayName = "My preview filter",
                 webXml = "web.xml", xmlSchemaVersion = "4.0")
public class MyPreviewWebApp extends AbstractWebApp { }     // shell; the behaviour is in web.xml
```

```xml
<!-- src/main/fsm-resources/web.xml -->
<filter><filter-name>MyPreview</filter-name><filter-class>…PreviewFilter</filter-class></filter>
<filter-mapping><filter-name>MyPreview</filter-name><url-pattern>/preview/*</url-pattern></filter-mapping>
```

- `fs-isolated-runtime` **contains no servlet API** `[jar]` (5.2.251108: no `javax.servlet` or
  `jakarta.servlet` classes). Add the servlet API as `compileOnly`; the web app provides it at runtime.
  **`javax` (Servlet 4.0) or `jakarta` (5/6) depends on the web container's version `[verify]`;** keep the
  coordinates, the `xmlSchemaVersion` and the `web.xml` version in step, in one place.
- The generated descriptor holds a `<web-app scopes="PROJECT,GLOBAL">` with `<web-xml>` and a
  `<web-resources>` entry naming the module jar, so the filter class is visible to the web app `[observed]`.
- Third-party libraries (for example a Markdown renderer) must be shipped as web resources
  (`fsWebCompile`); the web app sees none of the server's libraries (see *Web-app components in Isolated
  Mode* in [isolated-mode-and-packaging.md](isolated-mode-and-packaging.md)).
- Log with `java.util.logging` from the filter: the FirstSpirit runtime classes are not what the web
  app sees `[verify]`. The output goes to the web container's log, not the FirstSpirit server log.
  Never log the `login.ticket` or other session parts of the request path.
- Where the component is installed (global or project web app) and the Cloud rules for adding a component
  to a **shared** web app (a support ticket) are in `firstspirit-cloud` (its cloud-constraints reference).

## Order of work

1. **Probe** — a filter that only logs the path and the content type and adds one response header proves
   it wraps the preview servlet at all.
2. **Retype** — for a template set whose extension is `md`, send `text/plain; charset=utf-8`.
3. **Render** — buffer the body, render Markdown to HTML in the filter, send `text/html; charset=utf-8`.
