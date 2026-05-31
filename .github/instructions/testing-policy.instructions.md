---
applyTo: "tests/**/*.ps1,scripts/build/**/*.ps1,.github/workflows/Tests.yml,.github/actions/check-coverage/action.yml"
---

# NovaModuleTools testing policy

## Scope

Use this file when changing production code, tests, coverage behavior, or CI test flows.

## Test loading pattern (mirrored, dot-source-first)

NovaModuleTools is migrating tests to a 1:1 source-to-test layout per issue #208. New and migrated tests follow this loading pattern:

- The test file's `BeforeAll` dot-sources **only** the `src/**/*.ps1` files it needs (the source under test plus its private collaborators that are not being mocked).
- Tests do **not** `Import-Module $project.OutputModuleDir`.
- Tests do **not** use `InModuleScope <ModuleName> { ... }`. Mocked functions live in the same scope as the test because they were dot-sourced into it.
- Shared fixtures and dot-source helpers live in `tests/TestHelpers/`.
- This makes `project.json` `Pester.CodeCoverage.Path = ["src/public/*.ps1", "src/private/*.ps1", "src/private/*/*.ps1", "src/private/*/*/*.ps1"]` produce real source-file coverage, including nested helper folders such as `src/private/build/manifest/` and `src/private/quality/duplicates/`, and means `Test-NovaBuild` does not require a `dist/` folder.

Example:

```powershell
BeforeAll {
    $projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    . (Join-Path $projectRoot 'src/private/quality/Initialize-NovaPesterCoverageConfiguration.ps1')
    . (Join-Path $projectRoot 'src/public/Test-NovaBuild.ps1')
}
```

Legacy tests that still use `Import-Module $project.OutputModuleDir` + `InModuleScope` can still exist while maintainers finish migrations, but the mirrored pattern itself now supports enabled repository coverage gates. Generated project templates still ship `CodeCoverage.Enabled = false` until maintainers opt into the coverage gate for their own project.

## Integration tests may import `dist/`

- New mirrored unit tests should keep dot-sourcing `src/**/*.ps1` files directly.
- Public command integration ownership lives in `tests/public/<Command>.Integration.Tests.ps1` when the purpose is validating built-module behavior, exported command shape, command wiring, or build-validation smoke coverage.
- Cross-cutting `*.Integration.Tests.ps1` files may `Import-Module ./dist/<ModuleName>/<ModuleName>.psd1` when the behavior genuinely spans multiple source files.
- For destructive or environment-coupled public commands, prefer safe `-WhatIf` integration coverage when that still proves `ShouldProcess`, routing, and output behavior.
- Keep that `dist/` import limited to integration scenarios; do not use it as the default pattern for mirrored unit tests.

## Cross-cutting tests are still allowed

Use a cross-cutting test file (not a mirrored one) when the behavior under test truly spans multiple source files:

- Architecture guardrails (layering, adapter boundaries, file ownership rules)
- Public command surface tests that exercise the built module end-to-end
- Workflow tests that intentionally validate multi-helper orchestration
- CLI route/forwarding tests that prove the routing topology, not the helpers it routes to

Cross-cutting files should be **named for the behavior** they validate (e.g., `ArchitectureGuardrails.Tests.ps1`), not for "remaining coverage". A test belongs in a mirrored file when it covers a single source file's behavior.

## Where new tests for a source file go

| Source file                       | Mirrored test file                        |
|-----------------------------------|-------------------------------------------|
| `src/public/<Name>.ps1`           | `tests/public/<Name>.Tests.ps1`           |
| `src/public/<Name>.ps1`           | `tests/public/<Name>.Integration.Tests.ps1` for built-module/public-command integration ownership |
| `src/private/<domain>/<Name>.ps1` | `tests/private/<domain>/<Name>.Tests.ps1` |
| `src/classes/<Name>.ps1`          | `tests/classes/<Name>.Tests.ps1`          |

A non-blocking mirror status helper is available at `scripts/build/Get-TestMirrorStatus.ps1` to show which source files still lack a mirrored test.

## Test expectations

- Behavior changes require Pester coverage.
- `Invoke-NovaTest` is the unit-test entrypoint and `Test-NovaBuild` is the build-validation integration-test entrypoint in Nova-managed projects. Do not validate with direct `Invoke-Pester`, because it can bypass Nova's build/import/StrictMode flow and disagree with what users see later.
- Prefer the smallest supported test scope first: `Invoke-NovaTest` for unit behavior, then `Test-NovaBuild` when the change needs built-module or integration validation, before running the full quality loop.
- For public commands, keep unit coverage in `tests/public/<Command>.Tests.ps1` and keep per-command integration ownership in `tests/public/<Command>.Integration.Tests.ps1` when the built command behavior itself needs validation.
- For destructive or environment-coupled public commands, prefer safe `-WhatIf` integration coverage when that still proves `ShouldProcess`, routing, and output semantics.
- Keep test names explicit about the behavior being proven.
- Reuse `*.TestSupport.ps1` helpers where possible.
- For every new or changed `src/**/*.ps1` file, add or update the matching source-mirrored `.Tests.ps1` file.
- Keep test files and helpers compatible with `project.json` `Manifest.PowerShellHostVersion`; if a project targets `5.1`, do not rely on PowerShell 7.x-only syntax, cmdlets, parameters, or APIs in the tests.
- Cover both the normal path and the meaningful unhappy, invalid, or boundary cases that the changed behavior introduces.
- Use mocks or stubs for collaborators when the test needs to isolate behavior or verify side effects.
- Keep tests isolated and order-independent; do not rely on shared mutable state between tests.
- Update tests when production signatures or behavior change instead of leaving stale expectations behind.
- Keep test flows linear and easy to scan; extract setup or assertion helpers when one test starts carrying too many responsibilities.
- Follow `.github/instructions/psscriptanalyzer.instructions.md` when PowerShell tests, test helpers, or build helpers change. Use `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` for the repo-standard analyzer run, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings.
- Use broad guardrail, architecture, command-model, or integration tests only for behavior that genuinely spans multiple source files; do not use them as the default place for unit coverage of unrelated source files.

## Repository test structure

- `tests/public/<Name>.Tests.ps1`, `tests/private/<domain>/<Name>.Tests.ps1`, `tests/classes/<Name>.Tests.ps1` - mirrored unit tests (preferred for new and migrated tests)
- `tests/public/<Name>.Integration.Tests.ps1` - per-command build-validation integration tests for public commands
- `tests/ArchitectureGuardrails.Tests.ps1` - layering and adapter boundaries
- `tests/NovaCommandModel*.Tests.ps1` - public command, CLI, and workflow behavior (legacy bucket, being migrated)
- `tests/*TestSupport.ps1`, `tests/TestHelpers/` - shared helpers, reusable fixtures, dot-source helpers
- `tests/CoverageGaps*.Tests.ps1`, `tests/Remaining*Coverage*.Tests.ps1` - legacy coverage buckets being retired in issue #207

## Coverage and CodeScene

- CI coverage is generated by `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`.
- `Invoke-NovaTest` produces the repository JaCoCo coverage report at `artifacts/coverage.xml`.
- `Test-NovaBuild` focuses on build-validation integration coverage and produces NUnit results without source coverage enforcement.
- The JaCoCo artifact is reused by the CodeScene PR coverage gate and by the develop/manual CodeScene analysis flow.
- The CodeScene analysis upload sends coverage twice: once for `line-coverage` and once for `branch-coverage`.
- Coverage paths in `project.json` must point at `src/**/*.ps1`, not at the built `dist` psm1. Nova does not override `CodeCoverage.Path`.
- Generated project templates still ship `CodeCoverage.Enabled = false` with a `90` percent target until maintainers opt in. Repositories that enable coverage should keep the configured target accurate and use the explicit `src/private/*.ps1`, `src/private/*/*.ps1`, and `src/private/*/*/*.ps1` path globs so nested private helper folders stay measurable.
- If CodeScene flags coverage or duplication, fix the underlying test design instead of suppressing the warning casually.

## Common pitfalls

- Importing the built `dist/NovaModuleTools` module from a new mirrored test - mirrored tests dot-source `src/**/*.ps1` files directly instead.
- Using `InModuleScope NovaModuleTools { ... }` in new tests - the function under test is already in scope after dot-sourcing.
- Direct `Invoke-Pester` runs can hide Nova-specific build/import/StrictMode behavior and should not be used as the project test entrypoint.
- Some legacy support helpers must be dot-sourced and re-exported inside `BeforeAll`; new TestHelpers should expose dot-source helpers directly.
- Duplicated test setup can lower Code Health even when tests pass.
- Tests that only cover the happy path can miss the edge cases that caused the change in the first place.
- Shared mutable state between tests makes failures order-dependent and unreliable.
- Docs-only changes usually do not need executable validation, but workflow/test docs must still be kept accurate.

## Verification

- `Invoke-NovaTest`
- `Test-NovaBuild`
- `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` when PowerShell code changed
- `pwsh -NoLogo -NoProfile -File ./run.ps1` before completion
