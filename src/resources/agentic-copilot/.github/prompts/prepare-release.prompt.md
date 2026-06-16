# Prepare a {{ProjectName}} release

> Invoke with `@.github/prompts/prepare-release.prompt.md`. Delegates to the `release-manager` agent.

Prepare release-related changes in {{ProjectName}} without publishing or tagging.

## Required process

1. **Before any other action:** invoke the `skill` tool for both `markdown-authoring` and `release-and-changelog`. This is a blocking requirement — do not read files or produce output until both skills are loaded. If either skill tool invocation fails or returns an error, stop immediately and report: `Required skill [name] could not be loaded. Please resolve this before continuing.` Do not proceed with any subsequent steps.
2. Read `CHANGELOG.md`, `RELEASE_NOTE.md`, `project.json`, `README.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`, and release workflow files, when present. If any required file is not found, stop and report which files are missing before proceeding. Do not create files that do not already exist unless explicitly instructed.
3. Identify any test files in the repository whose names or content relate to versioning, packaging, publishing, or release logic, and review them to understand the intended behavior being validated.
4. Confirm whether the change affects stable releases, prereleases, or both. Based on the nature of the changes, propose the new version string using semantic versioning: breaking changes = major, new public API = minor, fixes or internal changes = patch. Use this version string consistently in all subsequent file updates.
5. Update `CHANGELOG.md` to reflect the changes identified in the prior steps. Update `RELEASE_NOTE.md` only for public interface, configuration, or migration changes. Update `CONTRIBUTING.md` only if the release process, versioning scheme, or contribution workflow has changed.
6. Use only the official Keep a Changelog section types in `CHANGELOG.md` and `RELEASE_NOTE.md`: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security`.
    - Do not create custom headings such as `Documentation`; place documentation-related release notes under the official type that best matches the actual impact.
    - If `CHANGELOG.md` already contains non-standard section headings in existing versioned entries, do not modify those historical entries. Only enforce the official section type rule for the `[Unreleased]` section.
7. Check whether `RELEASE_NOTE.md` needs the placeholder rule under `## [Unreleased]`. This placeholder is already formatted under the official `### Added` heading and is exempt from step 6 content-type guidance — do not reclassify it.
    - 7a. If there are no real public API or workflow changes, ensure `### Added` contains exactly `No public API or workflow changes in this release. Internal maintenance only.`
    - 7b. If there are real release-note entries, remove that placeholder.
8. Keep `RELEASE_NOTE.md` free of compare-link footer URLs.
9. Verify that the version string in `project.json` matches the latest versioned heading in `CHANGELOG.md`, and confirm that release workflow files, when present references the correct version source.
10. Summarize the result using the exact structure from `.github/pull_request_template.md`. For sections in the pull request template that are not applicable to this release preparation, write `N/A` rather than omitting the section or leaving it blank. Make the summary concise, reviewer-focused, directly reusable, and compliant with the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) when the output is returned as Markdown.

## Repository-specific reminders

- Do not publish packages.
- Do not create tags.
- Do not push release commits.
- Keep unreleased changelog entries aligned with the final intended behavior, not internal iteration history.
- Keep `CHANGELOG.md` exhaustive and keep `RELEASE_NOTE.md` limited to public interface, configuration, and migration changes.
- Treat `.github/pull_request_template.md` as the source of truth for release-preparation summaries.
- If the summary must be pasted as one Markdown block in the UI, it should follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).
