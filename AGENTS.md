# FirstSpirit AI Toolkit — Contributor Guide

This repo contains skills and platform manifests for building FirstSpirit CMS
projects with AI coding assistants.

## Prerequisites

- `jq` (`brew install jq` / `apt install jq`) — required by `bump-version.sh`,
  `test-manifests.sh`, and `test-hooks.sh`.
- `shellcheck` (`brew install shellcheck`) — required by the CI lint step.

`lint-skills.sh` needs neither.

## Adding a Skill

1. Choose the right category under `skills/`. Three exist today — `templating/`,
   `project/`, `deployment/` — and `content/` and `diagnostics/` are reserved for
   future skills; create one when you add its first skill. The linter does not
   check categories, so this is a convention, not a validated rule.
2. Create a new directory named after your skill. The name must be lowercase
   kebab-case — `a-z`, `0-9`, and hyphens only. Uppercase letters and underscores
   are rejected.
3. Add a `SKILL.md` file with this frontmatter. The `name` field must match the
   directory name **exactly** — CI fails on any mismatch.

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
   the relevant category section. **CI does not check this** — the linter only
   validates that the bootstrap index and its `references/*.md` files link each
   other. A skill missing from the index still passes, and no harness will find
   it. Do not rely on the linter to catch this.
7. Run `./scripts/lint-skills.sh` to verify the frontmatter rules in steps 2-4.

## Version Management

All platform manifest versions must stay in sync. To bump:

```bash
./scripts/bump-version.sh 0.2.0
```

To verify consistency (also runs in CI):

```bash
./scripts/bump-version.sh --check
```

To find version strings elsewhere in the repo that the manifests don't declare:

```bash
./scripts/bump-version.sh --audit
```

## Running CI Checks Locally

```bash
./scripts/lint-skills.sh          # validate all SKILL.md files and the bootstrap index
./scripts/bump-version.sh --check # check version consistency
./scripts/test-manifests.sh       # validate the platform manifests
./scripts/test-hooks.sh           # test session-start gating and per-harness output
shellcheck --severity=warning hooks/session-start hooks/run-hook.cmd scripts/*.sh scripts/lib/*.sh
```