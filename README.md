# FirstSpirit AI Toolkit

Skills for building and managing [FirstSpirit CMS](https://www.crownpeak.com/products/crownpeak-dxp) projects with AI coding assistants.

## Install

Find your assistant below. Most installs are two commands: register this
repository as a plugin marketplace, then install the toolkit from it. There is
nothing to download or build first.

Two names come up along the way. The marketplace is **`firstspirit`**; the plugin
inside it is **`firstspirit-ai-toolkit`**. Where a command needs both, it joins
them as `firstspirit-ai-toolkit@firstspirit`.

### Claude Code

```bash
/plugin marketplace add e-Spirit/firstspirit-ai-toolkit
/plugin install firstspirit-ai-toolkit
```

The first command registers this repository as a marketplace; the second installs
the plugin from it.

### GitHub Copilot

```bash
copilot plugin marketplace add e-Spirit/firstspirit-ai-toolkit
copilot plugin install firstspirit-ai-toolkit@firstspirit
```

Copilot CLI reads the marketplace manifest this repo already ships at
`.claude-plugin/marketplace.json`.

Once installed, the toolkit loads its skill index automatically at session start — only when the project looks like FirstSpirit (same detection as Claude Code). No per-project setup needed.

**No plugin install?** Add the following to your project's `.github/copilot-instructions.md` instead (create the file if it doesn't exist):

```
If this project involves FirstSpirit CMS, read `skills/using-firstspirit-toolkit/SKILL.md` for the available skills and when to use them. If it does not, ignore that file entirely.
```

### Codex CLI

```bash
codex plugin marketplace add https://github.com/e-Spirit/firstspirit-ai-toolkit
codex plugin add firstspirit-ai-toolkit@firstspirit
```

Note `plugin add`, not `plugin install`. Confirm with `codex plugin list`.

### Codex App

Codex marketplaces are imported per workspace by an admin, not added per user.

1. Go to **Admin** → **Plugins** → **Add** → **Import marketplace**.
2. Enter `https://github.com/e-Spirit/firstspirit-ai-toolkit` — the repository URL
   only, with no branch or subdirectory path. Leave the subdirectory blank.
3. Authorize GitHub access when prompted, using an account that can read the
   repository.
4. Review the import and set the plugin's installation policy.

Developers then install it from the plugin browser:

```bash
codex /plugins
```

The first import can take up to an hour for a large marketplace; after that it
syncs daily, and an admin can force one with **Sync now**.

### Gemini CLI

Gemini has no plugin concept — the toolkit ships as a Gemini **extension**, which
is why the manifest lives at the repository root as `gemini-extension.json`.
Install it by repository URL:

```bash
gemini extensions install https://github.com/e-Spirit/firstspirit-ai-toolkit
```

Note the plural `extensions`. The command needs `git` on your machine, cannot be
run from inside Gemini's interactive mode, and takes effect on the next session.
Gemini copies the extension rather than referencing it, so pull later changes
with `gemini extensions update firstspirit-ai-toolkit`.

### Cursor

Cursor has no install CLI — it is either a marketplace import or a local
directory.

**Team marketplace (recommended for a team):** in the Cursor dashboard go to
**Plugins** → **Add Marketplace** under Team Marketplaces, choose **Import from
Repo**, point it at `e-Spirit/firstspirit-ai-toolkit`, then **Add to
Marketplace**. Members install it from **Customize** in the sidebar.

**Local copy (for one machine, or to try it):** symlink this repository into
Cursor's local plugin directory, then reload:

```bash
git clone https://github.com/e-Spirit/firstspirit-ai-toolkit.git
mkdir -p ~/.cursor/plugins/local
ln -s "$PWD/firstspirit-ai-toolkit" ~/.cursor/plugins/local/firstspirit-ai-toolkit
```

Restart Cursor (or run **Developer: Reload Window**) and confirm the plugin's
components appear under **Customize**. A symlink rather than a copy means
`git pull` is enough to update it.

## What's Included

### Skills

Skills are organised into FirstSpirit domain categories:

| Category | Skills |
|----------|--------|
| `content/` | Content store management, datasets |
| `templating/` | Page, section, and link templates |
| `project/` | Project setup and configuration |
| `deployment/` | Publishing and generation runs |
| `diagnostics/` | Troubleshooting and health checks |

### When the toolkit loads

The toolkit is meant to stay out of the way on projects that have nothing to do
with FirstSpirit. How it does that depends on what the harness supports.

**Claude Code, GitHub Copilot, Cursor and Gemini CLI** run a session-start hook,
so the skill index is only loaded when the project looks like FirstSpirit. On
anything else the hook prints a single line telling the assistant where to find
the index if the work turns out to be FirstSpirit after all — and nothing else is
loaded.

**Codex** has no session-start hook to run, so the index is always loaded.
Gating there is done by the skill itself: its first section tells the assistant
to ignore the toolkit entirely, and not mention it, unless the task actually
involves FirstSpirit. The detection below and the `FIRSTSPIRIT_PROJECT` variable
therefore have no effect on Codex.

#### How a FirstSpirit project is detected

Used by the four hook-based harnesses above. A project counts as FirstSpirit if
any of these is present:

- a `.firstspirit` marker file (empty file is enough), or `fs-project.yaml`;
- an external-sync export tree (the `FS_References.txt` / `FS_Info.txt` sidecars);
- a `module.xml` / `module-isolated.xml` that names FirstSpirit (`de.espirit`,
  `firstspirit`) — the filename alone is too generic to count — or a build file
  (`pom.xml`, `build.gradle`) that depends on the Access API or isolated runtime
  (`fs-isolated-runtime`, `fs-access`, `de.espirit.firstspirit`);
- a server or CLI descriptor (`fs-server.conf`, `fs-cli.yaml`) or a built `.fsm`;
- a decoupled frontend depending on FSXA (`fsxa-api`, `fsxa-pattern-library`).

The scan skips `node_modules`, `.git`, `target`, `dist`, `build` and `.gradle`, so
it stays fast on large repositories and a marker inside a dependency never counts.

Drop an empty `.firstspirit` in a repo the detector doesn't recognise to force it
on. Override either way with the `FIRSTSPIRIT_PROJECT` environment variable
(`1` = always load, `0` = never — `0` also suppresses the reminder line).

## Contributing

See [CLAUDE.md](CLAUDE.md) for contributor guidelines.

## Requirements

**Users:** none. The session-start hook is pure bash (3.2+) and needs no external
tools, so the toolkit works on a stock macOS or Linux box.

**Contributors:** `jq` (`brew install jq` / `apt install jq`) for the version-bump
and test scripts, and `shellcheck` (`brew install shellcheck`) for the lint step.

## License and legal

MIT © 2026 Crownpeak Technology GmbH — see [LICENSE](LICENSE). FirstSpirit is a product of
Crownpeak Technology GmbH, a Rezolve Ai PLC company.

[Imprint](https://www.firstspirit.com/policies/imprint/) ·
[Legal](https://www.firstspirit.com/policies/legal/) ·
[Privacy policy](https://www.firstspirit.com/policies/privacy-policy/)

FirstSpirit is a trademark of Crownpeak Technology GmbH. Claude, GitHub Copilot, Codex, Gemini
and Cursor are trademarks of their respective owners; this toolkit is not affiliated with or
endorsed by them.
