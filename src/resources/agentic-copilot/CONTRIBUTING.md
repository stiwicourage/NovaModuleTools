# Contributing

Thank you for contributing. Keep changes small, reviewable, and easy to validate.

Before opening a pull request:

- update tests when behavior changes
- keep tests mirrored to changed source files: one focused `.Tests.ps1` file for every new or changed `src/**/*.ps1` file
- use `tests/TestHelpers/` or test-support files for shared setup instead of broad catch-all test files
- add or update PlatyPS-compatible help under `docs/{{ProjectName}}/en-US/` when public commands or public classes change
- use Nova commands and `project.json` for build, test, package, and release behavior
- keep PowerShell code, tests, and examples compatible with `project.json` `Manifest.PowerShellHostVersion`; if the project targets `5.1`, do not add PowerShell 7.x-only features
- keep `run.ps1` ordered as ScriptAnalyzer, then `Invoke-NovaBuild`, then `Test-NovaBuild`
- if `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before you ask for review
- keep one externally called function per file and match the file name to that function; private files may keep extra functions only as same-file support helpers
- follow `.github/instructions/code-quality-matrix.instructions.md` as the best-effort src/tests quality matrix; this starter does not require `.codescene/code-health-rules.json`
- keep `docs/{{ProjectName}}/en-US/*.md` as valid PlatyPS command help by using `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp`
- make every changed or generated text file end with exactly one trailing newline and no extra blank lines at the bottom
- do not exclude or suppress PSScriptAnalyzer rules
- do not hand-create module `.psm1` or module `.psd1` files in source
- review `README.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` when the workflow or public behavior changed
- keep PowerShell cmdlet guidance, CLI guidance, and contributor guidance clearly separated
- validate the changed path before you ask for review

## Agentic Copilot workflow

Recommended flow:

1. **Design**
    - Use `/agent architect`, `.github/agents/architect.agent.md`, and `.github/prompts/design-change.prompt.md` when the scope still needs analysis.
2. **Implement**
    - Use `/agent powershell-developer`, `.github/agents/powershell-developer.agent.md`, and `.github/prompts/implement-issue.prompt.md` to implement the agreed change.
    - If the work is mainly about tests or coverage, use `/agent test-engineer`, `.github/agents/test-engineer.agent.md`, and `.github/prompts/improve-test-coverage.prompt.md`.
3. **Review**
    - Use `/agent reviewer`, `.github/agents/reviewer.agent.md`, and `.github/prompts/review-change.prompt.md` before handoff or pull request review.
4. **Prepare release**
    - Use `/agent release-manager`, `.github/agents/release-manager.agent.md`, and `.github/prompts/prepare-release.prompt.md` when release-facing files change.
