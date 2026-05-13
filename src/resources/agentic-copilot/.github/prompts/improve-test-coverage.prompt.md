# Improve {{ProjectName}} test coverage

Improve changed-code coverage in {{ProjectName}} without lowering maintainability.

## Required process

1. Identify the exact uncovered file and line or branch.
2. Read the nearby production code and the most relevant existing test/support files.
3. Add the smallest test that proves the missing behavior.
4. If setup is duplicated, refactor the tests before adding more assertions.
5. Re-run the focused tests, then the repository quality loop if code changed.
6. Recheck quality tooling coverage or maintainability if that was the original failure.

## Repository-specific reminders

- Many tests expect a built `dist/{{ProjectName}}` module.
- The CI coverage flow writes `artifacts/pester-coverage.cobertura.xml`.
- Do not "fix" coverage by weakening assertions or suppressing quality tooling warnings.
