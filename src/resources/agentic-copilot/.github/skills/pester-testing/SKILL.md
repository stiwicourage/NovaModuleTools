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
- `Test-NovaBuild`
- the repository quality loop, when present
- `./scripts/build/ci/Invoke-{{ProjectName}}CI.ps1 -OutputDirectory ./artifacts`

## Expected practices

- Match existing `Describe` / `It` naming style.
- Prefer support helpers for repeated setup.
- For new and migrated tests, dot-source `src/**/*.ps1` files directly in `BeforeAll`. Do not `Import-Module $project.OutputModuleDir` in mirrored unit tests, and do not use `InModuleScope {{ProjectName}} { ... }` - the function under test is already in scope after dot-sourcing.
- Use `Test-NovaBuild` as the authoritative test entrypoint in Nova-managed projects. Do not validate with direct `Invoke-Pester`, because it can miss the Nova build/import/StrictMode flow.
- Add coverage for both happy paths and explicit warnings/errors when behavior changed.
- For every new or changed `src/**/*.ps1` file, add or update one focused test file that mirrors the source path under `tests/`.
- Keep test files and helpers compatible with `project.json` `Manifest.PowerShellHostVersion`; if a project targets `5.1`, do not introduce PowerShell 7.x-only syntax, cmdlets, parameters, or APIs in the tests.
- Use `.github/instructions/testing-policy.instructions.md` as the test-design source of truth. Cover normal, boundary, and unhappy paths; isolate collaborators with mocks/stubs where needed; and extract setup or assertion helpers when a test stops being easy to scan.
- Keep shared setup in `tests/TestHelpers/` or `*TestSupport.ps1`; do not hide unrelated source-file coverage in broad catch-all test files.
- If a mirrored test is not practical because the behavior is genuinely cross-cutting, document the reason in the handoff and point to the owning integration or guardrail test.

## Mirrored layout example

```powershell
BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/private/quality/Initialize-NovaPesterCoverageConfiguration.ps1')
}

Describe 'Initialize-NovaPesterCoverageConfiguration' {
    It 'leaves CodeCoverage.Path to project.json when coverage is enabled' {
        # ...
    }
}
```

## Common pitfalls

- Importing the built `dist/{{ProjectName}}` module from a new mirrored test - dot-source the relevant `src/**/*.ps1` files instead.
- Using `InModuleScope {{ProjectName}} { ... }` in new mirrored tests - the function is already in scope after dot-sourcing.
- Duplicating setup instead of extending `*.TestSupport.ps1` or `tests/TestHelpers/`.
- Exporting helper functions at the wrong time in test lifecycle.
- Validating a Nova-managed project with direct `Invoke-Pester` instead of `Test-NovaBuild`.
- Passing tests while still degrading maintainability through duplication.
- Grouping unrelated source files into one large test file when a source-mirrored layout would make ownership clearer.
- Adding source files without a matching mirrored test or an explicit cross-cutting-test justification.
- Ignoring boundary/unhappy-path coverage or test isolation and relying on happy-path-only verification.

## Verification

- Run `Test-NovaBuild`
- Run the repository quality loop when one exists before finishing code changes
- If coverage is the goal, inspect `artifacts/coverage.xml` produced by the CI helper flow. Coverage is JaCoCo and references source files under `src/**/*.ps1` directly.
