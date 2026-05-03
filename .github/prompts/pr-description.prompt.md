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

---

## Output format

You MUST return the PR description using this exact structure:

### Pull Request Template

.github/pull_request_template.md