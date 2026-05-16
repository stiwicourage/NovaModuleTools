---
applyTo: "src/**/*.ps1,scripts/**/*.ps1,run.ps1,reload.ps1"
---

# Code quality matrix

## Purpose

Use this file as the maintainability guidance for PowerShell source and helper scripts in this repository.

It frames ten widely recognized maintainability dimensions in PowerShell terms: unit size, unit complexity, duplication, interface width, separation of concerns, coupling, component balance, codebase size, automated tests, and clean code. Each guideline below covers one dimension with concrete PowerShell thresholds.

This file tells Agentic Copilot how to shape source code from the start. Test-specific guidance lives in `.github/instructions/testing-policy.instructions.md` and the `pester-testing` skill. The matching operational workflow for these ten rules lives in the `building-maintainable-code` skill.

## How to apply this guidance

- Use these rules when writing or reviewing `src/**/*.ps1`, `scripts/**/*.ps1`, `run.ps1`, and `reload.ps1`.
- Prefer these patterns in new or heavily changed code instead of leaving cleanup for later.
- Treat the thresholds as default goals, not as opinions. Use them to decide whether a function or file should be split.
- If a change must violate one of these rules, keep the exception narrow and explain the trade-off clearly in the handoff.
- Favor small refactors that remove the smell at the source over comments, suppressions, or wrappers that only hide it.
- Apply lower-level (unit) guidelines before higher-level (component) guidelines. Fix size, complexity, duplication, and interface width first; balance and component coupling become much easier afterward.
- Every commit counts. Leave each touched file at least as healthy as you found it; that is how the codebase trends upward over time.

## Guideline 1 — Write short units of code

- Threshold: keep each PowerShell function body at most 15 lines, excluding the `function` line, the closing `}`, the `param(...)` block, and blank lines.
- Why: short units are easier to read, test, reuse, and review, and they fit inside human and agent working memory.
- How to apply in PowerShell:
    - Extract named helper functions; in `src/private/` they may stay as sibling top-level functions in the same file when they belong together.
    - Replace inline transformation chains with a helper named after its intent.
    - Move repeated setup or formatting into helpers, not into comments that mark sections.
- Common objection: "It is one logical step." If the function still ends up over 15 lines, the step has substeps. Name them.

## Guideline 2 — Write simple units of code

- Threshold: keep cyclomatic complexity at most 5, which is 4 branch points. Count `if`, `elseif`, `switch` case bodies, `-and`, `-or`, ternary `? :`, `while`, `for`, `foreach`, and `catch`.
- Why: complex units have too many paths to test thoroughly and are the most common source of regressions.
- How to apply in PowerShell:
    - Replace long `switch` blocks or `if`/`elseif` chains with a dispatch hashtable keyed by mode, provider, state, or kind.
    - Replace nested decision branches with early returns and small `Test-*` / `Resolve-*` / `Get-*Action` helpers.
    - Use PowerShell classes when several branches behave like the same operation on different data.
- Common objection: "The domain is complex." The domain may be complex; the unit must not be. Split the decision layer from the work layer.

## Guideline 3 — Write code once

- Rule: no Type 1 clones. Any identical block of 6 or more functional lines that appears twice is a finding.
- Why: duplicated code drifts. Bugs fixed in one copy keep living in the other.
- How to apply in PowerShell:
    - Extract the shared block into a helper under the correct `src/private/<domain>/` folder and call it from both sites.
    - When two flows differ only in inputs or order of small steps, parameterize the helper instead of cloning it.
    - For repeated test setup, extend `tests/*TestSupport.ps1` or `tests/TestHelpers/` instead of copying `BeforeAll` blocks.
- Common objection: "It is a small variation, so cloning is fine." Extract the shared part and pass the variation as a parameter, a scriptblock, or a small lookup table.

## Guideline 4 — Keep unit interfaces small

- Threshold: at most 4 parameters per function. `[CmdletBinding()]` common parameters do not count.
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
    - Route environment access, Git execution, REST calls, uploads, and self-update behavior through their approved private helpers. `tests/ArchitectureGuardrails.Tests.ps1` is authoritative.
    - Hide provider-specific or platform-specific branching behind a small adapter surface so callers depend on a stable contract, not on the provider's quirks.
    - Avoid pass-through helpers that only forward parameters to another function. Either add policy, validation, translation, or abstraction, or call the underlying function directly.
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
    - Use `Test-NovaBuild` as the authoritative test entrypoint in Nova-managed projects. Do not call `Invoke-Pester` directly.
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
    - No broad catches. Catch specific exceptions only when the layer adds context; otherwise let failures surface clearly through `Stop-NovaOperation` or a structured `ErrorRecord` instead of silent fallback.
    - Files must end with exactly one trailing newline and no extra blank lines at the bottom.
- Common objection: "Style is taste." Style is repeatable. These items are not taste, they are signals reviewers and tools rely on.

## Review expectations

- Flag long mixed-responsibility functions, deep nesting, duplicated blocks, long parameter lists, pass-through helpers, provider-specific branching spread across callers, dead or commented-out code, magic values, and broad or hidden exception handling.
- When a finding is unit-level (Guidelines 1–4), prefer raising it before component-level findings (Guidelines 5–8). The unit fix usually makes the component fix smaller.
- When the code smell is test-specific, route that feedback through `.github/instructions/testing-policy.instructions.md` and the `pester-testing` skill instead of stretching this file to cover test-only patterns.
- For step-by-step refactoring of unhealthy files, use the `building-maintainable-code` and `guiding-refactoring-with-code-health` skills together: the first picks the right guideline, the second runs measured maintainability checks between steps.
