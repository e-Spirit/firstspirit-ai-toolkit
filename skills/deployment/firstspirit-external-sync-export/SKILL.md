---
name: firstspirit-external-sync-export
description: >-
  Produce a FirstSpirit external-sync export on disk by running the FirstSpirit
  Command Line Interface (FS-CLI / fsdevtools) directly against a server. This
  is the executable "how do I actually get the export" skill. Use it to keep a
  project copy in git or a similar VCS, to work on a project's source outside
  the server, to move or reimport a project onto another server, or to build a
  git-based developer pipeline on a self-hosted or local server (FirstSpirit
  Cloud already provides such a pipeline; this skill reproduces a similar setup
  elsewhere). Use it whenever you need to
  export a FirstSpirit project (its stores and project properties) to a local
  external-sync directory, set up fs-cli from scratch, connect fs-cli to a
  server (including a FirstSpirit Cloud instance behind Keycloak SSO),
  authenticate without exposing a password, or troubleshoot an fs-cli run.
  Covers: installing fsdevtools from the official e-Spirit/FSDevTools release;
  supplying the FirstSpirit Access API jar it needs (fs-isolated-runtime /
  fs-isolated-client) version-matched to the server; running it on a
  compatible JRE with the required --add-opens flags (the shipped launcher's
  javap-based check silently drops them on a JRE); choosing the connection mode
  (HTTP vs HTTPS vs SOCKET — Cloud needs HTTPS on 443); the export command and
  its identifiers (templatestore / pagestore / sitestore / mediastore /
  globalstore / contentstore, projectproperty, path:, entities:, schema:) and
  options (--useReleaseState, --keepObsoleteFiles); the import command and its
  options (--layerMapping/-lm for schema→layer mapping, --import-comment,
  --dont-create-project, --permissionMode) for writing a sync directory back into
  a project or seeding a second server; and the concrete
  failure→fix table (UnsupportedClassVersionError 65.0, InaccessibleObjectException,
  HTTP 400 from the load balancer, "couldn't authenticate"). The tool goes by
  several names: repository **FSDevTools**, feature **FirstSpirit External
  Synchronization** (external sync), technical CLI name **fs-cli** (project
  `fsdevtools`). Triggers on "external sync", "external synchronization",
  "FSDevTools", "fs-cli", "fsdevtools", "export a FirstSpirit project to disk",
  "run fs-cli export", "fs-cli import", "import a project into FirstSpirit",
  "layer mapping", "connect fs-cli to Cloud", "export a project to git", "move a
  project to another server", even when the word "skill" is not used. For the
  Git-based development pipeline (Bamboo, fs-project.yaml, Template Transport) and
  Cloud constraints use the FirstSpirit Cloud documentation; this skill is the direct/local fs-cli run.
metadata:
  source-commit: 2d55f3c
  published: 2026-09-15
  toolkit-version: 0.2.0
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# FirstSpirit external sync — export & import

External synchronisation writes a FirstSpirit project's store elements to a
plain-file directory tree (`SiteStore/`, `TemplateStore/`, `PageStore/`, …), a
source-agnostic form suited to version control and project transport — and
**imports** that tree back into a project, on the same server or another one.
This skill covers both directions with the **FirstSpirit Command Line Interface
(FS-CLI, project name `fsdevtools`, repository FSDevTools)** run **directly
against a server** — install, connect, authenticate, export, import, troubleshoot.

## When to use which route

There are two ways a project gets exported. Pick before you start.

- **Direct fs-cli run (this skill).** You run `fs-cli export` from your machine
  against a server and get the tree locally. Right for a one-off — a diagnostic,
  an audit, a content review, a documentation pass, a local inspection.
- **Git-based development pipeline.** A CI plan (Bamboo) runs the export
  server-side from an `fs-project.yaml` and commits the result to Git — the
  `externalSync.exportElements` / `designForQa|Prod|Subprojects` model. This is
  the *maintained* export of a Cloud project, not an ad-hoc pull. It is owned by
  **the FirstSpirit Cloud documentation** (Distributed development, Template Transport). If the
  project already has such a repo, use it instead of a manual run; this skill
  does not restate that workflow.

## The four things that make a run work

An fs-cli run fails at one of four gates, in this order. The references follow
the same order; work top-down.

1. **fs-cli can start** — the tool is installed, has the FirstSpirit Access API
   jar in its `lib/`, and runs on a compatible JRE with the right VM flags.
   → `references/fs-cli-setup.md`
2. **It reaches the server** — correct connection mode for the host (Cloud is
   HTTPS on 443, not the default HTTP), port, servlet zone.
   → `references/connection-and-auth.md`
3. **It authenticates** — a valid FirstSpirit login for that instance, supplied
   without exposing the password. → `references/connection-and-auth.md`
4. **It exports the right things** — the project **name** (not id), the export
   identifiers, the sync directory, and the release/obsolete options.
   → `references/export-command.md`

**Importing** uses the same gates 1–3 (start, reach, authenticate). Its
command-side concerns — layer mapping (`-lm`), project creation, and
complete-tree safety — are in `references/import-command.md`.

When a run breaks, match the exact error in `references/troubleshooting.md` —
every failure mode below has a verified message and fix.

## Fast path

If fs-cli is already set up, a whole-project export is one command. The
`scripts/fs-cli-export.sh` wrapper encodes the JRE + `--add-opens` + `HTTPS`
defaults so you don't rediscover them:

```bash
FS_HOST=<host> FS_PROJECT="<Project Name>" FS_SYNC_DIR=<dir> \
FS_USER=<login> FS_PWD=<password> \
  scripts/fs-cli-export.sh \
  export projectproperty:ALL templatestore pagestore sitestore mediastore globalstore contentstore
```

Each run keeps fs-cli's (password-redacted) output in
`results/firstspirit-external-sync-export/<run>/fs-cli.log` and appends one summary line to
`logs/firstspirit-external-sync-export.log` — under `FS_OUT_ROOT`, else the skills monorepo
root, else the working directory; add `results/` and `logs/` to your project's `.gitignore` when
you run it inside a repo. The export itself goes to `FS_SYNC_DIR`.

Read `references/export-command.md` before trusting the identifier list — a
"whole project" is a choice, and entities (database content) and schemas need
explicit identifiers.

## Non-negotiables

- **Never put a password on a shared command line or in output.** Read it from
  an env file the operator controls; redact it from any log you show. See the
  credential handling in `references/connection-and-auth.md`.
- **The Access API jar must match the server build.** A jar from a different
  FirstSpirit version either won't load or will misbehave. Match the server's
  reported version (e.g. `5.2.260815`). See `references/fs-cli-setup.md`.
- **Export is destructive to the sync directory by default.** fs-cli mirrors the
  project into `-sd`, deleting files for elements no longer exported
  (`deleteObsoleteFiles=true`). Export into the intended directory, not over
  unrelated files. See `references/export-command.md`.
- **Import is destructive to the project by default.** fs-cli mirrors the sync
  directory into the project, **deleting** elements not present in the tree.
  Import the complete tree, into a project whose settings (languages, resolutions,
  structure) match the source. See `references/import-command.md`.

## Release gate — before any customer project

The portfolio's **hard legal/anonymisation gate (G1)** applies to this skill by
its nature: an external-sync export can contain **user data** (the `USERS`
project property, editor names, dataset content). Producing an export of an
**internal reference / demo / website project** is fine. Producing one of a
**customer or partner project** is blocked until the legal-approval and
data-anonymisation approach clears (the portfolio governance docs). Do not export a
customer project "just to try it out" ahead of that sign-off.

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). Reports are routed per `FEEDBACK.md`; on a public copy, open an issue on
this skill's repository.
