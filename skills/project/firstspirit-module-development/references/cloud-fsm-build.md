# Building an FSM for the Cloud pipeline

How the Gradle build of a module that the **Cloud pipeline** builds is put together, and the
compatibility traps between Gradle, the FSM plugin, the JDK and the FirstSpirit runtime jar.

Scope: this file owns the **build files**. The pipeline around them — Bitbucket repository,
Bamboo plans, which branch deploys to which stage, the PROD ticket and patch day — is owned by
`firstspirit-cloud` (its environments-and-workflow reference, section *The module repo (Cloud
archetype)*). Component design and scopes are in [module-descriptor.md](module-descriptor.md) and
[multi-project-layout.md](multi-project-layout.md). Do not restate the pipeline here.

A Cloud module is **built by the pipeline, not installed as a black-box `.fsm`**. A local
`./gradlew assembleFSM` compiles and validates; it does not deploy anything.

---

## The files

| File | Holds | Rule |
| --- | --- | --- |
| `build.gradle.kts` | plugins, repositories, dependencies, the `firstSpiritModule { }` block, publishing, release | Kotlin DSL. Do not edit the credential blocks; the pipeline injects its own values through the same property names `[observed]`. |
| `settings.gradle.kts` | the plugin repository (with credentials) and `rootProject.name` from `gradle.properties` | `rootProjectName` must not be empty. |
| `gradle.properties` | every value of the module (table below) | The build fails when a required key is blank. |
| `ci.properties` | `fsm.project.path` for the pipeline | Empty when the root project builds the FSM; the subproject path with a trailing slash otherwise. |
| `gradle/wrapper`, `gradlew` | the pinned Gradle version | Commit them. A new Windows checkout needs `git update-index --chmod=+x gradlew`. |
| `~/.gradle/gradle.properties` | `artifactory_hosting_username`, `artifactory_hosting_password` | **User-level, never in the repository.** Access differs for staff, partners and customers. |

## A single-project build

The shape of a module with a handful of components (one assembly project, no subprojects). Use
[multi-project-layout.md](multi-project-layout.md) once a Java API or a web app that must stay
slim is involved.

```kotlin
plugins {
    id("java-library")
    id("maven-publish")
    id("de.espirit.firstspirit-module") version "9.0.2"    // Gradle 9 needs plugin 7.0.0 or newer
    id("net.researchgate.release") version "3.2.0"
}

tasks.withType<JavaCompile> {
    options.encoding = "UTF-8"
    options.release.set(Integer.parseInt(project.property("java.languageLevel") as String))
}

group = project.property("groupId") ?: error("groupId not set")

repositories {
    maven(url = "<the Cloud Artifactory repo URL>") {
        // credentials { … } read the two artifactory_hosting_* properties from the user-level
        // ~/.gradle/gradle.properties; keep the archetype's block unchanged
    }
}

val fsRuntimeVersion = project.property("firstSpirit.version") as String

dependencies {
    compileOnly("de.espirit.firstspirit:fs-isolated-runtime:${fsRuntimeVersion}")   // provided by the server
    testImplementation(platform("org.junit:junit-bom:<version>"))
    testImplementation("org.junit.jupiter:junit-jupiter-api")
    testRuntimeOnly("org.junit.jupiter:junit-jupiter-engine")
    testRuntimeOnly("org.junit.platform:junit-platform-launcher")   // Gradle 9 no longer provides it
    testImplementation("de.espirit.firstspirit:fs-isolated-runtime:${fsRuntimeVersion}")
}

tasks.withType<Test> { useJUnitPlatform() }

firstSpiritModule {
    moduleName  = project.property("firstSpiritModule.moduleName") as String
    displayName = project.property("firstSpiritModule.displayName") as String
    description = project.property("firstSpiritModule.description") as String
    vendor      = project.property("firstSpiritModule.vendor") as String
}

publishing {
    publications { create("fsm", MavenPublication::class) { artifactId = project.name; artifact(tasks.assembleFSM) } }
    // repository: snapshot or release by the version suffix (-SNAPSHOT); same credentials as above
}
```

`[observed]` in two Cloud modules built this way (a `UrlFactory` module and a web-app filter
module). The release plugin is configured with `requireBranch = "main|master"` and publishes after
`afterReleaseBuild`; a release runs only on the release branch.

## `gradle.properties`

| Key | Meaning | Note |
| --- | --- | --- |
| `version` | module version, `-SNAPSHOT` until released | the suffix selects the snapshot or release repository |
| `rootProjectName` | Gradle root project name | names the `.fsm` file |
| `groupId` | Maven group | part of the Artifactory coordinates |
| `java.languageLevel` | `options.release` | see the JDK table below |
| `firstSpirit.version` | the `fs-isolated-runtime` to compile against | the target server's level; `compileOnly`, never bundled |
| `firstSpiritModule.moduleName` | technical module id | load-bearing, see below |
| `firstSpiritModule.displayName`, `.description`, `.vendor` | descriptor header | shown in ServerManager |
| `publishing.snapshotRepository`, `publishing.releaseRepository` | Artifactory repositories | the Cloud defaults are the `es-*-local` pair `[observed]` |

**Choose the module name and the Maven coordinates before the first push.** Once the pipeline and the
installed module exist they are the installed identity; changing `moduleName` installs a second
module instead of updating the first (see *Naming scheme* in
[isolated-mode-and-packaging.md](isolated-mode-and-packaging.md)).

## Gradle, plugin, JDK and runtime must agree

| Pair | Rule | Source |
| --- | --- | --- |
| Gradle 9 and the FSM plugin | plugin **below 7.0.0 cannot run on Gradle 9**; 9.0.2 was the plugin used with Gradle 9.8 | `[observed]` |
| JDK 25 | Gradle **9.1 or newer** is required to run on JDK 25; the Cloud pipeline can run a "Compatibility (Temurin N)" plan that rebuilds under a newer JDK (see `firstspirit-cloud`) | `[observed]` |
| `java.languageLevel` and bytecode | `options.release` fixes your classes' target. 17 runs on a Java 21 server | `[observed]` |
| The runtime jar's own bytecode | `fs-isolated-runtime` **5.2.251108** is class-file major **61** (Java 17) `[jar]`; **5.2.261011** is **65** (Java 21) `[jar]`. Compiling against a Java 21 jar needs a JDK 21 even when your own level is 17 | `[jar]` |
| Local build without a newer JDK | override the runtime for the build only: `./gradlew build -PfirstSpirit.version=<an older runtime already in the Gradle cache>`. This proves your code compiles and your tests pass; it does not prove compatibility with the target runtime | `[observed]` |

Read the target server's runtime and Java level from the server (see `firstspirit-cloud`) before
you set `firstSpirit.version` and `java.languageLevel`.

## What a green local build proves

`./gradlew build assembleFSM` ran `compileJava`, `test`, `assembleFSM` and a **`validateDescriptor`**
task `[observed]`. Check the result instead of trusting it:

1. `build/fsm/<rootProjectName>-<version>.fsm` exists.
2. Unzip it: `META-INF/module-isolated.xml` lists the components you expect, each with the right
   `scope`; the jar is under `lib/`; any `web.xml` is at the archive root `[observed]`.
3. A **web-app** component carries `<web-resources>` naming the module jar — the plugin adds it
   without further wiring in a single-project build `[observed]`. Add third-party libraries with
   `fsWebCompile`, see [multi-project-layout.md](multi-project-layout.md).

The pipeline builds with its own credentials and may run more checks than your machine (a
compliance plan; see `firstspirit-cloud`). A passing local build is therefore not a promise that the
branch is green; it is the cheapest first check.

## Tests the pipeline insists on

At least one unit test must pass, or the build fails `[observed]`. Keep logic that needs no server in
plain classes (a parser, a name normaliser) so it can be tested without mocking a broker; test the
component classes through the built descriptor. See the test advice in
[best-practices.md](best-practices.md).
