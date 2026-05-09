# Skill: CodeScene quality and coverage

## When to use

Use this skill when CodeScene reports low Code Health, duplication, or changed-code coverage failures.

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
- Fix duplicated test structure by extracting or parameterizing setup.
- Add the smallest test that covers the missing changed-code branch.
- Prefer incremental refactors over large rewrites.

## Common pitfalls

- Counting a passing Pester run as sufficient when CodeScene still flags duplication
- Adding more assertions into already-large test files instead of splitting responsibly
- Ignoring changed-code coverage failures because total coverage looks fine

## Verification

- Re-run the affected test file(s)
- Re-run the CodeScene file review after the refactor
- Run the pre-commit safeguard before suggesting a commit
- Run a change-set analysis before suggesting a PR for larger branch work
- Run `./run.ps1` after code changes
