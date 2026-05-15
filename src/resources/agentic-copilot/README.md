# {{ProjectName}}

{{ProjectDescription}}

## Agentic Copilot workflow

Follow this workflow when working with Copilot in this repository.

1. **Design**
    - Start with `/agent architect`, `.github/agents/architect.agent.md`, and `.github/prompts/design-change.prompt.md` to scope the change before implementation.
2. **Implement**
    - Use `/agent powershell-developer`, `.github/agents/powershell-developer.agent.md`, and `.github/prompts/implement-issue.prompt.md` when the change is already scoped.
    - If the work is mainly about tests or coverage, use `/agent test-engineer`, `.github/agents/test-engineer.agent.md`, and `.github/prompts/improve-test-coverage.prompt.md`.
3. **Review**
    - Use `/agent reviewer`, `.github/agents/reviewer.agent.md`, and `.github/prompts/review-change.prompt.md` before handoff or pull request review.
4. **Prepare release**
    - Use `/agent release-manager`, `.github/agents/release-manager.agent.md`, and `.github/prompts/prepare-release.prompt.md` when preparing the pull request summary and release-facing follow-up.

## Nova project expectations

- Use Nova commands and `project.json` for build, test, package, and release behavior.
- Treat `project.json` `Manifest.PowerShellHostVersion` as the compatibility target for PowerShell code, tests, and examples. If it is `5.1`, do not introduce PowerShell 7.x-only features.
- Keep `run.ps1` as the local quality loop: ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`.
- Use `Test-NovaBuild` as the project test entrypoint. Do not validate with direct `Invoke-Pester`, because it can bypass Nova's build/import/StrictMode flow and disagree with later user-visible test runs.
- If `run.ps1` or `Invoke-ScriptAnalyzerCI.ps1` reports ScriptAnalyzer findings, fix them before review or handoff.
- Follow `.github/instructions/psscriptanalyzer.instructions.md` as the ScriptAnalyzer workflow source of truth. Prefer `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1`, and use direct `Invoke-ScriptAnalyzer` only for focused local checks that reuse the repo-approved settings.
- Keep one externally called function per file and match the file name to that function. Public files own one command each; private files may keep extra functions only as same-file support helpers.
- Follow `.github/instructions/code-quality-matrix.instructions.md` as the best-effort maintainability guidance for source/helper scripts, and `.github/instructions/testing-policy.instructions.md` for test design. These guide agents and reviewers in this generated project.
- Generate valid PlatyPS help under `docs/{{ProjectName}}/en-US/` whenever command help changes. Use `New-MarkdownCommandHelp`, `Update-MarkdownCommandHelp`, and `Test-MarkdownCommandHelp` instead of hand-writing the help structure.
- Every new public entry point must add its matching help file in the same change.
- Make every changed or generated text file end with exactly one trailing newline and no extra blank lines at the bottom before handoff.
- Do not exclude or suppress PSScriptAnalyzer rules; fix analyzer findings in the code.
- Do not hand-create module `.psm1` or module `.psd1` files in source; Nova generates them under `dist/{{ProjectName}}/`.
- Add PlatyPS-compatible help under `docs/{{ProjectName}}/en-US/` when public commands or public classes change.
- Keep tests mirrored to source files: every new or changed `src/**/*.ps1` file should have one focused `.Tests.ps1` file, for example `src/private/foo/Get-Thing.ps1` -> `tests/private/foo/Get-Thing.Tests.ps1`.
- Put shared test setup in `tests/TestHelpers/` or a test-support file instead of grouping unrelated source coverage into broad catch-all tests.

## Start here

{{StartHereBody}}
