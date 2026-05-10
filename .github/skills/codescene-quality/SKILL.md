---
name: codescene-quality
description: Guidance for improving NovaModuleTools CodeScene Code Health, duplication, and changed-code coverage outcomes.
---

# Skill: CodeScene quality and coverage

## When to use

Use this skill when CodeScene reports low Code Health, duplication, or changed-code coverage failures.

Use the narrower sibling skills when the task is more specific:

- Use `/guiding-refactoring-with-code-health` when refactoring an unhealthy file and choosing small structural steps.
- Use `/safeguarding-ai-generated-code` when AI-touched changes need Code Health gates before commit, handoff, or PR
  readiness.

## Relevant files and tools

- `tests/ArchitectureGuardrails.Tests.ps1`
- `tests/*Coverage*.Tests.ps1`
- `tests/*TestSupport.ps1`
- `.github/actions/check-coverage/action.yml`
- `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`
- CodeScene review / safeguard tooling

## Expected practices

- Treat Code Health as the repository's authoritative maintainability signal.
- Aim for Code Health `10.0` on touched files, not merely "good enough."
- Treat CodeScene findings as actionable maintainability signals.
- If CodeScene tooling is unavailable locally, continue with the normal repository validation flow and continue silently;
  pull requests and CI remain the effective CodeScene gate.
- Fix duplicated test structure by extracting or parameterizing setup.
- Add the smallest test that covers the missing changed-code branch.
- Prefer incremental refactors over large rewrites.

## Common pitfalls

- Counting a passing Pester run as sufficient when CodeScene still flags duplication
- Adding more assertions into already-large test files instead of splitting responsibly
- Ignoring changed-code coverage failures because total coverage looks fine

## Verification

- Re-run the affected test file(s)
- Re-run the CodeScene file review after the refactor when local CodeScene tooling is available
- Run the pre-commit safeguard before suggesting a commit when local CodeScene tooling is available
- Run a change-set analysis before suggesting a PR for larger branch work when local CodeScene tooling is available
- Run `./run.ps1` after code changes
