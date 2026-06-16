# Review a {{ProjectName}} change

> Invoke with `@.github/prompts/review-change.prompt.md`. Delegates to the `reviewer` agent.

Review a {{ProjectName}} change set with emphasis on correctness, maintainability, validation, and workflow safety. If the diff contains no files matching any checked pattern (no `src/**/*.ps1`, test, or docs files), state explicitly which checks were not applicable and confirm that the remaining checks (changelog, PR template, release automation) were still performed.

## Required process

1. **Before any other action:** always invoke the `skill` tool for `markdown-authoring` before producing output unless the user explicitly requests plain text. This is a blocking requirement. If the `skill` tool for `markdown-authoring` returns an error or is unavailable, stop and report: "Could not load markdown-authoring skill. Review cannot proceed until the skill is available." Do not produce review output without it.
2. Compare the changed files against the relevant repository instructions and skills.
3. If a referenced instructions or skills file cannot be read, stop and report which file is missing before continuing. Do not proceed with the affected check using assumed content.
4. Start with the highest-risk public command, workflow, or release path in the diff.
5. Check changed `src/**/*.ps1` against `.github/instructions/code-quality-matrix.instructions.md` and `tests/**/*.ps1` against `.github/instructions/testing-policy.instructions.md`.
6. Check changed PowerShell validation flow against `.github/instructions/psscriptanalyzer.instructions.md`; flag direct analyzer usage that bypasses the repository wrapper or repo-approved settings without a clear reason.
7. When command help was added or updated in changed `docs/{{ProjectName}}/en-US/*.md`, check those files against `.github/instructions/platyps-help.instructions.md`.
8. Verify changed help files follow the `New-MarkdownCommandHelp` / `Update-MarkdownCommandHelp` / `Test-MarkdownCommandHelp` workflow.
9. Confirm every new public entry point has a matching help file.
10. Confirm required PlatyPS section structure is intact.
11. Check whether tests, docs, and changelog updates match the change, and flag Nova-managed validation that bypasses `Invoke-NovaTest` or `Test-NovaBuild` with direct `Invoke-Pester`.
12. List the top 3-5 highest-severity issues first, each with a one-sentence rationale for its priority ranking.
13. Note any missing validation or follow-up work.

## Repository-specific reminders

- Use `.github/pull_request_template.md` as the review checklist.
- Watch for CLI vs PowerShell wording drift.
- Watch for quality tooling maintainability regressions in tests.
- Treat publish/release automation edits as high-risk even when the diff is small.
