# Improve NovaModuleTools test coverage

Improve changed-code coverage in NovaModuleTools without lowering maintainability.

## Required process

1. Identify the exact uncovered file and line or branch.
2. Read the nearby production code and the most relevant existing test/support files.
3. Place new tests in the source-mirrored path under `tests/` by default: one focused `.Tests.ps1` file per covered `src/**/*.ps1` file.
4. Use an existing guardrail or integration test only when it intentionally owns genuinely cross-cutting behavior, and document that ownership in the handoff.
5. Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort test-code matrix; keep new or heavily changed tests within the warning thresholds unless the scope explicitly justifies otherwise.
6. Follow `.github/instructions/psscriptanalyzer.instructions.md` when test code or test helpers change. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` for repo-standard analyzer runs, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings.
7. Add the smallest test that proves the missing behavior.
8. If setup is duplicated, refactor the tests before adding more assertions.
9. Re-run the focused tests, then the repository quality loop if code changed.
10. Recheck CodeScene coverage or Code Health if that was the original failure.

## Repository-specific reminders

- Many tests expect a built `dist/NovaModuleTools` module.
- The CI coverage flow writes `artifacts/pester-coverage.cobertura.xml`.
- Do not "fix" coverage by weakening assertions or suppressing CodeScene warnings.
