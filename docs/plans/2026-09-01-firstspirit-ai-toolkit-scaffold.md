# FirstSpirit AI Toolkit — Scaffold Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create the complete file and directory scaffold for the `firstspirit-ai-toolkit` repository, ready for FirstSpirit-specific skills to be added.

**Architecture:** Mirror the Superpowers plugin structure with platform manifests for Claude Code, Codex App, Gemini CLI, and Cursor; a categorised `skills/` directory with a session-start bootstrap skill; a `mcp-servers/` stub for the FirstSpirit REST API; and version management and CI scripts.

**Tech Stack:** Bash (scripts and hooks), JSON (manifests), Markdown (skills and docs), TypeScript (MCP server stub, Node.js 18+), jq (version bump script dependency)

**Spec:** `docs/specs/2026-09-01-firstspirit-ai-toolkit-design.md`

## Global Constraints

- Package name: `firstspirit-ai-toolkit`, version `0.1.0`, MIT license
- Author: `Guy Brown <guy.brown@rezolve.com>`
- All SKILL.md `description` fields must start with `"Use when"`
- All shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, LF line endings
- All JSON: 2-space indentation, no trailing commas
- MCP server scope: `@firstspirit-ai-toolkit/`
- jq is a runtime dependency of `bump-version.sh` — document it in README
- No npm dependencies at the skills layer; only the MCP server stub uses npm

---

### Task 1: Repository init and root config files

**Files:**
- Create: `package.json`
- Create: `LICENSE`
- Create: `.gitignore`
- Create: `.gitattributes`
- Create: `.pre-commit-config.yaml`
- Create: `RELEASE-NOTES.md`
- Create: `CODE_OF_CONDUCT.md`

**Interfaces:**
- Produces: npm package identity (`name`, `version`, `scripts`) consumed by Tasks 2, 3, 8

- [ ] **Step 1: Initialise the repo**

```bash
cd /Users/guybrown/Projects/firstspirit-agentic-cms
git init
```

- [ ] **Step 2: Create package.json**

```json
{
  "name": "firstspirit-ai-toolkit",
  "version": "0.1.0",
  "type": "module",
  "description": "Skills and tools for building and managing FirstSpirit CMS projects with AI",
  "license": "MIT",
  "author": {
    "name": "Guy Brown",
    "email": "guy.brown@rezolve.com"
  },
  "keywords": [
    "firstspirit",
    "cms",
    "skills",
    "agentic",
    "ai-toolkit",
    "claude",
    "codex",
    "gemini"
  ],
  "scripts": {
    "bump": "./scripts/bump-version.sh",
    "lint": "./scripts/lint-skills.sh",
    "check-versions": "./scripts/bump-version.sh --check"
  },
  "repository": {
    "type": "git",
    "url": "https://github.com/guybrown/firstspirit-ai-toolkit"
  }
}
```

- [ ] **Step 3: Create LICENSE (MIT)**

```
MIT License

Copyright (c) 2026 Guy Brown

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

- [ ] **Step 4: Create .gitignore**

```
node_modules/
dist/
*.log
.DS_Store
.env
evals/
coverage/
*.tsbuildinfo
```

- [ ] **Step 5: Create .gitattributes**

```
* text=auto
*.sh text eol=lf
hooks/session-start text eol=lf
hooks/run-hook.cmd text eol=lf
scripts/*.sh text eol=lf
```

- [ ] **Step 6: Create .pre-commit-config.yaml**

```yaml
repos:
  - repo: local
    hooks:
      - id: lint-skills
        name: Lint skills
        entry: ./scripts/lint-skills.sh
        language: script
        pass_filenames: false
        always_run: true
```

- [ ] **Step 7: Create RELEASE-NOTES.md**

```markdown
# Release Notes

## 0.1.0 — 2026-09-01

Initial scaffold. Platform manifests for Claude Code, Codex App, Gemini CLI,
and Cursor. Bootstrap skill, five domain-category stub skills, and MCP server
stub for the FirstSpirit REST API. Version management and CI scripts included.
```

- [ ] **Step 8: Create CODE_OF_CONDUCT.md**

```markdown
# Contributor Covenant Code of Conduct

## Our Pledge

We as members, contributors, and leaders pledge to make participation in our
community a harassment-free experience for everyone, regardless of age, body
size, visible or invisible disability, ethnicity, sex characteristics, gender
identity and expression, level of experience, education, socio-economic status,
nationality, personal appearance, race, caste, color, religion, or sexual
identity and orientation.

## Our Standards

Examples of behavior that contributes to a positive environment:
- Using welcoming and inclusive language
- Being respectful of differing viewpoints and experiences
- Gracefully accepting constructive criticism
- Focusing on what is best for the community

Examples of unacceptable behavior:
- Trolling, insulting or derogatory comments, and personal or political attacks
- Public or private harassment
- Publishing others' private information without explicit permission

## Enforcement

Instances of abusive, harassing, or otherwise unacceptable behavior may be
reported to guy.brown@rezolve.com. All complaints will be reviewed and
investigated promptly and fairly.

This Code of Conduct is adapted from the [Contributor Covenant](https://www.contributor-covenant.org), version 2.1.
```

- [ ] **Step 9: Verify and commit**

```bash
git add package.json LICENSE .gitignore .gitattributes .pre-commit-config.yaml RELEASE-NOTES.md CODE_OF_CONDUCT.md
git status   # confirm only these 7 files are staged
git commit -m "chore: initialise repo with root config and identity files"
```

---

### Task 2: Platform manifests and version sync config

**Files:**
- Create: `.claude-plugin/plugin.json`
- Create: `.claude-plugin/marketplace.json`
- Create: `.codex-plugin/plugin.json`
- Create: `.cursor-plugin/plugin.json`
- Create: `gemini-extension.json`
- Create: `.version-bump.json`

**Interfaces:**
- Consumes: package identity from Task 1 (`name`, `version`, `author`)
- Produces: manifest files consumed by Task 3 (bump script) and Task 5 (hooks)

- [ ] **Step 1: Create .claude-plugin/plugin.json**

```bash
mkdir -p .claude-plugin
```

```json
{
  "name": "firstspirit-ai-toolkit",
  "description": "Skills and tools for building and managing FirstSpirit CMS projects with AI",
  "version": "0.1.0",
  "author": {
    "name": "Guy Brown",
    "email": "guy.brown@rezolve.com"
  },
  "homepage": "https://github.com/guybrown/firstspirit-ai-toolkit",
  "repository": "https://github.com/guybrown/firstspirit-ai-toolkit",
  "license": "MIT",
  "keywords": [
    "firstspirit",
    "cms",
    "skills",
    "agentic",
    "ai-toolkit"
  ]
}
```

- [ ] **Step 2: Create .claude-plugin/marketplace.json**

```json
{
  "name": "firstspirit-ai-toolkit",
  "owner": {
    "name": "Guy Brown",
    "email": "guy.brown@rezolve.com"
  },
  "plugins": [
    {
      "name": "firstspirit-ai-toolkit",
      "version": "0.1.0",
      "source": "./"
    }
  ]
}
```

- [ ] **Step 3: Create .codex-plugin/plugin.json**

```bash
mkdir -p .codex-plugin
```

```json
{
  "name": "firstspirit-ai-toolkit",
  "displayName": "FirstSpirit AI Toolkit",
  "description": "Skills and tools for building and managing FirstSpirit CMS projects with AI",
  "version": "0.1.0",
  "author": {
    "name": "Guy Brown",
    "email": "guy.brown@rezolve.com"
  },
  "license": "MIT",
  "homepage": "https://github.com/guybrown/firstspirit-ai-toolkit",
  "skills": "./skills/",
  "brandColor": "#0066CC",
  "defaultPrompt": "You are working in a FirstSpirit CMS project. Use the firstspirit-ai-toolkit skills to assist with content management, templating, project setup, deployment, and diagnostics.",
  "capabilities": [
    "skills"
  ],
  "sessionStart": {
    "skill": "using-firstspirit-toolkit"
  },
  "keywords": [
    "firstspirit",
    "cms",
    "skills",
    "agentic"
  ]
}
```

- [ ] **Step 4: Create .cursor-plugin/plugin.json**

```bash
mkdir -p .cursor-plugin
```

```json
{
  "name": "firstspirit-ai-toolkit",
  "displayName": "FirstSpirit AI Toolkit",
  "description": "Skills and tools for building and managing FirstSpirit CMS projects with AI",
  "version": "0.1.0",
  "skills": "./skills/",
  "hooks": "./hooks/hooks-cursor.json"
}
```

- [ ] **Step 5: Create gemini-extension.json**

```json
{
  "name": "firstspirit-ai-toolkit",
  "description": "Skills and tools for building and managing FirstSpirit CMS projects with AI",
  "version": "0.1.0",
  "contextFileName": "GEMINI.md"
}
```

- [ ] **Step 6: Create .version-bump.json**

```json
{
  "files": [
    { "path": "package.json", "field": "version" },
    { "path": ".claude-plugin/plugin.json", "field": "version" },
    { "path": ".claude-plugin/marketplace.json", "field": "plugins.0.version" },
    { "path": ".codex-plugin/plugin.json", "field": "version" },
    { "path": ".cursor-plugin/plugin.json", "field": "version" },
    { "path": "gemini-extension.json", "field": "version" }
  ],
  "audit": {
    "exclude": [
      "CHANGELOG.md",
      "RELEASE-NOTES.md",
      "node_modules",
      "docs",
      "mcp-servers",
      "evals"
    ]
  }
}
```

- [ ] **Step 7: Validate all JSON files**

```bash
for f in .claude-plugin/plugin.json .claude-plugin/marketplace.json \
          .codex-plugin/plugin.json .cursor-plugin/plugin.json \
          gemini-extension.json .version-bump.json; do
  jq . "$f" > /dev/null && echo "OK: $f" || echo "INVALID: $f"
done
```

Expected: six `OK:` lines, no `INVALID:` lines.

- [ ] **Step 8: Commit**

```bash
git add .claude-plugin/ .codex-plugin/ .cursor-plugin/ gemini-extension.json .version-bump.json
git commit -m "chore: add platform manifests and version sync config"
```

---

### Task 3: Version bump script

**Files:**
- Create: `scripts/bump-version.sh`

**Interfaces:**
- Consumes: `.version-bump.json` (Task 2), manifest files (Task 2)
- Produces: `./scripts/bump-version.sh --check` exits 0 when all versions match

- [ ] **Step 1: Create scripts/bump-version.sh**

```bash
mkdir -p scripts
```

Write `scripts/bump-version.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG="$REPO_ROOT/.version-bump.json"

usage() {
  echo "Usage:"
  echo "  $0 <new-version>  — bump all tracked manifest versions"
  echo "  $0 --check        — report all versions; exit 1 on drift"
  echo "  $0 --audit        — grep repo for undeclared version strings"
}

# Convert dot-path like "plugins.0.version" to jq path ".plugins[0].version"
to_jq_path() {
  echo ".$1" | sed 's/\.\([0-9][0-9]*\)/[\1]/g'
}

get_version() {
  local file="$1" field="$2"
  local jq_path
  jq_path="$(to_jq_path "$field")"
  jq -r "$jq_path" "$REPO_ROOT/$file" 2>/dev/null || echo "NOT_FOUND"
}

set_version() {
  local file="$1" field="$2" new_ver="$3"
  local jq_path tmp
  jq_path="$(to_jq_path "$field")"
  tmp="$(mktemp)"
  jq "$jq_path = \"$new_ver\"" "$REPO_ROOT/$file" > "$tmp"
  mv "$tmp" "$REPO_ROOT/$file"
}

CMD="${1:-}"

case "$CMD" in
  --check)
    echo "Checking version consistency..."
    first_ver=""
    drift=0
    while IFS= read -r entry; do
      file="$(echo "$entry" | jq -r '.path')"
      field="$(echo "$entry" | jq -r '.field')"
      ver="$(get_version "$file" "$field")"
      printf "  %-45s %s\n" "$file ($field)" "$ver"
      if [ -z "$first_ver" ]; then
        first_ver="$ver"
      elif [ "$ver" != "$first_ver" ]; then
        echo "  ERROR: drift in $file — expected $first_ver, got $ver"
        drift=1
      fi
    done < <(jq -c '.files[]' "$CONFIG")
    if [ "$drift" -eq 0 ]; then
      echo "All versions consistent: $first_ver"
    else
      exit 1
    fi
    ;;

  --audit)
    current_ver="$(jq -r '.version' "$REPO_ROOT/package.json")"
    echo "Auditing for undeclared occurrences of $current_ver..."
    mapfile -t excludes < <(jq -r '.audit.exclude[]' "$CONFIG")
    exclude_args=()
    for exc in "${excludes[@]}"; do
      exclude_args+=(--exclude-dir="$exc" --exclude="$exc")
    done
    grep -r "$current_ver" "$REPO_ROOT" \
      "${exclude_args[@]}" \
      --include="*.json" --include="*.yaml" --include="*.yml" \
      --include="*.md" \
      -l 2>/dev/null || echo "No undeclared occurrences found."
    ;;

  ""|--*)
    usage
    exit 1
    ;;

  *)
    NEW_VER="$CMD"
    echo "Bumping all versions to $NEW_VER..."
    while IFS= read -r entry; do
      file="$(echo "$entry" | jq -r '.path')"
      field="$(echo "$entry" | jq -r '.field')"
      set_version "$file" "$field" "$NEW_VER"
      echo "  Updated $file ($field) → $NEW_VER"
    done < <(jq -c '.files[]' "$CONFIG")
    echo "Done. Verify with: ./scripts/bump-version.sh --check"
    ;;
esac
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/bump-version.sh
```

- [ ] **Step 3: Run --check and verify it passes**

```bash
./scripts/bump-version.sh --check
```

Expected output: six lines each showing `0.1.0`, then `All versions consistent: 0.1.0`.

- [ ] **Step 4: Commit**

```bash
git add scripts/bump-version.sh
git commit -m "chore: add version bump script"
```

---

### Task 4: Hook system

**Files:**
- Create: `hooks/hooks.json`
- Create: `hooks/hooks-cursor.json`
- Create: `hooks/run-hook.cmd`
- Create: `hooks/session-start`

**Interfaces:**
- Consumes: `skills/using-firstspirit-toolkit/SKILL.md` at runtime (created in Task 6)
- Produces: Session-start hooks that Claude Code and Cursor fire on `SessionStart`

- [ ] **Step 1: Create hooks/hooks.json (Claude Code format)**

```bash
mkdir -p hooks
```

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "\"${CLAUDE_PLUGIN_ROOT}/hooks/run-hook.cmd\" session-start",
            "shell": "bash",
            "async": false
          }
        ]
      }
    ]
  }
}
```

- [ ] **Step 2: Create hooks/hooks-cursor.json (Cursor format)**

```json
{
  "version": 1,
  "hooks": {
    "sessionStart": [
      {
        "command": "./hooks/run-hook.cmd session-start"
      }
    ]
  }
}
```

- [ ] **Step 3: Create hooks/run-hook.cmd**

```bash
#!/usr/bin/env bash
set -euo pipefail
HOOK_NAME="${1:-}"
if [ -z "$HOOK_NAME" ]; then
  echo "Usage: run-hook.cmd <hook-name>" >&2
  exit 1
fi
HOOKS_DIR="$(cd "$(dirname "$0")" && pwd)"
exec "$HOOKS_DIR/$HOOK_NAME"
```

- [ ] **Step 4: Create hooks/session-start**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PLUGIN_ROOT="$(dirname "$SCRIPT_DIR")"
SKILL_FILE="$PLUGIN_ROOT/skills/using-firstspirit-toolkit/SKILL.md"

if [ ! -f "$SKILL_FILE" ]; then
  echo '{"additionalContext":"FirstSpirit AI Toolkit: bootstrap skill not found."}' 
  exit 0
fi

SKILL_CONTENT="$(cat "$SKILL_FILE")"

if [ -n "${CLAUDE_PLUGIN_ROOT:-}" ]; then
  # Claude Code expects this shape
  jq -n --arg content "$SKILL_CONTENT" \
    '{hookSpecificOutput: {hookEventName: "SessionStart", additionalContext: $content}}'
elif [ -n "${CURSOR_PLUGIN_ROOT:-}" ]; then
  # Cursor expects this shape
  jq -n --arg content "$SKILL_CONTENT" \
    '{additional_context: $content}'
else
  # Generic fallback for unknown harnesses
  jq -n --arg content "$SKILL_CONTENT" \
    '{additionalContext: $content}'
fi
```

- [ ] **Step 5: Make hook scripts executable**

```bash
chmod +x hooks/run-hook.cmd hooks/session-start
```

- [ ] **Step 6: Smoke-test the session-start script (Claude Code shape)**

```bash
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/session-start | jq .hookSpecificOutput.hookEventName
```

Expected: the skill file doesn't exist yet (Task 6 creates it), so output is:
```
{"additionalContext":"FirstSpirit AI Toolkit: bootstrap skill not found."}
```
That is the correct fallback — confirm the script exits 0.

- [ ] **Step 7: Commit**

```bash
git add hooks/
git commit -m "chore: add SessionStart hook system for Claude Code and Cursor"
```

---

### Task 5: Agent instruction files and README

**Files:**
- Create: `CLAUDE.md`
- Create: `AGENTS.md`
- Create: `GEMINI.md`
- Create: `README.md`

**Interfaces:**
- Consumes: package identity from Task 1, manifest structure from Task 2
- Produces: GEMINI.md file-reference consumed by Gemini CLI (bootstraps the toolkit skill for Gemini users)

- [ ] **Step 1: Create CLAUDE.md**

```markdown
# FirstSpirit AI Toolkit — Contributor Guide

This repo contains skills, MCP server stubs, and platform manifests for building
FirstSpirit CMS projects with AI coding assistants.

## Adding a Skill

1. Choose the right category under `skills/`: `content/`, `templating/`, `project/`,
   `deployment/`, or `diagnostics/`.
2. Create a new directory named after your skill (letters, numbers, hyphens only).
3. Add a `SKILL.md` file with this frontmatter:

```yaml
---
name: your-skill-name
description: "Use when [specific triggering conditions]."
---
```

4. The `description` field must start with `"Use when"` — this is validated by CI.
5. Add your skill's instructions in the Markdown body.
6. Update `skills/using-firstspirit-toolkit/SKILL.md` to mention your new skill in
   the relevant category section.
7. Run `./scripts/lint-skills.sh` to verify.

## Adding an MCP Server

1. Create a new directory under `mcp-servers/` named after the server.
2. Initialise an npm package: `npm init -y` then set `"name"` to
   `@firstspirit-ai-toolkit/mcp-<server-name>`.
3. Add the MCP SDK: `npm install @modelcontextprotocol/sdk`.
4. Create `src/index.ts` with your server entry point.
5. Document wire-up in the server's own `README.md` and in the root `mcp-servers/README.md`.

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
./scripts/lint-skills.sh          # validate all SKILL.md files
./scripts/bump-version.sh --check # check version consistency
```

## Publishing

```bash
npm publish --access public
```

MCP server sub-packages are published independently from their own directories.
```

- [ ] **Step 2: Create AGENTS.md (identical content to CLAUDE.md)**

Copy the content of `CLAUDE.md` verbatim to `AGENTS.md` — the two files serve the same purpose for different harnesses.

- [ ] **Step 3: Create GEMINI.md**

```
@./skills/using-firstspirit-toolkit/SKILL.md
@./skills/using-firstspirit-toolkit/references/gemini-tools.md
```

Note: Gemini CLI has no hook system. `GEMINI.md` is its bootstrap mechanism — it file-references the skill directly. The `@` prefix is Gemini CLI's include syntax.

- [ ] **Step 4: Create README.md**

```markdown
# FirstSpirit AI Toolkit

Skills, agents, and MCP servers for building and managing [FirstSpirit CMS](https://www.crownpeak.com/products/crownpeak-dxp) projects with AI coding assistants.

## Install

### Claude Code

```bash
/plugin install firstspirit-ai-toolkit
```

Or via self-hosted marketplace:

```bash
/plugin marketplace add guybrown/firstspirit-ai-toolkit-marketplace
/plugin install firstspirit-ai-toolkit
```

### Codex App

```
plugin install firstspirit-ai-toolkit
```

### Gemini CLI

```bash
gemini extension add firstspirit-ai-toolkit
```

### Cursor

Install via the Cursor plugin marketplace or manually reference `.cursor-plugin/`.

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

### MCP Servers

| Server | Package | Purpose |
|--------|---------|---------|
| `firstspirit-api` | `@firstspirit-ai-toolkit/mcp-firstspirit-api` | FirstSpirit REST API tools |

Wire up the MCP server in your project:

```bash
claude mcp add firstspirit-api -- npx @firstspirit-ai-toolkit/mcp-firstspirit-api
```

Set environment variables:
- `FS_URL` — FirstSpirit server URL (e.g. `https://your-server.example.com`)
- `FS_API_KEY` — FirstSpirit API key

## Contributing

See [CLAUDE.md](CLAUDE.md) for contributor guidelines.

## Requirements

- `jq` for the version bump script (`brew install jq` / `apt install jq`)
- Node.js 18+ for MCP servers

## License

MIT © Guy Brown
```

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md AGENTS.md GEMINI.md README.md
git commit -m "docs: add agent instruction files and README"
```

---

### Task 6: Bootstrap skill

**Files:**
- Create: `skills/using-firstspirit-toolkit/SKILL.md`
- Create: `skills/using-firstspirit-toolkit/references/codex-tools.md`
- Create: `skills/using-firstspirit-toolkit/references/cursor-tools.md`
- Create: `skills/using-firstspirit-toolkit/references/gemini-tools.md`

**Interfaces:**
- Produces: `skills/using-firstspirit-toolkit/SKILL.md` consumed by `hooks/session-start` at runtime

- [ ] **Step 1: Create skills/using-firstspirit-toolkit/SKILL.md**

```bash
mkdir -p skills/using-firstspirit-toolkit/references
```

```markdown
---
name: using-firstspirit-toolkit
description: "Use when starting any session that involves FirstSpirit CMS work — establishes what skills are available and when to invoke them."
---

# FirstSpirit AI Toolkit

You have the FirstSpirit AI Toolkit loaded. Before responding or taking action on any FirstSpirit task, check whether a more specific skill applies.

## Rule

If there is even a small chance a skill applies to your task, you MUST invoke it before acting. Check for skills before clarifying questions, before exploring the codebase, before writing code.

## Available Skills

### Content (`skills/content/`)
- **manage-content** — Use when reading, writing, querying, or restructuring content in FirstSpirit content stores or datasets.

### Templating (`skills/templating/`)
- **design-templates** — Use when creating or modifying FirstSpirit page templates, section templates, or link templates.

### Project (`skills/project/`)
- **setup-project** — Use when configuring a new FirstSpirit project, modifying project settings, or managing users and groups.

### Deployment (`skills/deployment/`)
- **publish-content** — Use when triggering generation runs, publishing content to delivery, or managing release workflows.

### Diagnostics (`skills/diagnostics/`)
- **diagnose-project** — Use when troubleshooting FirstSpirit project issues, checking project health, or analysing logs.

## Platform Tool Mappings

If you are running on a harness listed below, read the corresponding reference for how abstract operations map to that harness's real tool names:

- **Codex:** read `skills/using-firstspirit-toolkit/references/codex-tools.md`
- **Cursor:** read `skills/using-firstspirit-toolkit/references/cursor-tools.md`
- **Gemini CLI:** read `skills/using-firstspirit-toolkit/references/gemini-tools.md`

Claude Code users: native tool names match the skill descriptions directly.
```

- [ ] **Step 2: Create references/codex-tools.md**

```markdown
# Codex Tool Mappings

When a skill mentions these abstract operations, use the corresponding Codex tool:

| Abstract operation | Codex tool |
|--------------------|------------|
| Create a todo / task list | `TodoList` |
| Dispatch a subagent | `Agent` |
| Ask the user a question | `AskUserQuestion` |
| Read a file | `Read` |
| Edit a file | `Edit` |
| Run a shell command | `Bash` |
| Search the web | `WebSearch` |
| Fetch a URL | `WebFetch` |
```

- [ ] **Step 3: Create references/cursor-tools.md**

```markdown
# Cursor Tool Mappings

When a skill mentions these abstract operations, use the corresponding Cursor tool:

| Abstract operation | Cursor tool |
|--------------------|-------------|
| Create a todo / task list | Use inline checklists in your response |
| Read a file | `read_file` |
| Edit a file | `edit_file` |
| Run a shell command | `run_terminal_cmd` |
| Search codebase | `codebase_search` |
| Search web | `web_search` |
```

- [ ] **Step 4: Create references/gemini-tools.md**

```markdown
# Gemini CLI Tool Mappings

When a skill mentions these abstract operations, use the corresponding Gemini CLI tool:

| Abstract operation | Gemini CLI tool |
|--------------------|-----------------|
| Create a todo / task list | Use inline checklists in your response |
| Read a file | `read_file` |
| Edit a file | `write_file` / `replace_in_file` |
| Run a shell command | `run_shell_command` |
| Search the web | `google_search` |
| Fetch a URL | `fetch_url` |
```

- [ ] **Step 5: Verify the session-start hook now produces the bootstrap skill content**

```bash
CLAUDE_PLUGIN_ROOT="$(pwd)" bash hooks/session-start | jq -r '.hookSpecificOutput.additionalContext' | head -5
```

Expected: first few lines of `skills/using-firstspirit-toolkit/SKILL.md` printed to stdout.

- [ ] **Step 6: Commit**

```bash
git add skills/using-firstspirit-toolkit/
git commit -m "feat: add bootstrap skill with platform tool mappings"
```

---

### Task 7: Stub skills

**Files:**
- Create: `skills/content/manage-content/SKILL.md`
- Create: `skills/templating/design-templates/SKILL.md`
- Create: `skills/project/setup-project/SKILL.md`
- Create: `skills/deployment/publish-content/SKILL.md`
- Create: `skills/diagnostics/diagnose-project/SKILL.md`

**Interfaces:**
- Consumes: SKILL.md format rules from spec
- Produces: one stub skill per category; each passes `lint-skills.sh`

- [ ] **Step 1: Create skills/content/manage-content/SKILL.md**

```bash
mkdir -p skills/content/manage-content
```

```markdown
---
name: manage-content
description: "Use when reading, writing, querying, or restructuring content in FirstSpirit content stores or datasets."
---

# Manage Content

> **Stub** — Replace this body with FirstSpirit content management instructions.

## When to Use

Use this skill when working with FirstSpirit content stores, datasets, or content creation workflows via the FirstSpirit API or SiteArchitect.

## Instructions

Add FirstSpirit-specific content management instructions here. Reference the
`firstspirit-api` MCP server for programmatic content access.
```

- [ ] **Step 2: Create skills/templating/design-templates/SKILL.md**

```bash
mkdir -p skills/templating/design-templates
```

```markdown
---
name: design-templates
description: "Use when creating or modifying FirstSpirit page templates, section templates, or link templates."
---

# Design Templates

> **Stub** — Replace this body with FirstSpirit template design instructions.

## When to Use

Use this skill when working with FirstSpirit template development: page templates,
section templates, link templates, or template sets in SiteArchitect or ContentCreator.

## Instructions

Add FirstSpirit-specific template design instructions here.
```

- [ ] **Step 3: Create skills/project/setup-project/SKILL.md**

```bash
mkdir -p skills/project/setup-project
```

```markdown
---
name: setup-project
description: "Use when configuring a new FirstSpirit project, modifying project settings, or managing users and groups."
---

# Setup Project

> **Stub** — Replace this body with FirstSpirit project setup instructions.

## When to Use

Use this skill when initialising a new FirstSpirit project, configuring project
properties, or managing project users, groups, and permissions.

## Instructions

Add FirstSpirit-specific project setup instructions here.
```

- [ ] **Step 4: Create skills/deployment/publish-content/SKILL.md**

```bash
mkdir -p skills/deployment/publish-content
```

```markdown
---
name: publish-content
description: "Use when triggering FirstSpirit generation runs, publishing content to delivery, or managing release workflows."
---

# Publish Content

> **Stub** — Replace this body with FirstSpirit publishing instructions.

## When to Use

Use this skill when triggering generation runs, pushing content to delivery
servers, or managing FirstSpirit release schedules.

## Instructions

Add FirstSpirit-specific deployment and publishing instructions here.
```

- [ ] **Step 5: Create skills/diagnostics/diagnose-project/SKILL.md**

```bash
mkdir -p skills/diagnostics/diagnose-project
```

```markdown
---
name: diagnose-project
description: "Use when troubleshooting FirstSpirit project issues, checking project health, or analysing server logs."
---

# Diagnose Project

> **Stub** — Replace this body with FirstSpirit diagnostics instructions.

## When to Use

Use this skill when a FirstSpirit project is behaving unexpectedly, when you
need to check project health, or when analysing server or generation logs.

## Instructions

Add FirstSpirit-specific diagnostic and troubleshooting instructions here.
```

- [ ] **Step 6: Commit**

```bash
git add skills/
git commit -m "feat: add stub skills for all five domain categories"
```

---

### Task 8: Lint script and CI

**Files:**
- Create: `scripts/lint-skills.sh`
- Create: `.github/workflows/ci.yml`
- Create: `.github/pull_request_template.md`

**Interfaces:**
- Consumes: all `SKILL.md` files under `skills/`
- Produces: `./scripts/lint-skills.sh` exits 0 on valid skills, 1 on violations; CI enforces this on every PR

- [ ] **Step 1: Create scripts/lint-skills.sh**

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SKILLS_DIR="$REPO_ROOT/skills"

errors=0
checked=0

while IFS= read -r skill_file; do
  checked=$((checked + 1))
  rel_path="${skill_file#"$REPO_ROOT/"}"

  # Extract frontmatter block (between the first two --- lines)
  frontmatter="$(awk '/^---/{p=!p; next} p{print}' "$skill_file" | head -20)"

  # Check name field
  name="$(echo "$frontmatter" | grep '^name:' | sed 's/^name:[[:space:]]*//' | tr -d '"' | head -1)"
  if [ -z "$name" ]; then
    echo "ERROR [$rel_path]: missing 'name' field in frontmatter"
    errors=$((errors + 1))
  fi

  # Check description field
  description="$(echo "$frontmatter" | grep '^description:' | sed 's/^description:[[:space:]]*//' | tr -d '"' | head -1)"
  if [ -z "$description" ]; then
    echo "ERROR [$rel_path]: missing 'description' field in frontmatter"
    errors=$((errors + 1))
  elif [[ "$description" != "Use when"* ]]; then
    echo "ERROR [$rel_path]: description must start with 'Use when', got: $description"
    errors=$((errors + 1))
  fi

done < <(find "$SKILLS_DIR" -name "SKILL.md" | sort)

echo "Checked $checked skill(s). Errors: $errors"
[ "$errors" -eq 0 ] || exit 1
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/lint-skills.sh
```

- [ ] **Step 3: Run lint and verify all six skills pass**

```bash
./scripts/lint-skills.sh
```

Expected:
```
Checked 6 skill(s). Errors: 0
```

- [ ] **Step 4: Create .github/workflows/ci.yml**

```bash
mkdir -p .github/workflows
```

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  validate:
    name: Validate
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Install jq
        run: sudo apt-get install -y jq

      - name: Check version consistency
        run: ./scripts/bump-version.sh --check

      - name: Lint skills
        run: ./scripts/lint-skills.sh
```

- [ ] **Step 5: Create .github/pull_request_template.md**

```markdown
## Summary

<!-- What does this PR do? -->

## Checklist

- [ ] `./scripts/lint-skills.sh` passes
- [ ] `./scripts/bump-version.sh --check` passes
- [ ] New skills have `description` starting with "Use when"
- [ ] `using-firstspirit-toolkit/SKILL.md` updated if new skills were added
- [ ] Version bumped if this is a release PR (`./scripts/bump-version.sh <version>`)
```

- [ ] **Step 6: Commit**

```bash
git add scripts/lint-skills.sh .github/
git commit -m "chore: add lint script and GitHub Actions CI workflow"
```

---

### Task 9: MCP server stub

**Files:**
- Create: `mcp-servers/README.md`
- Create: `mcp-servers/firstspirit-api/package.json`
- Create: `mcp-servers/firstspirit-api/tsconfig.json`
- Create: `mcp-servers/firstspirit-api/src/index.ts`
- Create: `mcp-servers/firstspirit-api/README.md`

**Interfaces:**
- Produces: `@firstspirit-ai-toolkit/mcp-firstspirit-api` npm package skeleton, ready for tool registration

- [ ] **Step 1: Create mcp-servers/README.md**

```bash
mkdir -p mcp-servers
```

```markdown
# MCP Servers

Each subdirectory is a self-contained MCP server published under the
`@firstspirit-ai-toolkit/` npm scope.

## Servers

| Server | Package | Status |
|--------|---------|--------|
| `firstspirit-api` | `@firstspirit-ai-toolkit/mcp-firstspirit-api` | Stub |

## Adding a New Server

1. Create a directory: `mcp-servers/<server-name>/`
2. Initialise: `cd mcp-servers/<server-name> && npm init -y`
3. Set `"name"` to `@firstspirit-ai-toolkit/mcp-<server-name>` in `package.json`
4. Install the SDK: `npm install @modelcontextprotocol/sdk`
5. Create `src/index.ts` using the boilerplate in `firstspirit-api/src/index.ts`
6. Add the server to the table above
7. Document wire-up in the server's own `README.md`

## Wire-Up (Consumer Projects)

```bash
claude mcp add <server-name> -- npx @firstspirit-ai-toolkit/mcp-<server-name>
```
```

- [ ] **Step 2: Create mcp-servers/firstspirit-api/package.json**

```bash
mkdir -p mcp-servers/firstspirit-api/src
```

```json
{
  "name": "@firstspirit-ai-toolkit/mcp-firstspirit-api",
  "version": "0.1.0",
  "type": "module",
  "description": "MCP server exposing FirstSpirit REST API operations as tools",
  "license": "MIT",
  "author": {
    "name": "Guy Brown",
    "email": "guy.brown@rezolve.com"
  },
  "main": "dist/index.js",
  "scripts": {
    "build": "tsc",
    "start": "node dist/index.js",
    "dev": "tsc --watch"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

- [ ] **Step 3: Create mcp-servers/firstspirit-api/tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

- [ ] **Step 4: Create mcp-servers/firstspirit-api/src/index.ts**

```typescript
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";

const FS_URL = process.env.FS_URL ?? "";
const FS_API_KEY = process.env.FS_API_KEY ?? "";

const server = new Server(
  { name: "firstspirit-api", version: "0.1.0" },
  { capabilities: { tools: {} } }
);

// List available tools
server.setRequestHandler(ListToolsRequestSchema, async () => ({
  tools: [
    // TODO: Register FirstSpirit API tools here.
    // Example shape:
    // {
    //   name: "get_project",
    //   description: "Retrieve a FirstSpirit project by ID",
    //   inputSchema: {
    //     type: "object",
    //     properties: { projectId: { type: "string" } },
    //     required: ["projectId"],
    //   },
    // },
  ],
}));

// Handle tool calls
server.setRequestHandler(CallToolRequestSchema, async (request) => {
  const { name } = request.params;
  throw new Error(`Unknown tool: ${name}`);
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

- [ ] **Step 5: Create mcp-servers/firstspirit-api/README.md**

```markdown
# @firstspirit-ai-toolkit/mcp-firstspirit-api

MCP server that exposes FirstSpirit REST API operations as tools for AI coding assistants.

> **Status: Stub** — No tools are registered yet. This package establishes the
> pattern and wire-up mechanism.

## Wire-Up

In your project:

```bash
claude mcp add firstspirit-api -- npx @firstspirit-ai-toolkit/mcp-firstspirit-api
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `FS_URL` | Yes | FirstSpirit server URL, e.g. `https://your-server.example.com` |
| `FS_API_KEY` | Yes | FirstSpirit API key |

## Development

```bash
npm install
npm run build
npm start
```

## Adding Tools

1. Register the tool in `ListToolsRequestSchema` handler with its `inputSchema`.
2. Add a `case` block in `CallToolRequestSchema` handler to execute it.
3. Use `FS_URL` and `FS_API_KEY` for authenticated REST calls.

## Publishing

```bash
npm publish --access public
```
```

- [ ] **Step 6: Verify package.json is valid JSON**

```bash
jq . mcp-servers/firstspirit-api/package.json > /dev/null && echo "OK"
```

Expected: `OK`

- [ ] **Step 7: Commit**

```bash
git add mcp-servers/
git commit -m "feat: add firstspirit-api MCP server stub"
```

---

### Task 10: Documentation and assets

**Files:**
- Create: `docs/porting-to-a-new-harness.md`
- Create: `docs/writing-skills.md`
- Create: `assets/` placeholder

**Interfaces:**
- Produces: contributor documentation; no code interfaces

- [ ] **Step 1: Create docs/porting-to-a-new-harness.md**

```markdown
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
```

- [ ] **Step 2: Create docs/writing-skills.md**

```markdown
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
```

- [ ] **Step 3: Create assets/ placeholder**

```bash
mkdir -p assets
touch assets/.gitkeep
```

Replace `assets/.gitkeep` with a real `app-icon.png` before submitting to any plugin marketplace.

- [ ] **Step 4: Final verification — run all checks**

```bash
./scripts/lint-skills.sh && ./scripts/bump-version.sh --check
```

Expected:
```
Checked 6 skill(s). Errors: 0
Checking version consistency...
  ...six lines showing 0.1.0...
All versions consistent: 0.1.0
```

- [ ] **Step 5: Final commit**

```bash
git add docs/ assets/
git commit -m "docs: add porting guide, skill authoring guide, and assets placeholder"
```

---

## Self-Review

**Spec coverage check:**

| Spec requirement | Covered by |
|-----------------|------------|
| Claude Code plugin manifest | Task 2 |
| Codex App plugin manifest | Task 2 |
| Cursor plugin manifest | Task 2 |
| Gemini CLI extension | Task 2 |
| .version-bump.json | Task 2 |
| bump-version.sh | Task 3 |
| hook system (Claude Code + Cursor) | Task 4 |
| CLAUDE.md / AGENTS.md / GEMINI.md | Task 5 |
| README with install instructions | Task 5 |
| Bootstrap skill + references/ | Task 6 |
| 5 category stub skills | Task 7 |
| lint-skills.sh | Task 8 |
| CI workflow | Task 8 |
| MCP server stub | Task 9 |
| porting guide + skill authoring guide | Task 10 |

All spec requirements covered. No gaps.
