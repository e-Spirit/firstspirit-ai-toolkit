# FirstSpirit Contexts

Class hierarchy of the FirstSpirit script contexts (replaces the former
`firstspirit-context-hierarchy.png` poster). Edit the Mermaid block below to update; it renders
in GitHub, Confluence, VS Code, Obsidian and most Markdown viewers.

```mermaid
classDiagram
    direction TB

    class SpecialistsBroker {
        requireSpecialist(SpecialistType~S~) S
        requestSpecialist(SpecialistType~S~) S
    }

    class BaseContext {
        is(Env) boolean
        logInfo(...)
        logWarning(...)
        logError(...)
        logDebug(...)
    }

    class ScriptContext {
        getConnection() Connection
        getProperty(String) Object
        setProperty(String, Object)
        removeProperty(String)
    }

    class ProjectScriptContext {
        getProject() Project
        getUserService() UserService
    }

    class ScheduleContext {
        getErrorCount() int
        getPath() String
        getProject() Project
        getStartTime() Date
        getTask() ScheduleTask
        getTasks() List~ScheduleTask~
        getVariable(String) Object
        getVariableNames() Set~String~
        setVariable(String, Serializable)
        setStartTime(Date)
        setStateToSuccess()
        setStateToFailed()
        ...
    }

    class GenerationScriptContext {
        getLanguage() Language
        getTemplateSet() TemplateSet
        isPreview() boolean
        isRelease() boolean
    }

    class ClientScriptContext {
        getElement() IDProvider
        getStoreElement() StoreElement
        getUser() User
        getUserGroups() Group[]
    }
    note for ClientScriptContext "getStoreElement() is @deprecated"
    note for SpecialistsBroker "requestSpecialist may return null; requireSpecialist throws IllegalStateException instead"

    class GenerationContext {
        getBasePath() String
        getCharacterReplacer(boolean) CharacterReplacer
        getContext(String) Context
        getDataset() Dataset
        getDebugMode() boolean
        getDeleteDirectory() boolean
        getEncoding() String
        getEvaluator() Evaluator
        getNavigationContext() IDProvider
        getNode() ContentProducer
        getPage() Page
        getPageContext() Context
        getPageParams() PageParams
        getScheduleContext() ScheduleContext
        getStartTime() Date
        getUrlCreator() UrlCreator
        getUrlCreatorProvider() UrlCreatorProvider
        mediaReferenced(Media, Language, Resolution)
        setDebugMode(boolean) void
        setUseMasterLanguageForData(boolean) void
    }

    class GuiScriptContext {
        getScript() Script
        showForm(...) FormData
    }

    class Content2ScriptContext {
        getData() List~Entity~
        getEntityType() EntityType
        getSelectedRow() Entity
    }

    class WorkflowScriptContext {
        doTransition(String) void
        doTransition(Transition) void
        getErrorInfo() TaskErrorInfo
        getSession() Map~Object,Object~
        getTask() Task
        getTransition() Transition
        getTransitionParameters() TransitionParameters
        getTransitions() Transition[]
        getWorkflowable() Workflowable
        getWorkflowContext() WorkflowContext
        gotoErrorState(String, Throwable) void
        sendEMail(String, String, String) void
        showActionDialog() Transition
    }

    SpecialistsBroker <|-- BaseContext
    BaseContext <|-- ScriptContext
    ScriptContext <|-- ProjectScriptContext
    ScriptContext <|-- ScheduleContext
    ProjectScriptContext <|-- GenerationScriptContext
    ProjectScriptContext <|-- ClientScriptContext
    GenerationScriptContext <|-- GenerationContext
    ClientScriptContext <|-- GuiScriptContext
    GuiScriptContext <|-- Content2ScriptContext
    GuiScriptContext <|-- WorkflowScriptContext
```

## Inheritance (plain text)

```
SpecialistsBroker
└── BaseContext
    └── ScriptContext
        ├── ProjectScriptContext
        │   ├── GenerationScriptContext
        │   │   └── GenerationContext
        │   └── ClientScriptContext
        │       └── GuiScriptContext
        │           ├── Content2ScriptContext
        │           └── WorkflowScriptContext
        └── ScheduleContext
```
