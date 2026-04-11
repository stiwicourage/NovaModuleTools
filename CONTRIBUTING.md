## Contributing

[![CodeScene Hotspot Code Health](https://codescene.io/projects/78904/status-badges/hotspot-code-health)](https://codescene.io/projects/78904)
[![CodeScene Average Code Health](https://codescene.io/projects/78904/status-badges/average-code-health)](https://codescene.io/projects/78904)

Contributions are welcome, but this repository is intentionally opinionated about maintainability.

If you want to contribute, please work in the same style as the project:

- Prefer the Nova command model and user-facing `nova` workflow over legacy MT naming or mixed command styles.
- Keep changes small, reviewable, and easy to understand.
- Aim for maintainable code:
    - short functions
    - simple branching
    - no copy/paste duplication
    - clear names
    - no dead code left behind
- Follow the Boy Scout Rule: leave the codebase a little cleaner than you found it.

Before opening a pull request, please run the local quality flow from the repository root:

```powershell
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"

Invoke-NovaBuild
& (Join-Path $PSScriptRoot 'scripts/build/Invoke-ScriptAnalyzerCI.ps1') -OutputDirectory (Join-Path $PSScriptRoot 'artifacts')
Remove-Module $projectName -ErrorAction SilentlyContinue
Import-Module $distModuleDir -Force

Test-NovaBuild
```

Please also make sure your contribution includes the right kind of follow-up work:

- add or update tests when behavior changes
- update help files in `docs/` when a command changes
- update `README.md` when usage, workflow, examples, or contributor expectations change
- update `CHANGELOG.md` when the change is relevant to users, maintainers, or future contributors
- keep `example/` useful if your change affects the real-world project layout or workflow

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
