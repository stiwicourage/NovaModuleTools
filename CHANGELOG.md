# Changelog

All notable changes to this project will be documented in this file.

The format follows the principles from Keep a Changelog and the project aims to follow Semantic Versioning.

## [Unreleased]

### Added

- New Nova release and publish building blocks to support:
    - publishing to a local module directory
    - publishing to a repository
    - resolving the local module path more reliably
    - cleaner semantic-version handling for release labels
- New internal scaffolding helpers to make `New-NovaModule` easier to maintain.
- New internal duplicate-function indexing helpers to improve build validation.
- New help pages for `Invoke-NovaCli` and `Invoke-NovaRelease`.
- Expanded regression test coverage for:
    - local and repository publish behavior
    - build-time resource lookup from `src/resources`
    - packaged/built module publish behavior
    - `Update-NovaModuleVersion -WhatIf`
- Added a working `example/` project that can be built, tested, imported, and used as a practical reference for new
  NovaModuleTools users.
- Added a standalone `scripts/build/Invoke-ScriptAnalyzerCI.ps1` helper so ScriptAnalyzer can run as a dedicated quality
  step outside Pester while still producing a CI-friendly report.
- Added dynamic help activation coverage so command help pages discovered in `docs/` are exercised through built
  `Get-Help` output.
- Added reusable CI helper scripts under `build/ci/` to install PowerShell dependencies, generate JUnit/Cobertura test
  reports, remap coverage to source paths, and upload coverage to CodeScene.
- Added regression coverage for the Cobertura source-path remapping used by the CodeScene upload flow.

### Changed

- BREAKING CHANGE: The codebase is now fully centered on the Nova command model instead of a mixed MT/Nova
  implementation.
- Internal source files were reorganized into clearer areas such as build, CLI, release, shared, scaffold, and duplicate
  validation.
- Semantic release support helpers now live in `scripts/release/support/` as one function per file while keeping the
  existing `Prepare-SemanticRelease.ps1` entrypoint and dot-sourced compatibility loader.
- `Publish-NovaModule` and `Invoke-NovaRelease` now use a cleaner publish flow that resolves targets before build/test
  steps run.
- `New-NovaModule` was refactored into smaller pieces, improving maintainability and bringing its Code Health back to
  `10.0`.
- README and command documentation were refreshed to consistently use the Nova command names and describe the
  CLI/release workflow more clearly.
- Release and test automation files were updated to better support the new Nova workflow.
- The GitHub test workflow now publishes CI artifacts and runs CodeScene coverage upload/analysis in a dedicated
  follow-up
  job after tests and coverage complete successfully.
- The semantic-release preparation step now rebuilds the changelog footer so release entries keep up-to-date GitHub
  comparison links.
- The repository example, local helper workflow, and command documentation were updated to better reflect how
  NovaModuleTools
  is intended to be used in day-to-day development.

### Removed

- Removed the legacy `MT` command implementation in favor of the Nova equivalents, including:
    - `Get-MTProjectInfo`
    - `Invoke-MTBuild`
    - `Invoke-MTTests`
    - `New-MTModule`
    - `Publish-MTLocal`
    - `Update-MTModuleVersion` / `UpdateModVersion`
- Removed the remaining MT-oriented internal layout and replaced it with the reorganized Nova-focused structure.
- Replaced legacy MT command documentation with Nova command documentation.

### Fixed

- Fixed local publishing so `Publish-NovaModule -Local` no longer falls back to the legacy publish path.
- Fixed build-time resource lookup so schema and template files are found in project `src/resources` when building from
  the repository root.
- Fixed local publish/release flows so the local module path is resolved before build/test steps can reload helper
  functions.
- Fixed `ShouldProcess` support in `Update-NovaModuleVersion`, `Set-NovaModuleVersion`, and `New-NovaModule`.
- Fixed ScriptAnalyzer issues caused by empty `catch` blocks and noncompliant helper naming.
- Fixed local test/build support imports and command-model regressions uncovered during the Nova standardization work.
- Fixed generated help activation so module and command help can be loaded with `Get-Help` after build/import.
- Fixed manifest handling so unsupported `Manifest` keys now fail fast with a clear validation error instead of being
  silently tolerated.
- Fixed local module path resolution maintainability by refactoring `Get-LocalModulePath` to Code Health `10.0` and
  adding regression coverage for both the matching and error paths.
- Fixed resource-copy maintainability by refactoring `Copy-ProjectResource` to Code Health `10.0` and adding regression
  coverage for both `copyResourcesToModuleRoot` modes.
- Fixed `Test-NovaBuild` so the generated Pester XML report is now written to `artifacts/TestResults.xml` instead of the
  `dist` folder.

### Documentation

- Updated `README.md` with:
    - a dedicated `Publish-NovaModule` section
    - local and repository publish examples
    - guidance for importing the built dist module during local development
    - notes about build-time resource lookup from `src/resources`
- Added README guidance for the working `example/` project, stricter manifest validation, built help expectations, and
  the
  separate ScriptAnalyzer CI workflow.
- Documented the new GitHub Actions coverage and CodeScene integration, including artifact paths and required CodeScene
  secrets.
- Replaced the outdated `New-NovaModule` screenshot in `README.md` with a concrete `project.json` example that shows the
  expected NovaModuleTools output more clearly.
- Refreshed the `README.md` contribution guidance so contributors are clearly asked to follow the Nova workflow, run the
  local quality loop, update documentation, and keep the codebase maintainable.
- Renamed and refreshed command documentation to match the Nova command model.
- Documented that `Test-NovaBuild` now places its Pester XML output in `artifacts/TestResults.xml`.
- Added GitHub comparison links to `CHANGELOG.md` so each release entry and the `Unreleased` section can be traced back
  to repository diffs.

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

- New optional project setting `copyResourcesToModuleRoot`. Setting to true places resource files in the root directory of module. Default is `false` to provide backward compatibility. Thanks to @[BrooksV](https://github.com/BrooksV)

### Fixed

- **BREAKING CHANGE**: Typo corrected: ProjecUri to ProjectUri. Existing projects require manual update.

## [0.0.9] - 2024-07-17

### Fixed

- Fixed #7, Invoke build should not through for empty tags

## [0.0.7] - 2024-07-17

### Added

- Now "Manifest" section of project JSON supports all Manifest parameters, use exact name of parameter (from New-ModuleManifest) as key in JSON

## Fixed

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

