# NovaModuleTools PR Description Generator

## Purpose

Generate a complete, high-quality pull request description for NovaModuleTools based on a change summary, commits, or
diff.

The output MUST follow the NovaModuleTools PR template exactly and be concise, precise, and reviewer-focused.

---

## Inputs

- Change description, commit messages, or diff (required)
- Optional: issue number, workflow touched, commands affected

---

## Instructions

Analyze the provided input and:

1. Infer the intent of the change (bugfix, feature, refactor, CI, docs, etc.)
2. Identify impacted areas (CLI, PowerShell, CI/CD, packaging, docs, etc.)
3. Detect validation steps performed (or infer what should have been run)
4. Highlight reviewer entry points (key files, workflows, or commands)
5. Identify risks, breaking changes, or follow-ups

Be pragmatic: if information is missing, make reasonable assumptions but call them out briefly.

Before generating the PR description, you MUST:

- Read this prompt file from `.github/prompts/pr-description.prompt.md` directly, even if hidden folders were not
  surfaced by an earlier search.
- Read `.github/pull_request_template.md` directly and treat it as authoritative.
- Resolve all relative paths from the repository root.
- Treat `./pr-descriptions/` as a repository-root-relative output folder.
- Never assume `.github/` content is missing just because a previous listing or glob search did not show hidden folders.

---

## Output format

You MUST return the PR description using this exact structure, you will find the template in
`.github/pull_request_template.md`:
You MUST fill in all sections, and you MUST NOT modify the template structure.
You MUST create a *.md file in the `./pr-descriptions/` folder with the same name as the PR title, and write the
generated description there.
If the folder does not exist yet, you MUST create it under the repository root before writing the file.
