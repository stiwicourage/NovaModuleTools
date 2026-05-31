---
name: building-maintainable-code
description: Use when writing or refactoring {{ProjectName}} PowerShell code, which should always follow the maintainability guidelines.
---

# Skill: Building maintainable code

## When to use

Use this skill when:

- adding a new public command or private helper to {{ProjectName}}
- refactoring a function, file, or domain folder that has grown over time
- a reviewer or the repository quality loop flags maintainability problems
- you want a concrete, PowerShell-aware playbook for the guidelines

Do not use this skill for:

- test-specific guidance — use the `pester-testing` skill
- release/changelog work — use the `release-and-changelog` skill
- measuring or driving a single file's score across steps — use the step-by-step workflow below for that

The companion instruction file is `.github/instructions/code-quality-matrix.instructions.md`. This skill is the actionable workflow that implements those rules.

## Relevant files and commands

- `src/public/*.ps1` and `src/private/<domain>/*.ps1`
- `tests/*Architecture*.Tests.ps1`
- the repository quality loop, when present
- `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
- `Invoke-NovaTest`
- `Test-NovaBuild`

## Guideline order and precedence

Apply lower-level guidelines first. Unit-level structure fixes (Guidelines 1–4) usually make the component-level work (5–8) smaller and safer.

1. Write short units of code
2. Write simple units of code
3. Write code once
4. Keep unit interfaces small
5. Separate concerns in modules
6. Couple architecture components loosely
7. Keep architecture components balanced
8. Keep your codebase small
9. Automate tests
10. Write clean code

## Thresholds at a glance

| Guideline | PowerShell threshold |
| --- | --- |
| 1 Short units | ≤ 15 lines per function body (excluding `function`/`}`, `param(...)`, blank lines) |
| 2 Simple units | ≤ 4 branch points per function (cyclomatic complexity ≤ 5) |
| 3 Write once | no identical block ≥ 6 functional lines repeated anywhere |
| 4 Small interfaces | ≤ 4 parameters per function (`[CmdletBinding()]` common parameters not counted) |
| 5 Separate concerns | one externally called function per file, matching the file name |
| 6 Loose coupling | infrastructure only via approved private adapters |
| 7 Balanced components | no `src/private/<domain>/` absorbing unrelated responsibilities |
| 8 Small codebase | no dead/commented-out code; reuse over custom utilities |
| 9 Automate tests | source-mirrored Pester for every changed `src/**/*.ps1` |
| 10 Clean code | no bad comments, magic values, swallowed exceptions; single trailing newline |

## Implementation playbook

Follow these steps for any non-trivial PowerShell change.

1. Read the changed function and surrounding file. Note where it sits in `src/public/`, `src/private/<domain>/`, or `scripts/`.
2. For each new or heavily changed function, walk the checklist below in order.
3. If a step requires a refactor, make it the smallest structural step that fixes the specific finding. Do not bundle unrelated cleanup.
4. After meaningful steps, run the repository quality loop when present (typically analyzer → build → `Invoke-NovaTest` → `Test-NovaBuild`).
5. Before handoff, normalize every changed text file to exactly one trailing newline.

### Step 1 — Short units (≤ 15 lines)

Counting rule: only the body lines count. Exclude `function`, opening `{`, closing `}`, `param(...)`, attribute lines, and blank lines.

Refactor options in PowerShell:

- Extract the most distinct top-of-function block into a named helper. Place it as a sibling top-level function in the same private file if it belongs to the entry function.
- Replace inline preparation with `Resolve-*`, `Get-*Context`, or `Build-*Request` helpers that return the prepared object.
- Move repeated formatting into `Format-*` helpers.

Example:

```powershell
function Invoke-NovaRelease {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)][string]$Version,
        [switch]$OverrideWarning
    )

    $context = Resolve-NovaReleaseContext -Version $Version -OverrideWarning:$OverrideWarning
    Assert-NovaReleasePreconditions -Context $context
    if (-not $PSCmdlet.ShouldProcess($context.Target, $context.Operation)) {
        return
    }

    Publish-NovaReleaseArtifacts -Context $context
    Write-NovaReleaseSummary -Context $context
}
```

### Step 2 — Simple units (≤ 4 branch points)

Counting rule: 1 base + each `if` / `elseif` / `switch` case body / `-and` / `-or` / ternary / `while` / `for` / `foreach` / `catch`.

Refactor options in PowerShell:

- Dispatch hashtable:

  ```powershell
  $script:NovaCommandMap = @{
      build    = { param($Args) Invoke-NovaBuild @Args }
      test     = { param($Args) Invoke-NovaTest @Args }
      testBuild = { param($Args) Test-NovaBuild @Args }
      package  = { param($Args) New-NovaPackage @Args }
  }

  function Invoke-NovaCli {
      param(
          [Parameter(Mandatory)][string]$Command,
          [hashtable]$Args = @{}
      )

      $handler = $script:NovaCommandMap[$Command]
      if ($null -eq $handler) {
          Stop-NovaOperation -Message "Unknown command '$Command'." -ErrorId 'Nova.Cli.UnknownCommand' -Category InvalidArgument -TargetObject $Command
      }

      & $handler $Args
  }
  ```

- Early returns instead of nested `if/else`.
- PowerShell classes when several branches behave like the same operation on different data.

### Step 3 — Write once (no clones ≥ 6 lines)

- If the same block lives in two files, extract it into `src/private/<best-fitting-domain>/<Verb-NovaThing>.ps1` and call it from both.
- For tests, extract into `tests/TestHelpers/*.ps1` or `tests/*TestSupport.ps1` rather than copying `BeforeAll` blocks.
- For data variations, parameterize. For step variations, pass a small scriptblock.

### Step 4 — Small interfaces (≤ 4 parameters)

If a function needs more than 4 inputs, bundle the related ones:

```powershell
function New-NovaTestWorkflowContextOption {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$TestResultPath,
        [Parameter(Mandatory)][string]$CoverageOutputPath,
        [double]$CoveragePercentTarget,
        [string[]]$IncludePath
    )

    return [pscustomobject]@{
        TestResultPath = $TestResultPath
        CoverageOutputPath = $CoverageOutputPath
        CoveragePercentTarget = $CoveragePercentTarget
        IncludePath = $IncludePath
    }
}

function Invoke-NovaTestWorkflow {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][pscustomobject]$WorkflowContext
    )

    # one shaped input instead of seven loose parameters
}
```

Use parameter sets only for genuinely different calling shapes, not to hide 8 parameters in one signature.

### Step 5 — Separate concerns in modules

- One externally called function per file, matching the file name.
- Helpers used only inside the file stay as sibling top-level functions in the same file. Never nest functions.
- When a private file mixes lookup, mutation, formatting, validation, and transport, split it by concern.

### Step 6 — Loose component coupling

- Direct `git`, `Invoke-WebRequest`, `Update-Module`, `$env:*`, file IO calls belong only inside their approved private helpers. `tests/*Architecture*.Tests.ps1` is the authoritative boundary.
- Hide provider-specific branching behind a small adapter surface.
- Drop pass-through helpers that only forward parameters and add nothing.

### Step 7 — Balanced components

- If `src/private/<domain>/` keeps growing because no other folder fits, propose a new domain folder rather than overloading the existing one.
- Keep workflow context objects narrow per workflow.

### Step 8 — Small codebase

- Delete dead code, obsolete helpers, and commented-out code in the same change. Use history as the safety net.
- Prefer existing repo helpers and well-known modules before adding a custom utility.
- Apply the same discipline to scaffold templates and Agentic Copilot resources; they multiply across every generated project.

### Step 9 — Automate tests

- Add or update one source-mirrored `tests/<area>/<Name>.Tests.ps1` for every changed `src/**/*.ps1` file.
- Cover happy path plus the meaningful unhappy/invalid/boundary cases that the change introduces.
- Validate with `Invoke-NovaTest` for unit behavior and `Test-NovaBuild` for build-validation integration behavior. Do not call `Invoke-Pester` directly.
- For full rules, follow the `pester-testing` skill and `.github/instructions/testing-policy.instructions.md`.

### Step 10 — Clean code

Run this short pass before handoff on every changed source file:

- replace magic literals with named constants or lookup tables
- remove bad comments, commented-out code, and dead branches
- shorten or rename overly long or multi-responsibility identifiers
- replace broad `catch { }` blocks with specific catches that add context, or remove the swallowing entirely
- confirm a single trailing newline on every changed text file

## Common pitfalls

- Counting only line numbers as the goal. The point is shape, not length; a 14-line function that does 5 things is still wrong.
- Splitting one large function into several equally tangled ones. Each extracted helper must have a clear single responsibility.
- Replacing duplication with overly clever abstractions. Prefer a small, named helper that does exactly the shared step.
- Hiding parameters in `[hashtable]$Options` without defining the shape. Use `[pscustomobject]` or a class so the contract is visible.
- Splitting files by file count rather than by concern. Two files that still mix the same concerns are no improvement over one.
- Adding adapters that only forward parameters. An adapter must add policy, validation, translation, or abstraction.
- Skipping the test mirror for a "trivial" change. Trivial changes are the ones whose regressions are hardest to spot later.
- Leaving "leftover" commented-out code "for later." Later is the next bad merge conflict.

## Verification

- the repository quality loop, when present
- `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` when iterating quickly on PowerShell changes
- `Invoke-NovaTest` for unit behavior validation
- `Test-NovaBuild` for build-validation integration behavior

