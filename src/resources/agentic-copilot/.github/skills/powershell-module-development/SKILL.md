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
- Treat `project.json` as the source of truth for Nova build, package, manifest, and release metadata.
- Read `project.json` `Manifest.PowerShellHostVersion` before changing PowerShell code, tests, or examples, and keep new work compatible with that target. A `5.1` project must not receive PowerShell 7.x-only syntax, cmdlets, parameters, or APIs unless the change explicitly adds guarded compatibility handling.
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source; Nova generates those files under `dist/{{ProjectName}}/`.
- Preserve native PowerShell semantics. Keep Nova naming patterns on public commands, and give private helpers clear implementation-focused names instead of public-style `Invoke-{{ShortName}}*`, `Get-{{ShortName}}*`, or `Update-{{ShortName}}*` naming.
- Keep one externally called function per file and match the file name to that function. In `src/private/`, additional related functions may stay only as same-file top-level support helpers called by that file's entry function; do not declare functions inside functions.
- Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort source-code maintainability guidance. Keep new or heavily changed code short, single-purpose, low-duplication, lightly nested, and split by clear responsibility; group related inputs instead of growing long parameter lists.
- Reuse existing workflow-context helpers and shared adapters.
- Follow the repository's PowerShell style rules: 4-space indentation, same-line opening braces, restrained blank lines, full cmdlet names, and readable operator spacing.
- Follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and the repository quality loop, when present, and use direct `Invoke-ScriptAnalyzer` only for focused local checks or deliberate analyzer-tooling work.
- Keep ScriptAnalyzer strict: do not add excluded rules, suppression attributes, or settings that hide analyzer findings.
- Keep local quality checks ordered as ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild` when the project defines a combined wrapper.
- If the repository quality loop or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before handoff instead of just reporting the failure.
- Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline with no extra blank lines at the end.
- Add or update valid PlatyPS-compatible help under `docs/{{ProjectName}}/en-US/` when public commands or public classes change. Always build and import the dist module first (`Import-Module ./dist/{{ProjectName}}/{{ProjectName}}.psd1 -Force`) before running `New-MarkdownCommandHelp` or `Update-MarkdownCommandHelp`, so PlatyPS writes the module name — not the command name — into `external help file` and `Module Name`. Use `Test-MarkdownCommandHelp` to validate structure before handoff instead of writing plain Markdown from scratch.
- For every new public `src/public/*.ps1` file, create the matching help file immediately in the same change.
- Add or update the source-mirrored Pester test file for every changed `src/**/*.ps1` file.

## Common pitfalls

- Adding more than one top-level function to a public file
- Mixing CLI flag spellings into PowerShell command output
- Calling `git`, `Invoke-WebRequest`, `Update-Module`, or `$env:` from the wrong layer
- Replacing explicit warning opt-ins with generic force semantics
- Creating a root module `.psm1` or module manifest `.psd1` by hand instead of letting Nova generate them from `project.json`
- Grouping two externally called private helpers in one file instead of splitting them into separate same-named files
- Declaring helper functions inside another function instead of keeping related private helpers as sibling top-level functions in the file
- Ignoring the source-code guidance and letting new or heavily changed functions grow long, deeply nested, duplicated, or multi-purpose without justification
- Writing plain Markdown under `docs/{{ProjectName}}/en-US/` that lacks YAML metadata or the PlatyPS structure expected by `Import-MarkdownCommandHelp`
- Editing PlatyPS YAML and section structure by hand when `New-MarkdownCommandHelp` or `Update-MarkdownCommandHelp` should have regenerated it
- Generating help markdown without the built module imported, which causes `external help file` to default to the command name and produces per-command XML files instead of a single `<ModuleName>-Help.xml`
- Adding a new public entry point without the matching help file in `docs/{{ProjectName}}/en-US/`
- Bypassing the repository analyzer wrapper/settings with ad hoc `Invoke-ScriptAnalyzer`, `-EnableExit`, or broad rule-exclusion changes
- Ignoring the project's `Manifest.PowerShellHostVersion` target and introducing PowerShell 7.x-only features into a `5.1` project
- Excluding PSScriptAnalyzer rules instead of fixing the code that violates them

## Verification

- `Test-NovaBuild` for the changed behavior
- `tests/*Architecture*.Tests.ps1` implications checked
- the repository quality loop, when present
