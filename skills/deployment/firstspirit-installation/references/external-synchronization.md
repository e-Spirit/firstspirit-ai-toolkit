# External Synchronization (FSDevTools, `fs-cli`)

Sources `[odfs]`, read 2026-10-13: *External Synchronization* documentation, introduction page (FirstSpirit 2026.11); the FSDevTools `README.md` in the public GitHub repository.
`firstspirit-external-sync-export` has the full procedure (install with the Access API jar, connect, export, import, troubleshoot; verified with fsdevtools 4.8.9); this page only names what an administrator has to prepare.

## Requirements `[odfs]`

- The **API-Access** licence feature on the server: external components such as `fs-cli` connect to it, so without it nothing works (`licence.md`). On Cloud: `firstspirit-cloud`.
- FSDevTools 4.5.0 and later needs FirstSpirit **2023-11-05 or later** on the server; **Java 17 or newer** with `JAVA_HOME` set; the tool is a binary distribution (zip or tar.gz) from the GitHub releases.
- A FirstSpirit user for the tool and the project name. Defaults come from the environment variables `fshost`, `fsport`, `fsmode` (HTTP, HTTPS or SOCKET), `fsuser`, `fspwd`, `fsservletzone`, `fsproject`; only the project has no default. Passwords belong in the environment, not in commands.
- Versions follow semantic versioning since 3.0.0; a major version can raise the minimum FirstSpirit version: read the release notes before updating.

## Limits worth knowing before promising it `[odfs]`

Development artefacts only, no editorial mass data; all environments must share the same project structure (for example the language count); no merge help, so conflict handling is the version-control system's job (Git recommended). Decision-level: `firstspirit-technical-product-knowledge`.
