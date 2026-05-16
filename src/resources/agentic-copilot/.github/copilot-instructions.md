# {{ProjectName}} Copilot instructions

## Purpose

Use this file as the repository-wide Copilot instruction entry point for {{ProjectName}}.

{{ProjectName}} is a Nova-managed PowerShell module project. Keep public commands, private helpers, Pester tests, release history, and documentation aligned with `project.json` and the generated project layout.

## Start here

Read these files before making non-trivial changes:

1. `README.md`
2. `CONTRIBUTING.md`
3. `.github/pull_request_template.md`
4. The relevant file in `.github/instructions/`
5. The relevant skill under `.github/skills/<skill-name>/SKILL.md`
6. `.github/instructions/code-quality-matrix.instructions.md` when shaping or reviewing `src/**/*.ps1` or source-like helper scripts
7. `.github/instructions/testing-policy.instructions.md` when shaping or reviewing `tests/**/*.ps1`, coverage behavior, or CI test flows
8. `.github/instructions/platyps-help.instructions.md` when creating or updating `docs/{{ProjectName}}/en-US/*.md`
9. `.github/instructions/psscriptanalyzer.instructions.md` when changing PowerShell code, test helpers, or analyzer wrappers

Prompt templates under `.github/prompts/*.prompt.md` are not auto-loaded. Reference them explicitly in chat when you want to use one of the repository's reusable task prompts.

For new or not-yet-scoped work, start with `.github/agents/architect.agent.md` and `.github/prompts/design-change.prompt.md`. That flow should stay conversational first: analyze the request, ask clarifying questions, present design options when needed, and only draft the final scoped solution or issue/work item after the discussion is complete. When unresolved questions still remain, architect should surface what is settled vs unresolved before asking whether to finalize, and should allow either full finalization or a resumable design-package-only handoff. Proposed scope cuts or out-of-scope boundaries must be confirmed by the user before they are treated as final.

## Repository map

- `src/public/` - public PowerShell command surface; one top-level function per file
- `src/private/` - internal helpers grouped by domain (`build/`, `cli/`, `package/`, `quality/`, `release/`, `scaffold/`, `shared/`, `update/`); keep one externally called helper per file, allow related same-file top-level support helpers, and do not nest function declarations inside other functions
- `tests/` - Pester tests and shared test-support scripts
- `scripts/build/` - local analyzer and build helpers
- `scripts/build/ci/` - CI coverage, quality tooling, and artifact helpers
- workflow files - repository workflow automation, when present
- reusable workflow actions - reusable workflow actions, when present
- `docs/{{ProjectName}}/en-US/` - command help source
- `docs/` - project documentation

## Repository-wide rules

- Keep changes small, reviewable, and easy to validate.
- Do not invent behavior that is not visible in source, tests, docs, workflows, or issues.

- Treat `project.json` as the source of truth for project metadata, build output, package settings, and release settings.
- Treat `project.json` `Manifest.PowerShellHostVersion` as the compatibility target for PowerShell code, tests, and examples. If a project targets `5.1`, do not introduce PowerShell 7.x-only syntax, cmdlets, parameters, or APIs unless the work explicitly adds guarded compatibility handling.
- Use Nova commands and repository wrappers for build, test, package, and release workflows; do not replace them with ad hoc PowerShell module build scripts.
- Do not create or maintain hand-written module `.psm1` or module `.psd1` files in source; Nova generates the built module root and manifest under `dist/{{ProjectName}}/` from `project.json` and `src/**/*.ps1`.
- Do not exclude or suppress PSScriptAnalyzer rules in repository analyzer helpers; fix the code that violates analyzer rules instead.
- Use `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1`, and only use direct `Invoke-ScriptAnalyzer` for focused local checks or deliberate analyzer-tooling changes.
- Keep `run.ps1` as the local quality loop: run ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`.
- Use `Test-NovaBuild` as the authoritative test entrypoint in Nova-managed projects. Do not call `Invoke-Pester` directly, because it can bypass Nova's build/import/StrictMode flow and disagree with the result users get later.
- If `run.ps1` or `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before review, handoff, or commit. Do not treat a failing local quality loop as an acceptable stopping point.
- Keep file/function ownership explicit: `src/public/` files should own exactly one top-level function each, and `src/private/` files should expose at most one externally called function per file. Additional private functions may stay only as related top-level support helpers used from the same file, the file name should match the function that owns the file, and PowerShell functions must not declare nested functions inside their bodies.
- Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort maintainability guidance for `src/**/*.ps1` and source-like helper scripts, and use `.github/instructions/testing-policy.instructions.md` for test-specific design rules; generated projects should follow that guidance through Agentic Copilot files.
- Generate valid PlatyPS help under `docs/{{ProjectName}}/en-US/` whenever command help changes. Use the Microsoft.PowerShell.PlatyPS workflow (`New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, `Test-MarkdownCommandHelp`) instead of hand-authoring command-help structure, and do not write plain Markdown that `Import-MarkdownCommandHelp` cannot parse.
- Every new public entry point requires its matching help file in the same change. A new `src/public/*.ps1` file is not complete until the matching `docs/{{ProjectName}}/en-US/<CommandName>.md` file exists.
- Review `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` after every meaningful change.
- Update tests when behavior changes.
- Prefer existing helpers and support files over ad hoc duplication.
- Treat maintainability as a release-readiness concern for this repository.
- Keep AI-touched files small, clear, and easy to review.
- Prefer small, incremental refactors over large rewrites when fixing maintainability issues.
- Use `.github/instructions/code-quality-matrix.instructions.md` and the `building-maintainable-code` skill as the PowerShell-translated source of the ten SIG maintainability guidelines (short and simple units, no duplication, small interfaces, separated concerns, loose coupling, balanced components, small codebase, automated tests, clean code).
- Keep command help `docs/{{ProjectName}}/en-US/*.md`, contributor docs, and release history clearly separated by audience and syntax.
- Add or update PlatyPS-compatible command help under `docs/{{ProjectName}}/en-US/` when public commands or public classes change, and create matching help immediately for every new public entry point.
- For every new or changed `src/**/*.ps1` file, add or update one focused source-mirrored Pester file: use `tests/public/<Name>.Tests.ps1` for `src/public/<Name>.ps1`, `tests/private/<domain>/<Name>.Tests.ps1` for `src/private/<domain>/<Name>.ps1`, and `tests/classes/<Name>.Tests.ps1` for `src/classes/<Name>.ps1`.
- Use shared helpers under `tests/TestHelpers/` or `tests/*TestSupport.ps1` for repeated setup; do not hide unrelated source-file coverage in broad catch-all test files unless the behavior is genuinely cross-cutting.

## Commit message guidance

- When you are asked to suggest or prepare a commit message, answer in English.
- Use Conventional Commit format.
- Extract the ticket number from `$GIT_BRANCH_NAME` and render it as `(#<number>)` immediately after the type when one is available.
- If `$GIT_BRANCH_NAME` starts with `hotfix/` or `bug/`, use `fix` as the type even when the implementation looks more like a feature. Use `fix!` if that branch change is also breaking.
- Otherwise estimate the type from the actual change:
    - `feat` for feature work
    - `fix` for bug fixes
    - `feat!` for breaking feature work
    - `fix!` for breaking fixes
- Keep the subject short, specific, and free of unnecessary detail.
- If you provide multiple commit message suggestions or summarize multiple change options, use bullet points.
- Do not invent a ticket number when `$GIT_BRANCH_NAME` does not contain one.

## Markdown output guidance

- When the output is intended to be copied as Markdown from the UI or written to a Markdown file, follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).
- Apply that rule especially to release summaries, review summaries, contributor-facing Markdown docs, prompt output, and PR-template-shaped text.

## Validation expectations

Use the smallest validation set that proves the change, then run the repository quality loop before finishing code work:

- local quality loop: `pwsh -NoLogo -NoProfile -File ./run.ps1`
- test validation: `Test-NovaBuild`
- analyzer only: `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`
- CI-parity coverage flow: use the repository-specific CI helper when one exists

When project-specific quality tooling is available:

- run the configured local safeguard before suggesting a commit
- run the configured branch or change-set check before suggesting a PR
- if quality tooling reports a regression, refactor instead of treating the work as done
- use the relevant refactoring guidance for small, measured maintainability improvements
- use the relevant review or quality guidance when deciding whether AI-touched work is ready for handoff

If optional quality tooling is unavailable locally, continue with the normal repository validation flow; pull requests and CI remain the effective gate.

For documentation-only changes, executable validation may be skipped if no code path or workflow behavior changed.

## File formatting rule

- Before handoff, review every changed or created text file and ensure it ends with exactly one trailing newline and no extra blank lines at the bottom.
- Do not leave any edited file with extra blank lines at the end, even if the functional code change is already complete.
- Do not alter internal whitespace just to enforce the trailing newline rule.

## Safety constraints

- Do not publish packages, create tags, or push changes unless explicitly requested.

- Do not add raw infrastructure calls in public commands when an adapter/helper layer already exists.

## Related guidance

- `.github/instructions/powershell-coding-standards.instructions.md`
- `.github/instructions/testing-policy.instructions.md`
- `.github/instructions/release-policy.instructions.md`

- `.github/skills/markdown-authoring/SKILL.md`
