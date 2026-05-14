---
name: pester-testing
description: Guidance for adding or refactoring {{ProjectName}} Pester coverage, regression tests, and test support structure.
---

# Skill: Pester testing

## When to use

Use this skill when adding tests, closing coverage gaps, fixing regressions, or refactoring test structure.

## Relevant files and commands

- `tests/*.Tests.ps1`
- `tests/*TestSupport.ps1`
- `pwsh -NoLogo -NoProfile -Command "Invoke-Pester -Path ./tests/<File>.Tests.ps1 -Output Detailed"`

## Expected practices

- Match existing `Describe` / `It` naming style.
- Prefer support helpers for repeated setup.
- Build/import the dist module when the test file expects it.
- Add coverage for both happy paths and explicit warnings/errors when behavior changed.
- For every new or changed `src/**/*.ps1` file, add or update one focused test file that mirrors the source path under `tests/`.
- Keep shared setup in `tests/TestHelpers/` or `*TestSupport.ps1`; do not hide unrelated source-file coverage in broad catch-all test files.
- If a mirrored test is not practical because the behavior is genuinely cross-cutting, document the reason in the handoff and point to the owning integration or guardrail test.

## Common pitfalls

- Forgetting that many tests assume `dist/{{ProjectName}}` already exists
- Duplicating setup instead of extending `*.TestSupport.ps1`
- Exporting helper functions at the wrong time in test lifecycle
- Passing tests while still degrading maintainability through duplication
- Grouping unrelated source files into one large test file when a source-mirrored layout would make ownership clearer
- Adding source files without a matching mirrored test or an explicit cross-cutting-test justification

## Verification

- Run the touched test file(s) directly first
- Run full regression tests before finishing code changes
- If coverage is the goal, inspect `artifacts/pester-coverage.cobertura.xml` via the CI helper flow
