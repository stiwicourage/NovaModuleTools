# NovaModuleTools

[![CodeScene Hotspot Code Health](https://codescene.io/projects/78904/status-badges/hotspot-code-health)](https://codescene.io/projects/78904) [![CodeScene Average Code Health](https://codescene.io/projects/78904/status-badges/average-code-health)](https://codescene.io/projects/78904) [![CodeScene System Mastery](https://codescene.io/projects/78904/status-badges/system-mastery)](https://codescene.io/projects/78904)

NovaModuleTools is an enterprise-focused evolution of ModuleTools, designed for large-scale PowerShell projects (10k+ lines of code) with a strong emphasis on structure, maintainability, and automated CI/CD pipelines.

## 💬 Description

Whether you're creating simple or robust modules, NovaModuleTools streamlines the process, making it perfect for CI/CD and automation environments. With comprehensive features included, you can start building PowerShell modules in less than 30 seconds. Let NovaModuleTools handle the build logic, so you can focus on developing the core functionality of your module.

[![NovaModuleTools@PowerShell Gallery][BadgeIOCount]][PSGalleryLink]
![WorkFlow Status][WorkFlowStatus]

The structure of the NovaModuleTools module is meticulously designed according to PowerShell best practices for module development. While some design decisions may seem unconventional, they are made to ensure that NovaModuleTools and the process of building modules remain straightforward and easy to manage.

> [!IMPORTANT]
> Check out this [original blog article](https://blog.belibug.com/post/ps-modulebuild) from Manjunath Beli explaining the core concepts that NovaModuleTools builds on.

## ⚙️ Install

```PowerShell
Install-Module -Name NovaModuleTools
```

> Note: NovaModuleTools is still in an early development phase and lots of changes are expected. Please read through the [changelog](/CHANGELOG.md) for all updates.

## 🧵 Design

To ensure this module works correctly, you need to maintain the folder structure and the `project.json` file path. The
best way to get started is by running the `New-NovaModule` command, which guides you through a series of questions and
creates the necessary scaffolding.

## 📂 Folder Structure

All module files should be inside the `src` folder.

```
.
├── project.json
├── private
│  └── New-PrivateFunction.ps1
├── public
│  └── New-PublicFunction.ps1
├── resources
│  └── some-config.json
└── classes
   └── Person.classes.ps1
   └── Person.enums.ps1
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

```
docs
├── NovaModuleTools.md
└── Invoke-NovaBuild.md
```

### Project JSON File

The `project.json` file contains all the important details about your module and is used during the module build. It should comply with a specific schema. You can refer to the sample `project-sample.json` file in the `example` directory for guidance.

Run `New-NovaModule` to generate the scaffolding; this will also create the `project.json` file.

#### Build settings (optional)

NovaModuleTools supports these optional settings at the top level of `project.json`.
If a setting is omitted, NovaModuleTools now treats it as `true` by default:

- `BuildRecursiveFolders` (default: `true`)
  - When `true`, NovaModuleTools will discover `.ps1` files recursively in `src/classes` and `src/private`.
  - `src/public` is always **top-level only** (never recursive).
  - For `Test-NovaBuild`, `BuildRecursiveFolders=false` runs only top-level `tests/*.Tests.ps1` files (the usual Pester
    naming convention), while `BuildRecursiveFolders=true` also includes tests in subfolders.
- `SetSourcePath` (default: `true`)
  - When `true`, NovaModuleTools writes exactly one `# Source: <relative path>` line before each concatenated source file in the generated `dist/<Project>/<Project>.psm1`.
  - Relative paths are project-relative and normalized to `/`, for example `# Source: src/private/core/security/SetTls12SecurityProtocol.ps1`.
  - This is useful when parser errors or runtime exceptions point at line numbers in the generated `.psm1` and you need to map them back to files under `src`.
- `FailOnDuplicateFunctionNames` (default: `true`)
  - When `true`, NovaModuleTools will parse the generated `dist/<Project>/<Project>.psm1` and fail the build if duplicate **top-level** function names exist.

Example:

```json
{
  "BuildRecursiveFolders": true,
  "SetSourcePath": true,
  "FailOnDuplicateFunctionNames": true
}
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

### Src Folder

- Place all your functions in the `private` and `public` folders within the `src` directory.
- All functions in the `public` folder are exported during the module build.
- All functions in the `private` folder are accessible internally within the module but are not exposed outside the module.
- `src/classes` should contain classes and enums. These files are placed at the top of the generated `psm1`.
- `src/resources` content is handled based on `copyResourcesToModuleRoot`.

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



By default, resource files from `src/resources` go into `dist/resources`. To place them directly in dist (avoiding the resources subfolder), set `copyResourcesToModuleRoot` to `true`. This provides greater control in certain deployment scenarios where resources files are preferred in module root directory.

Leave `src\resources` empty if there is no need to include any additional content in the `dist` folder.

An example of the module build where resources were included and `copyResourcesToModuleRoot` is set to true.

```powershell
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

## 💻 Commands

### New-NovaModule

This interactive command helps you create the module structure. Easily create the skeleton of your module and get started with module building in no time.

```powershell
## Create a module skeleton in Work Directory
New-NovaModule ~/Work
```

![image-20240625210008896](./assets/image-20240625210008896.png)

### Invoke-NovaBuild

`NovaModuleTools` is designed so that you don't need any additional tools like `make` or `psake` to run the build
commands. There's no need to maintain complex `build.ps1` files or sample `.psd1` files. Simply follow the structure
outlined above, and you can run `Invoke-NovaBuild` to build the module. The output will be saved in the `dist` folder,
ready for distribution.

If `SetSourcePath` is enabled in `project.json`, `Invoke-NovaBuild` also annotates the generated `.psm1` with
`# Source: src/...` comments before each concatenated file block to make debugging easier.

```powershell
# From the Module root 
Invoke-NovaBuild

## Verbose for more details
Invoke-NovaBuild -Verbose
```

### Get-NovaProjectInfo

This function provides complete info about the project, which can be used in Pester tests or for general troubleshooting.

### Test-NovaBuild

All Pester configuration is stored in `project.json`. Run `Test-NovaBuild` from the project root. With the default
`BuildRecursiveFolders=true`, it discovers test files in nested folders under `tests`; set `BuildRecursiveFolders=false`
to run only top-level `tests/*.Tests.ps1` files, matching Pester's normal test-file convention.

- To skip a test inside the test directory, use `-skip` in a `Describe`/`It`/`Context` block within the Pester test.
- Use `Get-NovaProjectInfo` command inside pester to get great amount of info about project and files

### Publish-NovaModule

Use `Publish-NovaModule` to build, test, and publish in one step.

```powershell
# Publish to your local PowerShell modules path
Publish-NovaModule -Local

# Publish to a repository
Publish-NovaModule -Repository PSGallery -ApiKey $env:PSGALLERY_API
```

For local mode, `Publish-NovaModule -Local` copies the built module directly to your local module path.

> [!TIP]
> During local development, make sure your shell uses the module you just built (not an older installed copy).
>
> ```powershell
> Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
> Import-Module ./dist/NovaModuleTools -Force
> Publish-NovaModule -Local
> ```

When running from the repository root, build-time schema/resource lookup also falls back to project resources under
`src/resources`.

### Update-NovaModuleVersion

A simple command to update the module version by modifying the values in `project.json`. You can also manually edit the file in your favorite editor. This command makes it easy to update the semantic version.

- Running `Update-NovaModuleVersion` without any parameters will update the patch version (e.g., 1.2.3 -> 1.2.4)
- Running `Update-NovaModuleVersion -Label Major` updates the major version and resets Minor, Patch to 0 (e.g., 1.2.1 ->
  2.0.0)
- Running `Update-NovaModuleVersion -Label Minor` updates the minor version and resets Patch to 0 (e.g., 1.2.3 -> 1.3.0)

## Advanced - Use it in Github Actions

> [!TIP]
> This repository uses Github actions to run tests and publish to PowerShell Gallery, use it as reference.

This is not required for local module builds. In this repository, GitHub Actions uses `semantic-release` on `main` to determine the next version from conventional commits, update `project.json` and `CHANGELOG.md`, create the `Version_<semver>` tag, create the GitHub release, and then publish the built module to PowerShell Gallery.

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

## 📝 Requirement

- Only tested on PowerShell 7.4, so it most likely will not work on 5.1. The underlying module can still support older versions; only the NovaModuleTools builder won't work on older versions.
- No dependencies. This module doesn’t depend on any other module. Completely self-contained.

## ✅ ToDo

- [ ] Add more tests

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request with your changes. Ensure that your code adheres to the existing style and includes appropriate tests.

## 📃 License

This project is licensed under the MIT License. See the LICENSE file for details.

[BadgeIOCount]: https://img.shields.io/powershellgallery/dt/NovaModuleTools?label=NovaModuleTools%40PowerShell%20Gallery
[PSGalleryLink]: https://www.powershellgallery.com/packages/NovaModuleTools/
[WorkFlowStatus]: https://img.shields.io/github/actions/workflow/status/stiwicourage/NovaModuleTools/Tests.yml
