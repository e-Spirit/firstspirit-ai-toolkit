# `top.WE_API.Report` — open a report and preset its filters

Java interface: `de.espirit.firstspirit.webedit.client.api.Report` [javadoc]
ODFS: JavaScript APIs › ContentCreator › Reports [odfs]

## Members

| Member | Signature | Note |
| --- | --- | --- |
| `show` | `void show(String reportName, JavaScriptObject filterParameters, boolean restart)` | open the report, set filters, maybe re-run [odfs] |
| `refresh` | `void refresh(String reportName)` | re-run the named report — **Javadoc only**, not on the ODFS page [javadoc] |

## `reportName`

Built-in reports use a shortcode; report plug-ins use the **fully qualified class name** of
the `ReportPlugin` implementation. [odfs]

| Report | Shortcode | `Report` constant [javadoc] |
| --- | --- | --- |
| Search | `Search` | `REPORT_SEARCH` |
| Bookmarks | `Bookmarks` | `REPORT_BOOKMARKS` |
| Tasks | `Tasks` | `REPORT_TASKS` |
| Project history | `History` | `REPORT_HISTORY` |
| References | `RelatedObjects` | `REPORT_RELATEDOBJECTS` |
| Notifications | `Notifications` | `REPORT_NOTIFICATIONS` |
| My changes | `MyChanges` | `REPORT_MYCHANGES` |
| Recent elements | `RecentElements` | `REPORT_RECENTELEMENTS` — Javadoc only, not in the ODFS table [javadoc] |

(`REPORT_GPT` = `"GPT"` exists but is `@Internal`. [javadoc])

```javascript
// Built-in "References" report, forced re-run
top.WE_API.Report.show("RelatedObjects", null, true);

// A module's report plug-in, keep current filters, don't re-run
top.WE_API.Report.show("de.espirit.firstspirit.opt.example.universal.report.TextBlocksReportPlugin", null, false);

// Preset three filters of the example plug-in
top.WE_API.Report.show(
  "de.espirit.firstspirit.opt.example.universal.report.TextBlocksReportPlugin",
  {"pattern_text": "FirstSpirit", "pattern_boolean": true, "pattern_select": "ascending"},
  false
);
```
[odfs]

## `filterParameters` — the rules [odfs]

- JSON object; keys are the **names of the plug-in's `Parameter` objects**, values by type:
  `ParameterText` → `String`, `ParameterBoolean` → `boolean`, `ParameterSelect` → `String`
  that matches one of its configured `SelectItem`s.
- `null` or `{}` → every filter keeps its current value (or the plug-in default on first
  display in this session).
- A key **omitted** → that filter keeps its current value / default.
- A key given with value **`null`** → that filter is reset to the plug-in default.
- Unknown keys are ignored. Values of the wrong type are coerced if possible, without
  guarantee; an uninterpretable value logs a JavaScript warning and leaves the filter as is.
- Defining `Parameter`s on the plug-in side: `firstspirit-module-development/references/data-access-and-reports.md`.

## `restart` [odfs]

- `true` → run the data provisioning again even if filters are unchanged.
- `false` → keep the existing result list **if** the filters did not change.
- Any actual filter change refreshes the result regardless of `restart`.
