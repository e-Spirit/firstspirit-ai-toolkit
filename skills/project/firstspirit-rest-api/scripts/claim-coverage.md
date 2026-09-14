# Claim coverage — which skill statements the smoke test actually verifies

`scripts/smoke-test.sh` exists so that a skill claim and the live server can be compared
mechanically. This table is the honest inventory: one row per probe with the claim it checks
and where that claim is stated, followed by the skill sections that have **no probe** — those
are verified only by the 2026-09-11 field test and the 2026-09-14 multi-project run, i.e. by
hand, once. Update both halves when a probe is added or a section is rewritten.

Legend: R = read-only (default run) · W = `--write` (W1–W9 page, W10–W12 page reference, W13–W17 medium, W18–W21 dataset, W22–W25 section template) · S = `--scripts` · E/O = environment/spec.

## Probes → claims

| Probe | Claim verified | Stated in |
| --- | --- | --- |
| E1 | a `.env` value starting with `$` must be single-quoted, else 401 with a misleading message | SKILL.md → Setup |
| R1 | Basic auth against `GET /projects/` works; 401 = credentials or E1 | SKILL.md → Setup |
| R2a/b | base URL ends in `/rest/v1`; `/rest/v3` is only the OpenAPI group, spec at `/rest/v3/api-docs` | SKILL.md → Setup |
| O1 | the server's OpenAPI surface is unchanged since the last run (snapshot diff per host; WARN with `<run>.diff.md` on change) | whole skill (staleness guard) |
| R3 | languages listing; abbreviations are UPPERCASE | SKILL.md → Language Handling; content-catalog.md → Language Handling |
| R4 | `GET /templates/section-templates/` is a bare array (`.[]`, not `.content[]`) | SKILL.md → Pagination; content-templates.md → Determine Template-Set UID |
| R5 | listing endpoints (`/pages/`) are bare arrays and ignore `?page/size` (0.0.23-beta) | SKILL.md → Pagination |
| R5b | `/search` is the one paginated endpoint (`{content,pageNumber,pageSize,hasNext}`) | SKILL.md → Pagination; search-and-discovery.md → Full-Text Search |
| R6 | page → `bodies` → `sections` → `form` returns `{editors:[…]}` | content-management.md → Pages, Sections; SKILL.md → Browse Structure |
| R7 | a single editor `GET …/form/{editor}/{LANG}` is a flat FormEditorDTO carrying the PATCH prerequisites | SKILL.md → The One Rule; content-catalog.md → The One Rule |
| R8 | language suffix must be UPPERCASE; lowercase → 404 | SKILL.md → Language Handling |
| R9 | `GET /search/by-uid?uid=` resolves a page | search-and-discovery.md → Search by UID |
| R10 | MediaStore enumeration answers 200 (was 405 before 0.0.23-beta) | content-management.md → Media |
| R11 | datasets live directly under `/data-sources/{uid}/` — no `/datasets/` segment | content-management.md → Data Sources |
| W1 | `POST /pages/ {uid, templateUid}` creates a page and returns a numeric `id` | content-management.md → Create Page |
| W2 | `PATCH …/rename` takes `{name, language}` and changes the display name; `{uid}` is rejected; the uid cannot change | content-management.md → Pages (rename) |
| W3 | `PUT …/bodies/{body}/sections/{name} {templateUid}` adds a section | content-management.md → Add Section to Body |
| W4 | GET → jq → PATCH round trip on a text editor keeps apostrophes, quotes, umlauts, newline (file-based payload) | SKILL.md → The One Rule, Rule 2 |
| W5 | minimal `{name,type,content}` PATCH: rejected or accepted on a scalar editor — recorded, never a fail (full DTO stays the rule) | SKILL.md → Rule 1, Why Manual Construction Fails |
| W6 | wrong Content-Type on PATCH is rejected — 415 or 500 (the `/form/{editor}` code) | SKILL.md → Critical Content-Type Rules, Error Codes |
| W7 | `POST …/actions {release, checkOnly:true}` dry-run works | content-management.md → Release Workflow; SKILL.md → Actions Pattern |
| W9 | `DELETE /pages/{uid}` then GET → 404 | content-management.md → Delete Page |
| W10 | `POST /page-references/ {uid, pageId, location}` creates a page reference pointing at the page (server answers 200) | content-management.md → Create PageReference |
| W11 | `GET /page-references/{uid}/settings` is readable (DTO: `filename`, `showInSitemap`) | content-management.md → Set as Start Node |
| W12 | `DELETE /page-references/{uid}` then GET → 404 | content-management.md → Page References |
| W13 | `POST /media/ {uid, filename, type}` mints an empty element (201) | content-management.md → Create Medium |
| W14 | `PUT …/media/{uid}/data` multipart part `file`; `GET …/data` returns the same bytes | content-management.md → Upload / Download File Data |
| W15 | `GET …/data/resolution/{res}` downloads a rendition (ORIGINAL = uploaded bytes) | content-management.md → Get with Resolution |
| W15b | `GET …/media/{uid}/resolutions` lists renditions with width/height/size | content-management.md → Media (resolutions) |
| W16 | medium type is immutable: `PATCH …/media/{uid}` → 405 | content-management.md → Media (drift note) |
| W17 | `DELETE …/media/{uid}` allowed (0.0.23-beta), then GET → 404 | content-management.md → Media (drift note) |
| W18 | `POST /data-sources/{ds}/` with no body creates a dataset; response carries `gid` (201) | content-management.md → List / Create Datasets |
| W19 | dataset fields follow GET → jq → PATCH on `…/{gid}/form/{editor}[/{LANG}]` | content-management.md → Write Dataset Fields |
| W20 | `…/{gid}/entity` is read-only: PATCH → 405 | content-management.md → Read Entity |
| W21 | `DELETE /data-sources/{ds}/{gid}` → 204, then GET → 404 | content-management.md → Data Sources |
| W22 | `POST /templates/section-templates/ {uid, name, description}` creates a template readable by uid (200) | content-templates.md → Section Template |
| W23 | `PUT …/gom` as `application/xml` answers an EMPTY 200; `gom/form` parses the editors | content-templates.md → Write GOM, Read Parsed Form Summary |
| W24 | `GET …/gom` returns the stored XML | content-templates.md → Read GOM |
| W25 | `DELETE /templates/section-templates/{uid}` → 204, then GET → 404 | content-templates.md → Create Templates |
| S0 | `GET /template-sets/` lists template sets (a 500 here was project-specific: broken conversion table) | content-templates.md → Determine Template-Set UID |
| S1 | `POST /scripts/` ignores `type`/`description` (stored MENU, description null) | SKILL.md → Scripts |
| S2 | there is no `PATCH /scripts/{name}` (404/405) | SKILL.md → Scripts |
| S3 | `PUT …/scripts/{name}/template-sets/{set}` (text/plain) + `POST …/execute` → 2xx with an EMPTY body; verify by read-back | SKILL.md → Scripts |
| S4 | `/execute` surfaces BeanShell parse errors in the response | SKILL.md → Scripts |
| S5 | the `/execute` context has no `getElement()` | SKILL.md → Scripts |
| S6 | `DELETE /scripts/{name}` | SKILL.md → Scripts |

## Sections with no probe

Ordered by how much the skill teaches versus how little is verified. Tier 2 (media, dataset, section template, page reference — W10–W25) landed 2026-09-14, verified on the designated throwaway project; still open below. Each row is a candidate
probe; the "throwaway" column says what a probe would have to create and delete.

| Skill section | What is claimed | Throwaway needed | Priority |
| --- | --- | --- | --- |
| content-templates.md → Create Templates (page, format, link), Rules XML; content-management.md → Create Data Source, Document Groups, Folders | remaining create endpoints | one of each | medium — same pattern as W22/W25, needs schema/table-template uids for the data source |
| content-catalog.md → Read / Write FS_CATALOG | catalog editor DTO with `_item` children; full-DTO PATCH mandatory | a page with a catalog section | medium — Rule 1 is only checked on a scalar editor (W5) |
| SKILL.md → Playbook: Duplicate a Page; content-management.md → Copy a Page | `POST …/actions {copy …}` | one copied page | medium |
| content-templates.md → Channel-Sources | `GET …/channel-sources/html` | none (read-only) | low — cheap, add with the next read-only batch |
| search-and-discovery.md → Search by ID, Find References, Invalid / External References | `/search/by-id`, `/search/invalid-references`, `/search/external-references` | none (read-only) | low — cheap |
| SKILL.md → Error Codes | which status each failure produces (404 / 415 / 500) | none | low — partially covered by R8, W2, W6 |
| SKILL.md → Language Handling for non-text editors (DOM, FS_REFERENCE) | GET → jq → PATCH works on structured editors too | a page with such editors | medium — every write probe hits a text field |
| content-management.md → Release Workflow (real release, not `checkOnly`) | release changes state | released throwaway page | not planned — state change on shared projects |

## How to add a probe

1. Pick a row above; write the probe next to its family in `smoke-test.sh` (`R` read-only,
   `W` inside the throwaway-page block, `S` inside the script block). Every probe names the
   claim in its `pass`/`fail` text and cites the skill section in a comment.
2. A behaviour the skill *documents as a quirk* (S1, S3) is asserted as documented — the
   probe fails when the server starts behaving "better", because that is when the skill text
   must change.
3. Move the row from "no probe" to "Probes → claims".
4. Run against at least two projects (a second `.env` via `--env`) before committing.
