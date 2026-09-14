# The export command — identifiers, options, output

Gate 4: **export the right things.** `fs-cli … export <identifiers…>` selects
what to write; the global options select where and in which state.

## Identifiers — what to export

Give one or more identifiers after `export`. The kinds:

| Kind | Form | Example |
|---|---|---|
| Store root node | `<store>` or `root:<store>` | `templatestore` |
| Element by uid | `<prefix>:<uid>` | `pageref:homepage` |
| Element by path | `path:/<STORE>/<UID\|NAME>` | `path:/MediaStore/technical` |
| Project property | `projectproperty:<NAME>` | `projectproperty:ALL` |
| Database schema | `schema:<name>[<opt>,<opt2>]` | `schema:products` |
| Entities (DB content) | `entities:<CONTENT2_UID>` | `entities:news` |

**Store root identifiers:** `templatestore`, `pagestore`, `contentstore`,
`sitestore`, `mediastore`, `globalstore`.

**Project properties:** `ALL`, `COMMON`, `CUSTOM_PROPERTIES`, `RESOLUTIONS`,
`GROUPS`, `SCHEDULE_ENTRIES`, `TEMPLATE_SETS`, `FONTS`, `MODULE_CONFIGURATIONS`,
`LANGUAGES`, `USERS`.

**Uid prefixes** (for `<prefix>:<uid>`): `content2`, `gcapage`, `mediafolder`,
`media`, `page`, `pagefolder`, `pagereffolder`, `documentgroup`, `pageref`,
`pagetemplate`, `schema`, `script`, `sectiontemplate`, `workflow`,
`formattemplate`, `linktemplate`, `query`, `tabletemplate`, `styletemplate`,
`tableformattemplate`.

### "Whole project" is a choice, not a keyword

There is no single "everything" token. A broad whole-project export is:

```
export projectproperty:ALL templatestore pagestore sitestore mediastore globalstore contentstore
```

Two things this does **not** include automatically:

- **Entities (database row content).** `contentstore` exports the Content-Store
  *structure*; actual dataset rows are exported with `entities:<content2-uid>`
  (optionally per schema with `schema:<name>`). Add them explicitly when you
  need content, not just the model. Large entity sets make the export much
  bigger and slower.
- **Anything you didn't name.** Identifiers are additive; omitted stores are
  omitted.

For a **diagnostic** (templates) you can export far less —
`projectproperty:ALL templatestore` is the design/scaffolding subset the
Git-pipeline projects use. For **content hygiene** or **documentation** you want
the content stores too. Scope to the consuming skill's need.

### Exporting content *with* entities (content hygiene / documentation)

`contentstore` writes only the **data-source structure** (the `CONTENT2` nodes) —
**not the dataset rows**. A content review of a dataset-driven project (much
documentation, product catalogues, news, glossaries) therefore sees *no* dataset
content unless you add `entities:` explicitly. Symptom in a consuming skill: the
Content Store is present but every dataset reads as absent/empty.

Export the schema plus every data source's entities:

```
export projectproperty:ALL templatestore pagestore sitestore mediastore \
       globalstore contentstore \
       schema:<schemaName> \
       entities:<content2-uid> entities:<content2-uid> …
```

- `schema:<name>` — the data model (tables/columns). Schema name = the folder
  under `TemplateStore/Schemes/` (the non-`FS_*` entry).
- `entities:<content2-uid>` — the rows behind one data source. One identifier per
  data source; they are additive.

**Enumerate the data-source uids** when you don't know them. From an existing
export, read them straight out of the Content Store:

```bash
grep -rhoE '<CONTENT2 [^>]*name="[^"]*"' <syncDir>/ContentStore \
  | grep -oE 'name="[^"]*"' | sort -u
```

(or from a running server via REST `GET /projects/{id}/data-sources/`, or in
SiteArchitect under the Content Store). Then pass each as `entities:<name>`.

**Cost.** Entities can dwarf the rest of the export — thousands of rows, much
larger and slower. Export them when the consuming skill needs *content*
(hygiene, documentation), not for a template-only diagnostic. `--useReleaseState`
applies to entities too: choose work vs. released deliberately.

### Adding entities without re-exporting everything (non-destructive)

To add datasets to a project you already exported, you do **not** re-pull the
whole project. Two non-destructive routes:

- **Separate folder (simplest, least intensive).** Export `schema:<name>` +
  the `entities:` you want into a *different* sync directory. The original
  export is untouched by definition; the consuming skill reads both trees. The
  schema is small and makes the entities folder self-contained. Entity data
  lands under `Entities/<schema>/<table>/…`.
- **Into the existing export dir** — you must pass **`--keepObsoleteFiles`**, or
  the default mirroring deletes everything not named in *this* command (i.e. all
  the stores you exported before). With `--keepObsoleteFiles` the entity files
  are added alongside the existing tree.

**Every entity needs a GID — by design.** An external-sync export is meant to be
**re-imported**, and import maps each entity back by its **GID** (a stable,
cross-project id); the older per-project `fs_id` is not stable enough to map
onto. So a dataset row without a GID cannot be round-tripped, and external sync
correctly refuses it: if any row in the requested entities lacks a GID, the
entire `entities:` export fails with `Entity <table> [<id>] has no gid` and
**nothing** is written. When that happens, export each data source
**individually** (with `--keepObsoleteFiles`) to harvest the healthy ones and
pinpoint the blocked ones; to include a blocked row in a re-importable export it
must be given a GID first (a project change). See `troubleshooting.md`. Report
which sources/rows were affected; don't present a partial entity export as
complete.

**Enumerating what to export vs. what came out.** The `entities:<uid>`
identifier is keyed by the **data source** (Content2) uid — the folder names
under `ContentStore/`. The exported rows are written under `Entities/<schema>/`
keyed by **table** name, so a table shared by several data sources appears once.

## Options — which state, and obsolete-file handling

| Option | Effect |
|---|---|
| `-sd`, `--syncDir <dir>` | target directory (default: current dir) |
| `-rf`, `--resultFile <file>` | JSON result path (default `lastCommandResult.json`). *[observed]* On fs-cli 4.8.9 an `export` run with `-rf` exited 0 but wrote **no** result file — don't build automation on it; parse the `== SUMMARY ==` block and the exit code instead |
| `--useReleaseState` | export the released state instead of the current (work) state |
| `--keepObsoleteFiles` | keep files for elements no longer exported (default: delete them) |
| `--excludeChildElements` | export the named elements without their children |
| `--excludeParentElements` | export without the parent chain |
| `--permissionMode <NONE\|ALL\|STORE_ELEMENT\|WORKFLOW>` | include permissions (default `NONE`) |

**Destructive-by-default warning.** Without `--keepObsoleteFiles`, fs-cli
**mirrors** the export into `-sd`: files for elements not in this export are
**deleted** (the run reports `deleteObsoleteFiles=true`). Always point `-sd` at
the directory you intend to be the project mirror — never at a directory holding
unrelated files.

**Preview vs release.** By default you get the **current/work** state (what
editors are editing). Use `--useReleaseState` to export what is released/live.
Choose deliberately — a content review of "what visitors see" wants release; a
template audit usually wants current.

## Output layout

The export writes one top-level directory per store, plus `Global/` for project
properties:

```
<syncDir>/
├── TemplateStore/   PageTemplates · SectionTemplates · FormatTemplates ·
│                    LinkTemplates · Scripts · Workflows · Schemes · StoreElement.xml
├── PageStore/       page folders → pages → sections
├── SiteStore/       structure folders → page references
├── MediaStore/      media folders → media (files + metadata)
├── ContentStore/    schemas / data sources (structure)
├── GlobalStore/     GCA folders, GCA pages, ProjectProperties, URL/User properties
└── Global/          project-property payloads
```

Each element is several files (content, metadata, `FS_References.txt`,
`FS_Info.txt`, `FS_Files.txt`, …) that together reconstruct the element. The sync root also
gets a hidden `.FirstSpirit/` directory with two bookkeeping files per project
(`Files_<project>_<id>.txt`, `Import_<project>_<id>.txt` — a manifest of every written file
with checksum, size, timestamp and MIME type). Keep it: it is what makes the next run
incremental. Stores you did not name are simply absent (a `pageref:` export creates only
`SiteStore/` and `Global/`).

**The obsolete-file rule in action.** Exporting into the same directory with a *smaller*
identifier list deletes what the list no longer covers — observed 2026-09-14: a first run with
`projectproperty:LANGUAGES projectproperty:RESOLUTIONS pageref:…`, then a second with only
`projectproperty:LANGUAGES pageref:…`, reported `Deleted elements: 1 | project properties: 1
… Resolutions ( deleted files: 1 )` and `Global/Project/Resolutions.xml` was gone. Use the
same identifier list every run, or `--keepObsoleteFiles`.

## Reading the result

fs-cli prints a `== SUMMARY ==` with created/updated/deleted/moved counts and a
per-store breakdown, and closes with `Execution time`. A whole-project run can
take many minutes and be hundreds of MB — run it non-interactively (background /
long timeout), not in a 2-minute foreground window. Exit code `0` = success.

*Benign warnings:* `WARN Error parsing export files in directory '/…' - content
files not found` during a run into an **empty/partial** target is fs-cli reading
the destination before writing — not an error.

## The pipeline alternative (pointer)

When the project is developed Git-first, the same export is expressed
declaratively in `fs-project.yaml` (`externalSync.exportElements`) and run by a
Bamboo plan, not by hand. That model — and the `features` /
`designForQa|Prod|Subprojects` content-transport layer around it — is owned by
**the FirstSpirit Cloud documentation** (Distributed development / Template Transport). Use it
for a maintained Cloud project; use the direct command here for a one-off pull.

---
*Sources: fs-cli 4.8.9 `help export`; a verified whole-project export
(8,746 elements, ~498 MB) from a FirstSpirit 5.2.260815 Cloud instance
(2026-08-03). See `SOURCES.md`.*
