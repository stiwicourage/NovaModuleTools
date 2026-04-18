## Contributing

[![CodeScene Hotspot Code Health](https://codescene.io/projects/78904/status-badges/hotspot-code-health)](https://codescene.io/projects/78904)
[![CodeScene Average Code Health](https://codescene.io/projects/78904/status-badges/average-code-health)](https://codescene.io/projects/78904)

**This repository is intentionally opinionated about maintainability, however, we welcome contributions that align with
our goals. We want to keep the codebase clean, maintainable, and easy to understand for both users and contributors.**

If you want to contribute, please work in the same style as the project:

- Prefer the Nova command model and user-facing `nova` workflow over legacy MT naming or mixed command styles.
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

Please also make sure your contribution includes the right kind of follow-up work:

- add or update tests when behavior changes
- update help files in `docs/` when a command changes
- update `README.md` when repository workflow, architecture, or contributor expectations change
- update `CHANGELOG.md` when the change is relevant to users, maintainers, or future contributors
- keep `src/resources/example/` useful if your change affects the real-world project layout or workflow

Documentation ownership is intentionally split:

- GitHub repository docs are for contributors and maintainers
- GitHub Pages content under `docs/*.html` is for end users
- command-help markdown under `docs/NovaModuleTools/en-US/` is build input, not general prose documentation

When updating documentation, write it for humans first. A reader should quickly understand:

- what changed
- why it changed
- how to use it
- whether existing behavior is affected

For changelog entries, follow the existing project format:

- Keep a Changelog structure
- Semantic Versioning intent
- reader-friendly wording under sections such as `Added`, `Changed`, `Fixed`, `Removed`, and `Documentation`

In short: build it, analyze it, test it, document it, and leave it in better shape than you found it.
