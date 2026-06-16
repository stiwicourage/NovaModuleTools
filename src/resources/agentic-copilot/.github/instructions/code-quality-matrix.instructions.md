---
applyTo: "src/**/*.ps1,scripts/**/*.ps1,reload.ps1"
---

# Code quality matrix

## Purpose

Use this file as the maintainability guidance for PowerShell source and helper scripts in this repository.

It frames ten widely recognized maintainability dimensions in PowerShell terms: unit size, unit complexity, duplication, interface width, separation of concerns, coupling, component balance, codebase size, automated tests, and clean code. Each guideline below covers one dimension with concrete PowerShell thresholds.

This file tells Agentic Copilot how to shape source code from the start. Test-specific guidance lives in `.github/instructions/testing-policy.instructions.md` and the `pester-testing` skill. The matching operational workflow for these ten rules lives in the `building-maintainable-code` skill.

## How to apply this guidance

- Use these rules when writing or reviewing `src/**/*.ps1`, `scripts/**/*.ps1`, and `reload.ps1`.
- For script files that contain top-level imperative code without wrapping functions (`run.ps1`, `reload.ps1`, and similar entry scripts), treat each logically distinct top-level block as a unit. If any such block exceeds 15 lines, extract it into a named private helper function and call it from the script.
- Prefer these patterns in new or heavily changed code instead of leaving cleanup for later.
- When reviewing a file that was not authored in this session, limit findings to: (a) all violations introduced or worsened by the current change, and (b) up to three pre-existing violations ranked by the G1-G10 priority order. Do not enumerate every pre-existing violation in a legacy file; instead note the total count and recommend a dedicated refactoring task.
- Treat the thresholds as default goals, not as opinions. Use them to decide whether a function or file should be split.
- If a change must violate one of these rules, keep the exception narrow and explain the trade-off clearly in the handoff.
- Favor small refactors that remove the smell at the source over comments, suppressions, or wrappers that only hide it.
- Apply lower-level (unit) guidelines before higher-level (component) guidelines. Fix size, complexity, duplication, and interface width first; balance and component coupling become much easier afterward.
- Every commit counts. Leave each touched file at least as healthy as you found it; that is how the codebase trends upward over time.

When multiple smells are present, raise findings in this order: (1) size - G1, (2) complexity - G2, (3) duplication - G3, (4) interface width - G4, (5) separation of concerns - G5, (6) coupling - G6, (7) balance - G7, (8) codebase size - G8, (9) test coverage - G9, (10) cleanliness - G10. Do not raise a component-level finding (G5-G8) until all unit-level findings (G1-G4) in the same file have been identified.

## Guideline 1 — Write short units of code

- Threshold: count only the executable statement lines inside the function body. Exclude: the `function` declaration line, the closing `}` of the function, the entire `param(...)` block (from `param` through its closing `)`), `[CmdletBinding()]`, `begin {` / `process {` / `end {` block-delimiter lines and their closing `}` lines, and blank lines. Every other line counts as one toward the 15-line limit.
- Why: short units are easier to read, test, reuse, and review, and they fit inside human and agent working memory.
- How to apply in PowerShell:
    - Extract named helper functions; in `src/private/` they may stay as sibling top-level functions in the same file when they belong to that entry function.
    - Replace inline transformation chains with a helper named after its intent.
    - Move repeated setup or formatting into helpers, not into comments that mark sections.
- Common objection: "It is one logical step." If the function still ends up over 15 lines, the step has substeps. Name them.

## Guideline 2 — Write simple units of code

- Threshold: keep the condition complexity score at most 5. Score 1 point for each: `if`, `elseif`, `switch` case body, ternary `? :`, `while`, `for`, `foreach`, `catch`, `-and`, and `-or`. This is stricter than standard cyclomatic complexity; it penalizes dense boolean guards as well as branching structure.
- Why: complex units have too many paths to test thoroughly and are the most common source of regressions.
- How to apply in PowerShell:
    - Replace long `switch` blocks or `if`/`elseif` chains with a dispatch hashtable keyed by mode, provider, state, or kind.
    - Replace nested decision branches with early returns and small `Test-*` / `Resolve-*` / `Get-*Action` helpers.
    - Use PowerShell classes when several branches behave like the same operation on different data.
- Common objection: "The domain is complex." The domain may be complex; the unit must not be. Split the decision layer from the work layer.

## Guideline 3 — Write code once

- Rule: no Type 1 clones. Any block of 6 or more consecutive executable statement lines that is textually identical in two or more locations is a Type 1 clone finding. Exclude blank lines, comment-only lines, and `#region` / `#endregion` markers when counting.
- Why: duplicated code drifts. Bugs fixed in one copy keep living in the other.
- How to apply in PowerShell:
    - Extract the shared block into a helper under the correct `src/private/<domain>/` folder and call it from both sites.
    - When two flows differ only in inputs or order of small steps, parameterize the helper instead of cloning it.
    - For repeated test setup, extend `tests/*TestSupport.ps1` or `tests/TestHelpers/` instead of copying `BeforeAll` blocks.
- Common objection: "It is a small variation, so cloning is fine." Extract the shared part and pass the variation as a parameter, a scriptblock, or a small lookup table.

## Guideline 4 — Keep unit interfaces small

- Threshold: at most 4 explicitly declared parameters in the `param()` block, regardless of whether they are mandatory, optional, or pipeline-bound. `[CmdletBinding()]` implicit common parameters (`Verbose`, `Debug`, `ErrorAction`, and similar) do not count. Pipeline-bound parameters declared in `param()` do count.
- Why: long parameter lists are hard to read at the call site, hard to extend safely, and usually a sign that two or more concepts have been bundled into one function.
- How to apply in PowerShell:
    - Group related parameters into a single `[pscustomobject]`, ordered hashtable, or small class such as a workflow context, an options object, or a request.
    - Use parameter sets when the function legitimately supports more than one calling shape, not as a way to hide 8 parameters in one signature.
    - Pass already-prepared context objects (for example `WorkflowContext`, `BuildOption`, `TestOption`) between helpers instead of passing every individual field.
- Common objection: "Each parameter is needed." If they always travel together, give the group a name and pass it as one object.

## Guideline 5 — Separate concerns in modules

- Rule: each file owns one externally called responsibility.
- Why: modules that mix concerns become magnets for unrelated changes and are harder to test, replace, or move.
- How to apply in PowerShell:
    - In `src/public/`, keep exactly one top-level public function per file, matching the file name.
    - In `src/private/`, keep at most one externally called function per file. Additional helpers may stay as sibling top-level functions in the same file when they belong to that entry function.
    - Do not declare nested functions inside other functions. Keep helpers as siblings at file scope.
    - When a private file starts mixing lookup, mutation, formatting, validation, and transport, split it by concern before it becomes a catch-all helper.
- Common objection: "It is convenient to keep both here." Convenience now becomes confusion later. Split early, while the seams are still obvious.

## Guideline 6 — Couple architecture components loosely

- Rule: public commands depend on private adapter/helper layers, not on raw infrastructure.
- Why: tight coupling to environment variables, Git, HTTP, file system, or module-update APIs spreads infrastructure leaks across the public surface and breaks tests.
- How to apply in PowerShell:
    - Route environment access, Git execution, REST calls, uploads, and self-update behavior through their approved private helpers. `tests/*Architecture*.Tests.ps1` is authoritative.
    - Hide provider-specific or platform-specific branching behind a small adapter surface so callers depend on a stable contract, not on the provider's quirks.
    - A helper that exists solely to rename or re-export another function with no added policy, validation, error translation, or mock surface is a pass-through and should be removed. A helper that wraps an infrastructure call (environment, Git, HTTP, file system, and similar) to provide a stable internal contract is an adapter and is exempt from this rule even if it currently forwards parameters directly, provided it lives under the appropriate `src/private/<domain>/` adapter folder.
- Common objection: "The adapter feels redundant." It pays off the moment the underlying call changes, gains an error mode, or needs mocking.

## Guideline 7 — Keep architecture components balanced

- Rule: keep `src/private/<domain>/` folders and the public surface balanced in size and responsibility.
- Why: one folder absorbing everything is a code smell at the component level. It signals missing domains.
- How to apply in PowerShell:
    - When one private domain keeps absorbing unrelated responsibilities, propose a new domain folder before it becomes the default dumping ground.
    - When the public command surface starts mixing CLI routing, package operations, and quality flows in the same file, split the public command instead of growing it.
    - Keep workflow contexts narrow per workflow. A single context object that knows everything about every flow is a balance smell.
- Common objection: "It is only a few helpers." A few becomes many. Name the concern early so callers and reviewers can find them.

## Guideline 8 — Keep your codebase small

- Rule: do not let the codebase grow for its own sake.
- Why: every line written is a line maintained, tested, reviewed, scanned, and reasoned about.
- How to apply in PowerShell:
    - Remove dead code, obsolete private helpers, and commented-out code instead of leaving them "just in case." Source control is the safety net.
    - Prefer existing platform capabilities, repository helpers, and well-known modules over custom utility layers when the custom code adds no durable value.
    - When extending behavior, ask whether the extension belongs in an existing helper rather than as a parallel new helper.
    - Treat scaffold and template additions like production code; they multiply across every generated project.
- Common objection: "We might need it later." Delete it now. Re-add it later from history with the context that proves it is needed.

## Guideline 9 — Automate tests

- Rule: every behavior change requires Pester coverage in this repository.
- Why: automated tests make change safe, predictable, and reviewable, and they are the only practical way to prevent regressions in a continuously evolving codebase.
- How to apply in PowerShell:
    - Add or update a source-mirrored `tests/<area>/<Name>.Tests.ps1` file for every changed `src/**/*.ps1` file.
    - Cover both the happy path and the meaningful unhappy, invalid, and boundary cases that the change introduces.
    - Use `Invoke-NovaTest` as the unit-test entrypoint and `Test-NovaBuild` as the build-validation integration-test entrypoint in Nova-managed projects. Do not call `Invoke-Pester` directly.
    - Isolate collaborators with mocks/stubs when verifying side effects or branching. Keep tests order-independent.
    - See `.github/instructions/testing-policy.instructions.md` and the `pester-testing` skill for the full testing rules.
- Common objection: "It is too small to test." If it is too small to test, it is too small to be a change worth landing.

## Guideline 10 — Write clean code

- Rule: leave no trace. Touched files leave with fewer smells than they arrived with.
- Why: small smells compound. A few magic numbers, a few swallowed exceptions, a few commented-out blocks per commit becomes an unmaintainable file in months.
- How to apply in PowerShell:
    - No bad comments. If a comment is needed to explain a line, rename the helper or split the function until the comment becomes redundant.
    - No commented-out code. Use source control history instead.
    - No dead code. Remove unreachable branches and unused private helpers.
    - No long or multi-responsibility identifiers. Use focused, intent-revealing names.
    - No magic literals. Lift unexplained numbers and strings into named constants, script variables, or lookup tables.
    - No broad catches. Catch specific exceptions only when the layer adds context; otherwise let failures surface clearly through `Stop-{{ShortName}}Operation` or a structured `ErrorRecord` instead of silent fallback.
    - Files must end with exactly one trailing newline and no extra blank lines at the bottom.
- Common objection: "Style is taste." Style is repeatable. These items are not taste, they are signals reviewers and tools rely on.

## Review expectations

- Flag long mixed-responsibility functions, deep nesting, duplicated blocks, long parameter lists, pass-through helpers, provider-specific branching spread across callers, dead or commented-out code, magic values, and broad or hidden exception handling.
- Guidelines 3 and 9 apply to test files to the extent that they address duplication and coverage requirements. For smells that are specific to Pester syntax, mock hygiene, or test-file structure beyond duplication and coverage, route feedback to `.github/instructions/testing-policy.instructions.md` and the `pester-testing` skill instead of stretching this file to cover test-only patterns.
- For step-by-step refactoring of unhealthy files, use the `building-maintainable-code` skill for checks between steps.
