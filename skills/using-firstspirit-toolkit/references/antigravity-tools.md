# Antigravity CLI (`agy`) Tool Mappings

When a skill mentions these abstract operations, use the corresponding Antigravity CLI tool:

| Abstract operation | Antigravity CLI tool |
|--------------------|----------------------|
| Read a file | `read_file` |
| Edit a file | `replace_file_content` / `multi_replace_file_content` |
| Write a new file | `write_to_file` |
| Run a shell command | `run_shell_command` |
| Search the web | `google_search` |
| Fetch a URL | `fetch_url` |
| Dispatch a subagent | `invoke_subagent` with `TypeName: "self"` (full-capability) or `"research"` (read-only) |

## Task tracking

Antigravity has **no todo tool** (`manage_task` manages background processes — `list` / `kill` / `status` / `send_input` — it is *not* a checklist). When a skill says to create a todo list or track tasks, maintain a **task artifact**: a markdown checklist saved with `write_to_file` (`IsArtifact: true`, `ArtifactMetadata.ArtifactType: "task"`), edited with `replace_file_content` / `multi_replace_file_content` as you go.

At the start of any multi-step task, create the task artifact listing every step of your plan. As you complete each step, edit the artifact to mark it done (`- [x]`). If the plan changes, update the checklist. Keep it current — it is your source of truth for what remains.
