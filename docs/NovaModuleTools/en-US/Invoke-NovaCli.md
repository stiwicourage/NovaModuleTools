---
document type: cmdlet
external help file: NovaModuleTools-Help.xml
HelpUri: ''
Locale: en-US
Module Name: NovaModuleTools
ms.date: 04/22/2026
PlatyPS schema version: 2024-05-01
title: Invoke-NovaCli
---

# Invoke-NovaCli

## SYNOPSIS

Provides the command backend for the `nova` alias and a more user-friendly CLI experience.

## SYNTAX

### __AllParameterSets

```powershell
PS> Invoke-NovaCli [[-Command] <string>] [[-Arguments] <string[]>] [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION

`Invoke-NovaCli` is the cmdlet behind the `nova` alias. In day-to-day usage, the intended experience is to run the
`nova` CLI rather than call `Invoke-NovaCli` directly.

It dispatches high-level commands such as `nova info`, `nova version`, `nova --version`, `nova --help`, `nova build`,
`nova test`, `nova package`, `nova deploy`, `nova init`, `nova update`, `nova notification`, `nova publish`,
`nova bump`, and `nova release`
to the matching Nova cmdlet.

Use `Invoke-NovaCli` when you need a scriptable PowerShell command entrypoint. Use `nova` when you want the
user-focused CLI experience.

Use `nova <command> --help` when you want the routed PowerShell help for a specific command such as `nova package`,
`nova deploy`, or `nova init`.

Mutating routed commands (`build`, `test`, `package`, `deploy`, `bump`, `update`, `notification`, `publish`, and
`release`) forward PowerShell
`-WhatIf`/`-Confirm` to the underlying cmdlet. That means `nova build -WhatIf` and
`Invoke-NovaCli -Command build -WhatIf` both preview the build instead of running it.

Use `nova package` when you want to build, test, and package the current project into one or more configured package
artifacts. By default it writes a `.nupkg` to `artifacts/packages/`, and you can override that with
`Package.OutputDirectory.Path` in `project.json`.

Use `Package.Types` in `project.json` when you want to switch from the default `NuGet` output to `Zip`, or when you
want both formats. Supported values are `NuGet`, `Zip`, `.nupkg`, and `.zip`, and matching is case-insensitive.

Set `Package.Latest` to `true` when you also want `nova package` to create companion latest-named package artifacts such
as `NovaModuleTools.latest.nupkg` next to the normal versioned files.

Set `Package.AddVersionToFileName` to `true` when `Package.PackageFileName` is a stable base name such as
`AgentInstaller` and you want Nova to append `.<Version>` from `project.json` before creating the package files.

Use `nova deploy` when you want to push existing package artifacts from the configured package output directory to a raw
HTTP endpoint. It can upload all matching artifacts for the configured package types, including versioned and `latest`
files, and it resolves the upload target from `-url`, `Package.RepositoryUrl`, or `Package.Repositories`.

For local publish inside an imported PowerShell session, `nova publish -local` now reloads the published module from the
resolved local install path after the copy succeeds. Preview or cancelled runs do not import anything.

Use `nova notification` to show the current prerelease self-update preference,
`nova notification -disable` to keep `nova update` on stable releases only, and
`nova notification -enable` to allow prerelease self-update targets again.

Use `nova version` to show the current project version from `project.json`.

Use `nova version -Installed` to show the locally installed version of the current project/module from the local
PowerShell module path.

Use `nova --version` to show the installed `NovaModuleTools` version. Those are intentionally separate version views.

Use `nova update` to self-update the installed `NovaModuleTools` module. It uses the stored prerelease preference to
decide whether a prerelease target is eligible. When that preference is disabled, `nova update` only targets stable
releases. When it is enabled, `nova update` may target a prerelease, but it always asks for explicit confirmation
before running a prerelease update. If no newer version is available, the standalone launcher prints a short
`You're up to date!` summary that includes the installed version.

For the standalone launcher, `nova bump -Confirm` uses a CLI-friendly confirmation prompt. Declined or suspended choices
cancel the bump cleanly and return control to the shell without printing a version result.

Use `nova bump -Preview` when you want an explicit prerelease-continuation bump. Stable versions resolve to the normal
semantic target plus `-preview`, while existing prerelease versions stay on the same semantic core and preserve the
current prerelease stem while appending or incrementing trailing digits such as `preview -> preview01`,
`preview09 -> preview10`, `rc -> rc01`, `rc1 -> rc2`, or `SNAPSHOT -> SNAPSHOT01`.

`nova init` remains interactive. Use `nova init -Path <path>` when you want an explicit destination and
`nova init -Example` when you want the packaged example scaffold. The CLI rejects positional `nova init <path>` usage
and also rejects `nova init -WhatIf` with a clear error.

Inside an imported PowerShell session, `nova` is available through the cmdlet alias. To make `nova` available directly
from zsh/bash on macOS or Linux, install the launcher once with `Install-NovaCli`. The standalone launcher also forwards
`-Verbose`, `-WhatIf`, and `-Confirm` for mutating commands.

## EXAMPLES

### EXAMPLE 1

```powershell
nova --version
```

Returns the installed `NovaModuleTools` module version.
The output format is `NovaModuleTools <Version>` for stable installs and `NovaModuleTools <Version>-<Prerelease>` when
the installed module manifest includes prerelease metadata.

### EXAMPLE 2

```powershell
PS> nova package --help
```

Shows the full help for `New-NovaModulePackage` through the CLI.

### EXAMPLE 14

```powershell
PS> nova deploy --help
```

Shows the full help for `Deploy-NovaPackage` through the CLI.

### EXAMPLE 15

```powershell
PS> nova init --help
```

Shows the full help for `Initialize-NovaModule` through the CLI without starting the interactive scaffold flow.

### EXAMPLE 16

```powershell
nova bump -Preview -WhatIf
```

Previews an explicit preview bump by routing `-Preview` through `Update-NovaModuleVersion`.

### EXAMPLE 17

```powershell
nova version
```

Returns the current project version from `project.json`.
The output format is `<ProjectName> <Version>`.

### EXAMPLE 3

```powershell
nova version -Installed
```

Returns the version currently installed locally for the current project/module.

### EXAMPLE 4

```powershell
nova build
```

Builds the module using `Invoke-NovaBuild`.

### EXAMPLE 5

```powershell
nova package
```

Builds, tests, and packages the current project by using the configured `Package.Types` values. When `Package.Types` is
omitted, `nova package` creates a `.nupkg` by default.

### EXAMPLE 6

```powershell
nova deploy --repository LocalNexus
```

Uploads the current project's generated package artifacts to the configured raw repository named `LocalNexus`.

### EXAMPLE 7

```powershell
nova deploy --url https://packages.example/raw/ --token $env:NOVA_PACKAGE_TOKEN
```

Uploads the matching package artifacts directly to the provided raw endpoint by using an explicit token.

### EXAMPLE 8

```powershell
nova publish --repository PSGallery --apikey $env:PSGALLERY_API
```

Parses CLI arguments and publishes using `Publish-NovaModule`.

When routed inside PowerShell with `-local`, the published module is reloaded from the local install path.

### EXAMPLE 9

```powershell
nova --help
```

Displays the built-in Nova CLI help text.

### EXAMPLE 10

```powershell
PS> Invoke-NovaCli -Command build
```

Shows the equivalent scripted PowerShell form behind `nova build`.

### EXAMPLE 11

```powershell
PS> Invoke-NovaCli -Command publish -Arguments @('-local') -WhatIf
```

Previews the routed local publish flow without rebuilding, testing, or copying the module.

### EXAMPLE 12

```powershell
PS> Invoke-NovaCli -Command init -Arguments @('-Path', '~/Work')
```

Runs the interactive init flow and creates the project under `~/Work`.

### EXAMPLE 13

```powershell
PS> Invoke-NovaCli -Command init -Arguments @('-Example', '-Path', '~/Work')
```

Runs the interactive init flow, scaffolds from the packaged example project, and creates the project under `~/Work`.

### EXAMPLE 18

```powershell
nova update
```

Updates the installed `NovaModuleTools` module by using the stored prerelease preference to resolve the best eligible
target.

If the resolved target is a prerelease, `nova update` asks for explicit confirmation before calling
`Update-Module NovaModuleTools -AllowPrerelease`.

Successful updates print the release notes link from the installed module manifest.

If no newer version is available, the standalone launcher prints `You're up to date!` and reports the installed
`NovaModuleTools` version.

### EXAMPLE 19

```powershell
nova notification
```

Shows whether prerelease self-updates are enabled and where the preference is stored.

### EXAMPLE 20

```powershell
nova notification -disable
```

Disables prerelease self-update targets so `nova update` stays on stable releases.

### EXAMPLE 21

```powershell
PS> Invoke-NovaCli -Command notification -Arguments @('-enable')
```

Re-enables prerelease self-update targets from the routed PowerShell entrypoint.

## PARAMETERS

### -Command

The command to execute. Supported values: `info`, `version`, `--version`, `--help`, `build`, `test`, `package`,
`deploy`,
`init`, `update`, `notification`, `publish`, `bump`, `release`.

```yaml
Type: System.String
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 0
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: false
DontShow: false
AcceptedValues: [ info, version, --version, --help, build, test, package, deploy, init, update, notification, publish, bump, release ]
HelpMessage: ''
```

### -Arguments

Remaining CLI arguments passed to the selected command.

```yaml
Type: System.String[]
DefaultValue: ''
SupportsWildcards: false
Aliases: [ ]
ParameterSets:
  - Name: (All)
    Position: 1
    IsRequired: false
    ValueFromPipeline: false
    ValueFromPipelineByPropertyName: false
    ValueFromRemainingArguments: true
DontShow: false
AcceptedValues: [ ]
HelpMessage: ''
```

### CommonParameters

This cmdlet supports the common parameters: `-Debug`, `-ErrorAction`, `-ErrorVariable`, `-InformationAction`,
`-InformationVariable`, `-OutBuffer`, `-OutVariable`, `-PipelineVariable`, `-ProgressAction`, `-Verbose`,
`-WarningAction`, `-WarningVariable`, `-WhatIf`, and `-Confirm`.

## INPUTS

## OUTPUTS

### System.String

Returned for text-oriented commands such as `nova --help`, `nova version`, `nova version -Installed`, and
`nova --version`.

### PSCustomObject

Returned when the selected subcommand returns an object, for example `nova info`, `nova deploy`, `nova notification`,
or `nova update`.

### None

Some routed commands complete without returning an output object.

## NOTES

For interactive use, prefer the `nova` alias.

Use `Invoke-NovaCli` directly when you need the underlying PowerShell command in scripts, tests, or command dispatch
implementations.

`Invoke-NovaCli` uses `SupportsShouldProcess` to surface native `-WhatIf` and `-Confirm`, then forwards those switches
only to mutating subcommands.

## RELATED LINKS

- `Invoke-NovaBuild`
- `Install-NovaCli`
- `Deploy-NovaPackage`
- `Test-NovaBuild`
- `Update-NovaModuleTool`
- `Invoke-NovaRelease`
