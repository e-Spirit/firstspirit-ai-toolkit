# Writing FirstSpirit AI Skills

## SKILL.md Format

```markdown
---
name: skill-name-with-hyphens
description: "Use when [specific triggering conditions]."
---

# Skill Title

## When to Use

[Expand on the triggering conditions. Be specific about what FirstSpirit
operations or user intents this skill handles.]

## Instructions

[Step-by-step guidance for the AI agent. Reference FirstSpirit concepts,
API endpoints, or SiteArchitect/ContentCreator UI paths as needed.]
```

## Rules

- `name`: lowercase kebab-case — `a-z`, `0-9`, and hyphens only. Uppercase
  letters and underscores are rejected. Must match the directory name exactly.
  Both rules are enforced by `./scripts/lint-skills.sh`.
- `description`: must be present, and must make clear when the skill applies.
  CI checks only that it exists, not how it is worded. `"Use when …"` is a good,
  greppable opening for a task-shaped skill; a lookup reference may lead with its
  topic instead (e.g. "Concrete lookup reference for …") and then say when to
  reach for it. What matters is that an agent can decide from the description
  alone whether to open the body.
- One skill per directory.

Keep the frontmatter as short as it can be while still covering the triggers —
every skill's description is loaded into context at session start, so this is
the toolkit's standing token cost. Several shipped skills run well over 1KB
because they enumerate trigger phrases; that is a deliberate trade, not a
target to copy.

## Placement

Put the skill in the category that best describes the FirstSpirit operation:

| Category | Use for | Status |
|----------|---------|--------|
| `templating/` | Page, section, and link templates | in use |
| `project/` | Project config, APIs, scripting, users, groups | in use |
| `deployment/` | Generation runs, publishing, delivery | in use |
| `content/` | Content stores, datasets, content creation | reserved — no skills yet |
| `diagnostics/` | Troubleshooting, health checks, logs | reserved — no skills yet |

The reserved directories do not exist yet; create one when you add its first
skill. Nothing in the tooling enforces this layout — the linter does not check
categories — so it is a convention for humans and agents browsing the tree.

## After Adding a Skill

1. Update `skills/using-firstspirit-toolkit/SKILL.md` — add your skill to the
   correct category section so agents know it exists.
2. Run `./scripts/lint-skills.sh` to validate.
3. Commit and open a PR — CI will re-validate.
