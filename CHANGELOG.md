# Changelog

All notable changes to this project will be documented in this file and **UNRELEASED** changes will be included in the next **stable** release!
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

- `Update-NovaModuleTool` and `% nova update` now split self-update failure details and recovery guidance across separate terminal lines, so long dependency errors stay readable instead of wrapping mid-sentence.
- `Invoke-NovaTest`, `Test-NovaBuild`, and `% nova test` now resolve and import a supported installed `Pester` version from `5.7.1` through `5.10.0` instead of using an unsupported `Pester 6.x` installation automatically.
    - Nova test workflows now fail early with a clear dependency error when only unsupported `Pester 6.x` versions are available.
- Nova test workflows now reuse an already loaded supported `Pester 5.x` version in the current PowerShell session before selecting a different installed version.
    - Repository CI no longer trips the `Pester` assembly loader by importing a gallery-installed `NovaModuleTools` module, building the local module, and then switching to another supported `Pester` version in the same session.

### Security

## [3.3.1] - 2026-07-15

### Fixed

- `Invoke-NovaTest`, `Test-NovaBuild`, and `% nova test` now resolve and import a supported installed `Pester` version from `5.7.1` through `5.10.0` instead of using an unsupported `Pester 6.x` installation automatically.
    - Nova test workflows now fail early with a clear dependency error when only unsupported `Pester 6.x` versions are available.
- Nova test workflows now reuse an already loaded supported `Pester 5.x` version in the current PowerShell session before selecting a different installed version.
    - Repository CI no longer trips the `Pester` assembly loader by importing a gallery-installed `NovaModuleTools` module, building the local module, and then switching to another supported `Pester` version in the same session.

## [3.3.0] - 2026-06-16

### Changed

- The maintained Agentic Copilot guidance shipped by Nova now uses stricter release, review, testing, and analyzer rules across prompts, skills, agents, and scaffold mirrors.
    - The repository and scaffolded guidance now stop earlier when required guidance files or required skills are missing, keep private-helper test ownership aligned with mirrored `tests/private/<domain>/<Helper>.Tests.ps1` paths, and require analyzer fallback guidance to reuse the repository wrapper settings.
    - The scaffold-sync guardrail test now verifies those release/review/test guidance expectations so future scaffold updates stay aligned with the maintained source files.

### Fixed

- `Test-NovaBuild` and `% nova test -b` now complete with a visible warning when a project has no `*.Integration.Tests.ps1` files, instead of failing the build-validation flow.
    - The guidance explains where build-validation tests belong, tells users to add at least one `*.Integration.Tests.ps1` file before rerunning `Test-NovaBuild`, and reminds users to keep unit tests in `Invoke-NovaTest`.
- The packaged example scaffold now includes a minimal `*.Integration.Tests.ps1` file that resolves the generated `ProjectName`, imports the built module, and validates `Get-ExampleGreeting`, so `nova init -e` projects can pass `Test-NovaBuild` even after the scaffold rewrites `project.json`.

## [3.2.0] - 2026-05-31

### Added

- `project.json` now has a single authoritative JSON schema hosted at `https://www.novamoduletools.com/schema/v{major}/project.json`.
    - `Invoke-NovaBuild` exports the schema to `docs/schema/v{major}/project.json` during build, creating the directory when missing.
    - `nova init` injects `"$schema": "https://www.novamoduletools.com/schema/v{major}/project.json"` into every scaffolded project.
    - `nova init` also writes `.vscode/settings.json` mapping `project.json` to the hosted schema URL so VS Code trusts the remote schema automatically without prompting.
    - VS Code picks up the schema automatically to provide field validation, autocomplete, and hover descriptions while editing `project.json`.
    - The two partial internal schemas (`Schema-Build.json`, `Schema-Pester.json`) are removed; `Schema-Project.json` is the new single source.
- Added `Invoke-NovaTest` as the dedicated NovaModuleTools unit-test command.
    - `% nova test` now routes to `Invoke-NovaTest`.
    - `Invoke-NovaTest` writes unit-test NUnit output to `artifacts/UnitTestResults.xml` and remains the code-coverage entry point.
    - `Invoke-NovaTest` now accepts a guarded `-PesterConfigurationOverride` hook for runtime-only unit-test data injection through `Run.Container`, including `PSCredential` values supplied through `New-PesterContainer -Data`.

### Changed

- `Get-NovaProjectInfo` now aligns its installed-version views with the existing CLI version contract.
    - `-Installed` now returns the installed version of the current project/module from the local module path.
    - `-InstalledNovaVersion` now returns the installed `NovaModuleTools` module name and version from PowerShell.
- `Update-NovaModuleTool` now suggests `Get-NovaProjectInfo -InstalledNovaVersion` after a successful self-update so the PowerShell verification step checks the installed NovaModuleTools version directly.
- `Test-NovaBuild` now focuses on build-validation integration tests instead of acting as the combined unit-and-build test entry point.
    - `% nova test --build` and `% nova test -b` now route to `Test-NovaBuild`.
    - `Test-NovaBuild` now writes build-validation NUnit output to `artifacts/TestResults.xml` without enforcing source coverage.
- CI, release, packaging, and repository quality workflows now run `Invoke-NovaTest` before `Test-NovaBuild` when tests are not skipped.

### Removed

- Removed boolean `Package.Latest` compat shim deprecated in 2.4.0. Setting `Package.Latest` to `true` or `false` now throws `Nova.Validation.InvalidPackageLatestPolicy` with a migration message. Use `"always"` or `"never"` instead.
- Removed `boolean` from the JSON schema `anyOf` for `Package.Latest` in `src/resources/Schema-Project.json` and `docs/schema/v3/project.json`. VS Code and schema-aware editors now reject boolean values for this field at edit time.

### Fixed

- `Publish-NovaModule` now keeps its completion summary available after local publish import or CI session refresh steps reload the module, so local publish flows no longer fail with missing private release-helper functions at the end of a successful publish.
- `Test-NovaBuild` and `% nova test` now keep the Nova progress display visibly active during long Pester runs instead of appearing stuck on one step while tests continue in the background.
    - During the long Pester phase, Nova now uses the discovered test count plus completed test results to drive the progress bar, so the visible percentage tracks real test completion instead of elapsed time.
    - The progress text now stays simple while the bar itself reflects the real test-driven completion state.
    - The configured Pester output still flows live so `project.json` settings such as `Pester.Output.Verbosity = "Detailed"` remain visible.
- Progress-enabled private workflows now have stronger mirrored progress-contract tests, and the repository adds a guardrail test so future `Write-Progress` workflows cannot land without matching test ownership.
- `Package.Types` values in `project.json` now report a human-readable validation error in VS Code instead of showing the raw regex pattern. VS Code now shows the accepted values (`NuGet`, `Zip`, `.nupkg`, `.zip`) directly in the error.

## [3.1.0] - 2026-05-24

### Added

- Added `Invoke-NovaAgenticCopilotScaffold` and `% nova copilot` for applying or refreshing Nova's managed Agentic Copilot scaffold in an existing project root.
    - The workflow reads `ProjectName` and `Description` from `project.json`, requires a `ShortName` on every run for token replacement, and fails clearly when the project metadata or short name is invalid.
    - Nova refreshes only the approved managed Agentic Copilot paths under `.github/` plus `AGENTS.md` and `CONTRIBUTING.md`, while `README.md`, `CHANGELOG.md`, and `RELEASE_NOTE.md` are created only when they are missing.
    - The new cmdlet and CLI route prompt before overwriting managed scaffold content by default, and support non-interactive execution only through `-OverrideWarning` / `--override-warning` / `-o`.
- Added `terminal-ux-design` to Nova's repository-local and scaffolded Agentic Copilot guidance.
    - The new guidance combines Atlassian's 10 design principles for delightful CLIs with Jakob Nielsen's 10 usability heuristics for user interface design, and applies them to both the PowerShell cmdlet surface and any unix-style CLI alias surface (such as `% nova`) as terminal-first user interfaces.
    - The new skill ships with a "two surfaces, two conventions" framing, a shared mapping table for concrete PowerShell cmdlet and CLI alias UX mechanisms, a universal instruction that points terminal-facing changes at the skill, and updated architect, implementation, and review agent entry points.

### Changed

- `Deploy-NovaPackage` now shows a concise resolved-upload summary before execution, reports progress while multiple artifacts are uploading, and prints a short completion summary with a suggested verification step after successful raw uploads.
- `Get-NovaProjectInfo` now fails with clearer recovery guidance when `-Path` does not exist, points to a file, or the target folder is missing `project.json`.
- `Get-NovaUpdateNotificationPreference -Verbose` now explains whether Nova is reading a stored preference or the built-in default, and the command help now points read-only PowerShell users to the matching `% nova notification` workflow.
- `Initialize-NovaModule` now shows scaffold progress, ends with the created project root plus the next suggested cmdlet, and fails with clearer guidance when the target project folder already exists.
- `Install-NovaCli` now prints the installed launcher path, suggests the next command to run, and gives a clearer `PATH` warning when the destination directory is not yet available from the shell.
- `Invoke-NovaAgenticCopilotScaffold` now shows apply progress, ends with the project root plus suggested review and validation steps, and fails with clearer cancellation guidance when the overwrite warning is declined.
- `Invoke-NovaBuild` now shows progress for the main build phases, ends with the output module directory plus the next suggested validation step, and explains the refreshed session when `-ContinuousIntegration` reloads the built module.
- `Invoke-NovaCli` now treats blank command input as root help, reports unknown commands with clearer recovery guidance, and ships a dedicated PlatyPS help topic for the PowerShell wrapper surface.
- `Invoke-NovaRelease` now shows progress for the main release phases, ends with the publish target plus a next-step hint, and uses a plan summary instead of a success summary when `-WhatIf` previews the release.
- `New-NovaModulePackage` now shows progress for build validation and artifact creation, ends with the package target plus the next suggested deployment step, and uses a package-plan summary in `-WhatIf` mode.
- `Publish-NovaModule` now shows progress for build validation, publish, local import, and CI restore phases, ends with the publish target plus a suggested verification step, and uses a publish-plan summary in `-WhatIf` mode.
- `Set-NovaUpdateNotificationPreference` now ends with a clear success or preview summary, prints the settings file path, suggests `Get-NovaUpdateNotificationPreference` as the next verification step, and gives a more actionable validation error when no enable/disable switch is supplied.
- `Test-NovaBuild` now shows progress across the main test phases, ends with the result file path plus a coverage summary and next-step hint when tests pass, uses a test-plan summary in `-WhatIf` mode, and fails with more actionable guidance when Pester or coverage checks fail.
- `Update-NovaModuleTool` now ends with a visible up-to-date, preview, cancelled, or updated summary, skips prerelease confirmation during `-WhatIf`, shows progress for the actual self-update step, and suggests `Get-NovaProjectInfo -Installed` after a successful update.
- `Update-NovaModuleVersion` now ends with a visible preview, cancelled, or updated summary, prints the resolved version file plus the detected/applied release label, shows progress while writing `project.json`, and suggests the next command to run after the bump.

### Fixed

- `Test-NovaBuild` now expands configured Pester coverage globs into concrete source files before invoking Pester, so nested helpers remain measurable in `artifacts/coverage.xml` while repository and scaffolded `project.json` defaults can stay on the simpler `src/private/**/*.ps1` entry.
- PowerShell command help `RELATED LINKS` now use valid PlatyPS Markdown links and point to shipped help topics instead of GitHub blob pages.

## [3.0.1] - 2026-05-18

### Fixed

- Website layout and copy now keep expanding with the browser width instead of stopping at fixed max-width caps on wide windows; the shared site stylesheet no longer limits the outer page shell, guide intros, leads, section headings, or guide body text to narrow fixed widths.
- The command cheat sheet now keeps the "Set up a project" section balanced by summarizing scaffold extras instead of repeating the full internal Agentic guidance list.
- The getting-started guide now splits the Agentic quickstart explanation into shorter paragraphs so the scaffold flow stays readable on the site.
- The core workflows guide now splits the scaffold and Agentic starter explanation into shorter paragraphs so the page stays readable on the site.
- The command cheat sheet now stacks the three "Set up a project" cards vertically so the section reads top-to-bottom without a missing grid slot.
- The Agentic Copilot starter shipped by `nova init` no longer tells generated projects to use a `run.ps1` quality wrapper that the template does not include.
    - The scaffold now points generated documentation and agent guidance to the repository quality loop wording plus the existing analyzer and `Test-NovaBuild` entrypoints instead.
- `nova init --example` now ships the packaged example with source-mirrored tests and `Pester.CodeCoverage.Enabled = true` by default.
    - The example scaffold now runs `Test-NovaBuild` against `src/**/*.ps1` without requiring a prior build, and the bundled docs describe that source-first coverage flow.

## [3.0.0] - 2026-05-17

### Added

- `Initialize-NovaModule` and `% nova init` now offer an optional interactive **Agentic Copilot** starter package for both the minimal and example scaffold flows.
    - The new prompt appears after the Git question, defaults to `No`, and adds one shared Nova-maintained starter tree when enabled.
    - Example scaffolds now merge the existing example README with the Agentic starter README instead of flattening the example guide into the generic starter file.
    - The starter tree is now generated from a filtered mirror of Nova's own agentic `.github/` files, with a dedicated sync script and drift test so future scaffolds and `dist` stay aligned with the maintained source guidance.
    - The generated architect/design prompt now requires final design packages and issue/work item drafts to be returned as copy-ready Markdown using the project Markdown authoring guidance.
  - The generated guidance now explicitly keeps Agentic Copilot projects on the Nova build model, treats `.psm1` / `.psd1` files as generated `dist` output, requires project test validation to run through `Test-NovaBuild` instead of direct `Invoke-Pester`, requires PlatyPS-compatible help for public commands/classes, expects one focused source-mirrored test file for every new or changed `src/**/*.ps1` file, tells agents to honor `project.json` `Manifest.PowerShellHostVersion` when writing PowerShell code and tests, and now asks for a short project name so placeholders such as `Invoke-<ShortName>*` can be replaced in the generated starter files.
      - The generated guidance now keeps local `run.ps1` quality loops ordered as ScriptAnalyzer, `Invoke-NovaBuild`, then `Test-NovaBuild`, and tells agents to fix ScriptAnalyzer findings reported by `run.ps1` instead of excluding, suppressing, or handing them off unresolved.
      - The generated guidance now points agents to the documented PSScriptAnalyzer workflow, using `./scripts/build/Invoke-ScriptAnalyzerCI.ps1` and `./run.ps1` as the normal entrypoints and reserving direct `Invoke-ScriptAnalyzer` for focused local checks that reuse repo-approved settings.
    - The generated PowerShell guidance now requires public files to keep one top-level function per file, requires private files to keep at most one externally called function per file, keeps any extra private functions limited to related same-file top-level support helpers whose file names match the owning function, forbids nested function declarations inside PowerShell functions, limits the `Invoke-<ShortName>*` / `Get-<ShortName>*` / `Update-<ShortName>*` naming guidance to public commands, and tells private helpers to avoid those public-style names in favor of clear implementation-focused helper names.
    - The generated guidance now expresses PowerShell source/helper-script maintainability rules through `code-quality-matrix.instructions.md` and keeps test-specific design guidance in the testing instruction/skill files.
      - The generated guidance now requires `docs/<ProjectName>/en-US/*.md` to stay valid PlatyPS help with YAML metadata and build-compatible structure, tells agents to use the documented `New-MarkdownCommandHelp` / `Update-MarkdownCommandHelp` / `Test-MarkdownCommandHelp` workflow instead of replacing command help with plain Markdown that breaks `nova build`, and requires a matching help file for every new public entry point in the same change.
      - The generated PowerShell guidance now requires agents to review every changed or generated text file before handoff and normalize the file ending to exactly one trailing newline with no extra blank lines at the bottom.
      - The starter now also ships a generated `scripts/build/Test-TextFileFormatting.ps1` helper and, when project tests are enabled, a `tests/TextFileFormatting.Tests.ps1` guardrail so trailing blank-line violations fail `Test-NovaBuild` instead of relying on instructions alone.
    - When Git is enabled during either scaffold flow, Nova now creates or updates a default `.gitignore` in the generated project root and appends only the missing Nova-managed artifact entries instead of overwriting existing ignore rules.
    - `Initialize-NovaModule` and `% nova init` now check for newer NovaModuleTools releases before the first interactive scaffold question and reuse the same non-blocking update warning behavior already used by build.
- `Test-NovaBuild` and `% nova test` now enforce `Pester.CodeCoverage.CoveragePercentTarget` from `project.json` when `CodeCoverage.Enabled` is `true`, failing the test run when measured coverage drops below the configured target.
- Added a non-blocking `scripts/build/Get-TestMirrorStatus.ps1` helper that reports source files under `src/public/`, `src/private/`, and `src/classes/` without a matching mirrored test file under `tests/`, to support the migration to the source-mirrored, dot-source-first test layout.
- Added mirrored, dot-source-first Pester test files for scaffold and update private helpers (`src/private/scaffold/*.ps1` and `src/private/update/*.ps1`), so each unit-level helper now has a focused test file under `tests/private/scaffold/` or `tests/private/update/` instead of being covered only through broad legacy coverage files.
- Added mirrored, dot-source-first Pester test files for build and shared private helpers (`src/private/build/*.ps1`, `src/private/build/manifest/*.ps1`, and `src/private/shared/*.ps1`), so each unit-level helper now has a focused test file under `tests/private/build/`, `tests/private/build/manifest/`, or `tests/private/shared/` instead of being covered only through broad legacy coverage files.
- Added mirrored, dot-source-first Pester test files for CLI private helpers (`src/private/cli/*.ps1`), so most CLI argument parsers, prompt helpers, and per-command CLI wrappers now have a focused test file under `tests/private/cli/`. Large cross-cutting CLI orchestrators (`InvokeNovaCliCommandRoute.ps1`, `GetNovaCliArgumentRoutingState.ps1`, `FormatNovaCliCommandHelp.ps1`, `ConfirmNovaCliAction.ps1`, `GetNovaCliInvocationContext.ps1`) stay covered by the existing cross-cutting CLI tests.
- Added mirrored, dot-source-first Pester test files for release private helpers (`src/private/release/*.ps1`), so most release, publish, and version-update helpers (local publish path resolution, publish parameter mapping, version label inference, version part calculation, prerelease label handling, release request shaping, and per-step write/import helpers) now have a focused test file under `tests/private/release/`. Multi-step release/publish/version-update workflow orchestrators (`InvokeNovaReleaseWorkflow.ps1`, `InvokeNovaPublishWorkflow.ps1`, `GetNovaVersionUpdateWorkflowContext.ps1`) stay covered by the existing cross-cutting release tests.
- Added mirrored, dot-source-first Pester test files for package private helpers (`src/private/package/*.ps1`), so most package metadata, archive-content, NuGet/Zip artifact, upload option, upload target, upload header/auth, upload file-resolution, upload request, and per-type upload helpers now have a focused test file under `tests/private/package/`. Multi-step package workflow orchestrators (`InvokeNovaPackageWorkflow.ps1`, `InvokeNovaPackageUploadWorkflow.ps1`, `GetNovaPackageWorkflowContext.ps1`, `GetNovaPackageUploadWorkflowContext.ps1`, `InvokeNovaPackageArtifactCreation.ps1`, `NewNovaPackageArtifacts.ps1`) stay covered by the existing cross-cutting package tests.
- Added mirrored, dot-source-first Pester test files for every public command (`src/public/*.ps1`), so each command (`Invoke-NovaBuild`, `Test-NovaBuild`, `New-NovaModulePackage`, `Initialize-NovaModule`, `Get-NovaProjectInfo`, `Get-/Set-NovaUpdateNotificationPreference`, `Install-NovaCli`, `Invoke-NovaCli`, `Update-NovaModuleTool`, `Update-NovaModuleVersion`, `Deploy-NovaPackage`, `Publish-NovaModule`, `Invoke-NovaRelease`) now has a focused command-surface test under `tests/public/` covering parameter forwarding, delegation to its workflow context/workflow helpers, and `ShouldProcess` / `-WhatIf` behavior without duplicating private helper coverage.
- Restored measured code coverage to the configured 99% target after the test-layout migration by adding mirrored, dot-source-first tests and branch coverage extensions across the remaining gap files in `src/private/quality/`, `src/private/package/`, `src/private/release/`, `src/private/scaffold/`, `src/private/build/`, and `src/private/shared/`. The full suite now reports 99% line coverage against `src/**/*.ps1` with no dist-folder dependency in any test file.

### Changed

- Removed the pre-migration broad coverage-bucket suites (`CoverageGaps*`, `CoverageCompletion*`, `Remaining*Coverage*`, broad `NovaCommandModel*`). The mirrored `tests/public/` and `tests/private/<domain>/` suites added in now own that coverage, and the restored 99% measured coverage confirms no regression, so the parked `tests/_legacy/` reference copies are no longer needed.
- Migrated the remaining mirrored private-helper tests (`tests/private/update/`, `tests/private/quality/`, `tests/private/build/InvokeNovaBuildWorkflow.Tests.ps1`, and `tests/private/scaffold/`) off the legacy `Import-Module dist + InModuleScope` pattern to the dot-source-first model, so the full mirrored test suite runs against `src/**/*.ps1` directly and does not require a prior `Invoke-NovaBuild`.
- Removed the dist-requiring integration and guardrail tests (`Module`, `OutputFiles`, `BuildOptions`, `CiCoverage`, `CliHelperCoverage`, `CliSharedParser`, `PackageLatestPolicy`, `PreambleBuild`, `UpdateNotification`) and their `*TestSupport.ps1` sidecars now that the mirrored suites cover the same behavior and `nova test` no longer depends on `dist/NovaModuleTools` being built first.
- Test-loading guidance for NovaModuleTools' own tests and for generated Agentic Copilot scaffolds now follows a source-mirrored, dot-source-first pattern: new mirrored tests dot-source the relevant `src/**/*.ps1` files directly in `BeforeAll` instead of importing the built `dist` module or wrapping assertions in `InModuleScope`, so tests run against source files and JaCoCo coverage references real source paths.
- `project.json` `Pester.CodeCoverage.Enabled` is `true` with a `99` percent target that the migrated, source-mirrored test suite now satisfies; this finalizes the temporary disable from the test-layout migration.
- Refactored the current branch's source-mirrored test batch into per-file `*.TestSupport.ps1` sidecars and data-driven assertions where needed, so the migrated tests keep Code Health at 10 without falling back to broad legacy buckets or dist-module loading.
- The architect/design flow now surfaces settled vs unresolved design items before finalization, offers explicit choices for full finalization vs design-package-only handoff, clarifies how to use design notes versus the paste-ready GitHub issue draft, and requires finalization output to follow the project Markdown authoring guidance.
- `ProjectTemplate.json` and the packaged example `project.json` now include Nova's default Pester `CodeCoverage` block with `Enabled=false`, shared `src/` coverage paths, JaCoCo output, and a `90` percent target so new projects can opt into coverage without hand-authoring the configuration.
- `Invoke-NovaModuleToolsCI.ps1` now delegates the full test run to a single `Test-NovaBuild` call; the previous second `Invoke-Pester` pass and post-run Cobertura source-path remapping step have been removed.
- CodeScene coverage upload now uses JaCoCo format instead of Cobertura and uploads both `line-coverage` and `branch-coverage` metrics in a single CI run; the helper script auto-discovers `artifacts/coverage.xml` instead of scanning for `*.cobertura.xml` files.
- `Tests.yml` coverage-gate step now matches `**/coverage.xml` instead of `**/pester-coverage.cobertura.xml` to align with the new JaCoCo artifact path.

### Fixed

- `Test-NovaBuild` and `% nova test` no longer emit `Remove-Item -Recurse` progress bars during the Pester run; `$global:ProgressPreference` is saved and restored around the test execution so CI logs stay clean.
- Code coverage in `Test-NovaBuild` now runs against the source files, instead of the built `dist/<ModuleName>/<ModuleName>.psm1` file so measured coverage percentages and line numbers align with the deployed module.
- `Invoke-CodeSceneAnalysis.ps1` now normalizes Pester's JaCoCo output before upload so the `<class sourcefilename>` and `<sourcefile name>` entries are bare filenames and `package + sourcefile` resolves to real repository paths. This fixes the CodeScene `cs-coverage upload` failure "The coverage data does not contains any records related to the current repo" that appeared after the source-mirrored coverage migration.
- The pull-request CodeScene coverage gate now normalizes downloaded JaCoCo coverage artifacts before running `cs-coverage check`, so PRs no longer report `0.0%` coverage across the board because of unnormalized `package + sourcefile` paths.
- `Invoke-CodeSceneAnalysis.ps1` now only invokes the `cs-coverage upload … --metric branch-coverage` step when the JaCoCo report actually contains `<counter type="BRANCH">` entries, so Pester reports that only emit line counters no longer fail the CodeScene step with "Requested metric is not present in coverage data".
- Pester coverage configuration now uses explicit private-folder depth globs instead of `src/private/**/*.ps1`, so nested helpers such as `src/private/build/manifest/` and `src/private/quality/duplicates/` are included in `artifacts/coverage.xml` during the full `Test-NovaBuild` run.

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

[Unreleased]: https://github.com/stiwicourage/NovaModuleTools/compare/3.3.1...HEAD
[3.3.1]: https://github.com/stiwicourage/NovaModuleTools/compare/3.3.0...3.3.1
[3.3.0]: https://github.com/stiwicourage/NovaModuleTools/compare/3.2.0...3.3.0
[3.2.0]: https://github.com/stiwicourage/NovaModuleTools/compare/3.1.0...3.2.0
[3.1.0]: https://github.com/stiwicourage/NovaModuleTools/compare/3.0.1...3.1.0
[3.0.1]: https://github.com/stiwicourage/NovaModuleTools/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/stiwicourage/NovaModuleTools/compare/2.4.0...3.0.0
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

