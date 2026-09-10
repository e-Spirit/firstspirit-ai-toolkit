# FirstSpirit AI Toolkit — Contributor Guide

This repo contains skills and platform manifests for building FirstSpirit CMS
projects with AI coding assistants.

## Adding a Skill

1. Choose the right category under `skills/`: `content/`, `templating/`, `project/`,
   `deployment/`, or `diagnostics/`.
2. Create a new directory named after your skill (letters, numbers, hyphens only).
3. Add a `SKILL.md` file with this frontmatter:

```yaml
---
name: your-skill-name
description: "What the skill covers and when it applies."
---
```

4. The `description` field must be present and make clear when the skill applies.
   Opening with `"Use when …"` is a good, greppable pattern but is **not** required
   — a topic-first description (e.g. "Concrete lookup reference for …") is fine.
   CI checks that a description exists, not its wording.
5. Add your skill's instructions in the Markdown body.
6. Update `skills/using-firstspirit-toolkit/SKILL.md` to mention your new skill in
   the relevant category section.
7. Run `./scripts/lint-skills.sh` to verify.

## Version Management

All platform manifest versions must stay in sync. To bump:

```bash
./scripts/bump-version.sh 0.2.0
```

To verify consistency (also runs in CI):

```bash
./scripts/bump-version.sh --check
```

Requires `jq` to be installed (`brew install jq` / `apt install jq`).

## Running CI Checks Locally

```bash
./scripts/lint-skills.sh          # validate all SKILL.md files and the bootstrap index
./scripts/bump-version.sh --check # check version consistency
./scripts/test-manifests.sh       # validate the platform manifests
./scripts/test-hooks.sh           # test session-start gating and per-harness output
shellcheck --severity=warning hooks/session-start hooks/run-hook.cmd scripts/*.sh scripts/lib/*.sh
```

## Publishing

```bash
npm publish --access public
```
