# Build a workflow in the Template Store (by hand)

The route that needs no code. Works in SiteArchitect and in the template-development view of ContentCreator.
Steps from the ODFS tutorial `[odfs]` and from a Hello World build in the ContentCreator template-development view on 2026-10-12 that the author has not re-run `[verify]`.
A workflow built without steps 5 and 7 saves fine but **is not offered on a page**; the causes are in `not-offered.md`. This order has not been run through the client end to end `[verify]`.

## Order

1. **Create the workflow.** Right-click *Workflows* in the Template Store › *New* › *Create new workflow*. Enter a reference name and a display name per editorial language; the reference name follows from the first display name `[verify]`. Editors see the display names on buttons and titles `[odfs]`. New workflows open in edit mode `[odfs]`.
2. **Create the script** (only if an activity should do something). Scripts, folder `workflow_scripts` (BasicWorkflows keeps its scripts in a folder of its own `[verify]`), *Create new script*. The source is in the *html* tab of the script `[observed]`. Body: see below.
3. **Wire the activity.** *State diagram* › right-click the state › *Edit activity* (the menu also has Add state, Add activity, Remove activity) `[verify]`. Pick the script, set *Execution* to *Automatic* for a step that runs by itself. Apply, then save.
   **Do not double-click a state**: it only moves it `[verify]`.
4. **Draw the transition out of the activity.** Hover the activity; a "+" handle appears at its top edge; drag it onto the End state; name the transition in the dialog (e.g. `done`) `[verify]`. The script calls it by that name.
5. **Set who may start it.** Select the transition leaving *Start* › *Fixed permissions* on › user group `Everyone`, or the groups that may start it `[odfs]`. The same for each following transition that a person takes. Start status type *Start (Set editor(s) automatically based on permissions)* for the Start state `[odfs]`.
6. **Settings tab.** Tick *Runnable in ContentCreator* if editors use that client; leave *Runnable without context* off for a workflow that works on an element; tick *Use display logic* and paste a script (below) `[verify]`.
7. **Authorise it in the stores.** On each store root: Extras › Change permissions › *Workflow permissions* › *Authorized* for the workflow › OK `[odfs]`.
8. **Reload the client and look for it.** ContentCreator: the status button of the page (the workflow panel), not the user menu and not the tasks panel `[observed]`. SiteArchitect: the element's *Workflow* context menu `[odfs]`.
9. **Run it, reach End.** Only then is it done.

## Hello World script

```
//!BeanShell
import de.espirit.firstspirit.agency.OperationAgent;
import de.espirit.firstspirit.ui.operations.RequestOperation;
req = context.requireSpecialist(OperationAgent.TYPE).getOperation(RequestOperation.TYPE);
req.setTitle("Hello World");
req.setKind(RequestOperation.Kind.INFO);
req.addOk();
req.perform("Hello World!");
context.doTransition("done");
```

- `RequestOperation` and the kinds WARN, INFO, QUESTION, ERROR are from the ODFS Messages page; the examples there call `addOk()` before `perform` `[odfs]`. ContentCreator shows WARN and INFO alike `[odfs]`.
- `doTransition` takes the transition's reference name; unnamed transitions appear in the ODFS demos as `"->Target"` (e.g. `"->Start"`) `[odfs]` `[verify]` how that name is formed.
- The script has not been run in a client yet `[verify]`. The other facts about script contexts are in `firstspirit-scripting`.

## Display logic

This is the display logic of the BasicWorkflows `release` package `[verify]`; it matches the documented behaviour that the release workflow is not available on Data Store folders `[odfs]`, and it suits any workflow meant for pages and sections:

```
//!Beanshell
import de.espirit.firstspirit.access.store.Store;
import de.espirit.firstspirit.access.store.contentstore.ContentFolder;

boolean isContentFolder(storeElement) {
	return storeElement.getStore().getType() == Store.Type.CONTENTSTORE
			&& storeElement instanceof ContentFolder;
}

storeElement = context.getElement();
return storeElement != null && !isContentFolder(storeElement);
```

## Editing tips `[verify]`

- Monaco (the script editor in the browser) closes brackets and quotes by itself; a typed script can end with stray characters. Look at the end of the script before saving.
- Wait a moment after switching a tab before typing; the editor loads late.
- Reopen the workflow after saving to prove that it persisted.
