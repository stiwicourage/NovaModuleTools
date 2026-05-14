---
name: powershell-module-development
description: Guidance for changing NovaModuleTools public commands, private helpers, CLI routing, packaging behavior, or project.json resolution. Use when implementing or refactoring NovaModuleTools PowerShell/module behavior.
---

# Skill: PowerShell module development

## When to use

Use this skill when changing public commands, private helpers, CLI routing support, packaging behavior, or project.json resolution.

## Relevant files

- `src/public/*.ps1`
- `src/private/build/`
- `src/private/cli/`
- `src/private/package/`
- `src/private/release/`
- `src/private/shared/`
- `project.json`
- `tests/NovaCommandModel*.Tests.ps1`
- `tests/ArchitectureGuardrails.Tests.ps1`

## Expected practices

- Keep public commands thin and delegating.
- Put implementation detail in the correct private domain folder.
- Treat `project.json` as the source of truth for Nova build, package, manifest, and release metadata.
- Read `project.json` `Manifest.PowerShellHostVersion` before changing PowerShell code, tests, or examples, and keep new work compatible with that target. A `5.1` project must not receive PowerShell 7.x-only syntax, cmdlets, parameters, or APIs unless the change explicitly adds guarded compatibility handling.
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source; Nova generates those files under `dist/<ProjectName>/`.
- Preserve native PowerShell semantics and Nova naming patterns.
- Reuse existing workflow-context helpers and shared adapters.
- Follow the repository's PowerShell style rules: 4-space indentation, same-line opening braces, restrained blank lines, full cmdlet names, and readable operator spacing.
- Keep ScriptAnalyzer strict: do not add excluded rules, suppression attributes, or settings that hide analyzer findings.
- Keep `run.ps1`-style local checks ordered as ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`.
- If `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before handoff instead of just reporting the failure.
- Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline with no extra blank lines at the end.
- Add or update PlatyPS-compatible help under `docs/<ProjectName>/en-US/` when public commands or public classes change.
- Add or update the source-mirrored Pester test file for every changed `src/**/*.ps1` file.

## Common pitfalls

- Adding more than one top-level function to a public file
- Mixing CLI flag spellings into PowerShell command output
- Calling `git`, `Invoke-WebRequest`, `Update-Module`, or `$env:` from the wrong layer
- Replacing explicit warning opt-ins with generic force semantics
- Creating a root module `.psm1` or module manifest `.psd1` by hand instead of letting Nova generate them from `project.json`
- Ignoring the project's `Manifest.PowerShellHostVersion` target and introducing PowerShell 7.x-only features into a `5.1` project
- Excluding PSScriptAnalyzer rules instead of fixing the code that violates them

## Verification

- Targeted Pester file(s) for the changed behavior
- `tests/ArchitectureGuardrails.Tests.ps1` implications checked
- `pwsh -NoLogo -NoProfile -File ./run.ps1`
