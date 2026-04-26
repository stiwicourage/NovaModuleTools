# NovaModuleTools | [![CodeScene general](https://codescene.io/images/analyzed-by-codescene-badge.svg)](https://codescene.io/projects/78904) ![WorkFlow Status][WorkFlowStatus]

NovaModuleTools is an enterprise-focused evolution of ModuleTools for structured PowerShell module development,
repository automation, and maintainable Nova workflows.

This README is the single developer-documentation entry point for the repository.

### If you are looking for end-user guides, go to [www.novamoduletools.com](https://www.novamoduletools.com/).

## Documentation split

| Audience                     | Location          | Purpose                                                   |
|------------------------------|-------------------|-----------------------------------------------------------|
| Contributors and maintainers | GitHub repository | Build, test, debug, document, and release NovaModuleTools |
| End users                    | GitHub Pages      | Install NovaModuleTools and follow guided usage workflows |

## Table of contents

- [Contributor entry points](#contributor-entry-points)
- [Development workflow](#development-workflow)
- [Repository structure and ownership](#repository-structure-and-ownership)
- [CI/CD and release automation](#cicd-and-release-automation)
- [Documentation ownership rules](#documentation-ownership-rules)
- [End-user docs on GitHub Pages](#end-user-docs-on-github-pages)
- [License](#license)

## Contributor entry points

Start here when you work on NovaModuleTools itself:

- [CONTRIBUTING.md](./CONTRIBUTING.md) — contribution expectations and review checklist
- [Development workflow](#development-workflow) — local setup, build, test, reload, and quality loop
- [Repository structure and ownership](#repository-structure-and-ownership) — architecture and folder responsibilities
- [CI/CD and release automation](#cicd-and-release-automation) — workflow, release, and publish responsibilities

Suggested reading order:

1. Read [CONTRIBUTING.md](./CONTRIBUTING.md)
2. Follow [Development workflow](#development-workflow) for local iteration
3. Use [Repository structure and ownership](#repository-structure-and-ownership) when deciding where changes belong
4. Use [CI/CD and release automation](#cicd-and-release-automation) when your change touches workflows, release
   automation, or publishing

## Development workflow

This section describes how to work on the NovaModuleTools repository itself.

### Prerequisites

Repository development expects:

- PowerShell 7.4 or newer
- Git
- `Pester`
- `PSScriptAnalyzer`
- `Microsoft.PowerShell.PlatyPS`

Node.js is only required if you are working on the current semantic-release-based publish pipeline.

### Build the module locally

From the repository root:

```powershell
PS> Set-Location $PSScriptRoot
PS> Invoke-NovaBuild
```

This creates the built module under `dist/NovaModuleTools/`.

When you want the test workflow to rebuild first, use:

```powershell
PS> Test-NovaBuild -Build
% nova test --build
% nova test -b
```

NovaModuleTools can self-update the installed module from PowerShell or the `nova` CLI launcher.

- Stable self-updates are always available.
- Prerelease self-updates are optional and can be managed with:

```powershell
PS> Set-NovaUpdateNotificationPreference -DisablePrereleaseNotifications
PS> Set-NovaUpdateNotificationPreference -EnablePrereleaseNotifications
PS> Get-NovaUpdateNotificationPreference
PS> Update-NovaModuleTool
PS> Update-NovaModuleTools   # alias
% nova notification --disable
% nova notification --enable
% nova notification
% nova update
```

Use `% nova notification` when you want the CLI-oriented workflow and the `Set-` / `Get-` cmdlets when you want the
PowerShell function form in scripts.

`Update-NovaModuleTool` (and its `Update-NovaModuleTools` alias), CLI:`% nova update` use that stored prerelease
preference to decide whether prerelease self-updates are eligible. When prerelease self-updates are disabled,
self-update stays on stable releases. When they are enabled, self-update may target a prerelease, but it asks for
explicit confirmation before proceeding.

Successful `Update-NovaModuleTool`, CLI:`% nova update`, and `Install-NovaCli` runs print the release notes link from
the
installed module manifest. When `Invoke-NovaBuild` detects a newer `NovaModuleTools` version after a build, the update
warning also includes that same release notes link.

To compare the current project version with what is installed locally for that same module, use:

```powershell
% nova version
% nova version --installed
% nova version -i
% nova --version
% nova -v
```

- `% nova version` shows the version from the current project's `project.json`
- `% nova version --installed` / `% nova version -i` shows the locally installed version of the current project/module
  from
  the local module path
- `% nova --version` / `% nova -v` shows the installed `NovaModuleTools` version

### CLI help

Use the launcher-oriented help forms when you want CLI syntax instead of PowerShell cmdlet help:

```powershell
% nova --help
% nova build --help
% nova build -h
% nova --help build
% nova -h build
```

- `% nova <command> --help` / `% nova <command> -h` shows short command help
- `% nova --help <command>` / `% nova -h <command>` shows long command help
- Long command help now includes the matching public GitHub Pages guide URL for the selected command, while short help
  stays link-free
- CLI help is launcher-native and uses CLI option spellings such as `--repository` and `-r`
- Use PowerShell `Get-Help` when you want cmdlet help such as `Get-Help Publish-NovaModule -Full`
- Root `% nova -v` means version, while command-level `% nova build -v` means verbose for supported routed commands

### Confirmation behavior

Use `% nova <mutating-command> --confirm` / `% nova <mutating-command> -c` when you want a CLI-safe confirmation prompt.

- `Y` / `Yes` and `A` / `Yes to All` continue
- `N` / `No` and `L` / `No to All` cancel with a non-zero exit code
- `S` / `Suspend` is not supported in CLI mode and is treated as cancel so `nova` returns directly to your original
  shell instead of opening a nested PowerShell prompt

Only the supported mutating `nova` commands accept `--confirm` / `-c`. Read-only routes and `% nova init` now reject the
CLI confirm flag with a clear validation error instead of silently treating it as a PowerShell-style concept.

Direct PowerShell cmdlets such as `Publish-NovaModule`, `Deploy-NovaPackage`, and `Update-NovaModuleVersion` keep their
native `-Confirm` behavior. The CLI-safe confirmation flow applies to `nova` CLI usage, while `Invoke-NovaCli` remains
the explicit PowerShell cmdlet entrypoint for routed command dispatch.

The module does not export a PowerShell alias named `nova`. Install the bundled launcher with `Install-NovaCli` when you
want `% nova ...` available directly from your shell.

### Reload the built module while iterating

Use the built output during development so you validate the same shape CI uses:

```powershell
PS> Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
PS> Invoke-NovaBuild
PS> Import-Module ./dist/NovaModuleTools -Force
```

If you are testing local publish behavior:

```powershell
PS> Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
PS> Publish-NovaModule -Local
```

`Publish-NovaModule -Local` now copies the module to the resolved local module path and reloads that published copy into
the active PowerShell session. If your repository workflow needs to switch back to the built `dist/` output afterward,
re-import `./dist/NovaModuleTools` explicitly.

When the same CI/self-hosting session must stay aligned with the built `dist/` output automatically, use the new
continuous-integration activation switches instead of handling re-imports manually:

```powershell
PS> Invoke-NovaBuild -ContinuousIntegration
PS> Update-NovaModuleVersion -ContinuousIntegration
PS> Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API -ContinuousIntegration
PS> Invoke-NovaRelease -PublishOption @{Repository = 'PSGallery'; ApiKey = $env:PSGALLERY_API} -ContinuousIntegration

% nova build --continuous-integration
% nova bump --continuous-integration
% nova publish --repository PSGallery --api-key $env:PSGALLERY_API --continuous-integration
% nova release --repository PSGallery --api-key $env:PSGALLERY_API --continuous-integration
```

These switches keep the behavior explicit and opt-in:

- `Invoke-NovaBuild -ContinuousIntegration` re-imports the freshly built module after the build succeeds
- `Update-NovaModuleVersion -ContinuousIntegration` re-imports the built module before the bump workflow starts
- `Publish-NovaModule -ContinuousIntegration` restores the built module after publish completes
- `Invoke-NovaRelease -ContinuousIntegration` forwards that CI intent through the nested build/bump boundaries and then
  restores the built module again after publish

Useful local helper:

```powershell
# reload.ps1
Set-Location $PSScriptRoot

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"
$distManifestPath = Join-Path $distModuleDir "$projectName.psd1"

Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
Invoke-NovaBuild
Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
$module = Import-Module $distManifestPath -Force -PassThru

& $module {
    Publish-NovaModule -Local
}

Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
$module = Import-Module $distManifestPath -Force -PassThru

# Only use Install-NovaCli for macOS/Linux users.
# & $module {
#     Install-NovaCli -Force
# }
```

### Run tests

Run the repository test workflow from the repository root:

```powershell
PS> Test-NovaBuild
```

Notes:

- `Test-NovaBuild` validates the built module output, not just loose source files
- it writes NUnit XML to `artifacts/TestResults.xml`
- it respects `BuildRecursiveFolders` when discovering tests

### Create a package artifact

Use the explicit packaging workflow when you want a package artifact for a Nova project without publishing to a
PowerShell repository:

```powershell
PS> New-NovaModulePackage
% nova package
```

The package command runs the normal build and test flow, then writes the generated package artifacts to
`artifacts/packages/` by default by using the generic `Package` section in `project.json` when present.
When `Manifest.Tags`, `Manifest.ProjectUri`, `Manifest.ReleaseNotes`, or `Manifest.LicenseUri` are present, Nova
copies them into the generated package metadata; when they are omitted, packaging still succeeds and the matching
package metadata fields are simply left out.

When tests already ran earlier in CI/CD, you can skip only the test step while still rebuilding before packaging:

```powershell
PS> New-NovaModulePackage -SkipTests
% nova package --skip-tests
% nova package -s
```

`-SkipTests` / `--skip-tests` skips `Test-NovaBuild` only. `Invoke-NovaBuild` still runs.

Use this `project.json` shape when you want to control the package types and output directory:

```json
{
  "Package": {
    "PackageFileName": "AgentInstaller",
    "AddVersionToFileName": true,
    "Types": ["NuGet", "Zip"],
    "Latest": true,
    "OutputDirectory": {
      "Path": "artifacts/packages",
      "Clean": true
    }
  }
}
```

- `Types` is optional. When it is missing, empty, or null, Nova defaults to `NuGet` and creates a `.nupkg`.
- Supported `Types` values are `NuGet`, `Zip`, `.nupkg`, and `.zip`, and matching is case-insensitive.
- Use `Types = ["Zip"]` when you only want a `.zip`, or `Types = ["NuGet", "Zip"]` when you want both files.
- `Latest` is optional and defaults to `false`. When set to `true`, Nova also creates a companion `*.latest.*`
  artifact for each selected package type, such as `NovaModuleTools.latest.nupkg` next to the normal versioned file.
- `PackageFileName` lets you override the base artifact name.
- `AddVersionToFileName` defaults to `false`. When set to `true`, Nova appends `.<Version>` from `project.json` to the
  configured `PackageFileName`, so `AgentInstaller` becomes `AgentInstaller.2.3.4` before the package
  extension is applied.
- When both `AddVersionToFileName` and `Latest` are enabled, the companion artifact substitutes that appended version
  suffix with `.latest`, such as `AgentInstaller.latest.nupkg`.
- `Path` selects where the package artifact(s) are written.
- `Clean` defaults to `true` and removes that output directory before a new package is created.
- Set `Clean` to `false` when you want to keep existing files in the package output directory.

### Upload package artifacts to a raw endpoint

Use the upload workflow when a Nova project must push existing package artifacts to a raw HTTP endpoint instead of a
PowerShell repository:

```powershell
PS> Deploy-NovaPackage -Repository LocalNexus
% nova deploy --repository LocalNexus
% nova deploy --url https://packages.example/raw/ --token $env:NOVA_PACKAGE_TOKEN
```

Use this `project.json` shape when you want Nova to resolve upload targets from named repositories:

```json
{
  "Package": {
    "Types": ["Zip"],
    "OutputDirectory": {
      "Path": "artifacts/packages",
      "Clean": true
    },
    "Repositories": [
      {
        "Name": "LocalNexus",
        "Url": "http://localhost:8081/repository/raw/com/novamoduletools/"
      }
    ]
  }
}
```

- `Deploy-NovaPackage` uploads existing package files only; it does not build, test, or create packages.
- `% nova deploy` is the CLI entrypoint for the same raw upload workflow and uses POSIX/GNU-style options such as
  `--repository`, `--url`, and `--token`.
- `-Url` overrides repository or package-level upload settings and is the simplest CI/CD path for the PowerShell cmdlet
  form.
- When `-PackagePath` is omitted, Nova resolves package files from `Package.OutputDirectory.Path`.
- `Package.FileNamePattern` overrides the default upload discovery pattern. When omitted, Nova falls back to
  `<Package.Id>*` and then applies the selected package type extension.
- If `Package.PackageFileName` uses a different base name than `Package.Id`, update `Package.FileNamePattern` too so
  automatic upload discovery keeps matching the generated files.
- When `Package.FileNamePattern` already ends with `.zip` or `.nupkg`, Nova treats that extension as authoritative.
  For example, `MyModule.*.zip` discovers `MyModule.1.2.3.zip` and `MyModule.latest.zip` without picking up
  `MyModule.1.2.3.nupkg`.
- When multiple matching files exist for a selected package type, Nova uploads all of them, including versioned and
  `latest` variants.
- `Package.Headers`, `Package.Auth`, `Package.RepositoryUrl`, and repository-specific overrides remain generic so the
  workflow works with raw endpoints such as Nexus or Artifactory without turning `Publish-NovaModule` into a vendor-
  specific upload command.

For module publishing and release flows, the same opt-in skip-tests behavior is available when tests already ran earlier
in the pipeline:

```powershell
PS> Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API -SkipTests
PS> Invoke-NovaRelease -PublishOption @{ Repository = 'PSGallery'; ApiKey = $env:PSGALLERY_API } -SkipTests
% nova publish --repository PSGallery --api-key $env:PSGALLERY_API --skip-tests
% nova release --repository PSGallery --api-key $env:PSGALLERY_API -s
```

These forms skip `Test-NovaBuild` only. `Publish-NovaModule` still builds before publishing, and `Invoke-NovaRelease`
still runs both build steps around the version bump.

When your pipeline continues in the same PowerShell session after build, bump, publish, or release, add
`-ContinuousIntegration` / `--continuous-integration` / `-i` to the supported commands so Nova re-activates the built
`dist/` module at the workflow boundaries where session state matters.

### Run code quality checks

Run ScriptAnalyzer with the repository helper:

```powershell
PS> ./scripts/build/Invoke-ScriptAnalyzerCI.ps1
```

This writes findings to `artifacts/scriptanalyzer.txt`.

For CI-parity coverage and report generation, use:

```powershell
PS> ./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1
```

That flow builds the module, runs ScriptAnalyzer, runs the normal test workflow, and emits CI-friendly reports such as:

- `artifacts/novamoduletools-nunit.xml`
- `artifacts/pester-junit.xml`
- `artifacts/pester-coverage.cobertura.xml`
- `artifacts/coverage-low.txt`

### Recommended local quality loop

```powershell
# run.ps1
Set-Location $PSScriptRoot

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"

Invoke-NovaBuild
& (Join-Path $PSScriptRoot 'scripts/build/Invoke-ScriptAnalyzerCI.ps1')
Remove-Module $projectName -ErrorAction SilentlyContinue
Import-Module $distModuleDir -Force
Test-NovaBuild
```

### Working on help and docs

Command help markdown lives under `docs/NovaModuleTools/en-US/` and is consumed by `Invoke-NovaBuild`.

Important distinction:

- `docs/NovaModuleTools/en-US/*.md` → PlatyPS command-help source
- `docs/*.html` → GitHub Pages end-user guides
- `README.md` and `CONTRIBUTING.md` → contributor documentation

Do not place general developer markdown under `docs/`, because the build scans `docs/**/*.md` when generating help.

## Repository structure and ownership

This section explains how the NovaModuleTools repository is organized and what each major area owns.

### Top-level overview

```text
.
├── .github/                    # GitHub Actions workflows
├── docs/                       # GitHub Pages HTML + PlatyPS help markdown
├── scripts/                    # build, CI, and release automation
├── src/                        # production PowerShell code and packaged resources
├── tests/                      # Pester suites and reusable test helpers
├── project.json                # NovaModuleTools project definition
├── package.json                # semantic-release tooling for current publish automation
└── CHANGELOG.md                # release notes and unreleased change tracking
```

### Source code layout

#### `src/public/`

Public cmdlets that make up the NovaModuleTools API surface, for example:

- `Invoke-NovaBuild`
- `Test-NovaBuild`
- `Initialize-NovaModule`
- `Update-NovaModuleVersion`

#### `src/private/`

Internal implementation helpers grouped by concern, including:

- `build/`
- `cli/`
- `quality/`
- `release/`
- `scaffold/`
- `shared/`
- `update/`

Keep new helpers small, focused, and near the concern they belong to.

#### `src/resources/`

Packaged resources that ship with the module, including:

- schemas
- the standalone `nova` launcher
- the packaged example project under `src/resources/example/`

The example project is both a shipped resource and a maintained working reference.

### Test layout

#### `tests/`

Repository-level Pester coverage for:

- public command behavior
- internal helper behavior
- build and packaging expectations
- CI/report generation flows

Shared test utilities live alongside the tests, for example:

- `GitTestSupport.ps1`
- `BuildOptions.TestSupport.ps1`
- `NovaCommandModel.TestSupport.ps1`

### Documentation layout

#### `README.md` and `CONTRIBUTING.md`

These are the top-level GitHub entry points for contributors and maintainers.

#### `docs/`

This folder has two different responsibilities that must stay separated by file type:

- `docs/*.html` → GitHub Pages end-user guides
- `docs/NovaModuleTools/en-US/*.md` → PlatyPS command-help source

The build treats markdown under `docs/` as help input, so general-purpose developer documentation should not be added
there.

### Scripts and automation

#### `scripts/build/`

Build, analyzer, and CI helper scripts.

#### `scripts/release/`

Release preparation and publish helpers used by the current release workflow.

These scripts are currently part of a wider GitHub Actions + semantic-release pipeline, not a standalone replacement for
it.

## CI/CD and release automation

This section describes the current repository automation used to validate and publish NovaModuleTools.

### CI expectations

The repository uses GitHub Actions under `.github/workflows/`.

At a minimum, contributor changes are expected to keep these workflows healthy:

- build
- test
- analyzer / coverage
- publish / release automation

Repository scripts under `scripts/build/ci/` provide local parity for CI-oriented reporting.

### Build and test automation

The normal repository workflow is:

1. `Invoke-NovaBuild`
2. `Test-NovaBuild`
3. ScriptAnalyzer via `scripts/build/Invoke-ScriptAnalyzerCI.ps1`
4. Optional CI helper flow via `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`

When you test local publish behavior during development, remember that `Publish-NovaModule -Local` reloads the
published module from the local install directory into the current PowerShell session. Re-import `dist/` if your next
step depends on the built-but-unpublished output instead.

The CI helper flow also produces JUnit and Cobertura artifacts for external systems.

### Release automation

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

### Where NovaModuleTools cmdlets fit

NovaModuleTools already provides strong release building blocks:

- `Update-NovaModuleVersion`
- `Publish-NovaModule`
- `Invoke-NovaRelease`

But these do not yet replace every semantic-release responsibility in the current repository workflow.

If you work on release automation, treat `package.json` and `.releaserc.json` as active parts of the present release
system.

### Contributor expectations for workflow changes

When you change CI, build, or release behavior:

- update tests
- update command help if public command behavior changes
- update `README.md` when contributor workflow changes
- update `CHANGELOG.md` when the change is relevant to users or maintainers

## Documentation ownership rules

- Keep contributor workflow, architecture, and automation documentation in `README.md`
- Keep `CONTRIBUTING.md` focused on contribution expectations and review checklist items
- Keep `docs/NovaModuleTools/en-US/*.md` focused on command-help source material
- Keep `docs/*.html` focused on end-user guides
- Do not duplicate the same workflow or setup prose across multiple contributor documents

## End-user docs on GitHub Pages

### [www.novamoduletools.com](https://www.novamoduletools.com/)

## License

This project is licensed under the MIT License. See LICENSE for details.

[PSGalleryLink]: https://www.powershellgallery.com/packages/NovaModuleTools/
[WorkFlowStatus]: https://img.shields.io/github/actions/workflow/status/stiwicourage/NovaModuleTools/Tests.yml
