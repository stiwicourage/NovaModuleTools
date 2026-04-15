# CI/CD and release automation

This guide describes the current repository automation used to validate and publish NovaModuleTools.

## CI expectations

The repository uses GitHub Actions under `.github/workflows/`.

At a minimum, contributor changes are expected to keep these workflows healthy:

- build
- test
- analyzer / coverage
- publish/release automation

Repository scripts under `scripts/build/ci/` provide local parity for CI-oriented reporting.

## Build and test automation

The normal repository workflow is:

1. `Invoke-NovaBuild`
2. `Test-NovaBuild`
3. ScriptAnalyzer via `scripts/build/Invoke-ScriptAnalyzerCI.ps1`
4. Optional CI helper flow via `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`

The CI helper flow also produces JUnit and Cobertura artifacts for external systems.

## Release automation

The current publish pipeline is still semantic-release based.

Key pieces:

- `.github/workflows/Publish.yml`
- `.releaserc.json`
- `package.json`
- `scripts/release/Prepare-SemanticRelease.ps1`
- `scripts/release/Publish-ToPSGallery.ps1`
- `scripts/release/SemanticReleaseSupport.ps1`

Responsibilities currently covered by the release pipeline include:

- choosing the next release version from commit history
- updating `project.json`
- finalizing `CHANGELOG.md`
- rebuilding after version changes
- creating release tags
- creating GitHub releases
- publishing to PowerShell Gallery

## Where NovaModuleTools cmdlets fit

NovaModuleTools already provides strong release building blocks:

- `Update-NovaModuleVersion`
- `Publish-NovaModule`
- `Invoke-NovaRelease`

But these do not yet replace every semantic-release responsibility in the current repository workflow.

If you work on release automation, treat `package.json` and `.releaserc.json` as active parts of the present release
system.

## Contributor expectations

When you change CI, build, or release behavior:

- update tests
- update command help if public command behavior changes
- update `README.md` / `developer-docs/` when contributor workflow changes
- update `CHANGELOG.md` when the change is relevant to users or maintainers

