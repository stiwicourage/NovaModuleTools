# Contributing

Thank you for contributing. Keep changes small, reviewable, and easy to validate.

Before opening a pull request:

- update tests when behavior changes
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
