# NovaModuleTools Copilot instructions

## Purpose

Index of repository-wide Copilot guidance for NovaModuleTools. This file is intentionally thin. Canonical rule text lives in `.github/instructions/` (path-scoped, auto-loaded by Copilot) and how-to guidance lives in `.github/skills/`.

## Start here

For non-trivial changes, read in this order:

1. `README.md`
2. `CONTRIBUTING.md`
3. `.github/pull_request_template.md`
4. `.github/instructions/repository-conventions.instructions.md` — cross-cutting rules
5. The topic-scoped instruction file(s) that match the paths you are touching
6. The skill listed under that topic in the task map below

For new or not-yet-scoped work, use the `architect` agent with `.github/prompts/design-change.prompt.md`. The architect flow is discussion-first: clarify the request, explore options, and only finalize a scoped solution or issue draft after the discussion is done.

## Repository map

- `src/public/` — public PowerShell commands; one top-level function per file, file name matches function name
- `src/private/` — domain-grouped helpers (`build/`, `cli/`, `package/`, `quality/`, `release/`, `scaffold/`, `shared/`, `update/`); one externally called helper per file
- `tests/` — Pester tests and shared test-support scripts; public command unit tests live under `tests/public/<Command>.Tests.ps1` and per-command build-validation integration tests live under `tests/public/<Command>.Integration.Tests.ps1`
- `scripts/build/` — local analyzer and build helpers
- `scripts/build/ci/` — CI coverage, CodeScene, and artifact helpers
- `.github/workflows/` — GitHub Actions CI, analyzer, dependency review, publish automation
- `.github/actions/` — reusable workflow actions used by release and coverage flows
- `docs/NovaModuleTools/en-US/` — PlatyPS command help source
- `docs/*.html` — end-user GitHub Pages content
- `.github/instructions/` — canonical rules, path-scoped via `applyTo:`
- `.github/skills/` — how-to playbooks invoked through the `skill` tool
- `.github/agents/` — role definitions for specialized agents
- `.github/prompts/` — reusable task prompts (not auto-loaded; invoke explicitly with `@.github/prompts/<name>.prompt.md`)

## Task map

The table below shows how to route work. Prompts are the task entry points; each prompt delegates to its agent, which uses the listed skills, which in turn enforce the listed instructions.

| Task                     | Prompt                               | Agent                                       | Primary skills                                                                                                                                                                                            | Primary instructions                                                                                               |
|--------------------------|--------------------------------------|---------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------|
| Design or scope a change | `design-change.prompt.md`            | `architect`                                 | `powershell-module-development`, `terminal-ux-design`, `github-actions`, `release-and-changelog`, `markdown-authoring`                                                                                    | `repository-conventions`, `code-quality-matrix`                                                                    |
| Implement an issue       | `implement-issue.prompt.md`          | `powershell-developer`                      | `powershell-module-development`, `terminal-ux-design`, `pester-testing`, `building-maintainable-code`, `codescene-quality`, `safeguarding-ai-generated-code`                                              | `repository-conventions`, `code-quality-matrix`, `psscriptanalyzer`, `powershell-coding-standards`, `platyps-help` |
| Review a change          | `review-change.prompt.md`            | `reviewer`                                  | `terminal-ux-design`, `codescene-quality`, `safeguarding-ai-generated-code`, `building-maintainable-code`, `docs-site`, `markdown-authoring`, `pester-testing`, `release-and-changelog`, `github-actions` | All `.github/instructions/*.instructions.md`                                                                       |
| Improve test coverage    | `improve-test-coverage.prompt.md`    | `test-engineer`                             | `pester-testing`, `building-maintainable-code`, `codescene-quality`, `github-actions`, `guiding-refactoring-with-code-health`, `safeguarding-ai-generated-code`                                           | `testing-policy`, `psscriptanalyzer`                                                                               |
| Prepare a release        | `prepare-release.prompt.md`          | `release-manager`                           | `release-and-changelog`, `markdown-authoring`                                                                                                                                                             | `release-policy`, `repository-conventions`                                                                         |
| Fix a CI failure         | `fix-ci-failure.prompt.md`           | `powershell-developer` (or `test-engineer`) | `github-actions`, `pester-testing`                                                                                                                                                                        | `testing-policy`, `psscriptanalyzer`, `repository-conventions`                                                     |
| Update website docs      | (no dedicated prompt — invoke agent) | `docs-site`                                 | `docs-site`, `markdown-authoring`                                                                                                                                                                         | `documentation-separation`                                                                                         |

## Notation

- Skills referenced as `/skill-name` in agent files map 1-to-1 to the `name:` field in `.github/skills/<skill-name>/SKILL.md`. The runtime invokes them through the `skill` tool with the bare name.
- Prompts are referenced by path. Custom prompts are not auto-loaded by the Copilot CLI; invoke them explicitly with `@.github/prompts/<name>.prompt.md`.
- Instructions auto-load when their `applyTo:` glob matches a file in the change set.

## Related guidance

- Cross-cutting rules: `.github/instructions/repository-conventions.instructions.md`
- Source code maintainability: `.github/instructions/code-quality-matrix.instructions.md` + `building-maintainable-code` skill
- Testing: `.github/instructions/testing-policy.instructions.md` + `pester-testing` skill
- PSScriptAnalyzer workflow: `.github/instructions/psscriptanalyzer.instructions.md`
- PowerShell coding standards: `.github/instructions/powershell-coding-standards.instructions.md`
- PlatyPS help generation: `.github/instructions/platyps-help.instructions.md`
- Terminal UX: `.github/instructions/terminal-ux-design.instructions.md` + `terminal-ux-design` skill
- Release flow: `.github/instructions/release-policy.instructions.md` + `release-and-changelog` skill
- Documentation separation: `.github/instructions/documentation-separation.instructions.md` + `docs-site` skill
