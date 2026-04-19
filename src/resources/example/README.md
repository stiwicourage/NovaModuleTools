# Nova example project

This folder is a **working example project** for `NovaModuleTools`.

It is meant to help a new user understand the smallest useful setup that can:

- build a module
- include a private helper
- include a resource file
- run Pester tests against the built module

## What is in this example?

- `project.json` – the NovaModuleTools project definition
    - includes a `Preamble` example that is written at the top of the built `.psm1`
  - includes a `Package` example so new users can see where generic package settings belong
  - intentionally keeps common top-level settings visible, including `CopyResourcesToModuleRoot`, so new users can
    see the available configuration keys in one place
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
PS> Pack-NovaModule
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
PS> Pack-NovaModule
PS> $project = Get-NovaProjectInfo
PS> Import-Module $project.OutputModuleDir -Force
PS> Get-ExampleGreeting
```

## Expected result

After `Invoke-NovaBuild`, the built module is written to:

```text
src/resources/example/dist/<ProjectName>
```

After `Pack-NovaModule`, the package artifact is written to:

```text
src/resources/example/artifacts/packages/
```

The example project sets `Package.Types` to `NuGet`, so the generated file is a `.nupkg` by default. Change
`Package.Types` to `['Zip']` when you only want a `.zip`, or `['NuGet', 'Zip']` when you want both package formats.

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

If you want a new project scaffold, use `New-NovaModule` (`nova init`). If you want a concrete project you can inspect,
run, or copy through `nova init -Example`, use this example folder.
