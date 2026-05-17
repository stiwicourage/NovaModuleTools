# Contributing

Thank you for contributing. Keep changes small, reviewable, and easy to validate.

Before opening a pull request:

- update tests when behavior changes
- keep tests mirrored to changed source files: one focused `.Tests.ps1` file for every new or changed `src/**/*.ps1` file
- use `tests/TestHelpers/` or test-support files for shared setup instead of broad catch-all test files
- add or update PlatyPS-compatible help under `docs/{{ProjectName}}/en-US/` when public commands or public classes change
- when you add a new public function, create its matching help file in the same change
- use Nova commands and `project.json` for build, test, package, and release behavior
- keep PowerShell code, tests, and examples compatible with `project.json` `Manifest.PowerShellHostVersion`; if the project targets `5.1`, do not add PowerShell 7.x-only features
- keep `run.ps1` ordered as ScriptAnalyzer, then `Invoke-NovaBuild`, then `Test-NovaBuild`
- use `Test-NovaBuild` as the project test entrypoint; do not validate with direct `Invoke-Pester`
- if `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before you ask for review
- follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth; use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings
- keep one externally called function per file and match the file name to that function; private files may keep extra related functions only as same-file top-level support helpers, and PowerShell functions must not declare nested functions inside their bodies
- follow `.github/instructions/code-quality-matrix.instructions.md` for source/helper-script maintainability and `.github/instructions/testing-policy.instructions.md` for test design
- keep `docs/{{ProjectName}}/en-US/*.md` as valid PlatyPS command help by using `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp`
- make every changed or generated text file end immediately after exactly one newline terminator with no blank spacer line at the bottom; use `pwsh -NoLogo -NoProfile -File ./scripts/build/Test-TextFileFormatting.ps1` for a focused check, and keep `tests/TextFileFormatting.Tests.ps1` green when Pester is enabled
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
