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
- If you encounter an existing `src/public/` file that violates the one-function or file-name-match rule, do not silently leave it. Note the violation in your response and, if fixing it is within the stated scope of the change, split or rename the file. If it is out of scope, flag it explicitly for a follow-up task.
- Public mutating commands should support PowerShell `ShouldProcess` semantics.
- Preserve existing naming and command model conventions for public commands/functions such as `Invoke-Nova*`, `Get-Nova*`, `Update-Nova*`, and the `nova` CLI routing model.
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source. Nova generates the built module root and manifest under `dist/NovaModuleTools/` from `project.json` and `src/**/*.ps1`.

## Internal structure rules

- Put internal helpers in the correct domain folder under `src/private/`.
- In `src/private/`, keep at most one externally called function per file and match the file name to that entry function.
- Additional functions in a private file are allowed only if they are never called from outside that file and exist solely to support the file's single entry-point function.
- If two private functions are both called from outside their file, split them into separate same-named files.
- If any secondary function is called from a second file, move it to its own same-named file immediately.
- If splitting a private function would create a file name that already exists under `src/private/`, report the collision explicitly and do not overwrite the existing file. Propose a resolution such as renaming one function, merging responsibilities, or flagging the case for human decision before proceeding.
- Do not declare functions inside other functions. Keep private support helpers as sibling top-level functions in the file instead of nested function declarations.
- Private helper names should not use the public `Invoke-Nova*`, `Get-Nova*`, `Update-Nova*`, or `nova` CLI route naming conventions. Give private helpers clear implementation-focused names that describe what the helper does.
- Before adding a new function that calls the filesystem, Git, network, or environment, check whether an approved wrapper already exists in the locations listed in `tests/ArchitectureGuardrails.Tests.ps1`. Use that wrapper instead of writing a new one. If `tests/ArchitectureGuardrails.Tests.ps1` is not accessible, stop and ask the user to provide it before making the related infrastructure change.
- Keep direct environment access, Git execution, upload requests, and self-update execution in their approved helper locations. `tests/ArchitectureGuardrails.Tests.ps1` is authoritative.
- Prefer explicit workflow-context objects (`[pscustomobject]` / ordered hashtables) for multi-step flows.

## Error and behavior rules

### Before writing code

1. Read `project.json` `Manifest.PowerShellHostVersion` before changing PowerShell source, scripts, or tests, and keep new usage compatible with that target. A `5.1` project must not receive PowerShell 7.x-only syntax, cmdlets, parameters, or APIs unless compatibility is explicitly guarded and within scope. If `Manifest.PowerShellHostVersion` is missing or cannot be parsed from `project.json`, default to targeting PowerShell 5.1 compatibility and note the assumption in your response.
2. Follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Use the repository analyzer wrapper for normal runs and reuse repository-approved settings when invoking `Invoke-ScriptAnalyzer` directly on a focused path. If `.github/instructions/psscriptanalyzer.instructions.md` is not accessible, stop and ask the user to provide it before proceeding with ScriptAnalyzer-related changes.
3. When public command help changes, follow `.github/instructions/platyps-help.instructions.md` and use `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp` instead of hand-authoring the help structure. If `.github/instructions/platyps-help.instructions.md` is not accessible, stop and ask the user to provide it before editing any help content. Do not fall back to hand-authoring the help structure.

### While writing code

1. Prefer clear, structured Nova errors over silent fallback behavior.
2. Preserve existing warning semantics; do not rename warning opt-ins to a generic `-Force` pattern.
3. Keep CLI spellings and PowerShell spellings distinct in messages and docs.
4. Do not add PSScriptAnalyzer `ExcludeRule`, `ExcludeRules`, suppression attributes, or generated settings that hide analyzer findings. Fix the rule violation instead.
5. In `run.ps1` and any task script that runs the full quality pipeline, invoke the tools in this order: (1) ScriptAnalyzer via the repository wrapper, (2) `Invoke-NovaBuild`, (3) `Invoke-NovaTest`, (4) `Test-NovaBuild`. Do not reorder them in other contexts.
6. If `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before treating the change as complete.

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

- Treat `.github/instructions/code-quality-matrix.instructions.md` as mandatory maintainability guidance for new or heavily changed code in `src/**/*.ps1`; keep that code short, single-purpose, low-duplication, and split by clear responsibility. If `.github/instructions/code-quality-matrix.instructions.md` is not accessible, stop and ask the user to provide it before proceeding with the related refactoring or maintainability-sensitive change.
- Favor short functions and extracted helpers over large nested logic.
- Replace long `switch` or `if`/`elseif` chains with lookup tables, dispatch helpers, or focused strategy functions when behavior varies by mode, provider, or state.
- Avoid copy/paste across source or test files.
- Remove dead code and commented-out code instead of leaving it behind.
- Prefer concise, specific names over identifiers that hide multiple responsibilities.
- Replace magic values with named constants, lookup tables, or variables that reveal intent.
- Add comments only when the code would otherwise be hard to follow.
- Avoid broad catch blocks that hide failures; catch specific exceptions only when the layer can add useful context.

## Verification

- Update or add Pester coverage for behavior changes.
- Recheck `tests/ArchitectureGuardrails.Tests.ps1` when changing layering or helper placement.
- Run `./run.ps1` before considering a code change complete. If `./run.ps1` cannot be executed because dependencies are missing or the environment is not configured, document the blocker explicitly in your response and list which verification steps were skipped. Do not treat the change as complete until a human confirms the run result.
- Resolve any ScriptAnalyzer findings that `./run.ps1` reports before handoff.
- Before handoff, review the changed/generated text files and normalize any file endings that violate the single-trailing-newline rule.
