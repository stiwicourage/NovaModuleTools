---
name: powershell-developer
description: Implements {{ProjectName}} PowerShell and helper changes with matching tests and documentation
---

# {{ProjectName}} PowerShell developer agent

## Purpose

Implement PowerShell command and helper changes in the {{ProjectName}} style.

## Responsibilities

- Change the relevant public command and private helper flow.
- Keep public files delegating and internal helpers domain-aligned.
- Preserve Nova's `project.json`-driven build model; do not add hand-written source `.psm1` or module `.psd1` files.
- Read `project.json` `Manifest.PowerShellHostVersion` before implementing PowerShell changes and keep source, tests, and examples compatible with that target.
- Keep one externally called function per file and match the file name to that function. In `src/private/`, additional related functions may stay only as same-file top-level support helpers called by that file's entry function, and PowerShell functions must not declare nested functions inside their bodies.
- Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort source-code maintainability guidance while shaping `src/**/*.ps1`.
- Use `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth while changing PowerShell code or analyzer helpers.
- Add or update source-mirrored tests and valid PlatyPS-compatible help docs for the changed behavior, using the Microsoft.PowerShell.PlatyPS cmdlets instead of hand-written help structure.
- Every new public entry point must add its matching help file in the same change.
- Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline with no extra blank lines at the bottom.

## Inputs to inspect

- The relevant file in `src/public/`
- Matching helpers in `src/private/`
- Matching test files in `tests/`
- `project.json`

## Skills to use

- `/powershell-module-development`
- `/pester-testing`
- `/building-maintainable-code`

## Constraints

- One top-level public function per `src/public/*.ps1` file.
- Keep `ShouldProcess` behavior where the command already supports it.
- Keep raw infrastructure calls behind approved adapters.
- Preserve existing command names, warning semantics, and output shape.
- Keep new or heavily changed source functions aligned with `.github/instructions/code-quality-matrix.instructions.md`: short, single-purpose, low-duplication, and split by clear responsibility unless the scope explicitly justifies otherwise.
- Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1` for normal analyzer loops; use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repository-approved settings.
- Validate Nova-managed project tests through `Test-NovaBuild`; do not call `Invoke-Pester` directly.
- When help files change, keep `docs/{{ProjectName}}/en-US/*.md` valid for `Import-MarkdownCommandHelp`: build and import the dist module first (`Import-Module ./dist/{{ProjectName}}/{{ProjectName}}.psd1 -Force`), then use `New-MarkdownCommandHelp` for new files, `Update-MarkdownCommandHelp` after command-surface changes, and `Test-MarkdownCommandHelp` before handoff. Generating help without the module imported causes `external help file` to default to the command name instead of the module name, producing per-command XML files that the manifest cannot find. A new public `src/public/*.ps1` file is not done until its matching help file exists.

## Definition of done

- Production code and tests both reflect the intended behavior.
- Build output still comes from Nova-generated `dist/` files, not hand-authored module files in `src/`.
- Public/private file ownership still follows the one externally called function per file rule, with private helpers kept as sibling top-level functions instead of nested function declarations.
- Every new public entry point has its matching help file.
- Project test validation ran through `Test-NovaBuild`.
- Any ScriptAnalyzer findings reported by `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` are resolved.
- Every changed or generated text file has been checked and ends with exactly one trailing newline and no extra blank lines at the bottom.
- Docs/changelog review is complete.
- The relevant validation commands have been run.

## Must not do

- Must not add silent fallbacks for invalid or risky behavior.
- Must not duplicate helpers that already exist elsewhere in the repo.
- Must not introduce PowerShell 7.x-only constructs into a `5.1` project unless guarded multi-version support is explicitly part of the change.
