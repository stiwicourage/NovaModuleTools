---
applyTo: "src/**/*.ps1,tests/**/*.ps1,scripts/**/*.ps1,run.ps1,reload.ps1"
---

# PSScriptAnalyzer workflow rules

## Scope

Use this file when changing PowerShell code, tests, build helpers, or analyzer wrappers.

## Why this matters

- PSScriptAnalyzer is the supported static analyzer for PowerShell scripts and modules in this repository.
- The repository quality loop already expects ScriptAnalyzer to run before build and test, so agents should follow that workflow instead of inventing their own lint steps.

## Required workflow

1. Use the repository wrappers as the authoritative entrypoints:
    - analyzer only: `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
    - full local loop: `./run.ps1`
2. Use raw `Invoke-ScriptAnalyzer` only for focused local investigation or when you are deliberately changing analyzer tooling.
3. When you call `Invoke-ScriptAnalyzer` directly, point it at real `.ps1`, `.psm1`, or `.psd1` paths, use `-Recurse` when analyzing a directory, and reuse the repository-approved analyzer settings through `-Settings` instead of inventing a new rule selection.
4. Treat `Error`, `Warning`, and `ParseError` diagnostics as findings to fix before handoff. Parser errors are analyzer diagnostics too and are not something to suppress away.
5. Do not add ad hoc `ExcludeRule`, `ExcludeRules`, `SuppressMessageAttribute`, or custom settings changes just to make the analyzer pass. Only keep analyzer exceptions that the repository already approves and can justify narrowly.
6. `Invoke-ScriptAnalyzer -Fix` is optional and only applies to selected rules. Review every change it would make, prefer `-WhatIf` first, and inspect the diff afterwards.
7. `Invoke-ScriptAnalyzer -EnableExit` is useful for CI shells, but if the repository already has a wrapper with established failure semantics, do not replace that wrapper with an ad hoc direct invocation.

## Authoring guidance

- Prefer one focused analyzer run on the changed files while iterating, then rerun `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`, then `./run.ps1` before handoff.
- Keep analyzer wrappers focused on source files and helper scripts, not generated output such as `dist/` or `artifacts/`.
- If the repository has a `PSScriptAnalyzerSettings.psd1` file or a wrapper-owned settings hashtable, treat that configuration as authoritative for direct `Invoke-ScriptAnalyzer` runs.
- Built-in presets such as `PSGallery` or `CodeFormatting` exist, but do not switch to them unless the repository explicitly adopts them.

## Review expectations

- Reviewers should flag direct `Invoke-ScriptAnalyzer` usage that bypasses the repository wrapper or repository-approved settings without a clear reason.
- Reviewers should flag new rule suppressions, exclusions, or analyzer-setting changes that are broader than the specific justified need.
- Reviewers should flag PowerShell changes handed off with unresolved analyzer findings.
