---
name: release-and-changelog
description: Guidance for NovaModuleTools semantic versioning, changelog handling, release notes, and publish-flow changes.
---

# Skill: release and changelog management

## When to use

Use this skill when working on semantic versioning, release automation, package metadata, prerelease flow,
`CHANGELOG.md`, or `RELEASE_NOTE.md`.

## Relevant files

- `CHANGELOG.md`
- `RELEASE_NOTE.md`
- `project.json`
- `.github/pull_request_template.md`
- `.github/workflows/Publish.yml`
- `src/public/InvokeNovaRelease.ps1`
- `src/public/PublishNovaModule.ps1`
- `src/public/UpdateNovaModuleVersion.ps1`
- release and package tests under `tests/`

## Expected practices

- Keep unreleased entries readable and outcome-focused.
- Keep `CHANGELOG.md` exhaustive and keep `RELEASE_NOTE.md` limited to interface-facing change summaries.
- Use `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` intentionally.
- Update an existing unreleased `Added` entry when a feature is still evolving before release.
- Verify whether stable and preview behavior differ.
- Shape release-preparation summaries so they fit the PR template directly.

## Common pitfalls

- Logging internal iteration history in the changelog instead of final unreleased behavior
- Copying internal-only changelog detail into `RELEASE_NOTE.md` when public interfaces are unchanged
- Forgetting that `main` and `develop` have different publish/version roles
- Changing package or release defaults without corresponding tests

## Verification

- Review `CHANGELOG.md`, `RELEASE_NOTE.md`, workflow docs, and affected tests together
- Run targeted versioning/package tests when behavior changed
- Run `./run.ps1` for code changes
