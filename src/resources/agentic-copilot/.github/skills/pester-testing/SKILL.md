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
- `Invoke-NovaTest`
- `Test-NovaBuild`
- the repository quality loop, when present
- `./scripts/build/ci/Invoke-{{ProjectName}}CI.ps1 -OutputDirectory ./artifacts`

## Expected practices

Use `.github/instructions/testing-policy.instructions.md` for the general test-design rules. Apply the repository-specific conventions below for file layout, import strategy, validation entrypoints, and exceptions.

### General style

- Match existing `Describe` / `It` naming style.
- Prefer support helpers for repeated setup.
- Cover normal, boundary, and unhappy paths; isolate collaborators with mocks/stubs where needed; and extract setup or assertion helpers when a test stops being easy to scan.
- Add coverage for both happy paths and explicit warnings/errors when behavior changed.

### File layout

- For every new or changed `src/**/*.ps1` file, add or update one focused test file that mirrors the source path under `tests/`.
- Public command unit tests belong in `tests/public/<Command>.Tests.ps1`; public command integration ownership belongs in `tests/public/<Command>.Integration.Tests.ps1` when the built-module behavior itself needs coverage.
- Private function tests belong in `tests/private/<RelativePath>.Tests.ps1`, mirroring the source path under `src/private/`. For example, a test for `src/private/quality/Initialize-NovaPesterCoverageConfiguration.ps1` belongs in `tests/private/quality/Initialize-NovaPesterCoverageConfiguration.Tests.ps1`.
- Keep shared setup in `tests/TestHelpers/` or `*TestSupport.ps1`; do not hide unrelated source-file coverage in broad catch-all test files.

### Import strategy

- For new and migrated tests, dot-source `src/**/*.ps1` files directly in `BeforeAll`. Do not `Import-Module $project.OutputModuleDir` in mirrored unit tests, and do not use `InModuleScope {{ProjectName}} { ... }` - the function under test is already in scope after dot-sourcing.
- If you encounter an existing test file that uses `Import-Module $project.OutputModuleDir` or `InModuleScope {{ProjectName}}`, migrate it to the dot-source pattern as part of the same change. If migration is out of scope for the current task, add a TODO comment in that test file and note it in your final handoff.

### Validation entrypoints

- Use `Invoke-NovaTest` as the unit-test entrypoint and `Test-NovaBuild` as the build-validation integration-test entrypoint in Nova-managed projects. Do not validate with direct `Invoke-Pester`, because it can miss the Nova build/import/StrictMode flow.

### Version compatibility

- Keep test files and helpers compatible with `project.json` `Manifest.PowerShellHostVersion`.
- If a project targets `5.1`, do not introduce PowerShell 7.x-only syntax, cmdlets, parameters, or APIs in the tests.
- If a project targets PowerShell 7.x or later, 7.x syntax and APIs are permitted. Always match the minimum version declared in `Manifest.PowerShellHostVersion` and avoid syntax requiring a higher version than declared.

### Coverage exceptions

- For destructive or environment-coupled public commands, prefer safe `-WhatIf` integration coverage when that still proves command wiring, `ShouldProcess`, and output semantics.
- If a mirrored test is not practical because the behavior is genuinely cross-cutting, add a brief comment at the top of the owning test file that explains why a mirrored test is not practical and which integration or guardrail test provides coverage instead.

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
- Validating a Nova-managed project with direct `Invoke-Pester` instead of `Invoke-NovaTest` and `Test-NovaBuild`.
- Passing tests while still degrading maintainability through duplication.
- Grouping unrelated source files into one large test file when a source-mirrored layout would make ownership clearer.
- Adding source files without a matching mirrored test or an explicit cross-cutting-test justification.
- Ignoring boundary/unhappy-path coverage or test isolation and relying on happy-path-only verification.

## Verification

- Run `Invoke-NovaTest`
- Run `Test-NovaBuild`
- Run the repository quality loop when one exists before finishing code changes
- If coverage is the goal, inspect `artifacts/coverage.xml` produced by the CI helper flow. Coverage is JaCoCo and references source files under `src/**/*.ps1` directly.
