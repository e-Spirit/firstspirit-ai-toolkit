# VideoManagementPro

Sources `[odfs]`, read 2026-10-13: *Documentation for Administrators* 1.11.9 (13.07.2026); *VideoManagementPro documentation* (project setup).
It connects **VideoManager Pro from movingimage**; the videos stay there and are only referenced.

## Cloud or on-prem

The administrator document describes the module on the FirstSpirit server (on-prem). On Cloud, module install is a Support request (`SKILL.md`); the project steps are the customer's. The Cloud path is not documented on these pages `[verify]`.

## Requirements `[odfs]`

FirstSpirit 5.2.230909 or later; module `videomanagementpro-<version>.fsm`; a licence that has the **AppCenter** on (`license.APPTAB_SLOTS`), because VideoManager Pro is shown in the AppCenter in SiteArchitect (never edit `fs-license.conf`: `licence.md`); a **technical movingimage user** who can see every video used in the project. **Not usable with the external FirstSpirit preview** (so not with OCM or headless previews).

## Steps, in order `[odfs]`

| # | Step | Where (EN labels) | Check |
|---|---|---|---|
| 1 | Install the module; give its folder **All permissions**; **restart the server** | ServerManager, Server properties, Modules | |
| 2 | Optional: HTTP proxy for the service (`http(s)://host:port`, user and password if needed); cache of the *MI24 Video Search Service* and *MI24 Video Permission Service* (invalidation: *Expire After Access* default, or *After Write*; default 5 minutes) | the services' *Configure* | |
| 3 | Project component *VideoManagementPro Project Configuration*: technical **user and password**; *Use this user in the preview* (else every editor is asked for their own movingimage login); **Test configuration & update**; choose the *Standard VideoManager* when the user sees several instances | Project properties, Project components | the test login passes (five failed logins in an hour lock the account for an hour) |
| 4 | Web component *VideoManagementPro Web Application* on the **Preview** tab and again on the **ContentCreator** tab; install and activate on a web server | Project properties, Web components | |
| 5 | In the project (example template set, chapter 3): script `getvideoembedcode` (`#!executable-class GetVideoEmbedCode`, scope **Template**, else generation errors), an image `dummy_video` as placeholder, and a section template with an `FS_INDEX` on `videomanagementpro-fsm/VideoManagementProPlugin` and a player combobox | SiteArchitect | a video can be dragged from the report into a section |

Changing the standard VideoManager later can cause form errors, because the players belong to the instance. With several video sections using different players on one page, the last one's player is used `[odfs]`.

## Adaptations the project needs before editors can use it `[odfs]`

Module documentation 1.11.9, 13.07.2026, chapter *Adaptations in the project*. The module ships no template set; the documentation describes one section template as an example and says the best implementation depends on the project.

| Piece | Rule |
|---|---|
| Script for embed codes | Reference name **`getvideoembedcode`**, content `#!executable-class` and the class `GetVideoEmbedCode` (parameters: a list `videoIds`, a map `parameters` with, so far, only `player_definition_id`). The script scope must be **Template**; another scope fails at generation |
| Placeholder image | Media with reference name **`dummy_video`**, **made by hand** (not delivered). Shown until the editor has authenticated in the preview, or when the editor may not view the video |
| Section template form | An `FS_INDEX` that saves the video id and takes its source from the module's plugin (`videomanagementpro-fsm/VideoManagementProPlugin`, exactly this form); a component to choose the player (the example uses a combo box fed by the module's `MI24PlayerValueProvider`); optional `FS_BUTTON` that opens VideoManager Pro with the `FS_INDEX` as `target` |
| One video per section | A rule that disables *Add* on the `FS_INDEX` once it holds one entry (`SIZE` of the component equals 0 enables it) |
| Drag and drop | If the page template has an `FS_BUTTON` for new sections, set the `FS_INDEX` as *Drop Editor* in the section properties |
| Several players on a page | With sections that use different players, the player of the **last** section is used for all |

The project component's option *Use this user in the preview*: on, the preview is generated with the technical user; **off, each editor is asked for their own movingimage access data once per client session**, which is why the placeholder image exists.
Template syntax belongs to `firstspirit-templating-reference`; project-side set-up as such is the work of `firstspirit-template-design`.
