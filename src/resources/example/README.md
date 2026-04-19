# Nova example project

This folder is a **working example project** for `NovaModuleTools`.

It is meant to help a new user understand the smallest useful setup that can:

- build a module
- include a private helper
- include a resource file
- run Pester tests against the built module
- show the full `project.json` configuration surface in one place

## What is in this example?

- `project.json` – the NovaModuleTools project definition
    - includes a `Preamble` example that is written at the top of the built `.psm1`
  - includes all current top-level project settings, including `CopyResourcesToModuleRoot`, `BuildRecursiveFolders`,
    `SetSourcePath`, and `FailOnDuplicateFunctionNames`
  - includes optional manifest metadata such as `ProjectUri`, `ReleaseNotes`, and `LicenseUri`
  - includes a complete `Package` example so new users can see where package metadata and generic raw upload settings
    belong
  - includes named `Package.Repositories` examples for `Deploy-NovaPackage` / `nova deploy`
- `src/public/Get-ExampleGreeting.ps1` – a public function exported from the built module
- `src/private/Get-ExampleConfiguration.ps1` – a private helper used by the public function
- `src/resources/greeting-config.json` – a resource file bundled into the built module
- `tests/Pester.Some.Tests.ps1` – tests that import the built module and verify its behavior

## Quick start

### If you are working from this repository

Run these commands from the repository root:

If `./dist/NovaModuleTools` is not available yet, build `NovaModuleTools` from the repository root first, or use the
PowerShell Gallery workflow below.

```powershell
PS> Import-Module ./dist/NovaModuleTools -Force
PS> Set-Location ./src/resources/example
PS> Invoke-NovaBuild
PS> Test-NovaBuild
PS> Merge-NovaModule
PS> $project = Get-NovaProjectInfo
PS> Import-Module $project.OutputModuleDir -Force
PS> Get-ExampleGreeting
PS> Get-ExampleGreeting -Name 'Stiwi' -AsObject
```

### If you installed NovaModuleTools from the PowerShell Gallery

```powershell
PS> Install-Module NovaModuleTools
PS> Import-Module NovaModuleTools
PS> $module = Get-Module NovaModuleTools -ListAvailable | Select-Object -First 1
PS> Set-Location (Join-Path $module.ModuleBase 'resources/example')
PS> Invoke-NovaBuild
PS> Test-NovaBuild
PS> Merge-NovaModule
PS> $project = Get-NovaProjectInfo
PS> Import-Module $project.OutputModuleDir -Force
PS> Get-ExampleGreeting
```

## Expected result

After `Invoke-NovaBuild`, the built module is written to:

```text
src/resources/example/dist/<ProjectName>
```

After `Merge-NovaModule`, the package artifact is written to:

```text
src/resources/example/artifacts/packages/
```

The example project sets `Package.Types` to `['NuGet', 'Zip']` and `Package.Latest` to `true`, so packing generates the
normal versioned `.nupkg` / `.zip` files plus companion `*.latest.*` files in the package output directory.

The example `project.json` also shows how to configure raw package upload settings such as:

- `Package.RepositoryUrl`
- `Package.UploadPath`
- `Package.Headers`
- `Package.Auth`
- `Package.Repositories`

That means you can inspect the example configuration and then adapt it for either:

```powershell
PS> Deploy-NovaPackage -Repository ExampleRaw
PS> nova deploy -repository ExampleRaw
```

For real projects, prefer environment-variable-backed tokens over committing literal secrets in source control.

You can then import it and call:

```powershell
PS> Get-ExampleGreeting
```

which returns:

```text
Hello, Nova user!
```

## Why this example is useful

This example is intentionally small, but it demonstrates the most important NovaModuleTools concepts:

- the real project folder layout under `src/`
- how module-level preamble lines from `project.json` are emitted before the generated source markers and module code
- how public and private functions are combined into one module
- how resource files are copied and used at runtime
- how tests should import the built module from `dist/`
- where the current package, packaging, and raw-upload configuration keys live in `project.json`

If you want a new project scaffold, use `Initialize-NovaModule` (`nova init`). If you want a concrete project you can
inspect,
run, or copy through `nova init -Example`, use this example folder.
