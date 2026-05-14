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
- Keep `run.ps1` as the local quality loop: ScriptAnalyzer first, then `Invoke-NovaBuild`, then `Test-NovaBuild`.
- Do not exclude or suppress PSScriptAnalyzer rules; fix analyzer findings in the code.
- Do not hand-create module `.psm1` or module `.psd1` files in source; Nova generates them under `dist/{{ProjectName}}/`.
- Add PlatyPS-compatible help under `docs/{{ProjectName}}/en-US/` when public commands or public classes change.
- Keep tests mirrored to source files: every new or changed `src/**/*.ps1` file should have one focused `.Tests.ps1` file, for example `src/private/foo/Get-Thing.ps1` -> `tests/private/foo/Get-Thing.Tests.ps1`.
- Put shared test setup in `tests/TestHelpers/` or a test-support file instead of grouping unrelated source coverage into broad catch-all tests.

## Start here

{{StartHereBody}}
