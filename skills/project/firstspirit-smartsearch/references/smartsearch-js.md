# smartsearch.js — search pages in the browser

Version **1.4.1 (23.08.2022)**, the latest release. Sources: the developer documentation and
release notes `[odfs]`, and the TypeDoc API pages (`docs.e-spirit.com/module/smartsearch.js/`)
`[javadoc]`. Signatures below come from the TypeDoc pages; where the guide disagrees with them,
the TypeDoc wins and the conflict is listed at the end. Lines tagged `[core]` were read in the
library source (repository at 1.4.2, which differs from 1.4.1 only in its build pipeline).
Nothing here was run against a server.

## Before you start

- **Target:** the main SmartSearch documentation says the library "requires the API gateway
  and is therefore only possible when using the cloud service". The library's own guide shows
  a self-hosted variant with a custom endpoint. Every request the library sends is a `GET`
  with only a `Content-Type: application/json` header, same-origin credentials and CORS mode,
  and its documented options offer no way to add headers `[core]`. So the library cannot
  authenticate against the server on its own. A self-hosted setup needs your own same-origin
  proxy that adds the credentials and passes only `execute` and `autocomplete` through
  (design advice, not tested). Never ship server credentials to a browser.
- **Prepared Search:** *Public* for anonymous use. *Authenticated* Prepared Searches cannot be
  used from the library: it cannot send `Authorization`, and `customParams` only become query
  parameters `[core]`. The gateway's CORS settings also allow no `Authorization` header from
  another origin (`search-api.md`).
- **Install:** from the delivered archive (not on npmjs.com):
  - bundle `dist/smartsearch.bundle.js` (or `smartsearch.ie11.bundle.js`) via `<script>`, or
  - the archive is an npm package: `npm install <package-name>.tgz`, then
    `import {SmartSearch} from "smartsearch.js"`.
- **Single-page assumption:** the examples assume a search page that does not reload; a reload
  loses the `Page` state.

## Minimal search page

```js
const fsss = new SmartSearch("https://<gateway-host>", "My_Prepared_Search", {
  autocompleteOptions: { highlight: true, language: "en", prefixThreshold: 3 },
  customParams: [{ language: "en" }]
});

fsss.attachAutocompleteWidget(document.getElementById("search-bar"));

async function run(term) {
  const page = await fsss.search(term);
  const renderer = fsss.getPageRenderer(page);
  const results = document.getElementById("results");
  results.innerHTML = "";
  renderer.renderSearchResultsToHTMLElement(results);
  renderer.renderPaginationToHTMLElement(document.getElementById("pagination"), 5);
}
```

Pagination buttons have **no click handlers**; attach them yourself (below).

## API

### `SmartSearch`

| Member | Signature | Notes |
|---|---|---|
| constructor | `new SmartSearch(host: string, preparedSearch: string, options?: SmartSearchOptions)` | `host` with protocol |
| `search` | `search(queryTerm: string, ...customParams: URLParam[]): Promise<Page>` | Params apply to this request only |
| `searchWithGroup` | `searchWithGroup(queryTerm, groupField: string, groupLimit: number, ...customParams): Promise<Map<string, Page>>` | Needs the PS script below |
| `getPageRenderer` | `getPageRenderer(page: Page): PageRenderer` | |
| `attachAutocompleteWidget` | `attachAutocompleteWidget(inputElement: HTMLInputElement, renderTarget?: HTMLDivElement): void` | Renders into `renderTarget` or the input's parent |
| `fetchAutocompleteList` | `fetchAutocompleteList(prefix: string, options?: AutocompleteOptions): Promise<string[]>` | Your own UI; at most 5 suggestions, by relevance |
| `setCustomParams` | `setCustomParams(...customParams: URLParam[]): void` | For **all** following requests; each call **replaces** the previous set; repeated keys allowed (1.4.0) |
| `deleteCustomParams` | `deleteCustomParams(...keys: string[]): void` | |
| `version` (static) | `version(): string` | |
| accessors | `searchClient: FetchClient`, `autocompleteWidget: AutocompleteWidget` | |

`SmartSearchOptions`: `{ apiEndpoint?: string; autocompleteOptions?: AutocompleteOptions;
customParams?: URLParam[] }`. `apiEndpoint` is appended to `host`, must start with `/`,
default `API_ENDPOINT = "/v1/prepared_search"` (the gateway path).
`AutocompleteOptions`: `{ highlight?: boolean; language?: string; prefixThreshold?: number }`
(default threshold `0`; use 3, see `search-api.md`). `URLParam` is `{ [key: string]: string }`.

### `Page` (one result page)

| Member | Signature / type |
|---|---|
| `searchResults` | `SearchResult[]` |
| `facets` | `Facet[]` |
| `numberOfResults` | `number` (accessor) |
| `didYouMean` | `string[]` (accessor) |
| `paginationParams` | `StaticPaginationParams {pageNumber, pageSize}` or `DynamicPaginationParams {start, rows}` |
| `getFacet(name)` | `Facet \| null`; `name` as in the cockpit |
| `getPage(n)`, `getFirstPage()`, `getLastPage()` | `Promise<Page>`; static pagination only |
| `next()`, `prev()` | `Promise<Page>`; `hasNext()`, `hasPrev()`, `hasPage(n)` |
| `getNumberOfPages()` | `number` |
| `resetFacets(include?: string[])` | `Promise<Page>`: first page without (those) facet filters |

### `Facet`

| Member | Signature |
|---|---|
| `name`, `displayName`, `type`, `counts`, `selectedValues` | accessors; `counts: FacetCount[] {value, count, filterQuery}` |
| `filter` | `filter(...filterValues: FacetValue[]): Promise<Page>`; no arguments = reset this facet; throws if a value is not allowed or multi-select is off |
| `customFilter` | `customFilter(filterValues: FacetValue[], ...customParams: URLParam[]): Promise<Page>` (1.2.0) |
| `reset` | `reset(): Facet` (prefer `filter()` with no arguments) |
| `setDisplayName`, `setSelectedValues` | chainable setters |

`FacetValue` is `string | number | boolean`.

### `PageRenderer`

Each `renderX(…)` returns an element; each `renderXToHTMLElement(element, …)` takes the
target element first, then the same parameters, and appends to it.

| Method | Parameters of `renderX` |
|---|---|
| `renderSearchResults` / `…ToHTMLElement` | none |
| `renderPagination` / `…ToHTMLElement` | `amount: number`: prev + `amount` page buttons + next |
| `renderPageButtons` / `…ToHTMLElement` | `amount: number` (returns `HTMLElement[]`) |
| `renderNextButton` / `renderNextButtonToHTMLElement` | `label = "Next"`; nothing if there is no next page |
| `renderPrevButton` / `renderPrevButtonToHTMLElement` | `label = "Prev"` |
| `renderDidYouMean` / `…ToHTMLElement` | none; **throws** when there are no suggestions |

Templates (accessors on the renderer): `searchResultTemplate.templateFunction(data: Result,
highlights: Highlighting): string`, `paginationTemplate.renderPage / renderNext / renderPrev
(value: string): string` (output is wrapped in `<li>`), `didYouMeanTemplate.renderDidYouMean
(value: string): string`. Each template also has `cssClasses`.

Default result template (`SEARCH_RESULT_FUNCTION`):

```js
(data, highlights) => `<a href="${data.link}"><h1>${data.title}</h1><p>${highlights.content}</p></a>`
```

Values are interpolated **unescaped**. Escape your own fields; `highlights` contains
`<strong>` markup by design.

### Default CSS classes (`defaults` module)

| Constant | Class |
|---|---|
| `CSS_SEARCH_RESULT_WRAPPER` / `_ELEMENT` | `smart-search-search-results` / `smart-search-search-result` |
| `CSS_PAGINATION` | `smart-search-pagination` |
| `CSS_PAGE_BUTTON`, `CSS_CURRENT_PAGE` | `smart-search-pagination-page`, `smart-search-pagination-current` |
| `CSS_PREV_BUTTON`, `CSS_NEXT_BUTTON` | `smart-search-pagination-prev`, `smart-search-pagination-next` |
| `CSS_DID_YOU_MEAN_WRAPPER` / `_ELEMENT` | `smart-search-did-you-mean-wrapper` / `-element` |
| `CSS_AUTOCOMPLETE_WIDGET`, `_ITEM`, `_ACTIVE` | `smart-search-autocomplete-widget`, `-item`, `-active` |

The autocomplete list gets the id `<input id>autocomplete-widget`. Page buttons carry the page
number in the attribute `smart-search-page-value` (0-based).

## Patterns

**Pagination clicks**

```js
const buttons = document.getElementsByClassName("smart-search-pagination")[0].children;
for (const button of buttons) {
  button.addEventListener("click", async (event) => {
    const n = Number(event.currentTarget.getAttribute("smart-search-page-value") || "0");
    const next = await page.getPage(n);      // `page` = the Page you rendered
    render(next);
  });
}
```

**Facets**

```js
const page = await fsss.search("shoes");
const facet = page.getFacet("color");        // cockpit name
if (facet) {
  facet.counts.forEach(c => renderCheckbox(c.value, c.count));
  const filtered = await facet.filter("red", "blue");   // multi-select facet
  const reset = await facet.filter();                   // this facet only
}
const all = await page.resetFacets();                    // every facet
```

**Custom parameters** (sorting, filters, statistics tags; read by the PS Groovy script):

```js
fsss.setCustomParams({ sortDate: "desc" }, { fq: "sort_date:[NOW-7DAY TO NOW]" });
await fsss.search("energy", { tag: "portal" });  // this request only
fsss.deleteCustomParams("fq");
```

**Grouping**: `searchWithGroup` sends `grouping=on`, `groupField`, `groupLimit`; the PS script
must translate them:

```groovy
def grouping = parameter.get("grouping")?.get(0)
if (grouping?.equals("on")) {
    solrQuery.set("group", true)
    solrQuery.set("group.field", parameter.get("groupField")?.get(0))
    solrQuery.set("group.limit", parameter.get("groupLimit")?.get(0))
}
```

## Corrections to the guide examples

| In the guide | Correct per TypeDoc / code |
|---|---|
| `{ endpoint: "/rest/api/v1/prepared_search" }` | The option is `apiEndpoint` |
| `renderNextButtonToHTMLELement(target)` | `renderNextButtonToHTMLElement(element, label?)` |
| `filteredPage.getNext()` (1.3.0 notes) | `next()` |
| Facet example: `fsss.search(...)` without `await`, then `facet.filter(...)` on an undefined `facet` | `await fsss.search(...)`; call `filter` on the `Facet` you got |
| Pagination example uses `searchResultPage.getPage(...)` (undefined) | The `Page` you rendered |
| `if(!key in data)` | `if (!(key in data))` |
| `alt="${data.alt}>` | Missing closing quote |
| `setCustomParams({fq: "\"_storage_date:[NOW-7 to NOW]\""})` (main docs) | No extra quotes, a unit, upper-case `TO`: `{fq: "_storage_date:[NOW-7DAY TO NOW]"}` |
| `{ "facet_filter_language": "en" }` as the language filter | The library builds facet filters as `facet.filter.<facet name>` and autocomplete sends `language` (`autocompleteOptions.language`) `[core]`; for a custom language filter use `{ "facet.filter.language": "\"en\"" }` or `language` as in the REST API |
