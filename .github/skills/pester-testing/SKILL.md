---
name: pester-testing
description: Guidance for adding or refactoring NovaModuleTools Pester coverage, regression tests, and test support structure.
---

# Skill: Pester testing

## When to use

Use this skill when adding tests, closing coverage gaps, fixing regressions, or refactoring test structure.

## Relevant files and commands

- `tests/*.Tests.ps1`
- `tests/*TestSupport.ps1`
- `pwsh -NoLogo -NoProfile -Command "Invoke-Pester -Path ./tests/<File>.Tests.ps1 -Output Detailed"`
- `pwsh -NoLogo -NoProfile -File ./run.ps1`
- `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1 -OutputDirectory ./artifacts`

## Expected practices

- Match existing `Describe` / `It` naming style.
- Prefer support helpers for repeated setup.
- Build/import the dist module when the test file expects it.
- Add coverage for both happy paths and explicit warnings/errors when behavior changed.

## Common pitfalls

- Forgetting that many tests assume `dist/NovaModuleTools` already exists
- Duplicating setup instead of extending `*.TestSupport.ps1`
- Exporting helper functions at the wrong time in test lifecycle
- Passing tests while still degrading Code Health through duplication

## Verification

- Run the touched test file(s) directly first
- Run `./run.ps1` before finishing code changes
- If coverage is the goal, inspect `artifacts/pester-coverage.cobertura.xml` via the CI helper flow
