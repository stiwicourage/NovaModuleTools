---
applyTo: "src/**/*.ps1,tests/**/*.ps1,scripts/**/*.ps1,run.ps1,reload.ps1"
---

# NovaModuleTools PowerShell coding standards

## Scope

Use this file when changing `src/public/`, `src/private/`, or PowerShell build/release helpers.

## Public command rules

- Keep public command files small and delegating.
- Keep exactly one top-level public function per file in `src/public/`.
- Match the file name to that top-level public function name.
- Public mutating commands should support PowerShell `ShouldProcess` semantics.
- Preserve existing naming and command model conventions such as `Invoke-Nova*`, `Get-Nova*`, `Update-Nova*`, and the `nova` CLI routing model.
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source. Nova generates the built module root and manifest under `dist/<ProjectName>/` from `project.json` and `src/**/*.ps1`.

## Internal structure rules

- Put internal helpers in the correct domain folder under `src/private/`.
- In `src/private/`, keep at most one externally called function per file and match the file name to that entry function.
- Additional functions in a private file are allowed only as support helpers called from that same file.
- If two private functions are both called from outside their file, split them into separate same-named files.
- Reuse existing adapters and shared helpers before adding new infrastructure calls.
- Keep direct environment access, Git execution, upload requests, and self-update execution in their approved helper locations. `tests/ArchitectureGuardrails.Tests.ps1` is authoritative.
- Prefer explicit workflow-context objects (`[pscustomobject]` / ordered hashtables) for multi-step flows.

## Error and behavior rules

- Prefer clear, structured Nova errors over silent fallback behavior.
- Preserve existing warning semantics; do not rename warning opt-ins to a generic `-Force` pattern.
- Keep CLI spellings and PowerShell spellings distinct in messages and docs.
- Read `project.json` `Manifest.PowerShellHostVersion` before changing PowerShell source, scripts, or tests, and keep new usage compatible with that target. A `5.1` project must not receive PowerShell 7.x-only syntax, cmdlets, parameters, or APIs unless compatibility is explicitly guarded and within scope.
- When public command help changes, follow `.github/instructions/platyps-help.instructions.md` and use `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp` instead of hand-authoring the help structure.
- Do not add PSScriptAnalyzer `ExcludeRule`, `ExcludeRules`, suppression attributes, or generated settings that hide analyzer findings. Fix the rule violation instead.
- Keep local quality wrappers ordered as ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`.
- If `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before treating the change as complete.

## Formatting rules

### Indentation

- Use spaces, not hard tabs.
- Use 4 spaces per indentation level.
- Indent block contents one level inside `function`, `if`, `switch`, `foreach`, `for`, `while`, `try`, `catch`,
  `finally`, `class`, and method bodies.
- When an expression wraps onto the next line, indent the continuation line one extra level instead of trying to align it visually to a previous token column.

### Spacing

- Use one space between language keywords and `(` in control statements such as `if (...)`, `foreach (...)`, `switch (...)`, `while (...)`, and `for (...)`.
- Use one space before an opening `{`.
- Use one space around binary, comparison, and logical operators.
- Use one space after commas in parameter and argument lists.
- Prefer `-not` over `!` for logical negation.
- Prefer full cmdlet names in standard PowerShell casing; do not introduce aliases.
- Prefer `[int]$Count` style type literals without an extra space before the variable name.

### Wrapping and braces

- Use same-line opening braces for functions, control statements, `try` / `catch` / `finally`, `switch` labels, classes, and methods.
- Keep `elseif`, `else`, `catch`, and `finally` on the same line as the preceding closing brace.
- Keep closing braces on their own line.
- Prefer multi-line `param(...)`, hashtables, and long argument sets over overly long single lines.
- When wrapping an expression, keep the operator on the preceding line when it reads naturally.

### Blank lines

- Use a single blank line between logical sections of a function when it improves readability.
- Do not stack multiple blank lines.
- Avoid decorative blank lines inside short blocks.
- Keep one blank line between top-level declarations when a file contains more than one declaration.
- Every changed or generated text file, including `.ps1` files, must end with exactly one trailing newline and no extra blank lines at the bottom.

## Maintainability rules

- Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort source-code matrix for `src/**/*.ps1`; warning thresholds are the default ceiling for new or heavily changed code.
- Favor short functions and extracted helpers over large nested logic.
- Avoid copy/paste across source or test files.
- Add comments only when the code would otherwise be hard to follow.

## Verification

- Update or add Pester coverage for behavior changes.
- Recheck `tests/ArchitectureGuardrails.Tests.ps1` when changing layering or helper placement.
- Run `./run.ps1` before considering a code change complete.
- Resolve any ScriptAnalyzer findings that `./run.ps1` reports before handoff.
- Before handoff, review the changed/generated text files and normalize any file endings that violate the single-trailing-newline rule.
