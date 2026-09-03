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

## Steps

### 1. Add the harness manifest

Each harness has its own manifest file and shape — they are **not** interchangeable.
Match the harness's own format. Current examples in this repo:

| Harness | Manifest | Bootstrap mechanism |
|---|---|---|
| Claude Code | `.claude-plugin/plugin.json` (skills auto-discovered; no `skills` field) | hook — `hooks/hooks.json` |
| Codex | `.codex-plugin/plugin.json` (`skills`, `sessionStart.skill`, `defaultPrompt`) | manifest `sessionStart.skill` |
| Cursor | `.cursor-plugin/plugin.json` (`skills`, `hooks` pointer) | hook — `hooks/hooks-cursor.json` |
| Gemini CLI | root `gemini-extension.json` (`contextFileName`) | context file — `GEMINI.md` |

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

- **Hook** (Claude Code, Cursor): register a `SessionStart` hook that runs
  `hooks/run-hook.cmd session-start`. Claude uses `hooks/hooks.json`; Cursor uses
  its own `hooks/hooks-cursor.json`. Then add a branch to `hooks/session-start`
  that detects your harness's env var and emits its JSON shape — see the existing
  branches: `CLAUDE_PLUGIN_ROOT` →
  `{hookSpecificOutput:{hookEventName,additionalContext}}`, `CURSOR_PLUGIN_ROOT` →
  `{additional_context}`, default → `{additionalContext}`. You do **not**
  reimplement detection: `session-start` already decides FirstSpirit-or-not and
  tiers the output, so a new hook harness inherits load-time gating for free.
- **Manifest declaration** (Codex): point the manifest at the bootstrap skill, e.g.
  `"sessionStart": { "skill": "using-firstspirit-toolkit" }`. This loads the skill
  **unconditionally** — load-time gating is not available, so behaviour on
  non-FirstSpirit projects relies entirely on the skill's self-gating.
- **Context file** (Gemini CLI): create a root context file (`GEMINI.md`) that
  file-references the bootstrap skill, e.g.
  `@./skills/using-firstspirit-toolkit/SKILL.md`. Also loads unconditionally;
  relies on self-gating.

> `AGENTS.md` is the contributor guide, not a bootstrap file — do not wire the
> bootstrap skill through it.

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

- hook-based harness: only the quiet discoverability line loads; no skill activates;
- unconditional harness (Codex, Gemini): the skill loads but **self-gates** — ask an
  unrelated, non-FirstSpirit question and confirm the assistant neither invokes nor
  mentions the FirstSpirit skills.

### 6. Update documentation

Add the new harness to the install table in `README.md`.
