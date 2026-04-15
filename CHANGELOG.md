# Changelog

All notable changes to this project will be documented in this file.

The format follows the principles from Keep a Changelog and the project aims to follow Semantic Versioning.

## [Unreleased]

### Added

- Add a standalone `nova` launcher for macOS/Linux through `Install-NovaCli`.
- Add release and publish flow support for local module directories, repository publishing, and semantic-version label
  handling.
- Add reusable CI helpers for ScriptAnalyzer, test reporting, coverage remapping, CodeScene upload, and
  `artifacts/coverage-low.txt` generation.
- Add optional `Preamble` support in `project.json` to write module-level setup lines before generated source content.
- Add a working `example/` project and a user-focused landing page under `docs/` to make onboarding easier.
- Add command help pages for `Invoke-NovaCli` and `Invoke-NovaRelease`.
- Add regression coverage for release, publish, CLI install, prompt handling, project metadata, and CI coverage flows.


### Changed

- Change the project to a Nova-first command model, replacing the previous mixed MT/Nova workflow.
- Change `CopyResourcesToModuleRoot` to an optional project setting that defaults to `false`, and standardize the
  setting name across templates, tests, and docs.
- Change `Publish-NovaModule` and `Invoke-NovaRelease` to resolve publish targets before running build and test steps.
- Change publish and release orchestration to share the same resolved publish execution helper, keeping preview
  forwarding and publish-target handling consistent.
- Change the bundled `nova` launcher to ship as a packaged module resource instead of a repo-root helper file.
- Change `nova version` and `nova --version` to include the component name alongside the version for clearer CLI output.
- Change mutating commands to support consistent native `-WhatIf`/`-Confirm` behavior, including routed preview support
  through `Invoke-NovaCli` and updated `Get-Help` examples.
- Change CI, release, and contributor documentation to reflect the Nova workflow, refreshed command help, and GitHub
  comparison links.

### Fixed

- Fix the standalone macOS/Linux `nova` launcher so `nova build -Verbose` forwards the verbose flag to the underlying
  build command.
- Fix the CI helper flow so its second Pester pass reloads the freshly built `dist/` module during test discovery.
- Fix `Get-NovaProjectInfo` so empty `project.json` files fail with a clear configuration error.
- Fix `Invoke-CodeSceneAnalysis.ps1` so `-TriggerAnalysis` can run without `-CoveragePath`.
- Fix local publishing and release flows so module paths are resolved correctly before helper reloads, and
  `Publish-NovaModule -Local` no longer falls back to the legacy path.
- Fix build-time resource lookup so schema and template files are found in project `src/resources` when building from
  the repository root.
- Fix `ShouldProcess` behavior in `Update-NovaModuleVersion`, `Set-NovaModuleVersion`, and `New-NovaModule`.
- Fix generated help activation so module and command help load correctly after build and import.
- Fix manifest validation so unsupported `Manifest` keys fail fast instead of being silently tolerated.
- Fix `Test-NovaBuild` so its Pester XML report is written to `artifacts/TestResults.xml`.
- Fix ScriptAnalyzer and related test-support issues uncovered during the Nova standardization work.

### Removed

- Remove the legacy `MT` commands, MT-oriented internal layout, and MT-focused command documentation.

## [1.9.0] - 2026-04-10

### Added

- Nova command model and CLI entrypoint:
    - New root command: `nova`
    - New public commands: `Get-NovaProjectInfo`, `Invoke-NovaBuild`, `Invoke-NovaCli`, `Invoke-NovaRelease`,
      `New-NovaModule`, `Publish-NovaModule`, `Test-NovaBuild`, `Update-NovaModuleVersion`
- Release orchestration helpers for command routing, version label detection from commits, and publish flow support.
- New test coverage in `tests/NovaCommandModel.Tests.ps1` for Nova command routing and release flow behavior.
- New GitHub workflow: Dependency Review (`.github/workflows/dependency-review.yml`).
- New GitHub workflow: PowerShell code quality (`.github/workflows/powershell.yml`).

### Changed

- Updated test workflow triggers in `.github/workflows/Tests.yml` to improve branch/PR coverage.
- Updated README module naming references to `NovaModuleTools`.
- Source alignment updates to match installed `NovaModuleTools` v`1.8.0` behavior for compatibility.

### Fixed

- Resource lookup compatibility in `Get-ResourceFilePath` for source/dist execution contexts.

### Documentation

- Added documentation and release notes context for the Nova command model and workflow/security updates.

## [1.8.0] - 2026-04-08

### Added
- Project settings:
  - `BuildRecursiveFolders` (default `true`): recursive discovery for `src/classes`, `src/private` and `tests`.
  - `SetSourcePath` (default `true`): include `# Source: <relative path>` before each concatenated source file in generated `dist/<Project>/<Project>.psm1`.
  - `FailOnDuplicateFunctionNames` (default `true`): fail build when duplicate top-level function names exist in generated `dist/<Project>/<Project>.psm1`.
  - Missing values for these settings are now treated as `true`.
  - The rebranded `NovaModuleTools` module now uses its own module `GUID`.

### Changed
- Build determinism: files are processed in a deterministic order by relative path (case-insensitive), and load order is always `classes → public → private`.

### Documentation
- README: document enterprise defaults, deterministic load order, and duplicate-function validation.

## [1.3.0] - 2025-09-23

- Added support for `ps1xml1` format data. Place it in resources folder with `Name.format.ps1xml` to be automatically added as format file and imported in module manifest

## [1.2.0] - 2025-09-17

### Added
- Added support for classes directory inside src
- New-NovaModule generates classes directory during fresh project
- `classes` directory should include `.ps1` files which contain enums and classes

### Fixed
- Version upgrade using update-mtmoduleversion now support build tags. Improvements to semver versioning.

## [1.1.3] - 2025-09-14

### Added

- Now supports preview tag in Update-NovaModuleVersion
- Now supports semver naming in both project.json and modulemanifest
- Module build supports `preview` or `prerelease` tag
- Preview version looks like `1.2.3-preview` 

## [1.1.0] - 2025-08-28

## Added

- Now Module manifest includes `AliasesToExport`. This helps loading aliases without explicitly importing modules to session. 
- thanks to @djs-zmtc for suggesting the feature

## [1.0.0] - 2025-03-11

### Added

- New optional project setting `CopyResourcesToModuleRoot`. Setting to true places resource files in the root directory
  of module. Default is `false` to provide backward compatibility. Thanks to @[BrooksV](https://github.com/BrooksV)

### Fixed

- **BREAKING CHANGE**: Typo corrected: ProjecUri to ProjectUri. Existing projects require manual update.

## [0.0.9] - 2024-07-17

### Fixed

- Fixed #7, Invoke build should not through for empty tags

## [0.0.7] - 2024-07-17

### Added

- Now "Manifest" section of project JSON supports all Manifest parameters, use exact name of parameter (from New-ModuleManifest) as key in JSON

## Fixed

- Fixed the example project README so it no longer suggests that `example/` includes a `run.ps1` helper script; it now
  points users to building `NovaModuleTools` from the repository root or using the Gallery workflow.
- Corrected typo in ProjectUri from `ProjecUri` to correct spelling.

## [0.0.6] - 2024-07-08

### Added

- `Test-NovaBuild` now supports including and excluding tags

### Fixed

- Code cleanup

## [0.0.5] - 2024-07-05

### Added

- More verbose info during MTModule creation

### Fixed

- Issue #2 : Git initialization implemented
- Issue #1 : Doesn't create empty `tests` folder when user chooses `no` to tests

## [0.0.4] - 2024-06-25

### Added
- First release to `psgallery`
- All basic functionality of Module is ready

[Unreleased]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.9.0...HEAD

[1.9.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.8.0...Version_1.9.0

[1.8.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.7.0...Version_1.8.0

[1.3.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.2.5-preview...Version_1.3.0

[1.2.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.1.4-preview...Version_1.2.0

[1.1.3]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.1.0...Version_1.1.3

[1.1.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.0.0...Version_1.1.0

[1.0.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_0.0.9...Version_1.0.0

[0.0.9]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_0.0.8...Version_0.0.9

[0.0.7]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_0.0.6...Version_0.0.7

[0.0.6]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_0.0.5...Version_0.0.6

[0.0.5]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_0.0.4...Version_0.0.5

[0.0.4]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_0.0.3...Version_0.0.4

