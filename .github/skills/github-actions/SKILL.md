---
name: github-actions
description: Guidance for changing NovaModuleTools GitHub Actions workflows, CI artifact flow, or reusable workflow actions.
---

# Skill: GitHub Actions and CI/CD

## When to use

Use this skill when changing CI workflows, artifact handling, CodeScene coverage flow, publish automation, or reusable actions under `.github/actions/`.

## Relevant files

- `.github/workflows/Tests.yml`
- `.github/workflows/Publish.yml`
- `.github/workflows/powershell.yml`
- `.github/actions/*/action.yml`
- `scripts/build/ci/*.ps1`
- `run.ps1`

## Expected practices

- Read the whole affected workflow before editing a single step.
- Keep artifact names and paths aligned with the scripts that produce them.
- Treat `main` and `develop` release behavior in `Publish.yml` as deliberate and branch-specific.
- If a change must alter release behavior for both `main` and `develop` at once, explicitly justify the change for each branch independently in comments or the PR description before editing `Publish.yml`.
- Always emit a step summary (`$GITHUB_STEP_SUMMARY`) for steps that produce test results, coverage reports, or publish outcomes. Omit summaries for purely mechanical setup steps such as checkout or dependency restore.

## Common pitfalls

- Changing release automation without understanding the custom actions
- Breaking the CodeScene coverage artifact handoff
- Updating docs or scripts without updating the matching workflow text
- Assuming documentation-only workflow changes are low-risk when they describe branch mutation or publish behavior

## Verification

- Re-run relevant local scripts when possible
- Re-read the touched workflow and script pair together
- Run `./run.ps1` if repo code or workflow helper scripts changed
- If local execution of `./run.ps1` is not possible, document the untested assumption explicitly in the PR description and flag it for reviewer verification.
