# NovaModuleTools | [![CodeScene general](https://codescene.io/images/analyzed-by-codescene-badge.svg)](https://codescene.io/projects/78904) ![WorkFlow Status][WorkFlowStatus]

NovaModuleTools is the source repository for the PowerShell module builder, scaffold, test workflow, CLI launcher, and
release automation that make up the Nova workflow.

This `README.md` is intentionally **developer-focused**. It explains how to work on the repository, validate changes,
and understand the internal structure of the project.

If you want to **use** NovaModuleTools rather than contribute to it, start with the public user guides on GitHub Pages:

- https://www.novamoduletools.com/

## Documentation split

This repository now keeps documentation on two separate tracks:

| Audience                     | Location          | Purpose                                                   |
|------------------------------|-------------------|-----------------------------------------------------------|
| Contributors and maintainers | GitHub repository | Build, test, debug, document, and release NovaModuleTools |
| End users                    | GitHub Pages      | Install NovaModuleTools and follow guided usage workflows |

Repository-side developer docs:

- `README.md` — contributor entry point
- `CONTRIBUTING.md` — contribution expectations and review checklist
- `developer-docs/README.md` — developer documentation hub
- `developer-docs/development-workflow.md` — local development, build, test, and reload workflows
- `developer-docs/repository-structure.md` — architecture and repository layout
- `developer-docs/ci-cd-and-release.md` — CI, release automation, and publish expectations

User-facing guides are intentionally kept out of the repository `README.md` and live under GitHub Pages in
`docs/*.html`.

## Technical overview

NovaModuleTools provides:

- project scaffolding through `New-NovaModule` / `nova init`
- module building through `Invoke-NovaBuild` / `nova build`
- test execution through `Test-NovaBuild` / `nova test`
- version bumping through `Update-NovaModuleVersion` / `nova bump`
- publish and release orchestration through `Publish-NovaModule` and `Invoke-NovaRelease`
- a packaged macOS/Linux launcher installed through `Install-NovaCli`
- generated PowerShell help from PlatyPS markdown under `docs/NovaModuleTools/en-US/`

The repository is intentionally organized around maintainability:

- public entrypoints under `src/public/`
- internal helpers under `src/private/`
- packaged module resources under `src/resources/`
- Pester coverage under `tests/`
- CI and release scripts under `scripts/`

## Development setup

### Required tools

- PowerShell 7.4 or newer for repository development
- Git
- PowerShell modules used by the local quality flow:
    - `Pester`
    - `PSScriptAnalyzer`
    - `Microsoft.PowerShell.PlatyPS`
- Node.js is only required when you work on the current semantic-release based publish pipeline

### Local bootstrap

From the repository root, build the module and load the freshly built output:

```powershell
Set-Location $PSScriptRoot
Invoke-NovaBuild
Import-Module ./dist/NovaModuleTools -Force
```

If you need the reusable CI bootstrap behavior locally, review:

- `scripts/build/ci/Install-CiPowerShellModules.ps1`
- `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`

## Repository structure

High-level layout:

```text
.
├── .github/                    # workflows
├── developer-docs/             # contributor-focused documentation
├── docs/                       # GitHub Pages HTML and PlatyPS command-help markdown
├── scripts/                    # build, CI, and release automation
├── src/public/                 # public cmdlets
├── src/private/                # internal helpers
├── src/resources/              # packaged resources, launcher, schemas, example project
├── tests/                      # Pester suites and test support helpers
├── project.json                # NovaModuleTools project definition
└── package.json                # semantic-release tooling for the current release pipeline
```

For a deeper breakdown of repository responsibilities and architectural boundaries, see
`developer-docs/repository-structure.md`.

## Local development workflow

Recommended contributor loop from the repository root:

```powershell
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

This produces the normal local artifacts under `artifacts/`, including:

- `artifacts/TestResults.xml`
- `artifacts/scriptanalyzer.txt`
- CI-compatible reports created by the CI helper flow

For the full development guide, including reload tips and CI parity helpers, see
`developer-docs/development-workflow.md`.

## Build and test expectations

Core developer commands:

```powershell
Invoke-NovaBuild
Test-NovaBuild
Update-NovaModuleVersion -WhatIf
Publish-NovaModule -Local -WhatIf
Invoke-NovaRelease -PublishOption @{ Local = $true } -WhatIf
```

Notes for contributors:

- `Test-NovaBuild` validates the built module and writes NUnit XML to `artifacts/TestResults.xml`
- `scripts/build/Invoke-ScriptAnalyzerCI.ps1` is the repository ScriptAnalyzer entrypoint
- `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1` is the CI-parity flow for coverage and report generation
- PlatyPS markdown under `docs/NovaModuleTools/en-US/` is used to build MAML help during `Invoke-NovaBuild`

## Reloading during development

When you are iterating on the module, prefer reloading the built output instead of relying on an older installed copy:

```powershell
Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
Invoke-NovaBuild
Import-Module ./dist/NovaModuleTools -Force
```

If you are testing local publish behavior, reload after publishing as well:

```powershell
Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
Publish-NovaModule -Local
Import-Module ./dist/NovaModuleTools -Force
```

## CI/CD and release expectations

The repository currently uses:

- GitHub Actions under `.github/workflows/`
- PowerShell CI helper scripts under `scripts/build/ci/`
- semantic-release orchestration for the publish workflow

The current release pipeline does more than version bumping. It coordinates:

- release version selection
- `project.json` updates
- changelog release preparation
- rebuild after version changes
- tagging and GitHub release automation
- PowerShell Gallery publish steps

For the release flow details and the role of `package.json`, see `developer-docs/ci-cd-and-release.md`.

## Documentation ownership in the repository

- Keep `docs/NovaModuleTools/en-US/*.md` focused on command help source material
- Keep GitHub Pages content in `docs/*.html` focused on end-user usage flows
- Keep contributor guidance in `README.md`, `CONTRIBUTING.md`, and `developer-docs/*.md`
- Do not reintroduce consumer onboarding into the repository `README.md`

## Contributing

Start with `CONTRIBUTING.md` and then use the developer docs hub in `developer-docs/README.md`.

Before opening a pull request, make sure you have:

- built the module
- run ScriptAnalyzer
- run the relevant Pester coverage
- reviewed help/docs changes
- updated `CHANGELOG.md` when the change is user-visible or contributor-relevant

## License

This project is licensed under the MIT License. See `LICENSE` for details.

[BadgeIOCount]: https://img.shields.io/powershellgallery/dt/NovaModuleTools?label=NovaModuleTools%40PowerShell%20Gallery
[PSGalleryLink]: https://www.powershellgallery.com/packages/NovaModuleTools/
[WorkFlowStatus]: https://img.shields.io/github/actions/workflow/status/stiwicourage/NovaModuleTools/Tests.yml
