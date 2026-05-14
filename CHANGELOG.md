# Changelog

All notable changes to this project will be documented in this file and **UNRELEASED** changes will be included in the next **stable** release!
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- `Initialize-NovaModule` and `% nova init` now offer an optional interactive Agentic Copilot starter package for both the minimal and example scaffold flows.
    - The new prompt appears after the Git question, defaults to `No`, and adds one shared Nova-maintained starter tree when enabled.
    - Example scaffolds now merge the existing example README with the Agentic starter README instead of flattening the example guide into the generic starter file.
    - The starter tree is now generated from a filtered mirror of Nova's own agentic `.github/` files, with a dedicated sync script and drift test so future scaffolds and `dist` stay aligned with the maintained source guidance.
    - The generated architect/design prompt now requires final design packages and issue/work item drafts to be returned as copy-ready Markdown using the project Markdown authoring guidance.
  - The generated guidance now explicitly keeps Agentic Copilot projects on the Nova build model, treats `.psm1` / `.psd1` files as generated `dist` output, requires project test validation to run through `Test-NovaBuild` instead of direct `Invoke-Pester`, requires PlatyPS-compatible help for public commands/classes, expects one focused source-mirrored test file for every new or changed `src/**/*.ps1` file, tells agents to honor `project.json` `Manifest.PowerShellHostVersion` when writing PowerShell code and tests, and now asks for a short project name so placeholders such as `Invoke-<ShortName>*` can be replaced in the generated starter files.
      - The generated guidance now keeps local `run.ps1` quality loops ordered as ScriptAnalyzer, `Invoke-NovaBuild`, then `Test-NovaBuild`, and tells agents to fix ScriptAnalyzer findings reported by `run.ps1` instead of excluding, suppressing, or handing them off unresolved.
      - The generated guidance now points agents to the documented PSScriptAnalyzer workflow, using `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1` as the normal entrypoints and reserving direct `Invoke-ScriptAnalyzer` for focused local checks that reuse repo-approved settings.
      - The generated PowerShell guidance now requires public files to keep one top-level function per file, requires private files to keep at most one externally called function per file, and keeps any extra private functions limited to same-file support helpers whose file names match the owning function.
      - The generated guidance now includes a best-effort src/tests quality matrix in Agentic Copilot instructions so PowerShell, test, and review flows can shape code toward the preferred thresholds without requiring `.codescene/code-health-rules.json` in generated projects.
      - The generated guidance now requires `docs/<ProjectName>/en-US/*.md` to stay valid PlatyPS help with YAML metadata and build-compatible structure, tells agents to use the documented `New-MarkdownCommandHelp` / `Update-MarkdownCommandHelp` / `Test-MarkdownCommandHelp` workflow instead of replacing command help with plain Markdown that breaks `nova build`, and requires a matching help file for every new public entry point in the same change.
      - The generated PowerShell guidance now requires agents to review every changed or generated text file before handoff and normalize the file ending to exactly one trailing newline with no extra blank lines at the bottom.


### Changed
- The architect/design flow now surfaces settled vs unresolved design items before finalization, offers explicit choices for full finalization vs design-package-only handoff, clarifies how to use design notes versus the paste-ready GitHub issue draft, and requires finalization output to follow the project Markdown authoring guidance.


### Deprecated


### Removed


### Fixed


### Security


## [2.4.0] - 2026-05-10
### Added
- Added a repository-local agentic coding setup under `.github/` for Copilot/AI-assisted repository work.
    - Includes repository instructions, focused agent role definitions, repo-specific skills, and reusable task prompts.
  - Aligns the agent guidance with Nova's existing PowerShell, Pester, CodeScene, GitHub Actions, and release conventions.
  - Adds a discussion-first architect flow so `architect.agent.md` together with `design-change.prompt.md` now keeps the early phase conversational, asks clarifying questions, presents design directions, and only finalizes the scoped solution and GitHub issue draft after the discussion is complete.
  - Requires architect/design flows to treat out-of-scope cuts and deferred work as proposals that must be confirmed by the user before they become part of the final scope or issue draft.
      - Includes branch-aware Conventional Commit guidance that derives ticket references from `$GIT_BRANCH_NAME` and keeps commit suggestions concise and English-only.
      - Treats CodeScene Code Health as authoritative, requires safeguard checks before commit/PR readiness, and carries the repository's trailing-newline formatting rule into the agent flow.
          - Keeps local agentic work moving silently when CodeScene tooling is unavailable on a contributor machine, while pull requests and CI remain the effective CodeScene gate.
      - Adds repository-local PowerShell style guidance for indentation, spacing, braces/wrapping, and blank-line usage.
      - Adds a dedicated docs-site agent and documentation-separation guidance so website docs keep a clear CLI-vs-cmdlet split.
      - Makes the repository agent files valid Copilot custom-agent profiles by adding the required YAML frontmatter so they load correctly in `/agent`.
      - Makes the release-manager flow own PR-template-based release summaries and removes the old standalone PR-description prompt.
      - Adds reusable markdown-authoring guidance so copy-ready Markdown output can use safe outer `~~~` fences without breaking inner triple-backtick code blocks.
      - Aligns the repository guidance with actual Copilot CLI formats by using `.github/copilot-instructions.md`,
        `.github/instructions/*.instructions.md`, and `.github/skills/<skill-name>/SKILL.md`, while keeping
        `.github/prompts/*.prompt.md` as explicit prompt templates.
      - Makes the relevant agent and prompt outputs explicitly point to the `markdown-authoring` skill when they produce Markdown summaries or UI-ready Markdown text.
      - Adds focused CodeScene skills for refactoring with Code Health and for safeguarding AI-touched code before commit or PR readiness, instead of overloading the broader `codescene-quality` skill.
- Added a root-level `RELEASE_NOTE.md` that is separate from `CHANGELOG.md`.
    - `CHANGELOG.md` remains the exhaustive release history.
  - `RELEASE_NOTE.md` now captures only public cmdlet, CLI, configuration, and migration-impacting changes, including backfilled summaries for the existing released versions in `CHANGELOG.md`.
  - `Tests.yml` now validates both files, and `Publish.yml` now finalizes both files during stable release preparation.
      - The public release-notes page now renders `RELEASE_NOTE.md` instead of the full changelog feed.


### Changed
- `Package.Latest` now supports policy values: `"never"`, `"stable"`, and `"always"`.
    - `"stable"` keeps the floating `latest` alias pinned to stable package versions.
    - Legacy boolean values still work for now and map to `"always"` / `"never"` for backward compatibility.
- Release-history handling now uses a separate root-level `RELEASE_NOTE.md`.
    - `CHANGELOG.md` remains the exhaustive release history.
  - `RELEASE_NOTE.md` now captures only public cmdlet, CLI, configuration, and migration-impacting changes, including backfilled summaries for the existing released versions in `CHANGELOG.md`.
  - `Tests.yml` now validates both files, and `Publish.yml` now finalizes both files during stable release preparation.
      - The public release-notes page now renders `RELEASE_NOTE.md` instead of the full changelog feed.


### Deprecated
- Boolean `Package.Latest` values are deprecated and will be removed in the next major version.


### Removed
- Removed the repository's Codecov integration in favor of CodeScene-only coverage reporting.
    - `Tests.yml` no longer uploads CI coverage results to Codecov.
    - The standalone `codecov.yml` configuration has been removed from the repository.


### Fixed
- Clarified contributor release/test guidance in `README.md` so repository and CI test runs still install `Pester 5.7.1`
  explicitly, while the published `NovaModuleTools` manifest continues to declare that dependency for installed workflows.


## [2.3.1] - 2026-05-08
### Fixed
- Fixed `nova bump` and `Update-NovaModuleVersion` so nested project folders now reuse parent Git repository history for bump inference instead of silently falling back to `Patch`.
- Fixed `nova bump` and `Update-NovaModuleVersion` so non-git bump flows now stop with a clear override-warning requirement instead of silently presenting `Patch | Commits: 0` as if it were an inferred result.


## [2.3.0] - 2026-05-06
### Changed
- Make prerelease self-update confirmation default to `No`.
    - `Update-NovaModuleTool`, `Update-NovaModuleTools`, and `% nova update` now require an explicit `Y` before a prerelease self-update continues, so pressing Enter cancels the update instead of accepting it.
- Render bold text in white across the hosted HTML documentation.
    - Emphasized `<strong>` and `<b>` text now stands out more clearly when scanning docs pages.


### Fixed
- Restore Nova-managed project test runs in CI/CD after `2.2.0` dropped the implicit `Pester` dependency.
    - CI/CD environments no longer need custom logic to install `Pester` themselves before running project tests.
  - Published `NovaModuleTools` manifests once again pull in `Pester 5.7.1` implicitly so existing CI/CD test flows keep working without extra installation logic.
      - `Test-NovaBuild` fails with a clear dependency error when `Pester` is not installed.


## [2.2.0] - 2026-05-06 [YANKED]
This release was yanked because it removed the implicit `Pester` dependency, before Nova's CI/CD test flow installed `Pester` explicitly. Projects using `NovaModuleTools 2.2.0` could fail to run tests in CI/CD unless maintainers added their own `Pester` installation step. The regression was fixed in `2.3.0`.
### Changed
- Align `Invoke-NovaRelease` PowerShell parameters with `Publish-NovaModule` and `% nova release`.
    - PowerShell release scripts can now pass `-Local`, `-Repository`, `-ModuleDirectoryPath`, and `-ApiKey` directly.
  - Deprecated `-PublishOption` usage should be changed in existing CI/CD automation as soon as possible. Keep stable `Update-NovaModuleVersion` / `% nova bump` releases on the SemVer major-zero development line. - When the current stable version is `0.y.z` and commit history implies a breaking change, Nova now plans the next minor version instead of auto-jumping to `1.0.0`.
- Stable `0.y.z` bump results now print one warning about manually setting `1.0.0` once the software is stable, while breaking-change bumps still report the detected `Major` label.
- Make `Update-NovaModuleVersion -Preview` / `% nova bump --preview` enter the preview track deterministically from stable versions.
    - Stable versions now always become the next patch preview, for example `0.2.0 -> 0.2.1-preview`, instead of reusing semantic history inference for the semantic core.
    - Existing prerelease versions still keep their current semantic core and continue the prerelease sequence.
    - Running the bump without `-Preview` still finalizes or advances prerelease versions by Nova's normal semantic rules.


### Deprecated
- `Invoke-NovaRelease` parameters that differ from `Publish-NovaModule` and `% nova release` such as `-Local`, `-Repository`, `-ModuleDirectoryPath`, and `-ApiKey` are now the primary PowerShell release parameters, while `-PublishOption` is deprecated and will be removed in the next major version.


### Fixed
- Fix the release workflow so repository publish steps run against the freshly built `dist/` module in each CI PowerShell process.
    - `Publish.yml` now imports the built module before `Invoke-NovaRelease` and `Publish-NovaModule`, which avoids missing private helper failures when the runner also has an older installed `NovaModuleTools` version available for autoload.
- Fix the command-line test workflow wording in `docs/core-workflows.html` so the CLI preview flag is shown as
  `--what-if`.
    - The GitHub Pages guide now keeps the PowerShell `-WhatIf` wording only in the PowerShell view and shows
      `--what-if` in the command-line view.
- Add a PowerShell installed-tool version view through `Get-NovaProjectInfo -Installed`.
    - PowerShell now exposes the installed `NovaModuleTools` module name and version directly instead of requiring the launcher-only `% nova --version` path.
    - `Get-Help Get-NovaProjectInfo` now documents both the project-version and installed-tool-version views.
- Stop build-driven workflows when a `src/public` file contains zero or multiple top-level functions.
    - This prevents helper functions from being exported accidentally just because they live in a public file.
  - `Invoke-NovaBuild`, `Test-NovaBuild -Build`, packaging, publishing, and release flows now surface the warning consistently.
  - PowerShell supports `-OverrideWarning`, and the `nova` CLI supports `--override-warning` / `-o` when maintainers intentionally want to continue past the warning.
- Fix `Invoke-NovaBuild` help discovery so it only scans `docs/<ProjectName>/` for PlatyPS markdown.
    - Regular markdown elsewhere under `docs/` no longer breaks the help-generation step.
  - When PlatyPS export does not create the expected help folder, Nova now raises a stable documentation error instead of a raw rename-path failure.
- Fix the repository `run.ps1` quality loop after the CI installer refactor introduced new ScriptAnalyzer warnings.
    - The internal CI installer helper now follows ScriptAnalyzer naming and `ShouldProcess` expectations.
    - `run.ps1` no longer stops in the analyzer step because of those helper warnings.
- Fix interactive `nova init` / `nova init -e` scaffold validation so invalid answers retry immediately at the prompt.
    - Invalid module names now show the validation message inline instead of failing after the full questionnaire.
  - Standard and example scaffold flows now share the same retry-first validation behavior through the common prompt path.


## [2.1.0] - 2026-04-29
### Added
- Add `Install-NovaCli` and a packaged `nova` launcher so macOS and Linux users can install and run `nova` directly from zsh or bash.
    - `nova` now remains the launcher-facing CLI surface, while `Invoke-NovaCli` stays the explicit PowerShell cmdlet entrypoint instead of exporting a `nova` PowerShell alias.
- Add optional `Preamble` support in `project.json` to write module-level setup lines at the top of generated `.psm1`
  files.
- Add native `-WhatIf` and `-Confirm` support across mutating Nova commands, including GNU-style routed CLI support for
  `--verbose`/`-v`, `--what-if`/`-w`, and `--confirm`/`-c` on `build`, `test`, `bump`, `publish`, and `release`.
    - Routed CLI confirmation now stays inside the `nova` experience instead of exposing PowerShell's `Suspend` prompt.
  - Entering `S` during CLI confirmation now cancels safely, returns a non-zero exit code, and returns directly to the original shell.
  - Direct PowerShell cmdlets such as `Deploy-NovaPackage`, `Publish-NovaModule`, and `Update-NovaModuleVersion`
    continue to use native PowerShell confirmation semantics.
  - Non-confirmable `nova` routes such as `info`, `version`, `--help`, `--version`, and `init` now reject
    `--confirm`/`-c` consistently instead of silently accepting a PowerShell-style confirmation concept.
- Add `Update-NovaModuleTool` (with `Update-NovaModuleTools` as a compatibility alias) and `% nova update` for self-updating the installed module.
    - Supports `Set-NovaUpdateNotificationPreference` / `Get-NovaUpdateNotificationPreference` for PowerShell usage.
  - Supports `% nova notification`, `% nova notification --disable`/`-d`, and `% nova notification --enable`/`-e` for CLI usage.
  - Uses the stored prerelease update preference to decide whether prerelease self-updates are eligible.
  - Requires explicit confirmation before a prerelease self-update proceeds.
- Add `% nova version --installed` / `% nova version -i` so users can compare the locally installed version of the current project/module with the current project version from `project.json`, while keeping `% nova --version` /
  `% nova -v` dedicated to the installed NovaModuleTools version.
- Add build-before-test support to the test workflow so `Test-NovaBuild -Build`, `% nova test --build`, and
  `% nova test -b` rebuild the project before running Pester.
- Add an opt-in `-Preview` mode to `Update-NovaModuleVersion` / GNU-style `% nova bump --preview` / `% nova bump -p` for explicit preview iteration.
    - Stable versions still use the normal semantic bump target first, then append `-preview`.
  - Existing prerelease versions now stay on the same semantic core and preserve the current prerelease stem while appending or incrementing trailing digits, for example `preview -> preview01`, `preview09 -> preview10`,
      `rc -> rc01`, `rc1 -> rc2`, `SNAPSHOT -> SNAPSHOT01`, and `SNAPSHOT1 -> SNAPSHOT2`.
- Add `New-NovaModulePackage` and `% nova package` so projects can build, test, and package the built module output as a
  `.nupkg` artifact by using generic metadata from `project.json`, including repositories whose test runs reload or remove `NovaModuleTools` before the final package step.
    - Package output supports `Package.Types` with case-insensitive `NuGet`, `Zip`, `.nupkg`, and `.zip` values.
    - Omitting `Package.Types` still defaults packaging to a `.nupkg` artifact.
    - Selecting both `NuGet` and `Zip` creates both package formats in the configured output directory.
  - `Package.AddVersionToFileName` can append the top-level project version to a custom `Package.PackageFileName`
    before the package extension is applied.
  - Setting `Package.Latest` to `true` also creates a companion `*.latest.*` artifact for each selected package type while keeping the normal versioned file.
      - Package output uses `Package.OutputDirectory.Path` with `Package.OutputDirectory.Clean` defaulting to `true`.
  - Add `Deploy-NovaPackage` and `% nova deploy` for raw HTTP package uploads that stay separate from PowerShell repository publishing.
      - Package upload resolves `-Url`, `Package.RepositoryUrl`, or named `Package.Repositories` targets and can merge generic headers/auth settings.
  - Package upload now discovers all matching artifacts for the selected package types, including versioned and
    `latest` files in the configured package output directory.
- Add opt-in skip-test support to the package, publish, and release workflows for CI/CD-oriented delivery paths where tests already ran earlier in the pipeline.
- Centralize delivery configuration resolution so raw package upload, update notification settings, and PSGallery publishing now follow one explicit precedence model without surfacing configured secrets in error text.
    - Raw upload now resolves command overrides before named repository settings, then package defaults.
  - Secret lookup now resolves explicit values before environment-variable indirection, then configured literal fallbacks.
- Keep CI-oriented publish and bump workflows bound to the freshly built module so follow-up `publish`, `release`, and
  `bump` steps no longer lose private helpers after module re-imports in the same session.
    - PowerShell now supports `New-NovaModulePackage -SkipTests`, `Publish-NovaModule -SkipTests`, and
      `Invoke-NovaRelease -SkipTests`.
    - The `nova` launcher now supports `--skip-tests` / `-s` on `nova package`, `nova publish`, and `nova release`.
    - Skip-tests bypasses `Test-NovaBuild` only; the related build steps still run.
- Add first-class CI activation switches so Nova can re-import the built `dist/` module at the workflow boundaries where session state matters.
    - PowerShell now supports `Invoke-NovaBuild -ContinuousIntegration`,
      `Update-NovaModuleVersion -ContinuousIntegration`,
      `Publish-NovaModule -ContinuousIntegration`, and `Invoke-NovaRelease -ContinuousIntegration`.
  - The `nova` launcher now supports `--continuous-integration` / `-i` on `nova build`, `nova bump`, `nova publish`, and `nova release` while keeping `nova version -i` dedicated to the installed-version view.
  - Build re-activates the freshly built module after the build succeeds, bump re-activates it before the version update starts, and publish/release restore the built module again after publish completes.
  - Repository publish no longer forces verbose `Publish-PSResource` output unless verbose logging was explicitly requested.
      - CI bump now reuses the already activated built-module command when the current session is already running from
        `dist/`, so publish-then-bump prerelease automation can continue in the same session without losing private helper bindings.
  - `Update-NovaModuleVersion -ContinuousIntegration` now also falls back to a patch bump when `HEAD` already matches the latest tag, so release automation can prepare the next prerelease version without requiring an extra commit.
- Keep standalone `nova bump` output stable by formatting version-update results in the CLI layer instead of relying on PowerShell's default object rendering.
    - `nova bump --what-if` and `% run.ps1` now surface a predictable summary for previous version, new version, label, and commit count.


### Changed
- Change the project to a Nova command model, replacing the previous mixed MT/Nova workflow.
    - All public commands are now Nova commands, and the `nova` CLI / `Invoke-NovaCli` command surface is the primary entry point for all operations.
- Change `nova` help to a dedicated CLI-native help system with both short and long command help forms.
- Isolate external workflow execution behind smaller internal adapters so git, raw package upload, repository publish, self-update, settings-file I/O, and CLI environment access have clearer change points and smaller test seams.
    - `% nova <command> --help` and `% nova <command> -h` now show short CLI help.
    - `% nova --help <command>` and `% nova -h <command>` now show long CLI help.
  - Long command help now includes the matching public GitHub Pages guide URL for the selected command, while short help stays focused on command syntax and options.
      - CLI help no longer delegates to PowerShell `Get-Help` and now consistently shows CLI option spellings such as
        `--repository` and `-r`.
- **BREAKING CHANGE**: Rename the public Nova scaffold cmdlets.
    - `New-NovaModule` → `Initialize-NovaModule`
    - No compatibility aliases are exported for the retired cmdlet names or CLI subcommands.
- Change `CopyResourcesToModuleRoot` to the canonical project setting name while keeping the default value `false`.
- Change `Publish-NovaModule -Local` and `% nova publish --local` so a successful local publish also reloads the published module from the local install path into the active PowerShell session.


### Removed
- **BREAKING CHANGE**: Remove the legacy `MT` commands and MT-branded command documentation in favor of the Nova command model.
    - All public commands are now Nova commands, and the `nova` CLI / `Invoke-NovaCli` command surface is the primary entry point for all operations.


### Fixed
- Fix unsupported `nova` help invocations so they now return Nova's structured CLI validation error instead of a PowerShell parameter-binding failure.
- Keep manifest/package helper edge cases aligned with their intended behavior.
    - Manifest settings resolution now accepts ordered dictionary metadata shapes in addition to plain hashtables.
  - `New-NovaPackageArtifacts` now accepts an empty metadata list and returns an empty artifact result instead of failing during parameter binding.
- Fix configuration and validation errors so empty `project.json` files and unsupported `Manifest` keys fail fast with clear messages.
- Fix semantic-release PSGallery publishing on fresh CI runners by bootstrapping the PSResourceGet repository store before
  `Publish-PSResource` runs.


## [1.9.1] - 2026-04-10
### Added
- Nova command model and CLI entrypoint:
    - New root command: `nova`
  - New public commands: `Get-NovaProjectInfo`, `Invoke-NovaBuild`, `Invoke-NovaCli`, `Invoke-NovaRelease`, `Initialize-NovaModule`, `Publish-NovaModule`, `Test-NovaBuild`, `Update-NovaModuleVersion`
- Release orchestration helpers for command routing, version label detection from commits, and publish flow support.
- New test coverage in `tests/NovaCommandModel.Tests.ps1` for Nova command routing and release flow behavior.
- New GitHub workflow: Dependency Review (`.github/workflows/dependency-review.yml`).
- New GitHub workflow: PowerShell code quality (`.github/workflows/powershell.yml`).


### Changed
- Updated test workflow triggers in `.github/workflows/Tests.yml` to improve branch/PR coverage.
- Updated README module naming references to `NovaModuleTools`.
- Source alignment updates to match installed `NovaModuleTools` v`1.8.0` behavior for compatibility.


### Deprecated
- `MT` commands and MT-branded command documentation in favor of the Nova command model.


### Fixed
- Resource lookup compatibility in `Get-ResourceFilePath` for source/dist execution contexts.


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
- New optional project setting `CopyResourcesToModuleRoot`. Setting to true places resource files in the root directory of module. Default is `false` to provide backward compatibility. Thanks to @[BrooksV](https://github.com/BrooksV)


### Fixed
- **BREAKING CHANGE**: Typo corrected: ProjecUri to ProjectUri. Existing projects require manual update.


## [0.0.9] - 2024-07-17
### Fixed
- Fixed #7, Invoke build should not through for empty tags


## [0.0.7] - 2024-07-17
### Added
- Now "Manifest" section of project JSON supports all Manifest parameters, use exact name of parameter (from New-ModuleManifest) as key in JSON


## Fixed
- Fixed the example project README so it no longer suggests that `example/` includes a `run.ps1` helper script; it now points users to building `NovaModuleTools` from the repository root or using the Gallery workflow.
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


[Unreleased]: https://github.com/stiwicourage/NovaModuleTools/compare/2.4.0...HEAD
[2.4.0]: https://github.com/stiwicourage/NovaModuleTools/compare/2.3.1...2.4.0
[2.3.1]: https://github.com/stiwicourage/NovaModuleTools/compare/2.3.0...2.3.1
[2.3.0]: https://github.com/stiwicourage/NovaModuleTools/compare/2.2.0...2.3.0
[2.2.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_2.1.0...2.2.0
[2.1.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_2.0.0...Version_2.1.0
[2.0.0]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.9.1...Version_2.0.0
[1.9.1]: https://github.com/stiwicourage/NovaModuleTools/compare/Version_1.8.0...Version_1.9.1
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
