# Changelog

All notable changes to this project will be documented in this file and **PreReleased/UNRELEASED** changes will be
included in the
next **stable** release!

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Add `Install-NovaCli` and a packaged `nova` launcher so macOS and Linux users can install and run `nova` directly
  from zsh or bash.
    - `nova` now remains the launcher-facing CLI surface, while `Invoke-NovaCli` stays the explicit PowerShell cmdlet
      entrypoint instead of exporting a `nova` PowerShell alias.
- Add optional `Preamble` support in `project.json` to write module-level setup lines at the top of generated `.psm1`
  files.
- Add `Initialize-NovaModule -Example` and GNU-style `% nova init --example` / `% nova init -e` support to scaffold a
  full
  working project from the packaged
  example resources.
- git initialization failures so more build and release paths now expose stable error ids and categories.
    - Runs the normal init flow
    - Applies the metadata entered during init to the generated `project.json`
    - Always creates the example test structure without prompting to enable tests
  - The packaged example `project.json` now keeps the current project, manifest, package, and raw-upload settings
    visible in one place so users can see the full supported configuration surface
- Add native `-WhatIf` and `-Confirm` support across mutating Nova commands, including GNU-style routed CLI support for
  `--verbose`/`-v`, `--what-if`/`-w`, and `--confirm`/`-c` on `build`, `test`, `bump`, `publish`, and `release`.
    - Routed CLI confirmation now stays inside the `nova` experience instead of exposing PowerShell's `Suspend` prompt.
    - Entering `S` during CLI confirmation now cancels safely, returns a non-zero exit code, and returns directly to the
      original shell.
  - Direct PowerShell cmdlets such as `Deploy-NovaPackage`, `Publish-NovaModule`, and `Update-NovaModuleVersion`
    continue to use native PowerShell confirmation semantics.
  - Non-confirmable `nova` routes such as `info`, `version`, `--help`, `--version`, and `init` now reject
    `--confirm`/`-c` consistently instead of silently accepting a PowerShell-style confirmation concept.
- Add `Update-NovaModuleTool` (with `Update-NovaModuleTools` as a compatibility alias) and `% nova update` for
  self-updating the installed module.
    - Supports `Set-NovaUpdateNotificationPreference` / `Get-NovaUpdateNotificationPreference` for PowerShell usage.
  - Supports `% nova notification`, `% nova notification --disable`/`-d`, and `% nova notification --enable`/`-e` for
    CLI
    usage.
  - Uses the stored prerelease update preference to decide whether prerelease self-updates are eligible.
  - Requires explicit confirmation before a prerelease self-update proceeds.
- Add `% nova version --installed` / `% nova version -i` so users can compare the locally installed version of the
  current
  project/module with
  the current project version from `project.json`, while keeping `% nova --version` / `% nova -v` dedicated to the
  installed
  NovaModuleTools version.
- Add build-before-test support to the test workflow so `Test-NovaBuild -Build`, `% nova test --build`, and `% nova
  test -b` rebuild the project before running Pester.
- Add an opt-in `-Preview` mode to `Update-NovaModuleVersion` / GNU-style `% nova bump --preview` / `% nova bump -p` for
  explicit preview iteration.
    - Stable versions still use the normal semantic bump target first, then append `-preview`.
    - Existing prerelease versions now stay on the same semantic core and preserve the current prerelease stem while
      appending or incrementing trailing digits, for example `preview -> preview01`, `preview09 -> preview10`,
      `rc -> rc01`, `rc1 -> rc2`, `SNAPSHOT -> SNAPSHOT01`, and `SNAPSHOT1 -> SNAPSHOT2`.
- Add `New-NovaModulePackage` and `% nova package` so projects can build, test, and package the built module output as a
  `.nupkg` artifact by using generic metadata from `project.json`, including repositories whose test runs reload or
  remove
  `NovaModuleTools` before the final package step.
    - Package output supports `Package.Types` with case-insensitive `NuGet`, `Zip`, `.nupkg`, and `.zip` values.
    - Omitting `Package.Types` still defaults packaging to a `.nupkg` artifact.
    - Selecting both `NuGet` and `Zip` creates both package formats in the configured output directory.
  - `Package.AddVersionToFileName` can append the top-level project version to a custom `Package.PackageFileName`
    before the package extension is applied.
  - Setting `Package.Latest` to `true` also creates a companion `*.latest.*` artifact for each selected package type
    while keeping the normal versioned file.
      - Package output uses `Package.OutputDirectory.Path` with `Package.OutputDirectory.Clean` defaulting to `true`.
  - Add `Deploy-NovaPackage` and `% nova deploy` for raw HTTP package uploads that stay separate from PowerShell
    repository publishing.
      - Package upload resolves `-Url`, `Package.RepositoryUrl`, or named `Package.Repositories` targets and can merge
    generic headers/auth settings.
  - Package upload now discovers all matching artifacts for the selected package types, including versioned and
    `latest` files in the configured package output directory.
- Add opt-in skip-test support to the package, publish, and release workflows for CI/CD-oriented delivery paths where
  tests already ran earlier in the pipeline.

### Fixed

- Keep CI-oriented publish and bump workflows bound to the freshly built module so follow-up `publish`, `release`, and
  `bump` steps no longer lose private helpers after module re-imports in the same session.
    - PowerShell now supports `New-NovaModulePackage -SkipTests`, `Publish-NovaModule -SkipTests`, and
      `Invoke-NovaRelease -SkipTests`.
    - The `nova` launcher now supports `--skip-tests` / `-s` on `nova package`, `nova publish`, and `nova release`.
    - Skip-tests bypasses `Test-NovaBuild` only; the related build steps still run.
- Add first-class CI activation switches so Nova can re-import the built `dist/` module at the workflow boundaries where
  session state matters.
    - PowerShell now supports `Invoke-NovaBuild -ContinuousIntegration`,
      `Update-NovaModuleVersion -ContinuousIntegration`,
      `Publish-NovaModule -ContinuousIntegration`, and `Invoke-NovaRelease -ContinuousIntegration`.
    - The `nova` launcher now supports `--continuous-integration` / `-i` on `nova build`, `nova bump`, `nova publish`,
      and `nova release` while keeping `nova version -i` dedicated to the installed-version view.
    - Build re-activates the freshly built module after the build succeeds, bump re-activates it before the version
      update starts, and publish/release restore the built module again after publish completes.
  - Repository publish no longer forces verbose `Publish-PSResource` output unless verbose logging was explicitly
    requested.
  - CI bump now reuses the already activated built-module command when the current session is already running from
    `dist/`, so publish-then-bump prerelease automation can continue in the same session without losing private helper
    bindings.

### Changed

- Change the project to a Nova command model, replacing the previous mixed MT/Nova workflow.
    - All public commands are now Nova commands, and the `nova` CLI / `Invoke-NovaCli` command surface is the primary
      entry point for all
      operations.
- Change `nova` help to a dedicated CLI-native help system with both short and long command help forms.
    - `% nova <command> --help` and `% nova <command> -h` now show short CLI help.
    - `% nova --help <command>` and `% nova -h <command>` now show long CLI help.
  - Long command help now includes the matching public GitHub Pages guide URL for the selected command, while short help
    stays focused on command syntax and options.
    - CLI help no longer delegates to PowerShell `Get-Help` and now consistently shows CLI option spellings such as
      `--repository` and `-r`.
- Refactor `tests/NovaCommandModel.TestSupport.ps1` into smaller, focused support scripts so the shared Nova command
  model
  test helpers are easier to maintain without changing test behavior.
- **BREAKING CHANGE**: Rename the public Nova scaffold cmdlets to approved verbs.
    - `New-NovaModule` → `Initialize-NovaModule`
    - No compatibility aliases are exported for the retired cmdlet names or CLI subcommands.
- Change `CopyResourcesToModuleRoot` to the canonical project setting name while keeping the default value `false`.
- Change `Publish-NovaModule -Local` and `% nova publish --local` so a successful local publish also reloads the
  published
  module from the local install path into the active PowerShell session.

### Fixed

- Fix configuration and validation errors so empty `project.json` files and unsupported `Manifest` keys fail fast with
  clear messages.
- Fix GitHub Pages guide fragment links so section anchors such as `#pack` scroll fully into view instead of hiding the
  section heading behind the sticky top navigation.

### Documentation

- Split documentation into contributor-focused repository docs and task-oriented GitHub Pages user guides.
- Expand the public site into a fuller developer end-user manual with rewritten getting started, core workflows, working
  with modules, troubleshooting, concepts, release notes, and license pages plus new reference-style pages for
  commands, `project.json`, packaging/delivery, and versioning/update behavior.
    - Improve page spacing, card padding, code-block separation, and responsive layout density so the documentation is
      easier to scan and less visually cramped.
  - The getting started and core workflows guides now let readers switch between PowerShell and command-line
    examples, including the local-publish-plus-`pwsh` handoff for `Get-ExampleGreeting` and fresh-process `pwsh`

- Clean the generated PowerShell cmdlet help so `Get-Help` pages no longer mix in `nova` launcher syntax or GNU-style
  CLI options.
    import/reload validation from the command-line path.
  - The command reference, working-with-modules, packaging-and-delivery, versioning-and-updates, and troubleshooting
    guides now use the same centered command-surface header and PowerShell/command-line example switching model.
  - The command-surface toggle sits centered in the top navigation area on the switched guides, with the `Menu`
    control aligned separately to the right and the header buttons tightened to match the menu height more closely.
  - The home page now presents its recommended first-path command examples in PowerShell form to match the default
    quickstart orientation.
  - The shared docs layout now keeps the same readable content width in PowerShell and command-line modes, while long
    command examples stay contained inside their own blocks instead of stretching the page.
  - All public pages now use the wider large-screen shell, and the single-column release-notes and license layouts use
    a broader centered content width that matches the updated site scale.
  - The public docs header logo is now larger so the NovaModuleTools brand is more prominent across the site.
- Refresh public `Get-Help` content and examples for the Nova commands, including CLI usage and preview/confirmation
  scenarios.
    - Simplify `Invoke-NovaCli` help so it matches the launcher-vs-cmdlet split cleanly and PlatyPS can generate command
      help without failing during local builds.
- Update the `nova` CLI documentation and help text to use POSIX/GNU-style long and short options while keeping
  PowerShell cmdlet examples in their native PowerShell form.
- Document the CLI-native short-help and long-help forms in the root help text, README, and `Invoke-NovaCli`
  reference.
- Clarify the documentation split between the `nova` launcher-oriented CLI surface and the explicit PowerShell
  `Invoke-NovaCli` cmdlet entrypoint, and mark examples consistently with `PS>` for PowerShell and `%` for CLI.

### Removed

- **BREAKING CHANGE**: Remove the legacy `MT` commands and MT-branded command documentation in favor of the Nova command
  model.
    - All public commands are now Nova commands, and the `nova` CLI / `Invoke-NovaCli` command surface is the primary
      entry point for all
      operations.

## [1.9.0] - 2026-04-10

### Added

- Nova command model and CLI entrypoint:
    - New root command: `nova`
    - New public commands: `Get-NovaProjectInfo`, `Invoke-NovaBuild`, `Invoke-NovaCli`, `Invoke-NovaRelease`,
      `Initialize-NovaModule`, `Publish-NovaModule`, `Test-NovaBuild`, `Update-NovaModuleVersion`
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
- Initialize-NovaModule generates classes directory during fresh project
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
