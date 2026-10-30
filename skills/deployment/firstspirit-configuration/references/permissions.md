# Permissions

Everything here is `[observed]` once on a development server (FirstSpirit 5.2.261116, 2026-10-07 and 2026-10-09) unless a tag says otherwise.

## The model

- **Access.** A project shows up in the clients (SiteArchitect, ContentCreator) only for a member of a group that
  has access to it. A server admin sees it in the ServerManager only. A project imported without its access group is
  invisible to everyone else `[observed]`.
- **Groups** are local or external. External groups are matched with a string from the identity provider (on Cloud:
  Keycloak). A project gets these on creation (Cloud): `Administrators` (local), `Everyone` (local, not changeable),
  and three admin groups `Administrators (CloudServices)`, `Administrators (Services)`, `Administrators (Techsupport)`
  `[verify]` (not stated in the Cloud documentation). Other groups are the customer's.
- **Store permissions**: a bit set per group on a store element. `CAN_SEE` 1, `CAN_READ` 2, `CAN_CHANGE` 4,
  `CAN_APPEND_FOLDER` 8, `CAN_APPEND_LEAF` 16, `CAN_DELETE_FOLDER` 32, `CAN_DELETE_LEAF` 64, `CAN_CHANGE_PERMISSION` 128,
  `CAN_RELEASE` 256, `CAN_META_SEE` 512, `CAN_META_CHANGE` 1024, `CAN_EVERYTHING` 2047 `[jar]`
  (`de.espirit.firstspirit.access.store.Permission`). API: `StoreElement.getPermission(Group)`, `setPermission(Group, Permission)`,
  `Permission.allow(int)`, `forbid(int)`, `isAllowed(int)` `[jar]`. Change an element with lock, set, save, unlock.
- **Workflow permissions**: which groups may start a workflow on a store element. `getCreateWorkflowPermission(Workflow)`,
  `setWorkflowPermission(s)`, `setInheritWorkflowPermission(boolean)`, `WorkflowPermission.allowGroup/setAllowedGroups`;
  per transition `WorkflowTransitionPermission` `[jar]`. Set `setInheritWorkflowPermission(false)` before setting them: without
  that call the setting did not persist `[observed]` (cause not proven).
- **Admin groups** (`Group.isAdmin()`) have implicit rights: their effective permission set reads as `CAN_SEE`, `CAN_READ`, `CAN_CHANGE`,
  `CAN_CHANGE_PERMISSION` whatever mask is stored `[observed]`.
- **Release**: `CAN_RELEASE` applies to the content stores. Nothing in the TemplateStore can be released (see `firstspirit-api-reference`).

## Which roles, in short

| Role | Means | Typical rights on content stores | Workflows |
|---|---|---|---|
| ProjectAdmin | everything | all | all |
| Chief editor | may release | see, read, change, append, delete, release | may start release and request release |
| Editor | may ask for release | see, read, change, append; no release | may start request release |
| Developer | works on the design | all on TemplateStore and GlobalStore; read on content | per project |

The numbers are a starting point in `scripts/permissions/policy.example.json`, not a rule.

## What export and import carry

- Store permissions are exported as `perm="<groupId>:<mask>,..."` on the store root `StoreElement.xml` (and on elements that have their own) `[observed]`;
  `fs-cli export --permissionMode` defaults to NONE, `import` to ALL (documented option of FSDevTools; the import and export commands are in `firstspirit-external-sync-export`).
- **Store-level workflow permissions are not in the export**, in any permission mode `[observed]`. After a re-created project they must be set again.
- Group definitions come with `projectproperty:GROUPS` (`Groups.xml` with user ids, `ExternalGroups.xml` with the external strings): keep them out of Git.
  A selective export has no group definitions; a project seeded from it has no access group.
- `fs-cli import` makes the project match the directory and removes objects the directory does not contain (`firstspirit-external-sync-export`), so a directory
  that holds only a few scripts would remove the rest. Install scripts through REST, not by importing them.
- When a project is developed in branches and a branch export is imported into the main project, the permissions exported from the branch
  can override those of main: decide the `--permissionMode` of export and import first, keep the role policy in version control and run
  `verify` after every import.

## Guided: set the permissions by hand

1. Write the role table: role, group name in this project, external string (Cloud), who is in it.
2. Check the groups: every group of the table exists in the project, and the access group exists. Do not touch `Everyone` or the `Administrators*` groups.
3. Per store (Page, Site, Media, Content, Global, Template): set the rights of each role as in the table; do not give `Everyone` anything it did not have.
4. Per store: set which groups may start which workflow (request release for editors, release for chief editors).
5. Read it back: as an editor, a chief editor and an admin, try one thing each (change a page; request release; release). UI names and paths: `[verify]`.

## Automated

```bash
export FS_HOST=… FS_USERNAME=… FS_PROJECT="<project name>"                   # a development server; FS_SCHEME=http FS_PORT=8000 for a local one
printf 'FirstSpirit password: '; read -rs FS_PASSWORD; echo                 # not echoed, not exported
cp scripts/permissions/policy.example.json scripts/permissions/policy.json    # edit the group names
FS_PASSWORD="$FS_PASSWORD" python3 scripts/permissions/permissions.py plan          # what would change
FS_PASSWORD="$FS_PASSWORD" python3 scripts/permissions/permissions.py apply --yes   # apply, then read back
FS_PASSWORD="$FS_PASSWORD" python3 scripts/permissions/permissions.py verify        # exit 1 if the project differs
```

The password is passed to the one command only; never put it on a command line or in a file under version control.

The tool runs `report.bsh` and `apply.bsh` in the project through the REST execute endpoint as a throwaway script and deletes it afterwards.
Output of a successful run is the script's `[INFO]` log lines `[observed]`; a script that logs nothing returns an empty body.

## Troubleshooting

| Symptom | Likely cause | What to do |
|---|---|---|
| The project is not visible in the clients | No access group on the project (a selective export, a seed without groups) | Add the access group (Cloud: the project admin group); seed with the groups |
| A person cannot do a task in a store | Store permission missing | `plan`, then `apply`; or set it by hand |
| A workflow cannot be started | Workflow permission missing, or the store inherits | `plan` lists it; the tool sets inherit to false |
| Everything was set, and after an import it is gone | Imported with a mode that did not carry it, or a branch export overrode main | Check `--permissionMode` on both sides; run `verify` after the import |
| `plan` says a workflow is not in the Template Store | The module that provides it (BasicWorkflows) is not installed in this project, or the policy uses a name the project does not have (the example policy names `release`, the uid of the BasicWorkflows release package) | Install it first, or take the workflow out of the policy; `report` lists the project's workflows |
| `apply` says a group does not exist | The group is not in the project and the policy has no external string for it | Add it to `policy.local.json` (not committed) |
| The permissions are right and a script that sets them keeps regressing | The script is the only record | Keep the policy in Git and run `verify` in CI |

## Not covered

Folder- and element-level permissions, transition permissions, permission variables. Not yet run on a FirstSpirit Cloud project;
the `developer` profile not yet run on a server.
