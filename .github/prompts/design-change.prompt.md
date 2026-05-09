# Design a NovaModuleTools change

Use this prompt with `architect.agent.md` when a change still needs analysis, scoping, and issue drafting before anyone
starts editing files.

## Required inputs

- The requested change, problem statement, or rough idea
- Relevant issue, discussion, or bug context if it already exists
- Known constraints, deadlines, or rollout concerns if they matter

## Required process

1. Clarify the real problem first. Ask focused follow-up questions when scope, public-surface impact, or ownership is
   unclear.
2. Read `README.md`, `CONTRIBUTING.md`, `.github/instructions/*.md`, and the most relevant `.github/skills/*.md` files.
3. Inspect the affected public command, private helper domain, tests, docs, workflows, or release files without editing
   them.
4. Decide whether the request affects public cmdlets, `% nova` CLI behavior, `project.json`, CI/workflows, command
   help, website docs, `CHANGELOG.md`, or `RELEASE_NOTE.md`.
5. Recommend the smallest maintainable approach that fits the existing repository structure.
6. End with an implementation-ready handoff and a GitHub issue draft.
7. Do not edit repository files unless the user explicitly switches from design to implementation.

## Required output

- Problem
- Why it matters
- Scope
- Out of scope
- Affected areas and likely files
- Validation and documentation impact
- Proposed implementation approach
- Open questions
- Recommended follow-on agent
- GitHub issue draft

## Repository-specific reminders

- Preserve the distinction between public PowerShell cmdlets and `% nova` CLI behavior.
- Keep contributor docs, command help, website docs, changelog entries, and release notes separated by audience.
- If the final design summary or GitHub issue draft is returned as Markdown or copy-ready UI output, format it according
  to `markdown-authoring.skill.md`.
- Draft issue text in English unless the user explicitly asks for another language.
