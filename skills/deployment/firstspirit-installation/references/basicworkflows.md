# BasicWorkflows

Source: BasicWorkflows documentation 1.6.2 (updated 02.09.2026) and release notes, `[odfs]`, read 2026-10-09.

## What it is

A module with three workflows for releasing and deleting elements in SiteArchitect and ContentCreator, taking
release and delete dependencies into account. Source code is public on GitHub; extensions are made by pull request `[odfs]`.

| Workflow package (ContentTransport feature package) | Workflow |
|---|---|
| `basicworkflows-export-basic-release` | Release |
| `basicworkflows-export-basic-delete` | Delete |
| `basicworkflows-export-basic-release-with-ai-review` | Release with AI Review (since 1.6.0, Beta, needs an AI assistant suite subscription) |

## Requirements `[odfs]`

- FirstSpirit in Isolated or Legacy mode, 2022.3 or later; Java 17.
- A licence with `license.WORKFLOW` = 1. Editing `fs-license.conf` invalidates it; contact Technical Support. See `licence.md`.
- Module file `basicworkflows.fsm`.

## Steps, in order `[odfs]` (section numbers of the documentation)

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 2.1 | Install the module, then **restart the server** | ServerManager, Server properties, Modules, Install, choose `basicworkflows.fsm` | A BasicWorkflows entry in the module list |
| 2.2 | Set the Element Status Provider to *BasicWorkflows Status Provider* | Project properties, ContentCreator | Status display in ContentCreator follows the workflows |
| 2.3 | Add the web component *BasicWorkflows_ContentCreator_Libary* (spelling as in the docs); activate or update the web server | Project properties, Web components, ContentCreator | Component listed; web server active |
| 2.4 | Import the three workflow packages (not done by the install) | ContentTransport, or since 1.6.0 the project app (2.7) | Entries under Workflows and Scripts in the Template Store |
| 2.5 | Authorise the workflows per store | Store root, Extras, Change permissions, tab *Workflow permissions*: tick *Authorized* for all three, and *Use release permission* for the release workflows | Workflows offered on an element |
| 2.6 | Optional: set the project's delete workflow | Project properties, Options, *Workflow to delete elements* | Del and the delete icon start the workflow |
| 2.7 | Optional (1.6.0): project app *BasicWorkflows Configuration* | Project properties, Project components, Add | Result dialog: installed / skipped / failed per package |

Notes from the documentation:

- **Project app (1.6.0).** Buttons: *Import Workflows* (imports all three packages, never overwrites existing elements, reports per package)
  and the checkbox *Show AI Review Report* (shows the report in ContentCreator for this project).
  This replaces the manual ContentTransport import of 2.4 for a project that has the app.
- **Delete workflow is exclusive.** One delete workflow per project. Once set, native deletion is gone, administrators included.
  The workflow must be authorised in the stores, or nothing can be deleted. The delete action must be modelled in the workflow
  or it ends successfully and the element stays.
- **Store permissions need the right person.** The *Change permissions* entry may be limited to project administrators.
- **AI review** is configured by a BeanShell action first in the workflow, setting session attributes
  (`prompt_operation_name`, `min_quality_score`, transition overrides); unset ones use defaults (documentation 4.3).

## Updates `[odfs]` (release notes)

Manual steps that the release notes name:

| Version | Step |
|---|---|
| 1.5.0 | Language-dependent release: server-side activation by Technical Support; add the `wf_languages` checkbox input to the release form |
| 1.4.1 | Existing projects add a data-source check to the workflow display logic |
| 1.2.0 | Remove all release workflow artifacts, import the new package |
| 1.1.2 | Remove all delete workflow artifacts, re-import |

Newer than 1.6.2 is not covered. Whether an update re-imports workflows by itself, and what the project app does to
workflows that exist in an older version, is `[verify]`.

## For the automation tools

The documentation names the packages, not the workflow uids. On a project with the three packages imported the workflows were
`release`, `delete` and `release_with_ai_review` (observed 2026-10-13, FirstSpirit 2026.11) `[observed]`; a request-release
workflow is not part of the module. A role policy for the tool in `firstspirit-configuration` names only workflows the project
has; create any other workflow first (`firstspirit-workflow-development`).
