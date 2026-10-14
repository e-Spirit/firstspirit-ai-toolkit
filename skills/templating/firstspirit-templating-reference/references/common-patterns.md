# Common FirstSpirit Patterns

> Scripting is covered in `firstspirit-scripting`; this page keeps a few template-side idioms for
> convenience.

Frequently used Java API patterns for FirstSpirit development.

---

## Lock / Modify / Unlock

```java
storeElement.setLock(true, false); // acquire exclusive lock
try {
    // ... modify the element (form data, name, metadata) ...
    storeElement.save();
} finally {
    storeElement.setLock(false, false); // always release
}
```

## Service resolution via SpecialistsBroker

```java
final StoreAgent storeAgent = broker.requireSpecialist(StoreAgent.TYPE);
final PageStore pageStore = (PageStore) storeAgent.getStore(Store.Type.PAGESTORE);
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
