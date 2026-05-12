---
applyTo: "CHANGELOG.md,RELEASE_NOTE.md,project.json,.github/workflows/Publish.yml,.github/pull_request_template.md,src/public/InvokeNovaRelease.ps1,src/public/PublishNovaModule.ps1,src/public/UpdateNovaModuleVersion.ps1,tests/**/*Release*.ps1,tests/**/*Package*.ps1"
---

# NovaModuleTools release policy

## Scope

Use this file when changing versioning, changelog handling, package metadata, publish workflows, or GitHub release automation.

## Versioning rules

- Follow Semantic Versioning intent.
- Treat `CHANGELOG.md` as the exhaustive release history.
- Treat `RELEASE_NOTE.md` as the interface-focused summary for public cmdlet, CLI, configuration, and migration changes.
- Keep `## [Unreleased]` valid and readable.
- Use only the official Keep a Changelog section types in both files: `Added`, `Changed`, `Deprecated`, `Removed`,
  `Fixed`, and `Security`.
- Do not add custom section headings such as `Documentation`; place documentation-related release notes under the official type that best matches the real change.
- If `RELEASE_NOTE.md` has no public API or workflow changes under `## [Unreleased]`, keep the exact placeholder under
  `### Added`: `No public API or workflow changes in this release. Internal maintenance only.`
- If `RELEASE_NOTE.md` has real release-note entries, do not keep that placeholder.
- Do not add compare-link footer URLs to `RELEASE_NOTE.md`.
- For unreleased feature iterations, update the existing `Added` entry instead of adding an internal-history `Changed`
  entry.

## Workflow rules

- `Publish.yml` owns the release/publish flow.
- `main` handles stable release commit/tag flow and prepares `develop` for the next prerelease.
- `develop` handles prerelease publish and next-prerelease bump flow.
- Do not change branch mutation behavior, tag creation, or publish steps without reading `.github/workflows/Publish.yml`
  and the related custom actions first.

## Documentation rules

- Review `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` for workflow or release changes.
- Update command help in `docs/NovaModuleTools/en-US/` when public command behavior changes.
- Update `docs/*.html` only when end-user behavior or examples changed.
- Use `.github/pull_request_template.md` as the authoritative structure when preparing a release summary for review.

## Agent safety rules

- Do not publish, create tags, or push release commits unless the task explicitly requires it.
- Do not assume a preview flow should move `latest`; check the current package and release tests first.
- Do not change release defaults without corresponding tests and changelog entries.

## Verification

- Validate the touched release or versioning path with targeted tests.
- Run `./run.ps1` after code changes.
- Re-read `.github/pull_request_template.md` before preparing release-related summaries.
