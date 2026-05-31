# Prepare a {{ProjectName}} release

> Invoke with `@.github/prompts/prepare-release.prompt.md`. Delegates to the `release-manager` agent.

Prepare release-related changes in {{ProjectName}} without publishing or tagging.

## Required process

1. **Before any other action:** invoke the `skill` tool for both `markdown-authoring` and `release-and-changelog`. This is a blocking requirement — do not read files or produce output until both skills are loaded.
2. Read `CHANGELOG.md`, `RELEASE_NOTE.md`, `project.json`, `README.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`, and release workflow files, when present.
2. Inspect the touched versioning, package, publish, or release tests.
3. Confirm whether the change affects stable releases, prereleases, or both.
4. Update changelog, release notes, and contributor docs as needed.
5. Use only the official Keep a Changelog section types in `CHANGELOG.md` and `RELEASE_NOTE.md`: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, and `Security`.
    - Do not create custom headings such as `Documentation`; place documentation-related release notes under the official type that best matches the actual impact.
6. Check whether `RELEASE_NOTE.md` needs the placeholder rule under `## [Unreleased]`:
    - If there are no real public API or workflow changes, ensure `### Added` contains exactly `No public API or workflow changes in this release. Internal maintenance only.`
    - If there are real release-note entries, remove that placeholder.
7. Keep `RELEASE_NOTE.md` free of compare-link footer URLs.
8. Validate the relevant release or versioning path.
9. Summarize the result using the exact structure from `.github/pull_request_template.md`.
10. Make the summary concise, reviewer-focused, directly reusable, and compliant with the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) when the output is returned as Markdown.

## Repository-specific reminders

- Do not publish packages.
- Do not create tags.
- Do not push release commits.
- Keep unreleased changelog entries aligned with the final intended behavior, not internal iteration history.
- Keep `CHANGELOG.md` exhaustive and keep `RELEASE_NOTE.md` limited to public interface, configuration, and migration changes.
- Treat `.github/pull_request_template.md` as the source of truth for release-preparation summaries.
- If the summary must be pasted as one Markdown block in the UI, it should follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).
