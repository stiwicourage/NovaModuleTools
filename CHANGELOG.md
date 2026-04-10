# Changelog

All notable changes to this project will be documented in this file.

The format follows the principles from Keep a Changelog and the project aims to follow Semantic Versioning.

## [Unreleased]

### Added

### Changed

### Fixed

### Documentation

## [1.9.1] - 2026-04-10

### Added

### Changed

### Fixed

### Documentation

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
- New-MTModule generates classes directory during fresh project
- `classes` directory should include `.ps1` files which contain enums and classes

### Fixed
- Version upgrade using update-mtmoduleversion now support build tags. Improvements to semver versioning.

## [1.1.3] - 2025-09-14

### Added
- Now supports preview tag in Update-MTModuleVersion
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

- `Invoke-MTTest` now supports including and excluding tags

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

