## Contributing
[![KeepAChangelog](https://img.shields.io/badge/changelog-KeepAChangelog-%23E05735)](https://keepachangelog.ps) 
[![CodeScene Average Code Health](https://codescene.io/projects/78904/status-badges/average-code-health)](https://codescene.io/projects/78904)

**This repository is intentionally opinionated about maintainability, however, we welcome contributions that align with
our goals. We want to keep the codebase clean, maintainable, and easy to understand for both users and contributors.**

If you want to contribute, please work in the same style as the project:

- Prefer the Nova command model and user-facing `nova` workflow over mixed command styles.
- Use the GitHub bug report form for reproducible defects, the feature request form for product/workflow ideas, and
  `SECURITY.md` instead of a public issue for vulnerability reports.
- Keep commits small, reviewable, and easy to understand.
    - The size of a pull request is not as important as the clarity of its intent and the ease of reviewing it.
    - A large pull request that is well-organized in smaller commits with clear messages can be easier to review than a
      small pull request that is not well-explained or has unclear intent.
- Aim for maintainable code:
    - short functions
    - simple branching
    - no copy/paste duplication
    - clear names
    - no dead code left behind
- Follow the Boy Scout Rule: leave the codebase a little cleaner than you found it.

Before making larger changes, read the contributor docs in:

- [README.md](./README.md)
- [README.md#development-workflow](./README.md#development-workflow)
- [README.md#repository-structure-and-ownership](./README.md#repository-structure-and-ownership)
- [README.md#cicd-and-release-automation](./README.md#cicd-and-release-automation)
- [.github/copilot-instructions.md](./.github/copilot-instructions.md)
- the relevant files under `.github/agents/`, `.github/skills/`, and `.github/prompts/` when you are using Copilot or
  another AI agent to help with repository work

GitHub now prefills pull requests with `.github/pull_request_template.md`.
Use it to explain intent clearly, record what you validated, and call out any required documentation or changelog work.

Repository-local agentic guidance now lives in `.github/`:

- `.github/copilot-instructions.md` for repository-wide Copilot instructions
- `.github/instructions/` for path-specific `*.instructions.md` rules and policies
- `.github/agents/` for focused agent responsibilities
- `.github/skills/` for task-specific Copilot skills stored as `<skill-name>/SKILL.md`
- `.github/prompts/` for reusable NovaModuleTools prompt templates that you reference explicitly in chat

The files in `.github/agents/` are repository-level Copilot custom agent profiles, so they should load in `/agent`
when your Copilot session starts from the NovaModuleTools repository root.

When you are shaping a new change, start with `architect.agent.md` and `design-change.prompt.md` so the first phase is a
design conversation: analysis, clarifying questions, and solution options before any final scoped proposal or GitHub
issue draft is produced. Proposed out-of-scope boundaries should be confirmed by the user before they become part of the
final scope. When unresolved design questions still remain, architect should summarize what is settled vs unresolved
before asking whether to finalize, and it should support either a full issue-ready handoff or a resumable
design-package-only handoff. Use `implement-issue.prompt.md` after the change is already scoped.

Pull requests against `main` and `develop` also run a CodeScene coverage-gate check when CI has produced the Cobertura coverage artifact, so PRs can be blocked when changed code falls below the configured coverage threshold.

**Before opening a pull request, please run the local quality flow from the repository root:**

```powershell title="run.ps1"
#run.ps1
Set-Location $PSScriptRoot

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"

Invoke-NovaBuild
& (Join-Path $PSScriptRoot 'scripts/build/Invoke-ScriptAnalyzerCI.ps1')
Remove-Module $projectName -ErrorAction SilentlyContinue
Import-Module $distModuleDir -Force

Test-NovaBuild
```

If you are working on the CodeScene integration, the CI coverage helper writes the Cobertura artifact that the
CodeScene upload step consumes:

- generate coverage with `./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`
- pull requests then download that uploaded artifact and run the CodeScene coverage-gate check through `.github/actions/check-coverage`
- then upload/trigger with `./scripts/build/ci/Invoke-CodeSceneAnalysis.ps1 -UploadCoverage -TriggerAnalysis`
- the upload helper auto-discovers a single `artifacts/*.cobertura.xml` file unless you pass `-CoveragePath`
- if upload succeeds but `-TriggerAnalysis` fails with a project-owner OAuth error, re-authorize the repository in
  CodeScene for the project owner; that failure is separate from `CS_ACCESS_TOKEN`

Please also make sure your contribution includes the right kind of follow-up work:

- add or update tests when behavior changes
- update help files in `docs/` when a command changes
- update `README.md` when repository workflow, architecture, or contributor expectations change
- update `CHANGELOG.md` when the change is relevant to users, maintainers, or future contributors
- update `RELEASE_NOTE.md` when the change affects public cmdlet usage, CLI usage, configuration semantics, or migration
  expectations
- keep `src/resources/example/` useful if your change affects the real-world project layout or workflow

Documentation ownership is intentionally split:

- GitHub repository docs are for contributors and maintainers
- GitHub Pages content under `docs/*.html` is for end users
- command-help markdown under `docs/<ProjectName>/` (for this repo `docs/NovaModuleTools/en-US/`) is build input
- markdown elsewhere under `docs/` is allowed for non-help documentation because the build ignores it

Keep CLI and cmdlet documentation clearly separated:

- use `nova` syntax in CLI-oriented website docs when a CLI variant exists
- only mention PowerShell cmdlets in website docs when there is no CLI equivalent for that task
- installation is the clearest allowed exception because NovaModuleTools installation is still PowerShell-driven

When updating documentation, write it for humans first. A reader should quickly understand:

- what changed
- why it changed
- how to use it
- whether existing behavior is affected

For release history and release-note entries, keep the split explicit:

- `CHANGELOG.md` records the full release history
- `RELEASE_NOTE.md` records only public cmdlet, CLI, configuration, and migration-impacting changes

For changelog entries, follow the existing project format:

- Keep a Changelog structure
- Semantic Versioning intent
- reader-friendly wording under sections such as `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed` and `Security`

In short: build it, analyze it, test it, document it, and leave it in better shape than you found it.
