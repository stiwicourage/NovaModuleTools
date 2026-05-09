# NovaModuleTools repository instructions

## Purpose

Use this file as the repository-local entry point for Copilot or other AI agents working in NovaModuleTools.

NovaModuleTools is not a generic PowerShell repo. It has a strong split between public commands, private helpers,
Pester-heavy testing, GitHub Actions automation, CodeScene coverage gates, and Keep a Changelog / SemVer release flow.

## Start here

Read these files before making non-trivial changes:

1. `README.md`
2. `CONTRIBUTING.md`
3. `.github/pull_request_template.md`
4. The relevant file in `.github/instructions/`
5. The relevant file in `.github/skills/`

## Repository map

- `src/public/` - public PowerShell command surface; one top-level function per file
- `src/private/` - internal helpers grouped by domain (`build/`, `cli/`, `package/`, `quality/`, `release/`,
  `scaffold/`, `shared/`, `update/`)
- `tests/` - Pester tests and shared test-support scripts
- `scripts/build/` - local analyzer and build helpers
- `scripts/build/ci/` - CI coverage, CodeScene, and artifact helpers
- `.github/workflows/` - GitHub Actions CI, analyzer, dependency review, and publish automation
- `.github/actions/` - reusable workflow actions used by release and coverage flows
- `docs/NovaModuleTools/en-US/` - command help source
- `docs/*.html` - end-user GitHub Pages content

## Repository-wide rules

- Keep changes small, reviewable, and easy to validate.
- Do not invent behavior that is not visible in source, tests, docs, workflows, or issues.
- Preserve the distinction between PowerShell cmdlet UX and `nova` CLI UX.
- Review `README.md`, `CONTRIBUTING.md`, and `CHANGELOG.md` after every meaningful change.
- Update tests when behavior changes.
- Prefer existing helpers and support files over ad hoc duplication.
- Treat Code Health as authoritative for maintainability in this repository.
- Target Code Health `10.0` for AI-touched files; `9.x` is not the goal state.
- Prefer small, incremental refactors over large rewrites when fixing maintainability issues.
- Keep `docs/*.html`, `docs/NovaModuleTools/en-US/*.md`, and contributor docs clearly separated by audience and syntax.

## Commit message guidance

- When you are asked to suggest or prepare a commit message, answer in English.
- Use Conventional Commit format.
- Extract the ticket number from `$GIT_BRANCH_NAME` and render it as `(#<number>)` immediately after the type when one
  is
  available.
- If `$GIT_BRANCH_NAME` starts with `hotfix/` or `bug/`, use `fix` as the type even when the implementation looks more
  like a feature. Use `fix!` if that branch change is also breaking.
- Otherwise estimate the type from the actual change:
    - `feat` for feature work
    - `fix` for bug fixes
    - `feat!` for breaking feature work
    - `fix!` for breaking fixes
- Keep the subject short, specific, and free of unnecessary detail.
- If you provide multiple commit message suggestions or summarize multiple change options, use bullet points.
- Do not invent a ticket number when `$GIT_BRANCH_NAME` does not contain one.

## Markdown output guidance

- When the output is intended to be copied as Markdown from the UI or written to a Markdown file, follow
  `.github/skills/markdown-authoring.skill.md`.
- Apply that rule especially to release summaries, review summaries, contributor-facing Markdown docs, prompt output,
  and
  PR-template-shaped text.

## Validation expectations

Use the smallest validation set that proves the change, then run the repository quality loop before finishing code work:

- local quality loop: `pwsh -NoLogo -NoProfile -File ./run.ps1`
- targeted tests: `Invoke-Pester -Path ./tests/<File>.Tests.ps1 -Output Detailed`
- analyzer only: `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
- CI-parity coverage flow: `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1 -OutputDirectory ./artifacts`

When CodeScene tooling is available:

- run the pre-commit safeguard on AI-touched changes before suggesting a commit
- run a branch/change-set analysis before suggesting a PR or declaring a larger change ready
- if CodeScene reports a regression, refactor instead of treating the work as done

For documentation-only changes, executable validation may be skipped if no code path or workflow behavior changed.

## File formatting rule

- Modified or created text files must end with exactly one trailing newline.
- Do not leave multiple blank lines at the end of edited files.
- Do not alter internal whitespace just to enforce the trailing newline rule.

## Safety constraints

- Do not publish packages, create tags, or push changes unless explicitly requested.
- Do not modify GitHub Actions release automation casually; `Publish.yml` mutates `main` and `develop`.
- Do not bypass warnings or guards silently; Nova uses explicit `-OverrideWarning` / `--override-warning`.
- Do not add raw infrastructure calls in public commands when an adapter/helper layer already exists.

## Related guidance

- `.github/instructions/powershell-coding-standards.md`
- `.github/instructions/testing-policy.md`
- `.github/instructions/release-policy.md`
- `.github/instructions/documentation-separation.md`
- `.github/skills/markdown-authoring.skill.md`
