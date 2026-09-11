# Porting to a New Harness

To add support for a new AI coding assistant harness:

## Requirements

1. The harness must be able to load a skill (or context file) at session start.
2. Skills under `skills/` must be discoverable by the harness.

## How the toolkit bootstraps

At session start the harness loads one bootstrap skill —
`skills/using-firstspirit-toolkit/SKILL.md` — which lists the available skills and
when to use them. Everything else flows from that skill.

Two layers keep it from being noise on non-FirstSpirit projects. Use whichever the
harness supports; the second is always in effect:

- **Load-time gating (preferred, hook-based only).** `hooks/session-start` detects
  whether the project is FirstSpirit and injects the full skill index only then —
  otherwise a single quiet discoverability line. See the detection in
  `hooks/session-start`.
- **Self-gating (always on).** The bootstrap skill itself opens by telling the
  assistant to ignore the toolkit unless the work involves FirstSpirit. Harnesses
  that can only load the skill unconditionally (no hook) still behave correctly,
  at the cost of the load-time tokens.

The detector recognises a FirstSpirit project from an explicit `.firstspirit` /
`fs-project.yaml` marker, an external-sync export tree, a `module.xml` or build
file naming `de.espirit` / `fs-isolated-runtime`, or an FSXA frontend dependency
(`fsxa-api`, `fsxa-pattern-library`). It prunes `node_modules`, `.git`, `target`,
`dist`, `build` and `.gradle`, so a marker inside a dependency never counts.

Three constraints bind any new branch you add to `hooks/session-start`:

- **No external tools.** The script emits its JSON with `printf` and a bash
  escaper, deliberately — a missing `jq` used to leave the bootstrap silent on
  every harness. Do not reintroduce a runtime dependency.
- **Never fail.** Any internal error means "not a FirstSpirit project" and exit 0.
  A non-zero exit or empty stdout is a broken session for the user.
- **bash 3.2.** macOS still ships it, so no associative arrays and no `mapfile`.

All three are covered by `./scripts/test-hooks.sh` and the shellcheck step; add a
case there for your harness's envelope when you add its branch.

## Steps

### 1. Add the harness manifest

Each harness has its own manifest file and shape — they are **not** interchangeable.
Match the harness's own format. Current examples in this repo:

| Harness | Manifest | Bootstrap mechanism |
|---|---|---|
| Claude Code | `.claude-plugin/plugin.json` (skills auto-discovered; no `skills` field) | hook — `hooks/hooks.json` |
| GitHub Copilot | `.github/hooks/firstspirit-ai-toolkit.json` + `.claude-plugin/plugin.json` | hook — `SessionStart` via `.github/hooks/`; conditional loading |
| Codex | `.codex-plugin/plugin.json` (`skills`, `sessionStart.skill`, `defaultPrompt`) — plus `.agents/plugins/marketplace.json`, the Codex marketplace registry read by the ChatGPT desktop app | manifest `sessionStart.skill` |
| Cursor | `.cursor-plugin/plugin.json` (`skills`, `hooks` pointer) | hook — `hooks/hooks-cursor.json` |
| Gemini CLI | root `gemini-extension.json` (`contextFileName`) | auto-discovered `hooks/hooks.json` (shared with Claude Code) + `GEMINI.md` context |

Minimum every manifest needs: `name`, `version`, and a way to reach the skills (a
`skills` path, or the harness's own auto-discovery). Copy the closest existing
manifest and adjust rather than starting from scratch.

### 2. Register the version

Add the manifest as an entry in the `files` array of `.version-bump.json`, so its
`version` is bumped along with the others:

```json
{
  "files": [
    { "path": ".<harness>-plugin/plugin.json", "field": "version" }
  ]
}
```

### 3. Wire the bootstrap skill

Pick the mechanism the harness supports:

- **Hook** (Claude Code, Cursor, GitHub Copilot): register a `SessionStart` hook
  that runs `hooks/run-hook.cmd session-start`. Claude uses `hooks/hooks.json`;
  Cursor uses `hooks/hooks-cursor.json`; Copilot uses
  `.github/hooks/firstspirit-ai-toolkit.json` (its auto-discovery path). Then add
  a branch to `hooks/session-start` that detects your harness's env var and emits
  its JSON shape. **Order matters, and the order is not alphabetical:** both
  Copilot and Cursor set `CLAUDE_PLUGIN_ROOT` for plugin hooks (Cursor sets it to
  the same value as `CURSOR_PLUGIN_ROOT`), so the generic Claude variable is the
  *last* signal to trust. Put your harness's own variable ahead of it, or your
  harness silently receives Claude's envelope and drops the context. The existing
  branches, in order: `COPILOT_PLUGIN_ROOT` or `COPILOT_AGENT_SESSION_ID` →
  `{additionalContext}`; `CURSOR_PLUGIN_ROOT` → `{additional_context}`;
  `CLAUDE_PLUGIN_ROOT` → `{hookSpecificOutput:{hookEventName,additionalContext}}`;
  default → `{additionalContext}`. Prefer a plugin-root variable over a session-id
  one, since the hook's own invocation already depends on the former. You do
  **not** reimplement detection: `session-start` already decides
  FirstSpirit-or-not and tiers the output, so a new hook harness inherits
  load-time gating for free.

  Note that `session-start` derives its own location from `$0`, never from a
  plugin-root variable — it uses those only as harness *signals*. That is
  deliberate: Cursor CLI has shipped a bug where a plugin's nested child process
  sees a *different* plugin's root, so a script that resolved its own paths from
  the environment could read another plugin's files. Keep it that way.
- **Manifest declaration** (Codex): point the manifest at the bootstrap skill, e.g.
  `"sessionStart": { "skill": "using-firstspirit-toolkit" }`. This loads the skill
  **unconditionally** — load-time gating is not available, so behaviour on
  non-FirstSpirit projects relies entirely on the skill's self-gating.
- **Auto-discovered hook file** (Gemini CLI): Gemini loads `hooks/hooks.json`
  from an installed extension automatically — the path is a convention, not
  something `gemini-extension.json` declares, and it is *the same path Claude
  Code auto-discovers*. One file therefore serves both, and its command must
  resolve for both: `${CLAUDE_PLUGIN_ROOT:-${extensionPath}}`. Gemini
  substitutes `${extensionPath}` itself (supported in `gemini-extension.json`
  and `hooks/hooks.json` only) before any shell runs and exports no variable of
  its own; Claude exports `CLAUDE_PLUGIN_ROOT` and never evaluates the default.
  Gemini's SessionStart output contract is
  `{"hookSpecificOutput": {"additionalContext": "…"}}` — a subset of Claude's
  envelope, so the shared `claude` shape satisfies it and needs no branch.

  Do not "fix" a collision here by giving one harness its own copy of the file.
  The harness you move off `hooks/hooks.json` may keep auto-discovering it
  anyway and register a second hook that cannot resolve, which is the same
  defect with the harnesses swapped.

  `GEMINI.md` still file-references the bootstrap skill for context; the hook is
  what gates it.
- **Marketplace registry** (Codex, in addition to its plugin manifest):
  `.agents/plugins/marketplace.json` lists the plugin for the ChatGPT desktop
  app. A repo-local plugin uses `"source": { "source": "local", "path": "./" }` —
  note that `"source": "url"` means a *git repository URL* and expects a real
  `https://…` value, so pairing it with a relative path silently selects the
  wrong install path. This registry only advertises the plugin; the bootstrap
  still comes from `sessionStart.skill` in `.codex-plugin/plugin.json`.

> `AGENTS.md` is the contributor guide, not a bootstrap file — do not wire the
> bootstrap skill through it. This applies to Codex too.

#### A harness this repo deliberately does not claim

**Antigravity CLI (`agy`)** was listed as supported before v1 and has been
withdrawn, because neither half of the integration actually worked:

- **Install.** Antigravity requires a `plugin.json` marker at the *plugin root*,
  whose schema is `"required": ["name"]` with `"additionalProperties": false` —
  only `name`, `description` and `$schema` are permitted. None of this repo's
  manifests can serve as that file, and there is no root-level one. It also has
  no install-from-URL path: real-world multi-harness repos generate a separate
  self-contained tree and run `agy plugin install <path>` against it.
- **Gating.** Antigravity's hook events are `PreToolUse`, `PostToolUse`,
  `PreInvocation`, `PostInvocation` and `Stop`. There is **no session-start
  event**: the earliest, `PreInvocation`, fires before *every model call*, so a
  naive port would re-inject the skill index on each turn. Its context-injection
  shape is different too — `{"injectSteps": [{"ephemeralMessage": "…"}]}`, not
  the `additionalContext` family the other harnesses use.

So supporting it means a root manifest, a generated plugin tree, a fifth emit
shape in `hooks/session-start`, and per-session dedupe state — a plan of its own,
ideally written by someone who can run `agy`. `scripts/test-manifests.sh` fails
on any reintroduced Antigravity claim; delete those assertions in the same commit
that makes support real.

### 4. Add tool mappings

Create `skills/using-firstspirit-toolkit/references/<harness>-tools.md` mapping the
abstract skill operations to the harness's real tool names, and reference it from
the bootstrap skill.

### 5. Acceptance test

**FirstSpirit project — the toolkit engages.** For hook-based harnesses, run in a
directory the detector recognises (an empty `.firstspirit` marker, or
`FIRSTSPIRIT_PROJECT=1`), or the hook emits only the quiet line. Open a fresh
session and send: `"Let's set up a new FirstSpirit project."` The `setup-project`
skill must activate before any code or instructions are generated.

**Non-FirstSpirit project — the toolkit stays out of the way.** Run a fresh session
in a plain directory and confirm:

- hook-based harness (Claude Code, Cursor, GitHub Copilot, Gemini CLI): only the quiet discoverability line loads; no skill activates;
- unconditional harness (Codex): the skill loads but **self-gates** — ask an
  unrelated, non-FirstSpirit question and confirm the assistant neither invokes nor
  mentions the FirstSpirit skills.

Never verify either case by asking the assistant whether the toolkit loaded. The
bootstrap skill instructs it to ignore the toolkit and not mention it when the
task is not FirstSpirit, so a self-report is exactly the question the gate
suppresses — testing has produced a confident "not loaded" with the index fully
loaded. Run the hook directly, or ask a real FirstSpirit question.

### 6. Update documentation

Add the new harness to the install table in `README.md`.
