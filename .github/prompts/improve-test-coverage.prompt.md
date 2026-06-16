# Improve NovaModuleTools test coverage

> Invoke with `@.github/prompts/improve-test-coverage.prompt.md`. Delegates to the `test-engineer` agent.

Improve changed-code coverage in NovaModuleTools without lowering maintainability.

## Required process

1. Identify the exact uncovered file and line or branch.
2. If no uncovered lines or branches are found, report that coverage is already complete and halt. If `artifacts/coverage.xml` is missing or stale, regenerate it by running `Invoke-NovaTest` before proceeding.
3. Read the nearby production code and the most relevant existing test/support files.
4. Place new tests in the source-mirrored path under `tests/` by default: one focused `.Tests.ps1` file per covered `src/**/*.ps1` file. If no corresponding `.Tests.ps1` file exists yet, create it with the standard file header and an empty `Describe` block before adding the first test. Do not add tests to an unrelated existing file.
5. Use an existing guardrail or integration test only when it intentionally owns genuinely cross-cutting behavior. When built-module behavior of a single public command needs validation, use `tests/public/<Command>.Integration.Tests.ps1` instead. For cross-cutting ownership, add a comment at the top of the integration test file in the format `# Cross-cutting owner: <reason>`.
6. Use `.github/instructions/testing-policy.instructions.md` as the test-design source of truth; keep new or heavily changed tests focused, isolated, and easy to scan.
7. Follow `.github/instructions/psscriptanalyzer.instructions.md` when test code or test helpers change. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` for repo-standard analyzer runs, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings.
8. Add the smallest test that proves the missing behavior.
9. If setup is duplicated, refactor the tests before adding more assertions.
10. Validate in this order:
	- Always run `Invoke-NovaTest`.
	- If `Invoke-NovaTest` exits with an error or test failures, stop immediately, report the failure output verbatim, and do not proceed.
	- Run `Test-NovaBuild` only if any `*.Integration.Tests.ps1` file was added, removed, or had its `# Cross-cutting owner: <reason>` comment added or removed.
	- If `Test-NovaBuild` exits with an error or test failures, stop immediately, report the failure output verbatim, and do not proceed.
	- Run the repository quality loop only if any `src/**/*.ps1` production file was modified.
	- Never use `Invoke-Pester` directly for Nova-managed validation.
11. Recheck CodeScene coverage or Code Health if that was the original failure. If the original failure type is not stated in the conversation, recheck CodeScene as the default final step.

## Repository-specific reminders

- Many tests expect a built `dist/NovaModuleTools` module.
- The CI coverage flow writes `artifacts/coverage.xml`.
- Use `Invoke-NovaTest` for unit coverage validation and `Test-NovaBuild` for build-validation integration coverage; direct `Invoke-Pester` can miss Nova-specific strict-mode behavior.
- Keep public command unit coverage in `tests/public/<Command>.Tests.ps1`. Use `tests/public/<Command>.Integration.Tests.ps1` when built-module behavior of that public command needs validation, and reserve existing cross-cutting guardrail or integration tests for behavior that intentionally spans multiple commands or workflows.
- For destructive or environment-coupled public commands, prefer safe `-WhatIf` integration coverage when that still proves `ShouldProcess`, routing, and output behavior.
- Do not "fix" coverage by weakening assertions or suppressing CodeScene warnings.
