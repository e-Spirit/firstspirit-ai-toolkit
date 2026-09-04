# Common FirstSpirit Patterns

> **Transitional — leaving this skill.** This file is Java Access API / BeanShell content, which
> is out of scope for a templating reference. It migrates to the **`firstspirit-scripting`** skill;
> use that skill for scripting. Kept here only until the migration lands.

Frequently used Java API patterns for FirstSpirit development.

---

## Lock / Modify / Unlock

```java
storeElement.setLock(true, false); // acquire exclusive lock
try {
    storeElement.setSomeProperty(newValue);
    storeElement.save();
} finally {
    storeElement.setLock(false, false); // always release
}
```

## Service resolution via SpecialistsBroker

```java
final PageStoreAgent pageStoreAgent = broker.requireSpecialist(PageStoreAgent.TYPE);
final PageStore pageStore = pageStoreAgent.getMasterPageStore();
```

## Language-aware content access

```java
final Project project = broker.requireSpecialist(ProjectAgent.TYPE).getProject();
final Language masterLanguage = project.getMasterLanguage();
final String text = textEditor.get(masterLanguage);
```

## Navigating the store by UID

```java
final IDProvider element = pageStore.getStoreElement("my-uid", IDProvider.UidType.PAGESTORE);
if (element instanceof Page page) {
    // work with page
}
```

## BeanShell scripting

- Use `context.logInfo/logError/...` for logging
- Start with `//!BeanShell` header
- Access stores via `context.getProject().getUserService().getStore(Store.Type.PAGESTORE)`
- Access form fields via `context.getElement().getFormData().get(language, "fieldName")`
- Obtain services: `context.requireSpecialist(ServicesBroker.TYPE).getService(MyService.class)`
