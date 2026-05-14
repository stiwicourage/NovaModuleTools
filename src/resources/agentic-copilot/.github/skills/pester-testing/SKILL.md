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
- Keep test files and helpers compatible with `project.json` `Manifest.PowerShellHostVersion`; if a project targets `5.1`, do not introduce PowerShell 7.x-only syntax, cmdlets, parameters, or APIs in the tests.
- Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort test-code matrix. Keep new or heavily changed test functions under the warning thresholds for lines of code (`70`), max arguments (`4`), nesting depth (`4`), complex conditional branches (`2`), and bumpy-road bumps (`2`); split assertion helpers before blocks exceed four consecutive asserts or four large assertion blocks per suite.
- Keep shared setup in `tests/TestHelpers/` or `*TestSupport.ps1`; do not hide unrelated source-file coverage in broad catch-all test files.
- If a mirrored test is not practical because the behavior is genuinely cross-cutting, document the reason in the handoff and point to the owning integration or guardrail test.

## Common pitfalls

- Forgetting that many tests assume `dist/{{ProjectName}}` already exists
- Duplicating setup instead of extending `*.TestSupport.ps1`
- Exporting helper functions at the wrong time in test lifecycle
- Passing tests while still degrading maintainability through duplication
- Grouping unrelated source files into one large test file when a source-mirrored layout would make ownership clearer
- Adding source files without a matching mirrored test or an explicit cross-cutting-test justification
- Ignoring the test-code matrix and letting new or heavily changed tests grow beyond the warning thresholds without justification

## Verification

- Run the touched test file(s) directly first
- Run full regression tests before finishing code changes
- If coverage is the goal, inspect `artifacts/pester-coverage.cobertura.xml` via the CI helper flow
