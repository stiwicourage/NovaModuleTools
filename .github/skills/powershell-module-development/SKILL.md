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
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source; Nova generates those files under `dist/<ProjectName>/`.
- Preserve native PowerShell semantics and Nova naming patterns.
- Reuse existing workflow-context helpers and shared adapters.
- Follow the repository's PowerShell style rules: 4-space indentation, same-line opening braces, restrained blank lines, full cmdlet names, and readable operator spacing.
- Add or update PlatyPS-compatible help under `docs/<ProjectName>/en-US/` when public commands or public classes change.
- Add or update the source-mirrored Pester test file for every changed `src/**/*.ps1` file.

## Common pitfalls

- Adding more than one top-level function to a public file
- Mixing CLI flag spellings into PowerShell command output
- Calling `git`, `Invoke-WebRequest`, `Update-Module`, or `$env:` from the wrong layer
- Replacing explicit warning opt-ins with generic force semantics
- Creating a root module `.psm1` or module manifest `.psd1` by hand instead of letting Nova generate them from `project.json`

## Verification

- Targeted Pester file(s) for the changed behavior
- `tests/ArchitectureGuardrails.Tests.ps1` implications checked
- `pwsh -NoLogo -NoProfile -File ./run.ps1`
