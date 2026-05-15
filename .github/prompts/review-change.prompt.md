# Review a NovaModuleTools change

Review a NovaModuleTools change set with emphasis on correctness, maintainability, validation, and workflow safety.

## Required process

1. Start with the highest-risk public command, workflow, or release path in the diff.
2. Compare the changed files against the relevant repository instructions and skills.
3. Check changed `src/**/*.ps1` against `.github/instructions/code-quality-matrix.instructions.md` and `tests/**/*.ps1` against `.github/instructions/testing-policy.instructions.md`.
4. Check changed PowerShell validation flow against `.github/instructions/psscriptanalyzer.instructions.md`; flag direct analyzer usage that bypasses the repository wrapper or repo-approved settings without a clear reason.
5. Check changed `docs/NovaModuleTools/en-US/*.md` against `.github/instructions/platyps-help.instructions.md` when command help was added or updated; flag files that do not follow the `New-MarkdownCommandHelp` / `Update-MarkdownCommandHelp` / `Test-MarkdownCommandHelp` workflow, miss a new public entry point's matching help file, or break the required PlatyPS section structure.
6. Check whether tests, docs, and changelog updates match the change, and flag Nova-managed validation that bypasses `Test-NovaBuild` with direct `Invoke-Pester`.
7. Call out the smallest set of meaningful issues first.
8. Note any missing validation or follow-up work.
9. If the review is returned as Markdown or copy-ready UI text, format it according to the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).

## Repository-specific reminders

- Use `.github/pull_request_template.md` as the review checklist.
- Watch for CLI vs PowerShell wording drift.
- Watch for CodeScene maintainability regressions in tests.
- Treat publish/release automation edits as high-risk even when the diff is small.
- Follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) when the review output is intended to be pasted as Markdown.
