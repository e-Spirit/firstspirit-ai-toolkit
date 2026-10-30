---
name: firstspirit-configuration
description: Configuring a FirstSpirit project and server after it exists, first topic permissions. Use it to set up or repair who can see a project and what each role may do in each store and workflow (groups and roles, store permissions, workflow permissions, BasicWorkflows, external groups on FirstSpirit Cloud), by hand with a checklist or with a tool that plans, applies and verifies from a role policy. Also for "I cannot see the project in the clients", "permissions were lost after the import", "which group may release", "configure a module's project component".
metadata:
  source-commit: "1e54562"
  published: "2026-10-30"
  toolkit-version: "0.7.0"
---

> **Beta.** Early public release. Feedback welcome; behaviour and structure may change.

# Configuring a FirstSpirit project

> **Beta.** Built from the product documentation and the Access API, checked where a tag says so: `[odfs]` product
> documentation, `[jar]` javap-verified against the FirstSpirit runtime jar,
> `[observed]` seen in a live run (dated, versioned), `[verify]` not yet checked on a server. Treat a `[verify]` statement
> as a lead, not a fact.

Configuration is what a project needs besides its templates and content: who may see it, who may do what,
which workflows run, which apps and module configurations are installed. This skill starts with
**permissions**, the part that is most often lost or wrong.

## Two ways to do it

| | Guided | Automated |
|---|---|---|
| Who | A person following the steps, troubleshooting as they go | A script or an agent |
| Needs | A client (SiteArchitect / ServerManager) and the right to change permissions | REST access to the project with the right to create a script and change permissions; Python 3 |
| Result | The steps and the checklist in `references/permissions.md` | `scripts/permissions/permissions.py`: plan, apply, verify, report |
| Safe because | The checklist ends with a read-back | Dry run is the default; only groups named in the policy change; Everyone and Administrators* never; read-back after apply |

Both start from the same table: **which group fills which role.** That table is the input. Group names are the
project's own; on FirstSpirit Cloud they are external groups whose membership comes from Keycloak, and the naming
is not enforced (one project may have `Editor`, another `Redaktion`).

## Which tool for which job

| Job | Use |
|---|---|
| Decide roles, groups and rights; fix "I cannot see / do / release" | `references/permissions.md` |
| Apply a role policy to a project and prove it | `scripts/permissions/` |
| Workflow permissions (authorise a workflow in a store) | `references/workflows.md` |
| ServerManager menu labels, German and English | `references/servermanager-labels.md` |
| Project component and options of an installed module; who may use it; schedules it adds | `references/module-configuration.md` |
| Install a module, activate it in a project | `firstspirit-installation` |
| Model or build a workflow; why a workflow is not offered | `firstspirit-workflow-development` |
| Keep permissions through a Git sync | the permission modes of export and import in `references/permissions.md`; keep the role policy in version control and run `verify` after every import |

## Not covered

Schedule entries, folder- and element-level permissions, and a plan-apply-verify tool for module configuration
(`references/module-configuration.md` is the guided part).

<!-- feedback-footer:v1 -->

## Feedback

Found something wrong, unclear, or missing? **Tell me in the chat — I'll log it for you**
(no form to fill). To report it yourself, open an issue on
this skill's repository.
