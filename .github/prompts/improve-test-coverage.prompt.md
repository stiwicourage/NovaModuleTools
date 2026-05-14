# Improve NovaModuleTools test coverage

Improve changed-code coverage in NovaModuleTools without lowering maintainability.

## Required process

1. Identify the exact uncovered file and line or branch.
2. Read the nearby production code and the most relevant existing test/support files.
3. Place new tests in the source-mirrored path under `tests/` by default: one focused `.Tests.ps1` file per covered `src/**/*.ps1` file.
4. Use an existing guardrail or integration test only when it intentionally owns genuinely cross-cutting behavior, and document that ownership in the handoff.
5. Add the smallest test that proves the missing behavior.
6. If setup is duplicated, refactor the tests before adding more assertions.
7. Re-run the focused tests, then the repository quality loop if code changed.
8. Recheck CodeScene coverage or Code Health if that was the original failure.

## Repository-specific reminders

- Many tests expect a built `dist/NovaModuleTools` module.
- The CI coverage flow writes `artifacts/pester-coverage.cobertura.xml`.
- Do not "fix" coverage by weakening assertions or suppressing CodeScene warnings.
