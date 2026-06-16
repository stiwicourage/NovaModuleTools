---
name: codescene-quality
description: Guidance for improving NovaModuleTools CodeScene Code Health, duplication, and changed-code coverage outcomes.
---

# Skill: CodeScene quality and coverage

## When to use

Use this skill when CodeScene reports low Code Health, duplication, or changed-code coverage failures.

Use the narrower sibling skills when the task is more specific:

- Use `/guiding-refactoring-with-code-health` when refactoring an unhealthy file and choosing small structural steps.
- Use `/safeguarding-ai-generated-code` when AI-touched changes need Code Health gates before commit, handoff, or PR readiness.

## Relevant files and tools

- `tests/ArchitectureGuardrails.Tests.ps1`
- `tests/*TestSupport.ps1`
- `.github/actions/check-coverage/action.yml`
- `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`
- CodeScene review / safeguard tooling

## Expected practices

- Treat Code Health as the repository's authoritative maintainability signal.
- Aim to improve touched files toward Code Health `10.0` in their post-change state, not merely "good enough."
- The `10.0` target applies to any file you touch; if a file already starts below `10.0`, improve it as far as safe incremental refactoring allows and document the before/after score delta.
- If incremental refactoring cannot reach `10.0` without a large structural rewrite, document the achieved score, cite the remaining CodeScene finding, and recommend the rewrite as follow-up work instead of doing it immediately.
- Treat CodeScene findings as actionable maintainability signals.
- If CodeScene tooling is unavailable locally, continue with the normal repository validation flow without blocking progress or surfacing an error, but note once that CI and PR gates remain the effective CodeScene check.
- Fix duplicated test structure by extracting or parameterizing setup.
- Add the minimal test, ideally a single focused test function with no shared setup beyond what already exists, that executes the uncovered changed-code branch and asserts its observable outcome.
- Prefer incremental refactors over large rewrites unless the current task explicitly calls for a larger structural change.

## Common pitfalls

- Counting a passing Pester run as sufficient when CodeScene still flags duplication
- Adding more assertions into already-large test files instead of splitting responsibly
- Ignoring changed-code coverage failures because total coverage looks fine

## Verification

Always:
- Re-run the affected test file(s)
- Run `./run.ps1` after code changes

When local CodeScene tooling is available:
- Re-run the CodeScene file review after the refactor when local CodeScene tooling is available
- Run the pre-commit safeguard before suggesting a commit when local CodeScene tooling is available
- Run a change-set analysis before suggesting a PR for larger branch work when local CodeScene tooling is available
- If any verification command fails with an error unrelated to the code change itself, such as a missing dependency or permission error, surface the exact error output to the user and pause before suggesting further steps.
