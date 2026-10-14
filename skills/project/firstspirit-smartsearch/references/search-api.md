# Search API — querying a Prepared Search

Source: SmartSearch documentation 5.12.1, chapter *Use cases* (3.1–3.5, 3.10–3.15, 3.17),
and the release notes up to 5.13.0 `[odfs]`, unless a line says otherwise. Host names below
are placeholders.

## Endpoints and authentication

| Call | API gateway (cloud) | SmartSearch server |
|---|---|---|
| Search | `GET /v1/prepared_search/{ps}/execute?query=…` | `GET /rest/api/v1/prepared_search/{ps}/execute?query=…` |
| Autocomplete | `GET /v1/prepared_search/{ps}/autocomplete?prefix=…` `[core]` | `GET /rest/api/v1/prepared_search/{ps}/autocomplete?prefix=…` |

- **Since 5.13.0 both calls also accept `POST`** with the same parameters form-encoded in
  the request body, on the gateway and on the server (release notes); use it when many `fq`
  clauses would exceed the URL length. The `GET` variants are unchanged.
- **Server:** always `Authorization: Basic <base64(user:password)>`; in OIDC mode a bearer
  token. Example from the docs:
  ```bash
  curl 'https://<server>:8181/rest/api/v1/prepared_search/demo/execute?query=searchterm' \
    -H 'Authorization: Basic <base64 user:password>'
  ```
- **Gateway:** no auth unless the PS is *Authenticated*. In OIDC mode send
  `Authorization: Bearer <token>` from the identity provider on search **and** autocomplete;
  the user needs *Execute* on *Search*, otherwise `403 Forbidden`.
- A browser on another origin cannot send `Authorization` to the gateway, so *Authenticated*
  Prepared Searches need a same-origin proxy or a server-side call.
- Server permissions per endpoint group `[core]`: execute and autocomplete need
  *Prepared Search: Execute*; the indexing and configuration endpoints are listed in
  `indexing.md` → *Permissions*.
- `query` is cut to **313 characters** (only this parameter, since 4.2.1).
- Since 5.11.2 client errors (invalid syntax, too many clauses, invalid sort field) return
  **400** with the cause in the body instead of 500 (release notes).
- The interactive spec of all server endpoints is the Swagger UI at `/swagger-ui/index.html`
  (cockpit link *API Documentation*). `/rest/backend/…` endpoints are the cockpit's own
  backend, not a public API; do not build on them `[core]`.

## Response shape

The fields smartsearch.js models as `SmartSearchResponse` (TypeDoc `[javadoc]`):

| Field | Content |
|---|---|
| `results[]` | Documents with the PS's *Output* fields; always `id`, usually `link`, `title` (an array) |
| `numRows` | Total hits (0 when grouping is on) |
| `highlighting` | Map document `id` → field → array of snippets with `<strong>` around matches |
| `facets[]` | `{name, counts:[{value, count, filterQuery, urlFilterQuery}]}` |
| `facetConfigs[]` | `{baseName, multiSelect}` per facet |
| `didYouMean[]` | Spelling suggestions (only below the spellcheck threshold) |
| `groups[]` | Grouped results when grouping is on |
| `requestParameters` | Echo of the parameters, values as arrays |
| `rows`, `fragSize`, `responseTime`, `explainData` | Paging size, highlight length, timing, Solr explain data |

New PS: 10 hits, sorted by score. Add `link` to the PS *Output* fields if clients need URLs
(Connect's auto-created PS does not have it; `smartsearch-connect.md`).

## Parameters

| Need | Parameter(s) | Notes |
|---|---|---|
| Search term | `query` | `*` matches everything (with `fq`) |
| Language | `language=de` | Shortcut for the language facet. Chinese needs `zh-cn` or `zh-tw`; plain `zh` returns 0 hits |
| Facet filter | `facet.filter.<baseName>=<value>` | Use the `urlFilterQuery` string from the response verbatim; repeat for multi-select facets |
| Classic paging | `haupia_pageNumber=<n>` (0-based), `haupia_pageSize=<n>` | Overrides *Hits per page* |
| Scroll paging | `haupia_start=<m>`, `haupia_rows=<n>` | For infinite scroll |
| Filter query | `fq=<solr clause>` | Repeatable. **User-controllable**: never use for access control |
| Statistics tag | `tag=<any>` | Shows up in *Analysis → Statistics* (`tags='portal' or tags='app'`) |
| Own parameters | any name | Read in the PS Groovy script via `parameter.get("name")` |

The facet order in the JSON cannot be configured; sort it on the client.

## Facets

- A facet exists only for a **`_keyword`** field (`color_keyword`); SmartSearch then fills
  `color_facet_string` and the facet appears in the PS field list marked *facet*. Create the
  field in an enhancer, an XML field, or a Connect/generic-API document (`indexing.md`).
- Only **field value facets** are supported; range and pivot facets are not available out of
  the box.
- Numeric facet values need an extra `<name>_facet_double` field.
- Response example (abridged):
  ```json
  "facets": [{"name": "color_facet_string",
    "counts": [{"value": "red", "count": 897,
                "filterQuery": "color_facet_string:red",
                "urlFilterQuery": "facet.filter.color=red"}]}],
  "facetConfigs": [{"baseName": "color", "multiSelect": true}]
  ```
  Next request: `…/execute?query=shoes&facet.filter.color=red`.
- *Exclude own filter* keeps the other values of a selected facet visible, so users can switch
  or multi-select.

## Autocomplete

```text
/rest/api/v1/prepared_search/{ps}/autocomplete?prefix=sun
/rest/api/v1/prepared_search/{ps}/autocomplete?prefix=son&language=de
/rest/api/v1/prepared_search/{ps}/autocomplete?prefix=ene&field=content_expanded
/rest/api/v1/prepared_search/{ps}/autocomplete?prefix=mod&field=model_keyword_lc
/rest/api/v1/prepared_search/{ps}/autocomplete?prefix=ene&fq=mime_type:html
```

- Default source is the `content` field; the response is a JSON array of strings.
- **Two-word suggestions:** `field=content_expanded` (filled automatically). For another
  field, write it into `<name>_expanded_autocomplete_<lang>` in an enhancer and query
  `field=<name>_expanded`.
- **Controlled phrases:** fill a `<name>_keyword_lc` field and query `field=<name>_keyword_lc`;
  the response contains the complete field values.
- Stopwords are never suggested (re-run the DG after changing them). PS restrictions apply.
- Send requests from **3 characters** on; shorter prefixes cost load and give useless lists.

## Sorting

- Fixed sort: PS field *Sort by*, for example `publication_date DESC` (default is score).
  Sortable types: `_integer`, `_long`, `_double`, `_date`, `_sort`, `_sort_de`.
- User-selectable sort: read a parameter in the PS Groovy script.
  ```groovy
  import org.apache.solr.client.solrj.SolrQuery
  def sortDateParam = parameter.get("sortDate")?.get(0)
  if (sortDateParam?.equals("asc")) {
      solrQuery.setSort("sort_date", SolrQuery.ORDER.asc)
  } else if (sortDateParam?.equals("desc")) {
      solrQuery.setSort("sort_date", SolrQuery.ORDER.desc)
  }
  ```
  Call with `&sortDate=desc` (smartsearch.js: `customParams`).

## Filter queries

- **In the PS Groovy script** (not user-changeable, the right place for restrictions):
  ```groovy
  solrQuery.addFilterQuery("creation_date:[NOW-7DAY TO NOW]")
  ```
- **As a parameter:**
  ```bash
  curl -G 'https://<gateway-host>/v1/prepared_search/mithras/execute/' \
    --data-urlencode 'query=*' --data-urlencode 'fq=_storage_date:[NOW-7DAY TO NOW]'
  ```
- `NOW` is always **UTC**. Date range examples: `[2020-01-01T00:00:00Z TO 2020-12-31T23:59:59Z]`,
  `[2020-01-01T00:00:00Z TO *]`; on a `_date_range` field:
  `fq={!field f=dateRange op=Contains}[2013 TO 2018]`.
- `fq` narrows the result set without changing the order.

## Highlighting

- Configured per field (*Highlight*) and by *Length of highlight* (default `content`, 200
  characters). Matches are wrapped in `<strong>`; join `highlighting[id]` to `results[]` by `id`.
- Change the markup or the boundary in the PS Groovy script:
  ```groovy
  solrQuery.setHighlightSimplePre("<em>")
  solrQuery.setHighlightSimplePost("</em>")
  solrQuery.set("hl.bs.type", "WORD")   // default SENTENCE; CHARACTER also possible
  ```
  `WORD` keeps snippets short but may cut sentences.
- Highlight snippets contain markup from the index: escape or sanitise everything else you
  render.

## Grouping

Requires a **`_token`** field (`category_token`). Set the Solr parameters in the PS Groovy
script; only the body is entered, the signature is fixed:

```groovy
void apply(SolrQuery solrQuery, Map<String,List<String>> parameter) {
    solrQuery.set('group', true)
    solrQuery.set('group.field', 'category_token')
    solrQuery.set('group.limit', '-1')     // default 1; -1 = all
}
```

With grouping, `numRows` is 0 and `results` is empty; read
`groups[].groups[]{value, numRows, results}`. smartsearch.js's `searchWithGroup` expects a
script that switches grouping on through `grouping`, `groupField` and `groupLimit`
parameters (`smartsearch-js.md`).

## Did you mean

`didYouMean[]` is filled when the hit count does not exceed the PS's *Spellcheck (hits less
than)* value. Only the `content` field is used; with a language filter the suggestions come from
that language.

## Must Match

PS field *Must Match* links several terms: `0` = OR, `100%` = AND, an absolute number = at
least that many terms (`2` of 4 equals `50%`).

## Spatial search

Field `<name>_pnt` with `lat,lon` (for example `48.137154,11.576124`), set in an enhancer.
PS Groovy script:

```groovy
solrQuery.add("fq", "{!geofilt sfield=city_pnt}")   // circle; {!bbox …} for a rectangle
solrQuery.add("pt", "48.366512,10.894446")
solrQuery.add("d", "100")                           // km
// sort by distance:
solrQuery.set("sort", "geodist() asc")              // needs sfield/pt as parameters
```

The documentation prints the first block with `{slr}Query` (a broken attribute); the variable
is `solrQuery`. Distance sorting is expensive on large indexes.

## Prepared Search Groovy script

- Signature `void apply(SolrQuery solrQuery, Map<String,List<String>> parameter)`; the edit
  mask wraps your body in it (fixed in 4.2.3, release notes).
- `solrQuery` is the SolrJ query about to be sent; `parameter` holds every request parameter
  as a list, so read with `parameter.get("x")?.get(0)`.
- Typical uses: sort switches, fixed `fq` filters, grouping, spatial filters, highlight
  settings. The PS *Preview* tab runs the script.
- The Solr parameter reference the docs link is the Solr 8.6 guide; the product runs Solr 9.7.
  Check parameters against the 9.x guide.
