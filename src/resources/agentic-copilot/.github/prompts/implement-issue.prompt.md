# Implement {{ProjectName}} issue

> Invoke with `@.github/prompts/implement-issue.prompt.md`. Delegates to the `powershell-developer` agent.

Implement the issue in the {{ProjectName}} repository using the repository-local instructions and skills.

## Required inputs

- Issue number or issue text
- Relevant files or failing behavior
- `$GIT_BRANCH_NAME` when a commit message suggestion is needed

## Required process

1. If scope, acceptance criteria, or ownership are still unclear, start with `.github/prompts/design-change.prompt.md` and `architect.agent.md` before implementing.
2. Read `README.md`, `CONTRIBUTING.md`, `.github/copilot-instructions.md`, and `.github/pull_request_template.md`.
3. Inspect the relevant public command, matching private helper domain, tests, and docs.
4. If the issue is release-, workflow-, or coverage-related, also inspect the matching workflow files, when present and `scripts/build/ci/*.ps1` files.
5. Preserve the Nova build model: use `project.json` and Nova commands for build/test/package/release behavior, and do not create hand-written source `.psm1` or module `.psd1` files.
6. Inspect `project.json` `Manifest.PowerShellHostVersion` before changing PowerShell code, tests, or examples, and keep the implementation compatible with that target.
7. Implement the smallest maintainable fix.
8. Use `.github/instructions/code-quality-matrix.instructions.md` for changed source/helper scripts and `.github/instructions/testing-policy.instructions.md` for changed tests; keep new or heavily changed code short, single-purpose, low-duplication, and easy to scan unless the scope explicitly justifies otherwise.
9. Follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and the repository quality loop, when present, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repository-approved settings.
10. Do not add PSScriptAnalyzer excluded rules, suppressions, or ad hoc analyzer settings that hide findings; fix analyzer findings in the code.
11. If the repository quality loop or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before handoff instead of only reporting the failure.
12. Keep file/function ownership explicit: one externally called function per file, with private-file extras limited to related same-file top-level support helpers, keep the file name aligned to the entry function, and do not declare functions inside functions.
13. Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline with no extra blank lines at the bottom.
14. Add or update the matching source-mirrored Pester file for every changed `src/**/*.ps1` file; if the behavior is genuinely cross-cutting, document which integration/guardrail test owns it and why a mirrored unit test is not practical.
15. Validate Nova-managed project tests through `Test-NovaBuild`; do not call `Invoke-Pester` directly because it can bypass Nova's build/import/StrictMode flow.
16. Add or update valid PlatyPS-compatible help under `docs/{{ProjectName}}/en-US/` when public commands or public classes change. Use `New-MarkdownCommandHelp` for new help, `Update-MarkdownCommandHelp` after command-surface changes, and `Test-MarkdownCommandHelp` before handoff; do not replace command help with plain Markdown prose.
17. For every new public entry point, create its matching help file immediately in the same change.
18. Review `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `RELEASE_NOTE.md`, help docs, and project docs as applicable.
19. If a commit message is requested, derive it from `$GIT_BRANCH_NAME` and the implemented change using the repository's Conventional Commit rules.
20. Run the relevant validation, then summarize what changed, why, and how it was verified.
21. If that summary is returned as Markdown or copy-ready UI output, format it according to the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).

## Repository-specific reminders

- Keep PowerShell cmdlet UX and `nova` CLI UX distinct.
- Do not silently bypass warnings or release safeguards.
- Prefer reuse of existing helpers and test-support files over duplication.
- Follow the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`) when the issue summary or final handoff is intended to be pasted as Markdown.
- Commit message suggestions must:
    - be in English
    - use Conventional Commit format
    - extract the ticket number from `$GIT_BRANCH_NAME` and format it as `(#<number>)` when available
    - force `fix` / `fix!` when `$GIT_BRANCH_NAME` starts with `hotfix/` or `bug/`
    - otherwise estimate `feat`, `fix`, `feat!`, or `fix!` from the actual change
    - stay short and not overly verbose
    - use bullet points when presenting multiple commit message options or multiple grouped changes
