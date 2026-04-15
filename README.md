# NovaModuleTools | [![CodeScene general](https://codescene.io/images/analyzed-by-codescene-badge.svg)](https://codescene.io/projects/78904) ![WorkFlow Status][WorkFlowStatus]

NovaModuleTools is an enterprise-focused evolution of ModuleTools, designed for large-scale PowerShell projects with a
strong emphasis on structure, maintainability, and automated CI/CD pipelines.

## Description
Whether you're creating simple or robust modules, NovaModuleTools streamlines the process, making it perfect for CI/CD and automation environments. With comprehensive features included, you can start building PowerShell modules in less than 30 seconds. Let NovaModuleTools handle the build logic, so you can focus on developing the core functionality of your module.

The structure of the NovaModuleTools module is meticulously designed according to PowerShell best practices for module development. While some design decisions may seem unconventional, they are made to ensure that NovaModuleTools and the process of building modules remain straightforward and easy to manage.

If you want a more user-focused overview of what NovaModuleTools does and how to get started without diving into all
repository details, see the public landing page in `docs/index.html`.

## Install | [![NovaModuleTools@PowerShell Gallery][BadgeIOCount]][PSGalleryLink]
```PowerShell
PS> Install-Module -Name NovaModuleTools
PS> Import-Module NovaModuleTools

# Optional on macOS/Linux: install the standalone nova launcher
PS> Install-NovaCli
```

`nova` is always available as a PowerShell alias after the module is imported.

If you want to run `nova` directly from `zsh`/`bash`, `Install-NovaCli` copies the bundled launcher to
`~/.local/bin/nova` by default. Add that directory to your shell `PATH` if it is not already present:

```zsh
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

## Design
To ensure this module works correctly, you need to maintain the folder structure and the `project.json` file path. The
best way to get started is by running `New-NovaModule` (`nova init`), which guides you through a series of questions
and creates the necessary scaffolding.

## Preview changes safely with `-WhatIf`
State-changing NovaModuleTools commands support PowerShell `-WhatIf`, so you can preview what would happen before files,
versions, test artifacts, or publish targets are changed.

```powershell
PS> Invoke-NovaBuild -WhatIf
PS> Test-NovaBuild -WhatIf
PS> Publish-NovaModule -Local -WhatIf
PS> Invoke-NovaRelease -PublishOption @{ Local = $true } -WhatIf
PS> Update-NovaModuleVersion -WhatIf
PS> Install-NovaCli -WhatIf
```

From the standalone CLI on macOS/Linux, the routed commands forward preview mode to the underlying PowerShell cmdlets:

```bash
nova build -WhatIf
nova test -WhatIf
nova bump -WhatIf
nova publish -local -WhatIf
nova release -local -WhatIf
```

`nova init` is intentionally still interactive and expects only an optional path argument, so the standalone CLI does
not support `nova init -WhatIf`.

For command-specific details and examples, run `Get-Help <CommandName> -Full` after importing the module.

## Folder Structure
All module files should be inside the `src` folder.

```
.
├── project.json
└── src
    ├── classes
    │   └── Person.classes.ps1
    │   └── Person.enums.ps1
    ├── public
    │   └── New-PublicFunction.ps1
    ├── resources
    │   └── some-config.json
    └── private
        └── New-PrivateFunction.ps1
```

### Dist Folder
The generated module is stored in the `dist` folder. You can easily import it or publish it to a PowerShell repository.

```
dist
└── TestModule
    ├── TestModule.psd1
    └── TestModule.psm1
```

### Docs Folder
Store `Microsoft.PowerShell.PlatyPS` generated Markdown files in the `docs` folder. If the `docs` folder exists and contains valid Markdown files, the build will generate a MAML help file in the built module.

The generated help is meant to work with normal PowerShell help commands after the module is built and imported.
That means your Markdown help should be written so built help can be activated with `Get-Help` for the matching command
names.

```
docs
├── NovaModuleTools.md
└── Invoke-NovaBuild.md
```

### Project JSON File

The `project.json` file contains all the important details about your module and is used during the module build. It
should comply with a specific schema. You can refer to the working example project in `example/`, especially
`example/project.json` and `example/README.md`, for guidance.

Run `New-NovaModule` (`nova init`) to generate the scaffolding; this will also create the `project.json` file.

#### Build settings (optional)
NovaModuleTools supports these optional settings at the top level of `project.json`.
If a setting is omitted, NovaModuleTools now treats it as `true` by default:

- `BuildRecursiveFolders` (default: `true`)
  - When `true`, NovaModuleTools will discover `.ps1` files recursively in `src/classes` and `src/private`.
  - `src/public` is always **top-level only** (never recursive).
  - For `Test-NovaBuild` (`nova test`), `BuildRecursiveFolders=false` runs only top-level `tests/*.Tests.ps1` files (the
    usual Pester
    naming convention), while `BuildRecursiveFolders=true` also includes tests in subfolders.
- `SetSourcePath` (default: `true`)
  - When `true`, NovaModuleTools writes exactly one `# Source: <relative path>` line before each concatenated source file in the generated `dist/<Project>/<Project>.psm1`.
  - Relative paths are project-relative and normalized to `/`, for example `# Source: src/private/core/security/SetTls12SecurityProtocol.ps1`.
  - This is useful when parser errors or runtime exceptions point at line numbers in the generated `.psm1` and you need to map them back to files under `src`.
- `Preamble` (default: omitted / no output)
    - When present, this must be a top-level array of strings in `project.json`.
    - NovaModuleTools writes each configured line at the very top of the generated `dist/<Project>/<Project>.psm1`, then
      inserts one blank line before the rest of the generated module content.
    - `Preamble` is independent from `SetSourcePath`: if both are used, the preamble is written first and the generated
      `# Source: ...` markers come after the blank line.
- `FailOnDuplicateFunctionNames` (default: `true`)
  - When `true`, NovaModuleTools will parse the generated `dist/<Project>/<Project>.psm1` and fail the build if duplicate **top-level** function names exist.

Example:
```json
{
  "BuildRecursiveFolders": true,
  "SetSourcePath": true,
  "Preamble": [
    "Set-StrictMode -Version Latest"
  ],
  "FailOnDuplicateFunctionNames": true
}
```

#### Manifest validation

If you include a `Manifest` section in `project.json`, NovaModuleTools now validates the keys before writing the built
module manifest.

- Use the exact parameter names supported by `New-ModuleManifest`.
- Unsupported keys now fail the build early with a clear error message instead of being silently ignored.

For example, a manifest key such as `BogusKey` now causes the build to stop with an error similar to:

```text
Unknown parameter(s) in Manifest: BogusKey
```

When `SetSourcePath` is enabled, the generated `.psm1` contains one marker line before each source block:
```powershell
# Source: src/classes/AgentListing.ps1
class AgentListing {
    # ...
}

# Source: src/private/core/security/SetTls12SecurityProtocol.ps1
function Set-Tls12SecurityProtocol {
    # ...
}
```

With `Preamble`, you can inject module-level setup lines before those source markers and before any generated class or
function content:

```json
{
  "Preamble": [
    "Set-StrictMode -Version Latest"
  ],
  "SetSourcePath": true
}
```

This produces a generated module that starts like this:

```powershell
Set-StrictMode -Version Latest

# Source: src/classes/AgentListing.ps1
class AgentListing {
    # ...
}
```

### Src Folder
- Place all your functions in the `private` and `public` folders within the `src` directory.
- All functions in the `public` folder are exported during the module build.
- All functions in the `private` folder are accessible internally within the module but are not exposed outside the module.
- `src/classes` should contain classes and enums. These files are placed at the top of the generated `psm1`.
- `src/resources` content is handled based on the optional `CopyResourcesToModuleRoot` setting.

#### Deterministic processing order
To ensure builds are deterministic across platforms, files are processed in this order:
1. `src/classes`
2. `src/public`
3. `src/private`

Within each folder group, files are processed in a deterministic order by relative path (case-insensitive).

#### Recursive folder support
By default, NovaModuleTools loads `src/classes` and `src/private` recursively, while `src/public` remains top-level only.

If `BuildRecursiveFolders` is set to `false`:
- `src/classes`, `src/private`, and `tests` switch to top-level-only discovery.
- `src/public` remains top-level only.
- This preserves the legacy top-level-only behavior for test discovery and source loading.

#### Resources Folder
The `resources` folder within the `src` directory is intended for including any additional resources required by your module. This can include files such as:
- **Configuration files**: Store any JSON, XML, or other configuration files needed by your module.
- **Script files**: Place any scripts that are used by your functions or modules, but are not directly part of the public or private functions.
- **formatdata files**: Store `Example.Format.ps1xml` file for custom format data types to be imported to manifest
- **types files**: Store `Example.Types.ps1xml` file for custom types data types to be imported to manifest
- **Documentation files**: Include any supplementary documentation that supports the usage or development of the module.
- **Data files**: Store any data files that are used by your module, such as CSV or JSON files.
- **Subfolder**: Include any additional folders and their content to be included with the module, such as dependant Modules, APIs, DLLs, etc... organized by a subfolder.

By default, resource files from `src/resources` go into `dist/resources`. You do not need to add
`CopyResourcesToModuleRoot` to `project.json` unless you want to override that default. To place resources directly in
dist (avoiding the resources subfolder), set `CopyResourcesToModuleRoot` to `true`. This provides greater control in
certain deployment scenarios where resources files are preferred in module root directory.

Leave `src\resources` empty if there is no need to include any additional content in the `dist` folder.

An example of the module build where resources were included and `CopyResourcesToModuleRoot` is set to true.

```text
dist
└── TestModule
├── TestModule.psd1
├── TestModule.psm1
├── config.json
├── additionalScript.ps1
├── helpDocumentation.md
├── sampleData.csv
└── subfolder
├── subConfig.json
├── subScript.ps1
└── subData.csv
```

### Tests Folder
If you want to run Pester tests, keep them in the `tests` folder. Otherwise, you can ignore this feature.

## Working example project

This repository includes a real example project in `example/`.

Use it when you want something you can build, test, import, and inspect right away instead of reading a minimal schema
example in isolation.

The example demonstrates:

- a real `project.json`
- a public command under `src/public`
- a private helper under `src/private`
- a bundled resource file under `src/resources`
- Pester tests that import the built module from `dist/`

Start here:

- `example/README.md`
- `example/project.json`

Typical local flow from the repository root:

```powershell
PS> Import-Module ./dist/NovaModuleTools -Force
PS> Set-Location ./example
PS> Invoke-NovaBuild
PS> Test-NovaBuild
PS> Import-Module ./dist/NovaExampleModule -Force
PS> Get-ExampleGreeting
```

Expected output:

```text
Hello, Nova user!
```

## Local quality workflow

For local repository work, a practical quality loop is:

```powershell
#run.ps1
Set-Location $PSScriptRoot

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"

Invoke-NovaBuild
& (Join-Path $PSScriptRoot 'scripts/build/Invoke-ScriptAnalyzerCI.ps1')
Remove-Module $projectName -ErrorAction SilentlyContinue
Import-Module $distModuleDir -Force

Test-NovaBuild
```

You generally do not need to add `$ErrorActionPreference = 'Stop'` to a module preamble or helper script.
NovaModuleTools now
uses explicit terminating errors in its own build/test paths, so examples in this repository keep the preamble focused
on
module setup such as `Set-StrictMode -Version Latest`.

This keeps ScriptAnalyzer as a separate code-quality step while `Test-NovaBuild` remains focused on Pester tests.
When ScriptAnalyzer runs this way, its findings are written to `artifacts/scriptanalyzer.txt` and are not counted as
Pester test cases. `Test-NovaBuild` also writes the Pester XML report to `artifacts/TestResults.xml` so test output and
quality artifacts stay in the same place.

For CI parity, this repository now also includes reusable helper scripts under `scripts/build/ci/`:

- `scripts/build/ci/Install-CiPowerShellModules.ps1`
- `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`
- `scripts/build/ci/Invoke-CodeSceneAnalysis.ps1`

The CI helper flow builds the module, runs ScriptAnalyzer, runs the normal `Test-NovaBuild` workflow, generates
additional CI-friendly reports, and remaps Cobertura coverage from `dist/<Project>/<Project>.psm1` back to `src/...`
paths using the generated `# Source:` markers.

Expected CI artifacts:

- `artifacts/novamoduletools-nunit.xml` — NUnit XML from `Test-NovaBuild`
- `artifacts/pester-junit.xml` — JUnit XML for CI systems that expect JUnit-compatible test reports
- `artifacts/pester-coverage.cobertura.xml` — Cobertura XML with source-relative paths suitable for CodeScene upload
- `artifacts/coverage-low.txt` — a simple low-coverage summary sorted by the least-covered source files first
- `artifacts/scriptanalyzer.txt` — ScriptAnalyzer findings (or a no-findings report)

## Commands

All `nova ...` examples below work in either of these modes:

- inside `pwsh` after `Import-Module NovaModuleTools`
- directly from `zsh`/`bash` on macOS/Linux after running `Install-NovaCli`

### Install-NovaCli

Use `Install-NovaCli` when you want the bundled `nova` launcher available directly from your normal shell.

```powershell
# Install to the default macOS/Linux location
PS> Install-NovaCli

# Install to a custom directory
PS> Install-NovaCli -DestinationDirectory ~/bin -Force
```

On Windows, keep using the `nova` alias inside `pwsh` after importing the module.

### New-NovaModule (`nova init`)

This interactive command helps you create the module structure. Easily create the skeleton of your module and get started with module building in no time.
```powershell
## Create a module skeleton in Work Directory
PS> New-NovaModule ~/Work

## Same action through the nova CLI
nova init ~/Work
```

### A typical interactive session looks like this:

```text
PS ~/Work> nova init

Module Name
Enter Module name of your choice, should be single word with no special characters
Name: NovaModuleTools

Module Description
What does your module do? Describe in simple words
Description: Self-contained installer that configures Azure DevOps build agents on Windows.

Semantic Version
Starting Version of the module (Default: 0.0.1)
Version: 1.7.2

Module Author
Enter Author or company name
Name: Stiwi Gabriel Courage

Supported PowerShell Version
What is minimum supported version of PowerShell for this module (Default: 7.4)
Version: 7.4

Git Version Control
Do you want to enable version controlling using Git
[Y] Enable Git  [N] Skip Git initialization: Y

Pester Testing
Do you want to enable basic Pester Testing
[Y] Enable pester to perform testing  [N] Skip pester testing: Y

Module NovaModuleTools scaffolding complete
```

### Invoke-NovaBuild (`nova build`)
`NovaModuleTools` is designed so that you don't need any additional tools like `make` or `psake` to run the build
commands. There's no need to maintain complex `build.ps1` files or sample `.psd1` files. Simply follow the structure
outlined above, and you can run `Invoke-NovaBuild` (`nova build`) to build the module. The output will be saved in the
`dist` folder, ready for distribution.

If `SetSourcePath` is enabled in `project.json`, `Invoke-NovaBuild` (`nova build`) also annotates the generated `.psm1`
with `# Source: src/...` comments before each concatenated file block to make debugging easier.

If `Preamble` is present, `Invoke-NovaBuild` writes those lines first, adds one blank line, and then continues with the
normal generated module content. This keeps module-level initialization explicit while preserving the existing build
order for classes, public functions, private functions, exports, and resource handling.

```powershell
# From the Module root 
PS> Invoke-NovaBuild

## Verbose for more details
PS> Invoke-NovaBuild -Verbose

## Same action through the nova CLI
nova build
```

### Get-NovaProjectInfo (`nova info` / `nova version`)

This function provides complete info about the project, which can be used in Pester tests or for general
troubleshooting. Use `nova info` for the full project object or `nova version` for a concise
`<ProjectName> <ProjectVersion>` string.

Use `nova --version` when you want to see the installed `NovaModuleTools` module name and version on the current
machine as `NovaModuleTools <ModuleVersion>`.

### Test-NovaBuild (`nova test`)

All Pester configuration is stored in `project.json`. Run `Test-NovaBuild` (`nova test`) from the project root. With the
default
`BuildRecursiveFolders=true`, it discovers test files in nested folders under `tests`; set `BuildRecursiveFolders=false`
to run only top-level `tests/*.Tests.ps1` files, matching Pester's normal test-file convention.

- The generated Pester XML report is written to `artifacts/TestResults.xml`.
- To skip a test inside the test directory, use `-skip` in a `Describe`/`It`/`Context` block within the Pester test.
- Use `Get-NovaProjectInfo` (`nova info`) inside Pester to get detailed information about the project and files.

### Publish-NovaModule (`nova publish`)

Use `Publish-NovaModule` (`nova publish`) to build, test, and publish in one step.
```powershell
# Publish to your local PowerShell modules path
PS> Publish-NovaModule -Local

# Publish to a repository
PS> Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API

# Same action through the nova CLI
nova publish --local

# Same repository publish through the nova CLI
nova publish --repository PSGallery --apikey $env:PSGALLERY_API
```

For local mode, `Publish-NovaModule -Local` (`nova publish --local`) copies the built module directly to your local
module path.

> [!TIP]
> During local development, make sure your shell uses the module you just built (not an older installed copy).
>
> ```powershell
> PS> Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
> PS> Publish-NovaModule -Local
> PS> Import-Module ./dist/NovaModuleTools -Force
> ```

When running from the repository root, build-time schema/resource lookup also falls back to project resources under
`src/resources`.

### Update-NovaModuleVersion (`nova bump`)

Use `Update-NovaModuleVersion` (`nova bump`) to update the version stored in `project.json` based on your Git commit
history.

- breaking changes produce a `Major` bump
- `feat:` commits produce a `Minor` bump
- `fix:` commits and all other cases produce a `Patch` bump

Use `nova bump -WhatIf` when you want to preview the exact next version before writing it. The preview returns the same
`PreviousVersion`, `NewVersion`, `Label`, and `CommitCount` information as a real bump, but it leaves `project.json`
unchanged.

Use `nova bump -Confirm` when you want an interactive CLI confirmation before applying the version bump. If you decline
or suspend that confirmation, NovaModuleTools returns to your shell without changing `project.json` and without printing
the version result table.

## Advanced - Use it in Github Actions
> [!TIP]
> This repository uses Github actions to run tests and publish to PowerShell Gallery, use it as reference.

This is not required for local module builds. In this repository, GitHub Actions uses `semantic-release` on `main` to determine the next version from conventional commits, update `project.json` and `CHANGELOG.md`, create the `Version_<semver>` tag, create the GitHub release, and then publish the built module to PowerShell Gallery.

As part of that prepare step, NovaModuleTools also refreshes the comparison links at the bottom of `CHANGELOG.md` so the
`[Unreleased]` section and each released version point to the matching GitHub diff view.

If you are running GitHub Actions, use the following yaml workflow template to test, build and publish a module, which helps to automate the process of:
1. Checking out the repository code.
1. Installing the `NovaModuleTools` bootstrap module from the PowerShell Gallery.
1. Building the module.
1. Running Pester tests.
1. Running semantic-release to choose the version, update release files, tag, and publish.

This allows for seamless and automated management of your PowerShell module, ensuring consistency and reliability in your build, test, and release processes.
```yaml
name: Build, Test and Publish

on:
  push:
    branches:
      - main

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: 20
          cache: npm

      - name: Install npm dependencies
        run: |
          npm ci
        shell: pwsh

      - name: Install NovaModuleTools bootstrap module form PSGallery
        run: |
          Install-PSResource -Repository PSGallery -Name NovaModuleTools -TrustRepository
          Install-PSResource -Repository PSGallery -Name Microsoft.PowerShell.PlatyPS -TrustRepository
          Install-PSResource -Repository PSGallery -Name Pester -TrustRepository
        shell: pwsh

      - name: Build Module
        run: Invoke-NovaBuild -Verbose
        shell: pwsh

      - name: Run Pester Tests
        run: Test-NovaBuild
        shell: pwsh

      - name: Run semantic-release
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          PSGALLERY_API: ${{ secrets.PSGALLERY_API }}
        run: npx semantic-release
        shell: pwsh
```

### Code coverage and CodeScene upload in GitHub Actions

`Tests.yml` now separates testing from CodeScene analysis:

1. `test-and-coverage`
    - installs the required PowerShell modules
   - runs `scripts/build/ci/Invoke-NovaModuleToolsCI.ps1`
    - uploads `artifacts/` and `dist/` as workflow artifacts
2. `codescene-analysis`
    - downloads the artifacts from the successful test job
   - can upload `artifacts/pester-coverage.cobertura.xml` to CodeScene as `line-coverage` when `-CoveragePath` is
     supplied
   - can also trigger a CodeScene analysis on `push` to `develop`/`main` and on manual runs without uploading coverage
     by omitting `-CoveragePath`

The analysis step expects these secrets or environment variables:

- `CS_URL`
- `CS_PROJECT_ID`
- `CS_ACCESS_TOKEN`

If one of these values is missing, the workflow fails early with a clear error message. If CodeScene rejects the
analysis trigger because the daily analysis rate limit has been reached, the workflow warns and continues instead of
failing the pipeline unnecessarily.

## Requirement
- Only tested on PowerShell 7.4, so it most likely will not work on 5.1. The underlying module can still support older versions; only the NovaModuleTools builder won't work on older versions.
- No dependencies. This module doesn’t depend on any other module. Completely self-contained.

## License
This project is licensed under the MIT License. See the LICENSE file for details.

[BadgeIOCount]: https://img.shields.io/powershellgallery/dt/NovaModuleTools?label=NovaModuleTools%40PowerShell%20Gallery
[PSGalleryLink]: https://www.powershellgallery.com/packages/NovaModuleTools/
[WorkFlowStatus]: https://img.shields.io/github/actions/workflow/status/stiwicourage/NovaModuleTools/Tests.yml
