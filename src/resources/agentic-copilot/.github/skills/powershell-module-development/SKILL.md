---
name: powershell-module-development
description: Guidance for changing {{ProjectName}} public commands, private helpers, CLI routing, packaging behavior, or project.json resolution. Use when implementing or refactoring {{ProjectName}} PowerShell/module behavior.
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
- `tests/*Command*.Tests.ps1`
- `tests/*Architecture*.Tests.ps1`

## Expected practices

- Keep public commands thin and delegating.
- Put implementation detail in the correct private domain folder.
- Preserve native PowerShell semantics and Nova naming patterns.
- Reuse existing workflow-context helpers and shared adapters.
- Follow the repository's PowerShell style rules: 4-space indentation, same-line opening braces, restrained blank lines, full cmdlet names, and readable operator spacing.

## Common pitfalls

- Adding more than one top-level function to a public file
- Mixing CLI flag spellings into PowerShell command output
- Calling `git`, `Invoke-WebRequest`, `Update-Module`, or `$env:` from the wrong layer
- Replacing explicit warning opt-ins with generic force semantics

## Verification

- Targeted Pester file(s) for the changed behavior
- `tests/*Architecture*.Tests.ps1` implications checked

