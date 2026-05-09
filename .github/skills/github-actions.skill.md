# Skill: GitHub Actions and CI/CD

## When to use

Use this skill when changing CI workflows, artifact handling, CodeScene coverage flow, publish automation, or reusable
actions under `.github/actions/`.

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
- Keep CI output human-readable in the step summary when relevant.

## Common pitfalls

- Changing release automation without understanding the custom actions
- Breaking the CodeScene coverage artifact handoff
- Updating docs or scripts without updating the matching workflow text
- Assuming documentation-only workflow changes are low-risk when they describe branch mutation or publish behavior

## Verification

- Re-run relevant local scripts when possible
- Re-read the touched workflow and script pair together
- Run `./run.ps1` if repo code or workflow helper scripts changed
