# Development workflow

This guide describes how to work on the NovaModuleTools repository itself.

## See also

- [Developer docs hub](./README.md)
- [Contribution guide](../CONTRIBUTING.md)
- [Repository structure](./repository-structure.md)
- [CI/CD and release automation](./ci-cd-and-release.md)

## Prerequisites

Repository development expects:

- PowerShell 7.4 or newer
- Git
- `Pester`
- `PSScriptAnalyzer`
- `Microsoft.PowerShell.PlatyPS`

Node.js is only required if you are working on the current semantic-release based publish pipeline.

## Build the module locally

From the repository root:

```powershell
Set-Location $PSScriptRoot
Invoke-NovaBuild
```

This creates the built module under `dist/NovaModuleTools/`.

## Reload the built module while iterating

Use the built output during development so you validate the same shape CI uses:

```powershell
Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
Invoke-NovaBuild
Import-Module ./dist/NovaModuleTools -Force
```

If you are testing local publish behavior:

```powershell
Remove-Module NovaModuleTools -ErrorAction SilentlyContinue
Publish-NovaModule -Local
Import-Module ./dist/NovaModuleTools -Force
```

```powershell title="reload.ps1"
#reload.ps1
Set-Location $PSScriptRoot

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"
$distManifestPath = Join-Path $distModuleDir "$projectName.psd1"

Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
Invoke-NovaBuild
Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
$module = Import-Module $distManifestPath -Force -PassThru

& $module {
    Publish-NovaModule -Local
}

Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
$module = Import-Module $distManifestPath -Force -PassThru

#Only use Install-NovaCli for macOS/Linux users.
#& $module {
#    Install-NovaCli -Force
#}
```

## Run tests

Run the repository test workflow from the repository root:

```powershell
Test-NovaBuild
```

Notes:

- `Test-NovaBuild` validates the built module output, not just loose source files
- it writes NUnit XML to `artifacts/TestResults.xml`
- it respects `BuildRecursiveFolders` when discovering tests

## Run code quality checks

Run ScriptAnalyzer with the repository helper:

```powershell
& ./scripts/build/Invoke-ScriptAnalyzerCI.ps1
```

This writes findings to `artifacts/scriptanalyzer.txt`.

For CI-parity coverage and report generation, use:

```powershell
& ./scripts/build/ci/Invoke-NovaModuleToolsCI.ps1
```

That flow builds the module, runs ScriptAnalyzer, runs the normal test workflow, and emits CI-friendly reports such as:

- `artifacts/novamoduletools-nunit.xml`
- `artifacts/pester-junit.xml`
- `artifacts/pester-coverage.cobertura.xml`
- `artifacts/coverage-low.txt`

## Recommended local quality loop

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

```powershell
#reload.ps1
Set-Location $PSScriptRoot

$projectName = (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'project.json') -Raw | ConvertFrom-Json).ProjectName
$distModuleDir = Join-Path $PSScriptRoot "dist/$projectName"
$distManifestPath = Join-Path $distModuleDir "$projectName.psd1"

Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
Invoke-NovaBuild
Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
$module = Import-Module $distManifestPath -Force -PassThru

& $module {
    Publish-NovaModule -Local
}

Get-Module $projectName -All | Remove-Module -Force -ErrorAction SilentlyContinue
$module = Import-Module $distManifestPath -Force -PassThru

& $module {
    Install-NovaCli -Force
}
```

## Working on help and docs

Command help markdown lives under `docs/NovaModuleTools/en-US/` and is consumed by `Invoke-NovaBuild`.

Important distinction:

- `docs/NovaModuleTools/en-US/*.md` → PlatyPS command-help source
- `docs/*.html` → GitHub Pages end-user guides
- `developer-docs/*.md` → contributor documentation

Do not place general developer markdown under `docs/`, because the build scans `docs/**/*.md` when generating help.

