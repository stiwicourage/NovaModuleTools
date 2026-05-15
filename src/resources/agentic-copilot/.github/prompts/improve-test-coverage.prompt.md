# Improve {{ProjectName}} test coverage

Improve changed-code coverage in {{ProjectName}} without lowering maintainability.

## Required process

1. Identify the exact uncovered file and line or branch.
2. Read the nearby production code and the most relevant existing test/support files.
3. Place new tests in the source-mirrored path under `tests/` by default: one focused `.Tests.ps1` file per covered `src/**/*.ps1` file.
4. Use an existing guardrail or integration test only when it intentionally owns genuinely cross-cutting behavior, and document that ownership in the handoff.
5. Use `.github/instructions/testing-policy.instructions.md` as the test-design source of truth; keep new or heavily changed tests focused, isolated, and easy to scan.
6. Follow `.github/instructions/psscriptanalyzer.instructions.md` when test code or test helpers change. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` for repo-standard analyzer runs, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings.
7. Add the smallest test that proves the missing behavior.
8. If setup is duplicated, refactor the tests before adding more assertions.
9. Re-run `Test-NovaBuild`, then the repository quality loop if code changed. Do not validate a Nova-managed project with direct `Invoke-Pester`.
10. Recheck quality tooling coverage or maintainability if that was the original failure.

## Repository-specific reminders

- Many tests expect a built `dist/{{ProjectName}}` module.
- The CI coverage flow writes `artifacts/pester-coverage.cobertura.xml`.
- Use `Test-NovaBuild` as the project test entrypoint; direct `Invoke-Pester` can miss Nova-specific strict-mode behavior.
- Do not "fix" coverage by weakening assertions or suppressing quality tooling warnings.
