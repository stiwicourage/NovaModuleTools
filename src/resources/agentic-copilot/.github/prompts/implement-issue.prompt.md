# Implement {{ProjectName}} issue

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
8. Use `.github/instructions/code-quality-matrix.instructions.md` as the best-effort quality matrix for changed `src/**/*.ps1` and `tests/**/*.ps1`; keep new or heavily changed code within the relevant warning thresholds unless the scope explicitly justifies otherwise.
9. Do not add PSScriptAnalyzer excluded rules or suppressions; fix analyzer findings in the code.
10. If `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before handoff instead of only reporting the failure.
11. Keep file/function ownership explicit: one externally called function per file, with private-file extras limited to same-file support helpers, and keep the file name aligned to the entry function.
12. Before handoff, review every changed or generated text file and normalize it to exactly one trailing newline with no extra blank lines at the bottom.
13. Add or update the matching source-mirrored Pester file for every changed `src/**/*.ps1` file; if the behavior is genuinely cross-cutting, document which integration/guardrail test owns it and why a mirrored unit test is not practical.
14. Add or update valid PlatyPS-compatible help under `docs/<ProjectName>/en-US/` when public commands or public classes change. Use `New-MarkdownCommandHelp` for new help, `Update-MarkdownCommandHelp` after command-surface changes, and `Test-MarkdownCommandHelp` before handoff; do not replace command help with plain Markdown prose.
15. Review `README.md`, `CONTRIBUTING.md`, `CHANGELOG.md`, `RELEASE_NOTE.md`, help docs, and project docs as applicable.
16. If a commit message is requested, derive it from `$GIT_BRANCH_NAME` and the implemented change using the repository's Conventional Commit rules.
17. Run the relevant validation, then summarize what changed, why, and how it was verified.
18. If that summary is returned as Markdown or copy-ready UI output, format it according to the `markdown-authoring` skill (`.github/skills/markdown-authoring/SKILL.md`).

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
