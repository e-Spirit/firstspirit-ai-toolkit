# Release Notes

## 0.2.0 — 2026-09-15

Skills in this release (each SKILL.md carries the same source commit in its `metadata:` block):

- `firstspirit-api-reference` @ 468d904 (beta)
- `firstspirit-templating-reference` @ a3ac0cf (beta)
- `firstspirit-scripting` @ 3bec7d0 (beta)
- `firstspirit-rest-api` @ 2556131 (beta)
- `firstspirit-external-sync-export` @ 2d55f3c (beta)

Changes since 0.1.0:

- First skill batch (beta): the five skills above replace the category stubs, marked beta and
  registered in the bootstrap Available Skills list.
- `firstspirit-rest-api`: "Set as Start Node" corrected to Page Reference Settings (`filename`,
  `showInSitemap`); List Resolutions added; `scripts/claim-coverage.md` ships with the smoke test;
  the smoke test writes `results/firstspirit-rest-api/<run>/` and appends a run line to `logs/`.
- `firstspirit-external-sync-export`: findings from a second FirstSpirit Cloud environment
  (client build-number mismatch, launcher JRE 21 or 25); the fs-cli wrapper keeps each run's
  redacted output under `results/` and appends a run line to `logs/`.
- `firstspirit-scripting`: the `DataProvider` / `IDProvider` trap table is inlined; the pointer to
  an unpublished operations catalogue is replaced by the Javadoc packages.
- All skills: references to skills that are not in this toolkit (template design, module
  development, headless, Cloud, operations) are rewritten as generic pointers, so no skill sends
  the user to something not installed; every SKILL.md carries a provenance stamp
  (`metadata: source-commit / published / toolkit-version`) — quote it when reporting an issue.


## 0.1.0 — 2026-09-01

Initial scaffold. Platform manifests for Claude Code, GitHub Copilot, Codex App,
Gemini CLI, and Cursor. Conditional session-start bootstrap, skill index, and
five domain-category stub skills. Version management, linting, and CI scripts
included.
