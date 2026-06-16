# Fix NovaModuleTools CI failure

> Invoke with `@.github/prompts/fix-ci-failure.prompt.md`. Delegate to `powershell-developer` when the failing step invokes a PowerShell script or custom action. Delegate to `test-engineer` when the failing step runs tests, generates coverage reports, or uploads test artifacts.

Investigate and fix a failing NovaModuleTools CI or workflow issue.

## Required inputs

- Failing workflow name, job, and error output

If any required input is missing, stop and ask the user to supply it before proceeding. Do not attempt to guess the failing workflow, job, or error output.

## Required process

1. Read the failing workflow in `.github/workflows/`.
2. Inspect the script or custom action that owns the failing step.
3. Reproduce locally by running the exact command from the failing workflow step. If that command is not directly runnable locally, document the closest approximation and note the difference. If the failure cannot be reproduced locally due to missing secrets, environment, or runner dependencies, document that fact explicitly and proceed to root-cause analysis using the error output and workflow definition alone.
4. Fix the root cause by changing only the files directly involved in the failure. Do not refactor unrelated code, rename public interfaces, or alter behavior outside the failing step.
5. If the fix changes what the workflow does, what it produces, or how it is invoked, update the corresponding tests and documentation to match the new behavior.
6. Summarize the failure mode, the fix, and the validation.

## Repository-specific reminders

- `Tests.yml` owns test/coverage artifacts and CodeScene coverage gates.
- `Publish.yml` is high-risk because it handles publish, release commits, tags, and branch updates.
- If the failing step is in `Publish.yml`, do not apply any fix without first presenting a detailed description of the change and its blast radius to the user for explicit approval before editing the file.
- `powershell.yml` is analyzer-focused and should stay narrow.
