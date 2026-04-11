# NovaExampleModule

This folder is a **working example project** for `NovaModuleTools`.

It is meant to help a new user understand the smallest useful setup that can:

- build a module
- include a private helper
- include a resource file
- run Pester tests against the built module

## What is in this example?

- `project.json` – the NovaModuleTools project definition
- `src/public/Get-ExampleGreeting.ps1` – a public function exported from the built module
- `src/private/Get-ExampleConfiguration.ps1` – a private helper used by the public function
- `src/resources/greeting-config.json` – a resource file bundled into the built module
- `tests/Pester.Some.Tests.ps1` – tests that import the built module and verify its behavior

## Quick start

### If you are working from this repository

Run these commands from the repository root:

If `./dist/NovaModuleTools` is not available yet, run `./run.ps1` once first or use the PowerShell Gallery workflow
below.

```powershell
Import-Module ./dist/NovaModuleTools -Force
Set-Location ./example
Invoke-NovaBuild
Test-NovaBuild
Import-Module ./dist/NovaExampleModule -Force
Get-ExampleGreeting
Get-ExampleGreeting -Name 'Stiwi' -AsObject
```

### If you installed NovaModuleTools from the PowerShell Gallery

```powershell
Install-Module NovaModuleTools
Import-Module NovaModuleTools
Set-Location /path/to/NovaModuleTools/example
Invoke-NovaBuild
Test-NovaBuild
Import-Module ./dist/NovaExampleModule -Force
Get-ExampleGreeting
```

## Expected result

After `Invoke-NovaBuild`, the built module is written to:

```text
example/dist/NovaExampleModule
```

You can then import it and call:

```powershell
Get-ExampleGreeting
```

which returns:

```text
Hello, Nova user!
```

## Why this example is useful

This example is intentionally small, but it demonstrates the most important NovaModuleTools concepts:

- the real project folder layout under `src/`
- how public and private functions are combined into one module
- how resource files are copied and used at runtime
- how tests should import the built module from `dist/`

If you want a new project scaffold, use `New-NovaModule` (`nova init`). If you want a concrete project you can inspect
and run immediately, use this example folder.
