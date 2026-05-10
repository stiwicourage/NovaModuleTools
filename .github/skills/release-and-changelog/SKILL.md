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
- Use only the official Keep a Changelog section types: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and
  `Security`.
- Do not create custom changelog headings such as `Documentation`; place documentation-related release notes under the
  official type that best matches the actual release impact.
- If `RELEASE_NOTE.md` has no public API or workflow changes under `## [Unreleased]`, keep the exact placeholder under
  `### Added`: `No public API or workflow changes in this release. Internal maintenance only.`
- If `RELEASE_NOTE.md` has real release-note entries, remove that placeholder.
- Keep `RELEASE_NOTE.md` free of compare-link footer URLs.
- Use `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security` intentionally.
- Update an existing unreleased `Added` entry when a feature is still evolving before release.
- Verify whether stable and preview behavior differ.
- Shape release-preparation summaries so they fit the PR template directly.

## Common pitfalls

- Logging internal iteration history in the changelog instead of final unreleased behavior
- Using unofficial changelog section types such as `Documentation`
- Copying internal-only changelog detail into `RELEASE_NOTE.md` when public interfaces are unchanged
- Leaving the no-public-changes placeholder in place after real release-note entries were added
- Forgetting that `main` and `develop` have different publish/version roles
- Changing package or release defaults without corresponding tests

## Verification

- Review `CHANGELOG.md`, `RELEASE_NOTE.md`, workflow docs, and affected tests together
- Run targeted versioning/package tests when behavior changed
- Run `./run.ps1` for code changes
