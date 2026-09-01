# Porting to a New Harness

To add support for a new AI coding assistant harness:

## Requirements

1. The harness must be able to inject a skill (or context file) at session start.
2. Skills under `skills/` must be discoverable by the harness.

## Steps

### 1. Add a manifest directory

Create `.<harness>-plugin/` with a `plugin.json`. Minimum fields:

```json
{
  "name": "firstspirit-ai-toolkit",
  "version": "0.1.0",
  "skills": "./skills/"
}
```

### 2. Register the version

Add the new `plugin.json` to `.version-bump.json`:

```json
{ "path": ".<harness>-plugin/plugin.json", "field": "version" }
```

### 3. Wire the bootstrap skill

- **Hook-based harnesses** (Claude Code, Cursor): add a hook entry that calls
  `hooks/run-hook.cmd session-start`. Update `hooks/session-start` to detect
  the harness env var and emit the correct JSON shape.
- **Context-file harnesses** (Gemini CLI): create a context file at the root
  (e.g. `GEMINI.md`) that file-references `skills/using-firstspirit-toolkit/SKILL.md`.

### 4. Add tool mappings

Create `skills/using-firstspirit-toolkit/references/<harness>-tools.md` mapping
abstract skill operations to the harness's real tool names. Reference it from
the bootstrap skill.

### 5. Acceptance test

Open a fresh session with the plugin installed and send:
`"Let's set up a new FirstSpirit project."`

The `setup-project` skill must activate before any code or instructions are generated.

### 6. Update documentation

Add the new harness to the install table in `README.md`.
