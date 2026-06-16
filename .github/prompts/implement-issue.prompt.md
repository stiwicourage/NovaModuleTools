# Implement NovaModuleTools issue

> Invoke with `@.github/prompts/implement-issue.prompt.md`. Delegates to the `powershell-developer` agent.

Implement the issue in the NovaModuleTools repository using the repository-local instructions and skills.

## Required inputs

- Issue number or issue text
- If the issue number cannot be resolved, the issue text is insufficient to determine scope, or the issue appears already implemented, stop and ask the user to clarify before proceeding. Do not attempt to infer intent from a missing or unresolvable issue.
- Relevant files or failing behavior
- `$GIT_BRANCH_NAME` when a commit message suggestion is needed
- If a commit message is requested but `$GIT_BRANCH_NAME` was not provided, generate the commit message without a ticket number suffix and note that the branch name was not available. Do not omit the commit message or halt.

## Required process

1. Read `README.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, and `.github/pull_request_template.md`.
2. If scope, acceptance criteria, or ownership are still unclear after that initial read, start with `.github/prompts/design-change.prompt.md` and `architect.agent.md` before implementing.
3. Identify which public command(s) are directly implicated by the issue. Inspect those commands, their private helper files in the matching subdirectory under `src/private/`, their Pester test files, and their help docs. If no single command is implicated, inspect all files referenced in the issue body.
4. If the issue is release-, workflow-, or coverage-related, also inspect the matching `.github/workflows/*.yml` and `scripts/build/ci/*.ps1` files.
5. Preserve the Nova build model: use `project.json` and Nova commands for build/test/package/release behavior, and do not create hand-written source `.psm1` or module `.psd1` files.
6. Inspect `project.json` `Manifest.PowerShellHostVersion` before changing PowerShell code, tests, or examples, and keep the implementation compatible with that target.
7. Implement the smallest maintainable fix.
8. Implementation phase: use `.github/instructions/code-quality-matrix.instructions.md` for changed source/helper scripts and `.github/instructions/testing-policy.instructions.md` for changed tests. Apply the short, single-purpose, low-duplication, easy-to-scan quality rules to any file where more than about 20% of lines are added or modified. The scope justifies an exception only when the issue text or an accepted design document explicitly states that a larger or more complex implementation is required.
9. During implementation, follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1`, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repository-approved settings.
10. During implementation, do not add PSScriptAnalyzer excluded rules, suppressions, or ad hoc analyzer settings that hide findings; fix analyzer findings in the code.
11. During implementation, keep file/function ownership explicit: one externally called function per file, with private-file extras limited to related same-file top-level support helpers, keep the file name aligned to the entry function, and do not declare functions inside functions.
12. During implementation, add or update the matching source-mirrored Pester file for every changed `src/**/*.ps1` file. If the behavior under test requires a fully built and imported module, depends on the interaction of three or more distinct source files, or cannot be isolated with mocks without rewriting the implementation, it qualifies as cross-cutting. In that case, document in the test file which integration or guardrail test covers it and why unit isolation is impractical.
13. During implementation, for public commands, keep unit coverage in `tests/public/<Command>.Tests.ps1` and keep per-command integration ownership in `tests/public/<Command>.Integration.Tests.ps1` when built-module behavior itself needs validation. For destructive or environment-coupled public commands, prefer safe `-WhatIf` integration coverage when that still proves `ShouldProcess`, routing, and output behavior.
14. During implementation, add or update valid PlatyPS-compatible help under `docs/NovaModuleTools/en-US/` when public commands or public classes change. Use `New-MarkdownCommandHelp` for new help, `Update-MarkdownCommandHelp` after command-surface changes, and `Test-MarkdownCommandHelp` before handoff; do not replace command help with plain Markdown prose.
15. During implementation, for every new public entry point, create its matching help file immediately in the same change.
16. Pre-handoff verification phase: after completing all implementation steps, run the pre-handoff verification pass over every file touched during implementation, including files added in earlier steps.
17. In that verification phase, if `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before handoff instead of only reporting the failure.
18. In that verification phase, review every changed or generated text file and normalize it to exactly one trailing newline with no extra blank lines at the bottom.
19. In that verification phase, validate Nova-managed project tests through `Invoke-NovaTest` for unit validation and `Test-NovaBuild` for build-validation integration validation; do not call `Invoke-Pester` directly because it can bypass Nova's build/import/StrictMode flow.
20. If `Invoke-NovaTest` or `Test-NovaBuild` reports test failures, fix the failures before handoff. Do not summarize or hand off with known failing tests. If a failure is pre-existing and unrelated to the current change, document it explicitly in the handoff summary with the test name and a brief explanation of why it is out of scope.
21. Review `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `RELEASE_NOTE.md`, help docs, and `docs/*.html` as applicable.
22. If a commit message is requested, derive it from `$GIT_BRANCH_NAME` and the implemented change using the repository's Conventional Commit rules.
23. If the summary will be returned as Markdown or copy-ready UI output, invoke the `markdown-authoring` skill before producing that final summary and format the handoff accordingly.
24. Run the relevant validation, then summarize what changed, why, and how it was verified.

## Repository-specific reminders

- Keep PowerShell cmdlet UX and `nova` CLI UX distinct.
- Do not silently bypass warnings or release safeguards.
- Prefer reuse of existing helpers and test-support files over duplication.
- Follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) when the issue summary or final handoff is intended to be pasted as Markdown.
- Commit message suggestions must:
    - be in English
    - use Conventional Commit format
    - extract the ticket number from `$GIT_BRANCH_NAME` and format it as `(#<number>)` when available
    - force `fix` / `fix!` when `$GIT_BRANCH_NAME` starts with `hotfix/` or `bug/`
    - otherwise estimate `feat`, `fix`, `feat!`, or `fix!` from the actual change
    - stay short and not overly verbose
    - use bullet points when presenting multiple commit message options or multiple grouped changes
