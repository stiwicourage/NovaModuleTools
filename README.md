# NovaModuleTools

[![CodeScene general](https://codescene.io/images/analyzed-by-codescene-badge.svg)](https://codescene.io/projects/78904)
![WorkFlow Status][WorkFlowStatus]
[![Keep a Changelog][changelog-badge]][changelog]

NovaModuleTools is an enterprise-focused evolution of ModuleTools for structured PowerShell module development, repository automation, and maintainable Nova workflows.

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
- [.github/copilot-instructions.md](./.github/copilot-instructions.md) — repository-local guidance for Copilot/AI agents and maintainers
- [Development workflow](#development-workflow) — local setup, build, test, reload, and quality loop
- [Repository structure and ownership](#repository-structure-and-ownership) — architecture and folder responsibilities
- [CI/CD and release automation](#cicd-and-release-automation) — workflow, release, and publish responsibilities

Suggested reading order:

1. Read [CONTRIBUTING.md](./CONTRIBUTING.md)
2. Read [.github/copilot-instructions.md](./.github/copilot-instructions.md) when you want repository-local coding guidance for Copilot/AI-assisted work
3. Follow [Development workflow](#development-workflow) for local iteration
4. Use [Repository structure and ownership](#repository-structure-and-ownership) when deciding where changes belong
5. Use [CI/CD and release automation](#cicd-and-release-automation) when your change touches workflows, release automation, or publishing

## Development workflow

This section describes how to work on the NovaModuleTools repository itself.

Repository-local Copilot/AI guidance now lives under:

- `.github/copilot-instructions.md` - repository-wide Copilot instructions that apply across NovaModuleTools work
- `.github/instructions/` - path-specific Copilot instructions stored as `*.instructions.md`
- `.github/agents/` - focused agent roles for architecture, implementation, testing, release, and review work
- `.github/skills/` - repo-specific Copilot skills stored as `<skill-name>/SKILL.md`
- `.github/prompts/` - reusable task prompts such as design framing, issue implementation, CI fixes, coverage work, and release prep; prompt files are referenced explicitly in chat, not auto-loaded like instructions or skills
- `CHANGELOG.md` and `RELEASE_NOTE.md` - exhaustive release history plus interface-focused release summaries

The files under `.github/agents/` are valid Copilot custom agent profiles and should be available from `/agent` when Copilot is started from the NovaModuleTools repository root.

For new or still-fuzzy work, start with `architect.agent.md` together with `design-change.prompt.md`. That pair should lead with discussion, questions, and design options rather than a finished solution in the first reply. Use
`implement-issue.prompt.md` once the scope, acceptance criteria, and follow-on implementation path are already clear. If architect proposes that part of the request is out of scope, treat that as a proposal to confirm rather than a final decision. If unresolved design questions still remain, architect should first summarize what is settled vs unresolved and then let the user choose between full finalization, a design-package-only handoff, or continued discussion.

### Prerequisites

Repository development expects:

- PowerShell 7.4 or newer
- Git
- `Pester`
- `PSScriptAnalyzer`
- `Microsoft.PowerShell.PlatyPS`

Node.js is not required for the repository's current build, test, or publish automation.

### Build the module locally

From the repository root:

```powershell
PS> Set-Location $PSScriptRoot
PS> Invoke-NovaBuild
```

This creates the built module under `dist/NovaModuleTools/`.

Files under `src/public/` are expected to contain exactly one top-level function each. Nova now stops build-driven workflows when a public file contains zero or multiple top-level functions, because that layout can accidentally export helpers as part of the public API surface. Use `-OverrideWarning` / `--override-warning` / `-o` only when you intentionally want to bypass that guard for a specific build, test-build, package, publish, or release run.

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

Use `% nova notification` when you want the CLI-oriented workflow and the `Set-` / `Get-` cmdlets when you want the PowerShell function form in scripts.

Update notification preferences use one shared settings location:

- Windows: `%APPDATA%/NovaModuleTools/settings.json`
- macOS/Linux with `XDG_CONFIG_HOME`: `$XDG_CONFIG_HOME/NovaModuleTools/settings.json`
- macOS/Linux fallback: `~/.config/NovaModuleTools/settings.json`

`Update-NovaModuleTool` (and its `Update-NovaModuleTools` alias), CLI:`% nova update` use that stored prerelease preference to decide whether prerelease self-updates are eligible. When prerelease self-updates are disabled, self-update stays on stable releases. When they are enabled, self-update may target a prerelease, but it asks for explicit confirmation before proceeding and defaults that prerelease prompt to `No`, so pressing Enter cancels the update.

Successful `Update-NovaModuleTool`, CLI:`% nova update`, and `Install-NovaCli` runs print the release notes link from the installed module manifest. When `Invoke-NovaBuild` detects a newer `NovaModuleTools` version after a build, the update warning also includes that same release notes link.

To inspect the current project version, the installed version of the current project module, or the installed
`NovaModuleTools` tool version, use:

```powershell
PS> Get-NovaProjectInfo -Installed
% nova version
% nova version --installed
% nova version -i
% nova --version
% nova -v
```

- `% nova version` shows the version from the current project's `project.json`
- `% nova version --installed` / `% nova version -i` shows the locally installed version of the current project/module from the local module path
- `Get-NovaProjectInfo -Installed` shows the installed `NovaModuleTools` module name and version from PowerShell
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
- Long command help now includes the matching public GitHub Pages guide URL for the selected command, while short help stays link-free
- CLI help is launcher-native and uses CLI option spellings such as `--repository` and `-r`
- Use PowerShell `Get-Help` when you want cmdlet help such as `Get-Help Publish-NovaModule -Full`
- Root `% nova -v` means version, while command-level `% nova build -v` means verbose for supported routed commands

### Confirmation behavior

Use `% nova <mutating-command> --confirm` / `% nova <mutating-command> -c` when you want a CLI-safe confirmation prompt.

- `Y` / `Yes` and `A` / `Yes to All` continue
- `N` / `No` and `L` / `No to All` cancel with a non-zero exit code
- `S` / `Suspend` is not supported in CLI mode and is treated as cancel so `nova` returns directly to your original shell instead of opening a nested PowerShell prompt

Only the supported mutating `nova` commands accept `--confirm` / `-c`. Read-only routes and `% nova init` now reject the CLI confirm flag with a clear validation error instead of silently treating it as a PowerShell-style concept.

Direct PowerShell cmdlets such as `Publish-NovaModule`, `Deploy-NovaPackage`, and `Update-NovaModuleVersion` keep their native `-Confirm` behavior. The CLI-safe confirmation flow applies to `nova` CLI usage, while `Invoke-NovaCli` remains the explicit PowerShell cmdlet entrypoint for routed command dispatch.

The module does not export a PowerShell alias named `nova`. Install the bundled launcher with `Install-NovaCli` when you want `% nova ...` available directly from your shell.

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

`Publish-NovaModule -Local` now copies the module to the resolved local module path and reloads that published copy into the active PowerShell session. If your repository workflow needs to switch back to the built `dist/` output afterward, re-import `./dist/NovaModuleTools` explicitly.

When the same CI/self-hosting session must stay aligned with the built `dist/` output automatically, use the new continuous-integration activation switches instead of handling re-imports manually:

```powershell
PS> Invoke-NovaBuild -ContinuousIntegration
PS> Update-NovaModuleVersion -ContinuousIntegration
PS> Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API -ContinuousIntegration
PS> Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API -ContinuousIntegration

% nova build --continuous-integration
% nova bump --continuous-integration
% nova publish --repository PSGallery --api-key $env:PSGALLERY_API --continuous-integration
% nova release --repository PSGallery --api-key $env:PSGALLERY_API --continuous-integration
```

These switches keep the behavior explicit and opt-in:

- `Invoke-NovaBuild -ContinuousIntegration` re-imports the freshly built module after the build succeeds
- `Update-NovaModuleVersion -ContinuousIntegration` re-imports the built module before the bump workflow starts
- `Update-NovaModuleVersion -ContinuousIntegration` also falls back to a patch bump when the current `HEAD` already matches the latest tag, so release automation can seed the next prerelease line without requiring an extra commit first
- `Update-NovaModuleVersion` and `% nova bump` now stop when Git-based bump inference is unavailable, unless you explicitly opt in to the Patch fallback with `-OverrideWarning` / `--override-warning` / `-o` for a non-git example/template flow
- `Update-NovaModuleVersion` and `% nova bump` treat stable `0.y.z` versions as the SemVer initial-development phase, so breaking-change bumps stay on the `0.y.z` line by planning the next minor version instead of jumping to `1.0.0`
- `Publish-NovaModule -ContinuousIntegration` restores the built module after publish completes
- `Invoke-NovaRelease -ContinuousIntegration` forwards that CI intent through the nested build/bump boundaries and then restores the built module again after publish

When the current stable version is still `0.y.z`, Nova also prints one warning that major version zero is still the initial-development line and that `1.0.0` must be set manually once the software is stable. Preview bumps keep their current behavior and are not remapped by this rule.

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
- contributor and CI environments should still install `Pester 5.7.1` explicitly before running `Test-NovaBuild`
- the published `NovaModuleTools` manifest also declares `Pester 5.7.1`, so installed end-user workflows can still resolve that dependency automatically

### Create a package artifact

Use the explicit packaging workflow when you want a package artifact for a Nova project without publishing to a PowerShell repository:

```powershell
PS> New-NovaModulePackage
% nova package
```

The package command runs the normal build and test flow, then writes the generated package artifacts to
`artifacts/packages/` by default by using the generic `Package` section in `project.json` when present. When `Manifest.Tags`, `Manifest.ProjectUri`, `Manifest.ReleaseNotes`, or `Manifest.LicenseUri` are present, Nova copies them into the generated package metadata; when they are omitted, packaging still succeeds and the matching package metadata fields are simply left out.

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
    "Types": [
      "NuGet",
      "Zip"
    ],
    "Latest": "stable",
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
- `Latest` is optional and defaults to `"never"`.
- Set `Latest` to `"stable"` when only stable versions should also create companion `*.latest.*` artifacts.
- Set `Latest` to `"always"` when both stable and preview versions should also create companion `*.latest.*` artifacts.
- Set `Latest` to `"never"` when you only want versioned package files.
- `PackageFileName` lets you override the base artifact name.
- `AddVersionToFileName` defaults to `false`. When set to `true`, Nova appends `.<Version>` from `project.json` to the configured `PackageFileName`, so `AgentInstaller` becomes `AgentInstaller.2.3.4` before the package extension is applied.
- When `AddVersionToFileName` is enabled and `Latest` is `"stable"` or `"always"`, the companion artifact substitutes the appended version suffix with `.latest`, such as `AgentInstaller.latest.nupkg`.
- `Path` selects where the package artifact(s) are written.
- `Clean` defaults to `true` and removes that output directory before a new package is created.
- Set `Clean` to `false` when you want to keep existing files in the package output directory.

### Upload package artifacts to a raw endpoint

Use the upload workflow when a Nova project must push existing package artifacts to a raw HTTP endpoint instead of a PowerShell repository:

```powershell
PS> Deploy-NovaPackage -Repository LocalNexus
% nova deploy --repository LocalNexus
% nova deploy --url https://packages.example/raw/ --token $env:NOVA_PACKAGE_TOKEN
```

Use this `project.json` shape when you want Nova to resolve upload targets from named repositories:

```json
{
  "Package": {
    "Types": [
      "Zip"
    ],
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
- Upload target precedence is explicit: `-Url` / `--url` and `-UploadPath` / `--upload-path` win first, then matching
  `Package.Repositories[]` values, then package-level `Package.RepositoryUrl` / `Package.RawRepositoryUrl` and
  `Package.UploadPath`.
- Secret precedence is explicit too: `-Token` / `--token` wins first, then `-TokenEnvironmentVariable` /
  `--token-env`, then merged repository/package `Auth.TokenEnvironmentVariable`, then merged repository/package
  `Auth.Token`.
- When `-PackagePath` is omitted, Nova resolves package files from `Package.OutputDirectory.Path`.
- `Package.FileNamePattern` overrides the default upload discovery pattern. When omitted, Nova falls back to
  `<Package.Id>*` and then applies the selected package type extension.
- If `Package.PackageFileName` uses a different base name than `Package.Id`, update `Package.FileNamePattern` too so automatic upload discovery keeps matching the generated files.
- When `Package.FileNamePattern` already ends with `.zip` or `.nupkg`, Nova treats that extension as authoritative. For example, `MyModule.*.zip` discovers `MyModule.1.2.3.zip` and `MyModule.latest.zip` without picking up
  `MyModule.1.2.3.nupkg`.
- When multiple matching files exist for a selected package type, Nova uploads all of them, including versioned and
  `latest` variants.
- `Package.Headers`, `Package.Auth`, `Package.RepositoryUrl`, and repository-specific overrides remain generic so the workflow works with raw endpoints such as Nexus or Artifactory without turning `Publish-NovaModule` into a vendor- specific upload command.
- `Publish-NovaModule` and `Invoke-NovaRelease` keep a matching secret rule for PowerShell repositories: `-ApiKey` /
  `--api-key` overrides any fallback, and `PSGallery` still checks `PSGALLERY_API` when no explicit API key was provided.

For module publishing and release flows, the same opt-in skip-tests behavior is available when tests already ran earlier in the pipeline:

```powershell
PS> Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API -SkipTests
PS> Invoke-NovaRelease -Repository PSGallery -ApiKey $env:PSGALLERY_API -SkipTests
% nova publish --repository PSGallery --api-key $env:PSGALLERY_API --skip-tests
% nova release --repository PSGallery --api-key $env:PSGALLERY_API -s
```

These forms skip `Test-NovaBuild` only. `Publish-NovaModule` still builds before publishing, and `Invoke-NovaRelease`
still runs both build steps around the version bump.

`Invoke-NovaRelease` now uses the same direct delivery parameters as `Publish-NovaModule` and `% nova release`, so PowerShell automation can pass `-Local`, `-Repository`, `-ModuleDirectoryPath`, and `-ApiKey` without wrapping them in a
`-PublishOption` hashtable.

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

That flow builds the module, runs ScriptAnalyzer, executes one coverage-enabled Pester run using the same Nova test workflow configuration, and emits CI-friendly reports such as:

- `artifacts/novamoduletools-nunit.xml`
- `artifacts/pester-junit.xml`
- `artifacts/pester-coverage.cobertura.xml`
- `artifacts/coverage-low.txt`

The `Tests.yml` workflow reuses that Cobertura artifact for the pull-request CodeScene coverage-gate check and for the develop/manual CodeScene upload-and-analysis flow. The CodeScene pull-request gate downloads the uploaded artifact and runs `cs-coverage check`, while the develop/manual CodeScene step uploads coverage through `scripts/build/ci/Invoke-CodeSceneAnalysis.ps1` before it triggers a follow-up analysis run. If coverage upload succeeds but the trigger fails with an OAuth/project-owner error, fix the repository authorization in CodeScene for the project owner. That trigger-side repository authorization is separate from `CS_ACCESS_TOKEN`.

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

Command help markdown lives under `docs/<ProjectName>/<Locale>/` and is consumed by `Invoke-NovaBuild`.

In this repository, that means `docs/NovaModuleTools/en-US/`.

Important distinction:

- `docs/<ProjectName>/**/*.md` → PlatyPS command-help source
- `docs/*.html` → GitHub Pages end-user guides
- `README.md` and `CONTRIBUTING.md` → contributor documentation

Within that split, keep CLI and cmdlet documentation separate:

- `docs/*.html` should use `nova` CLI syntax when a CLI variant exists
- PowerShell cmdlets may appear in `docs/*.html` only when there is no CLI equivalent for that step, such as
  `Install-Module -Name NovaModuleTools`
- `docs/NovaModuleTools/en-US/*.md` remains the cmdlet-help surface

If you want build-generated PowerShell help, place it under `docs/<ProjectName>/`. Markdown elsewhere under `docs/` is ignored by help generation, so you can keep non-help docs there when needed.

## Repository structure and ownership

This section explains how the NovaModuleTools repository is organized and what each major area owns.

### Top-level overview

```text
.
├── .github/                    # GitHub Actions workflows
├── docs/                       # GitHub Pages HTML + PlatyPS help markdown
├── scripts/                    # build and CI automation
├── src/                        # production PowerShell code and packaged resources
├── tests/                      # Pester suites and reusable test helpers
├── project.json                # NovaModuleTools project definition
├── CHANGELOG.md                # exhaustive release history and unreleased change tracking
└── RELEASE_NOTE.md             # interface-focused release notes for public usage changes
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
- the Agentic Copilot starter package under `src/resources/agentic-copilot/`

The example project is both a shipped resource and a maintained working reference. The Agentic Copilot starter package is generated from Nova's repository-local agentic guidance, including Nova build/test/package expectations, `project.json` `Manifest.PowerShellHostVersion` compatibility guidance, generated `dist` module files, command-help ownership, source-mirrored test guidance, Test-NovaBuild-only project test guidance that forbids direct `Invoke-Pester` so agent validation matches Nova's build/import/StrictMode flow, guidance that ScriptAnalyzer findings reported by `run.ps1` must be fixed before handoff, explicit PSScriptAnalyzer workflow guidance for `./scripts/build/Invoke-ScriptAnalyzerCI.ps1`, `./run.ps1`, and focused `Invoke-ScriptAnalyzer` usage, explicit public/private PowerShell file ownership rules, best-effort source/helper-script maintainability guidance plus separate test-design guidance that live in Agentic Copilot files, explicit valid-PlatyPS help guidance for
`docs/<ProjectName>/en-US/*.md` that uses the documented `New-MarkdownCommandHelp` / `Update-MarkdownCommandHelp` /
`Test-MarkdownCommandHelp` workflow and requires a matching help file for every new public entry point in the same change, and a strict file-ending rule for changed or generated text files. When the init flow adds that starter package, it also asks for a short project name so scaffolded guidance can replace placeholders such as `Invoke-<ShortName>*`. Run
`./scripts/build/Sync-AgenticCopilotScaffold.ps1` after changing `.github/agents/`, `.github/instructions/`,
`.github/skills/`, `.github/prompts/`, or `.github/copilot-instructions.md` so future scaffolds and `dist` stay in sync.

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
- `docs/<ProjectName>/**/*.md` → PlatyPS command-help source for the current project

The build only treats markdown under `docs/<ProjectName>/` as help input. Markdown elsewhere under `docs/` can be used for other documentation without affecting help generation.

### Scripts and automation

#### `scripts/build/`

Build, analyzer, and CI helper scripts.

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

When CodeScene coverage upload is needed, run
`scripts/build/ci/Invoke-CodeSceneAnalysis.ps1 -UploadCoverage -TriggerAnalysis`. That script auto-discovers a single `*.cobertura.xml` file under `artifacts/` unless you pass `-CoveragePath`
explicitly. The repository `Tests.yml` workflow now also downloads that same Cobertura artifact during pull requests and runs the CodeScene coverage-gate check before merge. If `-TriggerAnalysis` fails after a successful upload, review the CodeScene response body: repository OAuth problems for the project owner must be fixed in CodeScene itself and are not solved by rotating `CS_ACCESS_TOKEN` alone.

### Build and test automation

The normal repository workflow is:

1. `Invoke-NovaBuild`
2. `Test-NovaBuild`
3. ScriptAnalyzer via `scripts/build/Invoke-ScriptAnalyzerCI.ps1`
4. Optional CI helper flow via `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`

When you test local publish behavior during development, remember that `Publish-NovaModule -Local` reloads the published module from the local install directory into the current PowerShell session. Re-import `dist/` if your next step depends on the built-but-unpublished output instead.

The CI helper flow also produces JUnit and Cobertura artifacts for external systems, including the coverage file that the CodeScene workflow gate and upload steps consume.

### Release automation

The current publish pipeline is PowerShell-based and no longer depends on Node.js or semantic-release tooling.

Key pieces:

- `.github/workflows/Publish.yml`
- `.github/actions/create-verified-commit/action.yml`
- `.github/actions/update-git-ref/action.yml`
- `.github/actions/create-annotated-tag/action.yml`
- `.github/actions/ensure-psresource-repository/action.yml`
- `scripts/build/ci/Install-CiPowerShellModules.ps1`

Responsibilities currently covered by the release pipeline include:

- updating `project.json`
- finalizing `CHANGELOG.md`
- finalizing `RELEASE_NOTE.md`
- creating release tags
- committing release changes back to `main`
- publishing to PowerShell Gallery
- preparing the next prerelease version on `develop`

The workflow now uses `KeepAChangelog` for changelog release moves, creates annotated git tags named directly from the release version, and bootstraps the local PSResourceGet repository store before calling `Publish-NovaModule`. The shared CI installer also installs `Pester 5.7.1` explicitly before it installs prerelease gallery modules so test workflows do not rely on transitive manifest dependency resolution.

### Where NovaModuleTools cmdlets fit

NovaModuleTools already provides the core release building blocks:

- `Update-NovaModuleVersion`
- `Publish-NovaModule`
- `Invoke-NovaRelease`

The repository workflow combines these with the `KeepAChangelog` module and local reusable GitHub actions instead of a separate semantic-release toolchain.

### Contributor expectations for workflow changes

When you change CI, build, or release behavior:

- update tests
- update command help if public command behavior changes
- update `README.md` when contributor workflow changes
- update `CHANGELOG.md` when the change is relevant to users or maintainers
- update `RELEASE_NOTE.md` when the change affects public cmdlet usage, CLI usage, configuration semantics, or migration expectations

## Documentation ownership rules

- Keep contributor workflow, architecture, and automation documentation in `README.md`
- Keep `CONTRIBUTING.md` focused on contribution expectations and review checklist items
- Keep `docs/<ProjectName>/**/*.md` focused on command-help source material for the current project
- Keep `docs/*.html` focused on end-user guides
- Do not duplicate the same workflow or setup prose across multiple contributor documents

## End-user docs on GitHub Pages

### [www.novamoduletools.com](https://www.novamoduletools.com/)

## License

This project is licensed under the MIT License. See LICENSE for details.

[PSGalleryLink]: https://www.powershellgallery.com/packages/NovaModuleTools/

[WorkFlowStatus]: https://img.shields.io/github/actions/workflow/status/stiwicourage/NovaModuleTools/Tests.yml

[changelog]: https://keepachangelog.com/

[changelog-badge]: https://img.shields.io/badge/changelog-Keep%20a%20Changelog-%23E05735
