<!-- Generated from .github/copilot-instructions.md by scripts/build/Sync-AgenticCopilotScaffold.ps1. Do not edit by hand. -->

# {{ProjectName}} Copilot instructions

## Purpose

Index of repository-wide Copilot guidance for {{ProjectName}}. This file is intentionally thin. Canonical rule text lives in `.github/instructions/` (path-scoped, auto-loaded by Copilot) and how-to guidance lives in `.github/skills/`.

## Start here

Start here:

1. If the work is new or not yet scoped, use the `architect` agent with `.github/prompts/design-change.prompt.md` first. The architect flow is discussion-first: clarify the request, explore options, and only finalize a scoped solution or issue draft after the discussion is done.
2. Otherwise, identify your task type in the Task map below and follow only the prompt, agent, and instructions listed for that row.
3. Use the reading order below only when no Task map row matches the work.

For any change that adds, removes, or modifies public commands, helper functions, tests, CI workflows, or documentation, read in this order:

1. `README.md`
2. `CONTRIBUTING.md`
3. `.github/pull_request_template.md`
4. `.github/instructions/repository-conventions.instructions.md` — cross-cutting rules
5. The topic-scoped instruction file(s) that match the paths you are touching
6. The skill listed under that topic in the task map below

## Repository map

- `src/public/` — public PowerShell commands; one top-level function per file, file name matches function name
- `src/private/` — domain-grouped helpers (`build/`, `cli/`, `package/`, `quality/`, `release/`, `scaffold/`, `shared/`, `update/`); one externally called helper per file
- `tests/` — Pester tests and shared test-support scripts; public command unit tests live under `tests/public/<Command>.Tests.ps1` and per-command build-validation integration tests live under `tests/public/<Command>.Integration.Tests.ps1`
- `scripts/build/` — local analyzer and build helpers
- `scripts/build/ci/` — CI coverage, quality tooling, and artifact helpers
- workflow files, when present — GitHub Actions CI, analyzer, dependency review, publish automation
- reusable workflow actions, when present — reusable workflow actions used by release and coverage flows
- `docs/{{ProjectName}}/en-US/` — PlatyPS command help source
- project docs — end-user GitHub Pages content
- `.github/instructions/` — canonical rules, path-scoped via `applyTo:`
- `.github/skills/` — how-to playbooks invoked through the `skill` tool
- `.github/agents/` — role definitions for specialized agents
- `.github/prompts/` — reusable task prompts (not auto-loaded; invoke explicitly with `@.github/prompts/<name>.prompt.md`)

## Task map

The table below shows how to route work. Prompts are the task entry points; each prompt delegates to its agent, which uses the listed skills, which in turn enforce the listed instructions.

| Task                     | Prompt                               | Agent                                       | Primary skills                                                                                                                                                                                            | Primary instructions                                                                                               |
|--------------------------|--------------------------------------|---------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| Design or scope a change | `design-change.prompt.md`            | `architect`                                 | `powershell-module-development`, `terminal-ux-design`, `workflow guidance`, `release-and-changelog`, `markdown-authoring`                                                                                    | `repository-conventions`, `code-quality-matrix`                                                                    |
| Implement an issue       | `implement-issue.prompt.md`          | `powershell-developer`                      | `powershell-module-development`, `terminal-ux-design`, `pester-testing`, `building-maintainable-code`                                              | `repository-conventions`, `code-quality-matrix`, `psscriptanalyzer`, `powershell-coding-standards`, `platyps-help` |
| Review a change          | `review-change.prompt.md`            | `reviewer`                                  | `terminal-ux-design`, `building-maintainable-code`, `documentation`, `markdown-authoring`, `pester-testing`, `release-and-changelog`, `workflow guidance` | All `.github/instructions/*.instructions.md`                                                                       |
| Improve test coverage    | `improve-test-coverage.prompt.md`    | `test-engineer`                             | `pester-testing`, `building-maintainable-code`                                           | `testing-policy`, `psscriptanalyzer`                                                                               |
| Prepare a release        | `prepare-release.prompt.md`          | `release-manager`                           | `release-and-changelog`, `markdown-authoring`                                                                                                                                                             | `release-policy`, `repository-conventions`                                                                         |
| Fix a CI failure         | `fix-ci-failure.prompt.md`           | `powershell-developer` when the failure is in source code or build scripts; `test-engineer` when the failure is in a Pester test file under `tests/` | `workflow guidance`, `pester-testing`                                                                                                                                                                        | `testing-policy`, `psscriptanalyzer`, `repository-conventions`                                                     |
| Update project docs      | Invoke `@documentation` directly and pass the target file path. No prompt file is required. | `documentation`                                 | `documentation`, `markdown-authoring`                                                                                                                                                                         | `documentation`                                                                                         |

If a change spans multiple task types, run each relevant flow sequentially in this order: design (if needed) → implement → test coverage → docs → release. Do not attempt to merge prompts.

## Notation

- Skills referenced as `/skill-name` in agent files map 1-to-1 to the `name:` field in `.github/skills/<skill-name>/SKILL.md`. The runtime invokes them through the `skill` tool with the bare name.
- Prompts are referenced by path. Custom prompts are not auto-loaded by the Copilot CLI; invoke them explicitly with `@.github/prompts/<name>.prompt.md`.
- Instructions auto-load when their `applyTo:` glob matches a file in the change set.
- If an expected instruction file does not auto-load because no file in the change set matches its `applyTo:` glob, explicitly load it with `@.github/instructions/<name>.instructions.md` before proceeding.

## Related guidance

- Cross-cutting rules: `.github/instructions/repository-conventions.instructions.md`
- Source code maintainability: `.github/instructions/code-quality-matrix.instructions.md` + `building-maintainable-code` skill
- Testing: `.github/instructions/testing-policy.instructions.md` + `pester-testing` skill
- PSScriptAnalyzer workflow: `.github/instructions/psscriptanalyzer.instructions.md`
- PowerShell coding standards: `.github/instructions/powershell-coding-standards.instructions.md`
- PlatyPS help generation: `.github/instructions/platyps-help.instructions.md`
- Terminal UX: `.github/instructions/terminal-ux-design.instructions.md` + `terminal-ux-design` skill
- Release flow: `.github/instructions/release-policy.instructions.md` + `release-and-changelog` skill
- Documentation separation: `.github/instructions/documentation.instructions.md` + `documentation` skill
