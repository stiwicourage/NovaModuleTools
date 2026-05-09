# Prepare a NovaModuleTools release change

Prepare release-related changes in NovaModuleTools without publishing or tagging.

## Required process

1. Read `CHANGELOG.md`, `project.json`, `README.md`, `CONTRIBUTING.md`, `.github/pull_request_template.md`, and
   `.github/workflows/Publish.yml`.
2. Inspect the touched versioning, package, publish, or release tests.
3. Confirm whether the change affects stable releases, prereleases, or both.
4. Update changelog and contributor docs as needed.
5. Validate the relevant release or versioning path.
6. Summarize the result using the exact structure from `.github/pull_request_template.md`.
7. Make the summary concise, reviewer-focused, directly reusable, and compliant with `markdown-authoring.skill.md` when
   the output is returned as Markdown.

## Repository-specific reminders

- Do not publish packages.
- Do not create tags.
- Do not push release commits.
- Keep unreleased changelog entries aligned with the final intended behavior, not internal iteration history.
- Treat `.github/pull_request_template.md` as the source of truth for release-preparation summaries.
- If the summary must be pasted as one Markdown block in the UI, it should follow `markdown-authoring.skill.md`.
