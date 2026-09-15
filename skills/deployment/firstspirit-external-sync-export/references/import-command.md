# The import command — mapping, project creation, safety

`fs-cli … import` writes a sync directory **back into a FirstSpirit project on a
server**. It is the reverse of `export`: where export mirrors the project to disk,
import mirrors the disk tree into the project — creating, updating, moving, and
**deleting** elements so the project matches the sync directory. Use it to seed a
second server from a git checkout, to reimport after editing source, or as the
"apply" step of a git-based developer pipeline on a self-hosted/local server.

Command (fs-cli): `import` — *"Imports a FirstSpirit project into a FirstSpirit
Server."*

## Minimal invocation

Connect exactly as for export (same global options), point `-sd` at the sync
directory, and run `import`:

```
fs-cli -h host -port 8000 -c HTTP -p "MyProject" -u user -pwd secret \
       -sd /path/to/syncdir import -lm *:CREATE_NEW
```

- Global options (`-h`, `-port`, `-c HTTP|HTTPS|SOCKET`, `-p`, `-u`, `-pwd`) and
  `-sd`/`--syncDir` behave exactly as in `connect.md` / `export-command.md`.
- `test` first: `fs-cli … test` verifies the connection before you mutate a
  project.

## Layer mapping — the option you will always think about

A schema in the export is tied to a **database layer**. On import into a project
that does **not already have that schema/layer**, you must say where it goes with
`-lm` / `--layerMapping`, or the run fails with:

```
Missing mapping for source layer 'null'! Please specify a layer mapping.
```

`--layerMapping` takes comma-separated `key:value` (or `key=value`) pairs; the
**key is the source schema UID**, the **value is the target layer name** (or the
literal `CREATE_NEW`). Mapping is remembered for later imports into the same
project. Verbatim examples from fs-cli:

| Example | Meaning |
|---|---|
| `import -lm *:CREATE_NEW` | Create a new target layer for **every** unknown source schema. Use if uncertain (activates the default Derby layer). |
| `import -lm my_schema:CREATE_NEW` | Create a new layer for source schema `my_schema` only. |
| `import -lm *:targetLayer` | Redirect every unknown source schema into `targetLayer`. The target layer **must already be attached to the project.** Use with caution. |
| `import -lm schema_a:targetLayer_a,schema_b:targetLayer_b` | Explicit per-schema mapping onto existing target layers. Use with caution. |

If the schema is already present in the target project, layer mapping is not
required.

## Options

| Option | Effect |
|---|---|
| `-lm`, `--layerMapping <map>` | Map source schema UIDs to target layers (see above). |
| `-i`, `--import-comment <text>` | Comment attached to the FirstSpirit revision the import creates. |
| `--dont-create-project` | Do **not** create the project if it is missing. **By default import creates it** — pass this to require a pre-existing project. |
| `--dont-create-entities` | Do not create dataset entities during import. |
| `--import-schedule-entry-active-state` | Import the active/inactive state of schedule entries (off by default). |
| `--permissionMode <NONE\|ALL\|STORE_ELEMENT\|WORKFLOW>` | Which permissions to import. **Default `ALL`** (note: export defaults to `NONE`). |
| `--updateExistingPermissions` | Overwrite permissions on already-existing elements (default `false`; no effect when `permissionMode=NONE`). |
| `-sd`, `--syncDir <dir>` | Source directory to import from (as in export). |

## What import changes on the server

Import makes the project match the sync directory. It **creates** new objects,
**updates** changed ones, **moves** relocated ones, and **removes** objects no
longer present in the tree. Only the add/import actions are kept in the target
project's revision history — the source project's history does not travel with
the export.

**This is destructive by design.** Two rules keep it safe:

1. **Import the complete sync folder, never a partial subset.** A partial import
   looks to fs-cli like "these elements were deleted," and it will remove them.
   If you exported a subset deliberately, import into a project that expects only
   that subset — not over a fuller one.
2. **Keep project settings standardized across servers.** Source and target
   should share the same languages, resolutions, template sets, and structure.
   Mismatched settings cause unwanted deletions or conversion on import.

Entities map back by **GID**, not the per-project `fs_id` — this is why the
export refuses entity rows without a GID (see `export-command.md`). Import relies
on that GID to match rows to the target schema.

## Creating a second project from an export

Because import creates the project when missing, seeding a fresh server is:

```
fs-cli -h host -port 8000 -c HTTPS -p "NewProject" -u user -pwd secret \
       -sd /path/to/syncdir import -lm *:CREATE_NEW -i "initial import"
```

The project `NewProject` is created, the default layer is provisioned for each
schema, and the tree is imported. For a project that must already exist, add
`--dont-create-project`.

## Where import sits in the sync workflow

Import is one step of the FirstSpirit External Synchronization workflow. The full
loop (git-side steps around the two fs-cli commands) is documented upstream:

- Update (pull) — https://docs.e-spirit.com/odfs/edocs/sync/how/1-update/index-2.html
- **Import** — https://docs.e-spirit.com/odfs/edocs/sync/how/2-import/index-2.html
- Modification — https://docs.e-spirit.com/odfs/edocs/sync/how/3-modification/index-2.html
- Export — https://docs.e-spirit.com/odfs/edocs/sync/how/4-export/index-2.html
- Commit / push — https://docs.e-spirit.com/odfs/edocs/sync/how/5-commit-push/index-2.html
- Conflict resolution — https://docs.e-spirit.com/odfs/edocs/sync/how/resolving-confl/index.html

For the maintained, declarative pipeline (`fs-project.yaml`, Bamboo, Template
Transport) that automates this on FirstSpirit Cloud, use the FirstSpirit Cloud documentation;
this skill is the direct/local fs-cli run for self-hosted or local servers.

## Not covered here: `project import`

fs-cli also has a separate `import-project` / project-import command that restores
a **whole-project export file** (a `.tar.gz` server backup), not an external-sync
directory. That is a different feature; this skill covers external-sync `import`.

---
*Sources: fs-cli `import` command (`ImportCommand.java`, FSDevTools, e-Spirit/FSDevTools
on GitHub — options and examples quoted verbatim); FirstSpirit External
Synchronization "Importing" how-to (docs.e-spirit.com). Import behaviour not yet
reproduced against a live server in this skill.*
