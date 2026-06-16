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
- When a change qualifies for both files, write the `CHANGELOG.md` entry with full technical detail and write the `RELEASE_NOTE.md` entry as a concise consumer-facing summary; do not copy the `CHANGELOG.md` text verbatim into `RELEASE_NOTE.md`.
- Keep `## [Unreleased]` valid and readable.
- Use only the official Keep a Changelog section types in both files: `Added`, `Changed`, `Deprecated`, `Removed`,
  `Fixed`, and `Security`. Under `## [Unreleased]`, `Changed` is valid for changes relative to the last released version, but not for internal iteration history of an unreleased feature that is already listed under `Added`.
- Do not add custom section headings such as `Documentation`; place documentation-related release notes under the official type that best matches the real change.
- Under `## [Unreleased]` > `### Added` in `RELEASE_NOTE.md`: if there are no public API or workflow changes, the section must contain exactly the line `No public API or workflow changes in this release. Internal maintenance only.` and nothing else. If there is at least one real entry, remove that placeholder line entirely before adding entries.
- Do not add compare-link footer URLs to `RELEASE_NOTE.md`.
- For unreleased feature iterations, update the existing `Added` entry instead of adding an internal-history `Changed`
  entry.

## Workflow rules

- `Publish.yml` owns the release/publish flow.
- `main` handles stable release commit/tag flow and prepares `develop` for the next prerelease.
- `develop` handles prerelease publish and next-prerelease bump flow.
- Do not change branch mutation behavior, tag creation, or publish steps without reading `.github/workflows/Publish.yml` and the related custom actions first.

## Documentation rules

- Read `README.md` and `CONTRIBUTING.md` to check for content that must be kept consistent with the current change; update them if they describe behavior that has changed. Always update `CHANGELOG.md` and `RELEASE_NOTE.md` as specified in the versioning rules.
- Update command help in `docs/NovaModuleTools/en-US/` when public command behavior changes.
- Update `docs/*.html` only when a public cmdlet's output, parameters, default values, or documented examples change in a way visible to module consumers.
- Use `.github/pull_request_template.md` as the authoritative structure when preparing a release summary for review.

## Agent safety rules

- Do not publish, create tags, or push release commits unless the task explicitly requires it.
- If it is unclear whether a task requires publishing, tagging, or pushing, ask for explicit confirmation before proceeding. Never infer publishing intent from context alone.
- Do not assume a preview flow should move `latest`; check the current package and release tests first.
- Do not change release defaults without corresponding tests and changelog entries.

## Verification

- Validate the touched release or versioning path with targeted tests.
- Run `./run.ps1` after code changes.
- If `./run.ps1` is not found or exits with a non-zero code, stop and report the failure with the full error output before proceeding with any further steps.
- Re-read `.github/pull_request_template.md` before preparing release-related summaries.
