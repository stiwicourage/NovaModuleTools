# Review a {{ProjectName}} change

Review a {{ProjectName}} change set with emphasis on correctness, maintainability, validation, and workflow safety.

## Required process

1. Start with the highest-risk public command, workflow, or release path in the diff.
2. Compare the changed files against the relevant repository instructions and skills.
3. Check whether tests, docs, and changelog updates match the change.
4. Call out the smallest set of meaningful issues first.
5. Note any missing validation or follow-up work.
6. If the review is returned as Markdown or copy-ready UI text, format it according to the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).

## Repository-specific reminders

- Use `.github/pull_request_template.md` as the review checklist.
- Watch for CLI vs PowerShell wording drift.
- Watch for quality tooling maintainability regressions in tests.
- Treat publish/release automation edits as high-risk even when the diff is small.
- Follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) when the review output is intended to be pasted as Markdown.
