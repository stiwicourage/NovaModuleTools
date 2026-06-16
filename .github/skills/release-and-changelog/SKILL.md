---
name: release-and-changelog
description: Guidance for NovaModuleTools semantic versioning, changelog handling, release notes, and publish-flow changes.
---

# Skill: release and changelog management

## When to use

Use this skill when working on semantic versioning, release automation, package metadata, prerelease flow, `CHANGELOG.md`, or `RELEASE_NOTE.md`.

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
- Use only the official Keep a Changelog section types: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security`, and choose the one that best matches the actual release impact.
- When the appropriate section type differs between `CHANGELOG.md` and `RELEASE_NOTE.md` for the same change, use the type that best describes the internal implementation in `CHANGELOG.md` and the type that best describes the public interface impact in `RELEASE_NOTE.md`. Document both choices in the PR description if they differ.
- If a single release change spans multiple section types, create separate entries under each relevant section type rather than combining them into one entry.
- Do not create custom changelog headings such as `Documentation`; place documentation-related release notes under the official type that best matches the actual release impact. For documentation-only changes with no behavior change, use `Fixed` if the docs corrected an error, `Changed` if existing doc content was revised, or `Added` if new documentation was introduced. If the documentation change accompanies a code change, include it in the same entry as that code change rather than creating a separate entry.
- `RELEASE_NOTE.md` placeholder rule:
	1. Check whether `## [Unreleased]` contains any entries describing public API or workflow changes.
	2. If no such entries exist, ensure the `### Added` section contains exactly this line: `No public API or workflow changes in this release. Internal maintenance only.`
	3. If real release-note entries exist, remove that placeholder line entirely.
- Keep `RELEASE_NOTE.md` free of compare-link footer URLs.
- If a feature is still evolving before release, update its existing `Added` entry in `[Unreleased]` rather than adding a new entry. If no entry exists yet for that feature, create one and update it as the feature evolves.
- If stable and preview behavior differ, document both behaviors explicitly in `CHANGELOG.md` under separate notes or a clearly labeled sub-description so readers can distinguish them.
- Branch versioning roles: `main` is the stable release branch, so version bumps and changelog entries there reflect published stable releases. `develop` is the prerelease branch, so version bumps there use prerelease suffixes and changelog entries remain under `[Unreleased]` until merged to `main`. Never apply stable versioning actions to `develop` or prerelease actions to `main`.
- When writing release-preparation summaries, structure the text to match the sections in `.github/pull_request_template.md` so it can be pasted without reformatting. Specifically, align entries to the changelog and validation sections of that template.

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
