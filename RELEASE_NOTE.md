# Release notes

This file summarizes the release notes for NovaModuleTools. **UNRELEASED** changes will be included in the next **stable** release!

## [Unreleased]

### Added

- Added `Invoke-NovaAgenticCopilotScaffold` and `% nova copilot` for adding or refreshing Nova's managed Agentic Copilot workflow in an existing project.
    - The workflow reads `ProjectName` and `Description` from `project.json`, requires an explicit `ShortName` on every run, and stops with a clear validation error when the target project metadata is missing or invalid.
    - Nova refreshes only its managed Agentic Copilot files and folders, while `README.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` are created only when they are missing.
    - The command prompts before overwrite by default and supports non-interactive execution only through `-OverrideWarning` / `--override-warning` / `-o`.

### Changed

- `Deploy-NovaPackage` now shows clearer terminal feedback during raw package uploads, including a concise pre-flight summary, progress across multiple artifacts, and a short verification hint after success.

### Deprecated

### Removed

### Fixed

### Security

## [3.0.1] - 2026-05-18

### Fixed

- The Agentic Copilot starter shipped by `nova init` no longer tells generated projects to use a `run.ps1` quality wrapper that the template does not include.
- `nova init --example` now ships the packaged example with source-mirrored tests and code coverage enabled by default, so `Test-NovaBuild` works before a build and measures `src/**/*.ps1`.

## [3.0.0] - 2026-05-17

### Added

- `Initialize-NovaModule` and `% nova init` now offer an optional **Agentic Copilot** starter package in both the minimal and example interactive scaffold flows.
    - The starter package follows a filtered mirror of Nova's maintained agentic guidance so newly scaffolded projects receive a broader Nova-style agentic baseline without Nova-specific surfaces.
    - When Git is enabled in either scaffold flow, Nova now creates or updates a default `.gitignore` in the generated project root and only appends the missing Nova-managed artifact entries instead of overwriting existing ignore rules.
    - Before the first interactive scaffold question, Nova now checks for newer NovaModuleTools releases and reuses the same non-blocking update warning behavior already used by build.
- `Test-NovaBuild` and `% nova test` now enforce `Pester.CodeCoverage.CoveragePercentTarget` from `project.json` when `CodeCoverage.Enabled` is `true`, so coverage gates work without extra external tooling.

### Changed

- New projects now start with Nova's default Pester `CodeCoverage` block in both the minimal template and packaged example `project.json`, with `Enabled=false`, shared `src/` coverage paths, JaCoCo output, and a `90` percent target ready to opt into.

## [2.4.0] - 2026-05-10
### Changed
- `Package.Latest` in `project.json` now accepts the policy values `"never"`, `"stable"`, and `"always"`.
    - Use `"stable"` when the floating `latest` package alias should follow stable package versions only.

### Deprecated
- Boolean `Package.Latest` values are deprecated and still map to `"always"` / `"never"` for now.
    - Migrate to the string-based policy values before the next major version.


## [2.3.1] - 2026-05-08
### Fixed
- `nova bump` and `Update-NovaModuleVersion` now reuse parent Git repository history when a project lives in a nested folder, instead of falling back to `Patch`.
- Non-git bump flows now stop with a clear override-warning requirement instead of presenting `Patch | Commits: 0` as if the value had been inferred automatically.


## [2.3.0] - 2026-05-06
### Changed
- Prerelease self-update confirmation now defaults to `No`.
    - `Update-NovaModuleTool`, `Update-NovaModuleTools`, and `% nova update` now require an explicit `Y` before a prerelease self-update continues.


### Fixed
- Nova-managed CI/CD test flows now pull in `Pester 5.7.1` again through the published `NovaModuleTools` manifest.
    - Existing CI/CD workflows no longer need their own `Pester` installation step just to keep project tests working.
    - `Test-NovaBuild` now fails with a clear dependency error when `Pester` is missing.


## [2.2.0] - 2026-05-06 [YANKED]
This release was yanked because it removed the implicit `Pester` dependency before Nova's CI/CD test flow installed `Pester` explicitly. Projects using `NovaModuleTools 2.2.0` could fail to run tests in CI/CD unless maintainers added their own `Pester` installation step. The regression was fixed in `2.3.0`.


### Changed
- `Invoke-NovaRelease` now aligns with `Publish-NovaModule` and `% nova release` by accepting `-Local`, `-Repository`,
  `-ModuleDirectoryPath`, and `-ApiKey` directly.
    - Existing automation should move away from deprecated `-PublishOption` usage.
- Stable `0.y.z` bump planning now stays on the major-zero line even when commit history implies a breaking change.
    - Nova now plans the next minor version instead of auto-jumping to `1.0.0`.
- `Update-NovaModuleVersion -Preview` and `% nova bump --preview` now enter the preview track deterministically from stable versions.
    - Stable versions always become the next patch preview, for example `0.2.0 -> 0.2.1-preview`.


## [2.1.0] - 2026-04-29
### Added
- `Install-NovaCli` and a packaged `nova` launcher now let macOS and Linux users install and run `nova` directly from zsh or bash.
- Mutating Nova commands now support native `-WhatIf` / `-Confirm`, and the routed CLI now supports `--what-if`, `--confirm`, and `--verbose` without dropping into PowerShell's `Suspend` prompt.
- Self-update support is now available through `Update-NovaModuleTool`, `Update-NovaModuleTools`, and `nova update`, with matching notification preference commands and CLI routes.
- `nova version --installed` / `-i` now shows the installed NovaModuleTools version beside the current project version.
- `Test-NovaBuild -Build` and `nova test --build` can now rebuild the project before running Pester.
- `Update-NovaModuleVersion -Preview` and `nova bump --preview` now support explicit preview-version iteration.
- `New-NovaModulePackage` / `nova package` and `Deploy-NovaPackage` / `nova deploy` now add generic package build and raw upload workflows.
- `-SkipTests` / `--skip-tests` and `-ContinuousIntegration` / `--continuous-integration` now support CI-oriented package, publish, release, and versioning flows.


### Changed
- Nova now uses the Nova command model and a CLI-native help system as the primary workflow surface.
- `Publish-NovaModule -Local` and `nova publish --local` now reload the published module from the local install path into the current PowerShell session.


### Removed
- **BREAKING CHANGE**: Legacy `MT` commands were removed in favor of the Nova command model.
- **BREAKING CHANGE**: `New-NovaModule` was renamed to `Initialize-NovaModule` without compatibility aliases.


### Fixed
- Invalid `nova help` invocations now return Nova's structured CLI validation errors.
- Empty or unsupported `project.json` configuration now fails fast with clearer validation messages.


## [1.9.1] - 2026-04-10
### Added
- Introduced the Nova command model and the `nova` root command together with the core public NovaModuleTools cmdlets.


### Deprecated
- `MT` commands and MT-branded documentation were deprecated in favor of the Nova command model.


### Fixed
- Resource lookup now behaves correctly when commands run from source or built `dist/` module contexts.


## [1.8.0] - 2026-04-08
### Added
- Added `BuildRecursiveFolders`, `SetSourcePath`, and `FailOnDuplicateFunctionNames` project settings for more explicit build control.


### Changed
- Build output is now generated in a deterministic file order, with `classes -> public -> private` load sequencing.


## [1.3.0] - 2025-09-23
### Added
- Resource format files named `Name.format.ps1xml` are now imported automatically through the generated module manifest.


## [1.2.0] - 2025-09-17
### Added
- Added `src/classes` support, and `Initialize-NovaModule` now creates the classes directory for new projects.


### Fixed
- Version updates now support build tags and improved semantic-version handling.


## [1.1.3] - 2025-09-14
### Added
- `Update-NovaModuleVersion` now supports preview tags, and project/build metadata now follows semver naming more consistently.
- Preview builds can now use `preview` or `prerelease` labels, for example `1.2.3-preview`.


## [1.1.0] - 2025-08-28
### Added
- Generated module manifests now include `AliasesToExport`, so exported aliases load without extra manual import work.


## [1.0.0] - 2025-03-11
### Added
- Added the optional `CopyResourcesToModuleRoot` project setting so resource files can be copied to the module root when needed.


### Fixed
- **BREAKING CHANGE**: `ProjecUri` was corrected to `ProjectUri`, and existing projects need a manual setting update.


## [0.0.9] - 2024-07-17
### Fixed
- `Invoke-NovaBuild` no longer fails when tag filters are empty.


## [0.0.7] - 2024-07-17
### Added
- The `Manifest` section in `project.json` now supports the full set of `New-ModuleManifest` parameters.


### Fixed
- The example project README now points users to the supported repository-root and Gallery workflows.
- Corrected the `ProjectUri` setting name in project metadata guidance.


## [0.0.6] - 2024-07-08
### Added
- `Test-NovaBuild` now supports include/exclude tag filtering.


## [0.0.5] - 2024-07-05
### Added
- Module initialization now prints more progress detail while a project is being created.


### Fixed
- New projects now initialize Git automatically when requested.
- Skipping tests during project creation no longer leaves behind an empty `tests` folder.


## [0.0.4] - 2024-06-25
### Added
- First PowerShell Gallery release of NovaModuleTools with the initial module workflow support.
