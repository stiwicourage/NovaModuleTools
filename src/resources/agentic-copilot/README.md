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

## Start here

{{StartHereBody}}
