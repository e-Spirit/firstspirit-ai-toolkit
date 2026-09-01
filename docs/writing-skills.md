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

- `name`: letters, numbers, hyphens only. Must match the directory name.
- `description`: starts with `"Use when"` — triggering conditions ONLY.
  Never summarise the workflow in the description; that causes agents to
  follow the description instead of reading the body.
- Frontmatter max 1024 characters.
- One skill per directory.

## Placement

Put the skill in the category that best describes the FirstSpirit operation:

| Category | Use for |
|----------|---------|
| `content/` | Content stores, datasets, content creation |
| `templating/` | Page, section, and link templates |
| `project/` | Project config, users, groups |
| `deployment/` | Generation runs, publishing, delivery |
| `diagnostics/` | Troubleshooting, health checks, logs |

## After Adding a Skill

1. Update `skills/using-firstspirit-toolkit/SKILL.md` — add your skill to the
   correct category section so agents know it exists.
2. Run `./scripts/lint-skills.sh` to validate.
3. Commit and open a PR — CI will re-validate.
