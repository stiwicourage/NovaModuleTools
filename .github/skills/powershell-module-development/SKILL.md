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
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source; Nova generates those files under `dist/NovaModuleTools/`.
- Preserve native PowerShell semantics and Nova naming patterns.
- Keep one externally called function per file and match the file name to that function. In `src/private/`, additional functions may stay only as same-file support helpers called by that file's entry function.
- Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort source-code matrix. Keep new or heavily changed source functions at or below the warning thresholds for lines of code (`16`), cyclomatic complexity (`6`), complex conditional branches (`6`), max arguments (`4`), and nesting depth (`6`) unless the change explicitly justifies more.
- Reuse existing workflow-context helpers and shared adapters.
- Follow the repository's PowerShell style rules: 4-space indentation, same-line opening braces, restrained blank lines, full cmdlet names, and readable operator spacing.
- Follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1`, and use direct `Invoke-ScriptAnalyzer` only for focused local checks or deliberate analyzer-tooling work.
- Keep ScriptAnalyzer strict: do not add excluded rules, suppression attributes, or settings that hide analyzer findings.
- Keep `run.ps1`-style local checks ordered as ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`.
- If `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before handoff instead of just reporting the failure.
- Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline with no extra blank lines at the end.
- Add or update valid PlatyPS-compatible help under `docs/NovaModuleTools/en-US/` when public commands or public classes change. Use `New-MarkdownCommandHelp` for new help, `Update-MarkdownCommandHelp` to refresh existing help metadata, and `Test-MarkdownCommandHelp` to validate structure before handoff instead of writing plain Markdown from scratch.
- For every new public `src/public/*.ps1` file, create the matching help file immediately in the same change.
- Add or update the source-mirrored Pester test file for every changed `src/**/*.ps1` file.

## Common pitfalls

- Adding more than one top-level function to a public file
- Mixing CLI flag spellings into PowerShell command output
- Calling `git`, `Invoke-WebRequest`, `Update-Module`, or `$env:` from the wrong layer
- Replacing explicit warning opt-ins with generic force semantics
- Creating a root module `.psm1` or module manifest `.psd1` by hand instead of letting Nova generate them from `project.json`
- Grouping two externally called private helpers in one file instead of splitting them into separate same-named files
- Ignoring the source-code matrix and letting new or heavily changed functions grow far beyond the warning thresholds without justification
- Writing plain Markdown under `docs/NovaModuleTools/en-US/` that lacks YAML metadata or the PlatyPS structure expected by `Import-MarkdownCommandHelp`
- Editing PlatyPS YAML and section structure by hand when `New-MarkdownCommandHelp` or `Update-MarkdownCommandHelp` should have regenerated it
- Adding a new public entry point without the matching help file in `docs/NovaModuleTools/en-US/`
- Bypassing the repository analyzer wrapper/settings with ad hoc `Invoke-ScriptAnalyzer`, `-EnableExit`, or broad rule-exclusion changes
- Ignoring the project's `Manifest.PowerShellHostVersion` target and introducing PowerShell 7.x-only features into a `5.1` project
- Excluding PSScriptAnalyzer rules instead of fixing the code that violates them

## Verification

- Targeted Pester file(s) for the changed behavior
- `tests/ArchitectureGuardrails.Tests.ps1` implications checked
- `pwsh -NoLogo -NoProfile -File ./run.ps1`
