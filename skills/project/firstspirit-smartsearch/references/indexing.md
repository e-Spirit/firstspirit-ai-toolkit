# Indexing — Data Generators, fields, enhancers and the write APIs

Source: SmartSearch documentation 5.12.1 (*Data*, *Usage of the SmartSearch Generic API*,
*Start/Stop Data Generators*, *Hot injection and hot deletion*, *Configuration Management
API*, *Import/Export*, *Examples of Groovy Scripts Enhancers*) and the *SmartSearch REST API
for external Data Generators* `[odfs]`, unless a line says otherwise. All write calls go to
the **server**, never the gateway, with `Authorization: Basic …` (or a bearer token in OIDC
mode).

## Document rules

- **Mandatory:** `id` (set by SmartSearch, **reserved**: a source field called `id` fails the
  generation), `title`, `content`, `link`. A document without `title`, `link` or `content` is
  invalid; a document with an empty `content` is not indexed (for example image-only PDFs).
- **Static fields:** `thumbnail` (image URL for result lists), `keywords` (no linguistic
  processing), `language` (ISO 639-1; longer codes are cut to two letters, `de_DE` → `de`; the
  original stays in `language_original_stored_only`).
- `title` and `content` are processed per language. Pass the language as `language_keyword`.
- A field that does not support multiple values keeps the first value and logs a warning.
- Since 5.12 a value that does not match its suffix type (text in a `_long`) is **dropped**
  with a warning naming field and cause; the rest of the document is indexed (release notes).

## Field suffixes

| Suffix | Type / purpose | Sort | Multi |
|---|---|---|---|
| `_integer`, `_long`, `_double` | Numbers | ✓ | |
| `_date` | UTC instant, `2020-10-05T12:14:29.058Z` | ✓ | |
| `_date_range` | Period (`2020-10-05`, `2023`); query with `{!field f=… op=Contains}` | | |
| `_keyword` | Keyword; **creates a facet automatically** (fills `_facet_string`) | | ✓ |
| `_keyword_lc` | Lower-cased keyword; controlled autocomplete phrases | | ✓ |
| `_sort` / `_sort_de` | Sort value, lower-cased, spaces removed; `_de` sorts umlauts and ß with their base letters | ✓ | |
| `_token` | **Grouping** key | | |
| `_pnt` | Geo point `lat,lon` (spatial search) | | |
| `_facet_string` | Text facet values (filled from `_keyword`) | | ✓ |
| `_facet_double` | Numeric facet values (fill yourself, e.g. `price_facet_double`) | | ✓ |
| `_stored_only` | Returned, not searchable, ≤ 32 766 characters | | ✓ |
| `_stored_only_big` | Returned, not searchable, unlimited | | ✓ |
| `_autocomplete`, `_expanded_autocomplete` | Extra (two-word) autocomplete terms, space-separated | | |
| `_text_<lang>`, `_autocomplete_<lang>`, `_expanded_autocomplete_<lang>` | Language-processed text and terms (`_text_de`) | | ✓ |

Fields that match no suffix are stored and generally allow multiple values. Languages: 26,
each with lower-casing, normalisation, stemming, stopwords and (where supported) synonyms.

## Data Generator types

### Common settings (*General* and *Enhancer* tabs)

- Name, default language, *Minimum number of documents for synchronization* (threshold before
  the index is updated), schedule.
- Status values: Ready, Record, First or Second Enhancer, Synchronized, Error; API DGs show
  *API Ready* permanently.
- Data is searchable **up to 15 minutes** after a run. *Reload Collection* (ADMIN only)
  commits all DGs at once; a single DG cannot be committed alone.
- *Empty* (eraser icon) deletes all documents of a DG from the index.
- The *Browser* (*Data → Browser*) shows every indexed document of a DG with all fields:
  the first place to look when a field or facet is missing.

### Web

- Start URL (a page, an XML sitemap or an index sitemap; sitemaps themselves are not indexed),
  maximum pages (`0` = all).
- Follows links and canonical links; never from HTTPS to HTTP. Links with `rel="nofollow"`
  are skipped. Since 5.6 malformed canonical `href` values are ignored (they need a scheme
  or a proper relative path).
- Exclude page parts with `<!-- NO INDEX -->` … `<!-- INDEX -->`.
- *Check URL Script* (Groovy, returns boolean; variable `url`):
  ```groovy
  return url.startsWith("https://www.example.com") && !url.contains("/shop/")
  ```
  `return true` can crawl forever.
- Options: ignore `<noscript>`, observe `robots.txt`, remove URL parameters, charset, user agent
  (default `smart-search-agent`), interval between downloads, timeouts.
- Status codes: 2xx indexed; 301 the new URL is used; 302/307 content of the target, old link
  kept; 4xx/5xx skipped and logged at DEBUG.
- Language detection order: `<html lang>`, `<body lang>`, `meta name="language"`,
  `content-language`, `og:locale`, `DC:language`, `og:locale:alternative`; then automatic
  detection from `content`; then the DG default.
- File types are extracted (PDF, Office, OpenDocument, RTF, text, HTML, XML, CSV, TSV, EML,
  JSON, Markdown, code files); the list depends on libraries and may change.

### XML

- *XML URL* over HTTP(S) only (no file system). Points at a **data XML** or a **seed XML**:
  ```xml
  <documents>
    <document uid="0815">
      <field name="title"><![CDATA[…]]></field>
      <field name="link"><![CDATA[https://…]]></field>
      <field name="content"><![CDATA[…]]></field>
      <field name="language_keyword"><![CDATA[en]]></field>
      <field name="category_keyword"><![CDATA[press]]></field>
      <field name="category_keyword"><![CDATA[socialmedia]]></field>
    </document>
  </documents>
  ```
  ```xml
  <seeds>
    <seed url="https://…/documents-01.xml"/>
    <seed url="https://…/another-seed.xml"/>
  </seeds>
  ```
  `uid` is a unique alphanumeric id; repeat a `field` for multiple values; wrap values in
  CDATA. Seeds nest without limit. XML sitemaps need the Web DG.

### External (legacy)

Receives documents over its own REST API (since 2.0.0.59). Create the DG in the cockpit
first; the calling technical user needs the right to execute a data generation. The docs say
bad credentials return `405` ("Not authorized"). All calls are under
`/rest/api/v1/datagenerator/external/{name}`, `Content-Type` and `Accept: application/json`:

| Step | Call | Notes |
|---|---|---|
| Begin | `POST …/begin` body `{"creationType": "NEW" \| "COPY_LATEST", "message": "…"}` (optional) | `412` if a generation is running; `COPY_LATEST` starts from the previous storage |
| Add | `PUT …/{name}` body `{"uid": "abc", "data": {"key": ["v1","v2"], "k2": "v"}}` | Same `uid` replaces; missing `uid` → `400` |
| Commit | `POST …/commit` | Enhancers run, storage is synced; returns immediately |
| Abort | `POST …/abort` | Frees resources |
| Status | `GET …/status`, `Accept: text/plain` | `IDLE`, `ERROR`, `CRAWLING` …; begin only from `IDLE` or `ERROR` |

Success is `204`. The documentation says the external DG "will be replaced … by the generic
API … and will not be developed further". New projects use the generic API.

### API (generic API and SmartSearch Connect)

Created automatically with the first document sent to an unknown DG name; cannot be started
or stopped. An identically named Prepared Search is created and linked to it at the same time.

## Generic API

```bash
# one document (language segment optional)
curl -X PUT 'https://<server>:8181/rest/api/v1/smartsearchconnect/myDG/de/00001' \
  -H 'Content-Type: application/json' -H 'Authorization: Basic <…>' \
  -d '{"link":"https://www.example.com/doc01.html","title":"Doc 01","content":"…",
       "myCategory_keyword":"Article","multiValuedField":["Value 01","Value 02"]}'

# several documents: array, each with its id in "uid"
curl -X POST 'https://<server>:8181/rest/api/v1/smartsearchconnect/myDG' \
  -H 'Content-Type: application/json' -H 'Authorization: Basic <…>' \
  -d '[{"uid":"00001","link":"…","title":"…","content":"…"},
       {"uid":"00002","link":"…","title":"…","content":"…"}]'

# delete: same URL as the PUT
curl -X DELETE 'https://<server>:8181/rest/api/v1/smartsearchconnect/myDG/de/00001' \
  -H 'Authorization: Basic <…>'
```

- Flat JSON: field → string or array of strings. Use suffixes for types.
- The documentation's curl examples carry no `Authorization` header. Send credentials: PUT,
  POST and DELETE of documents need *Execute* on *Data Generator* `[core]`.
- The `v1` in the path is the API version segment (`/rest/api/{apiVersion}/smartsearchconnect/…`).
  Your own documents (`link`, `title`, `content` required) are accepted on **`v1` only**;
  `v2` exists for SmartSearch Connect's FirstSpirit JSON `[core]`.
- More endpoints than the chapter shows (SmartSearch 5.12.2) `[core]`:
  - `GET /rest/api/smartsearchconnect` — the server's API versions and the toJson versions each
    supports (Connect negotiates with it).
  - `GET …/smartsearchconnect/{dg}` — does the DG exist (*Read*).
  - `PUT …/smartsearchconnect/{dg}` — create the DG and its
    PS without a document (*Write*).
  - Query parameter `datageneratorLanguage` (default `de`) on the creating PUT.
  - `DELETE /rest/api/v1/datagenerator/API/{dg}/deleteAll` — remove all documents of the DG;
    `…/deleteAllBefore` with JSON body `{"timestamp": "<ISO-8601 UTC>"}` — remove documents
    last written before that instant (400 for a missing or future timestamp). Both *Execute*.
    Connect uses `deleteAllBefore` to prune after a full run.
- Commit: documents are committed to Solr **30 s** after arrival; the environment variable
  `API_CRAWLER_COMMIT_WITHIN` (ms) on the SmartSearch system shortens it, for tests only
  (SmartSearch Connect documentation, *DataGenerator*) `[odfs]`.
- Mandatory-field remarks such as `fsTitle` in the Swagger UI belong to the Connect use and can
  be ignored for your own documents.
- Since 5.4 the `httpStatus` in an `ApiLoggingResponse` is an integer, not an enum
  (release notes).
- Add enhancers to the auto-created DG in the cockpit like for any DG.

## Start and stop a Data Generator

```bash
curl 'https://<server>:8181/rest/api/v1/datagenerator/WEB/mithras/start' -H 'Authorization: Basic <…>'
curl 'https://<server>:8181/rest/api/v1/datagenerator/WEB/mithras/stop'  -H 'Authorization: Basic <…>'
```

`GET`, path `/{TYPE}/{name}/start|stop`; `200` started, `409` already running. Typical use: a
FirstSpirit job starts the Web DG after a full generation. A delete endpoint for DGs exists
since 5.5.0: `DELETE /rest/api/v1/datagenerator/{TYPE}/{name}` (*Delete*) `[core]`.

`{TYPE}` is one of `WEB`, `XML`, `EXTERNAL`, `API` `[core]`; spell it
upper-case as above.

## Hot injection and hot deletion

Server only, permission *Execute* on *Data Generator*. For Web and XML DGs.

| | Injection | Deletion |
|---|---|---|
| Call | `PUT /rest/api/v1/datagenerator/{type}/{name}/inject` | `DELETE /rest/api/v1/datagenerator/{type}/{name}/delete` |
| Body | Web/XML: URL list as `text/plain` (one per line, default) or `application/json` array; XML: also a data XML document as `text/xml` | JSON `{"id": "<solr id>"}` or `{"url": "<link>"}`: exactly one of the two, both or neither is `400` `[core]` |
| Visible | Within 15 minutes | Immediately; triggers re-indexing, so use sparingly |
| Result | `200` success (the docs say "200 - No Content"), `404` unknown DG, other 4xx/5xx failed (see log) | Same |

Injected URLs are processed one by one: links on them are **not followed** (canonical links
neither), the *Check URL Script* is not evaluated, the log reports new / changed / ignored
pages. For permanent removal, change the DG so it never captures the page.

## Enhancers (Groovy)

Run per document, in configured order, after the built-in enhancers:

```groovy
void manipulate(final Document document, final String html, final org.jsoup.nodes.Document jsoupDocument) {
    // only the body is entered in the cockpit
}
```

`html` and `jsoupDocument` are filled for **Web** DGs only.

| Task | Code |
|---|---|
| Add a value (repeat for multi-value) | `document.addData("fieldName", "value")` |
| Replace all values | `document.setSingleValue("field", "new value")` |
| Remove a field | `document.removeData("fieldName")` |
| Read and test | `document.getData("category").contains("article")` |
| Keep out of the index | `document.setBoost(0)` |
| Page title from HTML | `document.addData("page_title", jsoupDocument.title())` |

Facet example: set a `_keyword` from other fields (remove first, then add):

```groovy
if (document.getData("fsType_keyword").contains("Dataset")
        && document.getData("entityType").contains("News")) {
    document.removeData("content_category_keyword")
    document.addData("content_category_keyword", "news")
}
```

The *Extracting names and nouns* enhancer fills `names_multi_keyword` and
`nouns_multi_keyword`, German only.

## Configuration Management API (5.9+)

`/rest/api/v1/configuration/…`: create, update and delete Data Generators, Prepared Searches,
Adaptable Results (elevate/exclude per PS and term), stopword lists and synonym lists. The
documentation points to the Swagger UI (`/swagger-ui/index.html`), which lists them; the
paths (SmartSearch 5.12.2) are `[core]`:

| Object | Paths (GET / PUT / DELETE) | Permission prefix |
|---|---|---|
| Data Generators | `…/configuration/datagenerators`, `…/datagenerators/{TYPE}/{name}` | Data Generator Read / Write / Delete |
| Prepared Searches | `…/configuration/preparedsearches/{name}` | Prepared Search Read / Write / Delete |
| Adaptable Results | `…/configuration/adaptableresults/{ps}`, `…/adaptableresults/{ps}/{term}` | Adaptable Results Read / Write / Delete |
| Stopwords | `…/configuration/stopwords/{list}`, `…/stopwords/{list}/{word}` | Stopwords Read / Write / Delete |
| Synonyms | `…/configuration/synonyms/{list}`, `…/synonyms/{list}/{term}` | Synonyms Read / Write / Delete |

Check the request bodies in the Swagger UI of the target version before scripting.

**Adaptable Results reference document ids.** The documentation says copying them from
staging to production is not supported.

## Import / Export (5.8+, ADMIN only)

- *System → Import/Export*: export writes `export-DD-MM-YYYY-HH-mm-ss-UTC.json` with
  `datagenerators`, `preparedSearches`, `adaptableResults` (arrays), `synonymLists`,
  `stopwordLists` (maps). **Users are not exported.**
- Import **completely overwrites**: entries missing from the file are deleted. Order: DGs, PSs,
  Adaptable Results, synonyms, stopwords. Errors are reported and the import continues.
- After an import: re-run the DGs; reload the Solr collection after synonym changes. Export
  first as a backup.
- The export includes Adaptable Results while the Configuration API chapter says they do not
  transfer between systems. The import copies the elevation ids verbatim, without remapping
  `[core]`; whether they hit depends on the document ids (previous section).

## Permissions (server, SmartSearch 5.12.2) `[core]`

| Call | Permission |
|---|---|
| Prepared Search execute, autocomplete | Prepared Search: Execute |
| Generic API: document PUT / POST / DELETE, `deleteAll`, `deleteAllBefore` | Data Generator: Execute |
| Generic API: DG exists (`GET …/{dg}`) | Data Generator: Read |
| Generic API: create DG and PS (`PUT …/{dg}`) | Data Generator: Write |
| DG start / stop / inject / hot delete; external DG calls | Data Generator: Execute |
| DG delete | Data Generator: Delete |
| Configuration Management API | Read / Write / Delete of the object type (table above) |

## Type mismatches (5.12)

When a field's value does not fit the type its suffix demands, the server suppresses that
field for the DG. The cockpit lists suppressed
fields (*type-mismatched fields*, release notes 5.12.0).
