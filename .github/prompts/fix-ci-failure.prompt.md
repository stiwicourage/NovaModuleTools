# Fix NovaModuleTools CI failure

> Invoke with `@.github/prompts/fix-ci-failure.prompt.md`. Delegates to the `powershell-developer` or `test-engineer` agent depending on the failing area.

Investigate and fix a failing NovaModuleTools CI or workflow issue.

## Required inputs

- Failing workflow name, job, and error output

## Required process

1. Read the failing workflow in `.github/workflows/`.
2. Inspect the script or custom action that owns the failing step.
3. Reproduce locally with the closest existing command or helper script.
4. Fix the root cause with the smallest safe change.
5. Update tests or docs if the workflow behavior changed.
6. Summarize the failure mode, the fix, and the validation.

## Repository-specific reminders

- `Tests.yml` owns test/coverage artifacts and CodeScene coverage gates.
- `Publish.yml` is high-risk because it handles publish, release commits, tags, and branch updates.
- `powershell.yml` is analyzer-focused and should stay narrow.
